#!/usr/bin/env python3

import os
import socket
import struct
import sys
import glob

import time

from collections import namedtuple 
  

QP_IP      = '192.168.1.10'
QP_PORT    = 7
BUFFER_SIZE = 1024

###############################################
# QPix DAQ node registers
###############################################
REG_ADDR    = {
  'CMD'           : 0x0a,
  'EVTSIZE'       : 0x4,
  'ASICMASK'      : 0x2,
  'HITTS'         : 0x3,
  'TRGTIME'       : 0x5,
  'CHANMASK'      : 0x6}

ASIC_REQ_OFFSET = 0x3 << 16 # ASIC requests offset
FIFO_CNT_OFFSET = 0x2 << 16 # FIFO counters
EVT_MEM_OFFSET  = 0x1 << 16 # event memory


###############################################
# Data objects
###############################################
# class QpixHitData(namedtuple):
  # x: int
  # y: int
  # t: int
  # m: int
QpixHitData = namedtuple("QpixHitData", "x y t m")


# class QpixEvtEndRsp(namedtuple) :
  # x:  int
  # y:  int
  # t0: int
  # t1: int
QpixEvtEndRsp = namedtuple("QpixEvtEndRsp", "x y t0 t1")

# class QpixRegData(namedtuple) :
  # x    : int
  # y    : int
  # addr : int
  # data : int
QpixRegData = namedtuple("QpixRegData", "x y addr data")

# class QpixEvtStats(namedtuple) :
  # t_trg    : int
  # t_end    : int
  # n_hits   : int
  # fifo_cnt : int
  # ok       : bool 
  # err      : bool
  # hits     : list
QpixEvtStats = namedtuple("QpixEvtStats", "t_trg t_end n_hits fifo_cnt ok err hits")

class QPInterface:
  """
  Basic class for the communication with QPix prototype
  """
  def __init__(self, ip = QP_IP, port = QP_PORT, buf_sz = 1024, socket = None):
    self.ip     = ip
    self.port   = port
    self.buf_sz = buf_sz

    if socket is None:
      self._connect()
    else:
      self.socket = socket

  def memRead(self, addr) :
    v = self.regRead(EVT_MEM_OFFSET + addr)
    return int(v)

  def regRead(self, addr):
    """
    Register read
    """
    args = ['QRR',addr]
    self.send(args)
    rsp = self.socket.recv(4)
    val = self._recvInt()
    # print(hex(val))
    return val

  def regWrite(self, addr, val):
    args = ['QRW',addr,val]
    self.send(args)
    rsp = self.socket.recv(4)
    # print(rsp)

  def send(self, args):
    bytearr = self.pack(args)
    pkg_len = len(bytearr)
    self.socket.send(bytearr)

  def pack(self, data):
    if isinstance(data, str): data = data.split(' ')
    hdr = data[0]+'\0'
    # print(hdr)
    byte_arr = str.encode(hdr)
    # form byte message 
    for arg in data[1:]:
      if not isinstance(arg, int): arg = int(arg, 0)
      byte_arr += self._intToLittleEndian(arg)

    return byte_arr

  def _shortToBigEndian(self, short_val):
    """
    Convert short to big-endian
    """
    return struct.pack('>H', short_val)

  def _intToBigEndian(self, int_val):
    """
    Convert int to big-endian
    """
    return struct.pack('>I', int_val)

  def _intToLittleEndian(self, int_val):
    return struct.pack('<I', int_val)

  def _recvInt(self):

    """
    Receive int from socket and convert it from big-endian
    """
    val = self.socket.recv(4)
    # print(val)
    return struct.unpack('<I', val)[0]

  def _connect(self):
    try:
      self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      self.socket.connect((self.ip, self.port))
      print(f"Connection to port {self.ip}:{self.port}.. Established!")
    except Exception as exc:
      print(exc)
      sys.exit(0)

class QPController(QPInterface):
  """
  Controller class to manage interfacing socket, and to expose public
  commands for communicating with Prototype's DAQ nodes, and ASICs within
  the array.
  """
  def __init__(self, ip=QP_IP, port=QP_PORT, buf_sz=BUFFER_SIZE):
    super().__init__(ip, port, buf_sz)

  def sendTrg(self) :
    """
    Send interrogation (trigger) command
    """
    self.regWrite(REG_ADDR['CMD'],0x1);

  def resetRouteState(self) : 
    """
    Reset routing state of the ASIC (finish event)
    """
    self.regWrite((ASIC_REQ_OFFSET) + (0<<4) + 1,2)

  def setAsicDirMask(self, x=0, y=0, mask=0) :
    self.regWrite((ASIC_REQ_OFFSET) + (1<<9) + ((x&0b111)<<6) + ((y&0b111)<<3) + 3,0x10 + (mask&0xf))

  def clearAsicDirMask(self, x=0, y=0) :
    self.regWrite((ASIC_REQ_OFFSET) + (1<<9) + ((x&0b111)<<6) + ((y&0b111)<<3) + 3,0)

  def setAsicsTimeout(self, timeout=0) :
    """
    Set timeout for ASICs to be in reporting_remote state
    If 0 the ASIC waits for resetRouteState command
    to go back to the IDLE state
    """
    self.regWrite((ASIC_REQ_OFFSET)+2, timeout)

  def getDataY(self, lsb, msb) : 
    return msb & 0xf

  def getDataX(self, lsb, msb) : 
    return (msb >> 4) & 0xf

  def getWordType(self, lsb, msb) : 
    return (msb >> 24) & 0xf 

  def getFifoCnt(self, x, y) : 
    return self.regRead(FIFO_CNT_OFFSET + (y<<4) + x)

  def hitDataConv(self, lsb, msb) :
    x = (msb >> 4) & 0xf
    y = msb & 0xf 
    t = lsb 
    m = (msb >> 8) & 0xffff

    return QpixHitData(x,y,t,m)

  def evtDataConv(self, lsb, msb) :
    x  = (msb >> 4) & 0xf
    y  = msb & 0xf 
    t0 = (lsb>>16) & 0xffff
    t1 = lsb & 0xffff

    return QpixEvtEndRsp(x,y,t0,t1)

  def injectHit(self, x, y, ts, chmask=0) : 
    """
    Inject a single hit into given ASIC
    """
    self.regWrite(REG_ADDR['HITTS'],ts)         # set timestamp
    self.regWrite(REG_ADDR['CHANMASK'], chmask) # set channels mask
    self.regWrite(REG_ADDR['ASICMASK'], (x << 16) + y) # inject hits by asic mask

  def injectHits(self, hits):
    """
    Inject a list of the hits
    """
    for d in hits :
      self.injectHit(d.x,d.y,d.t,d.m)
  
  def readEvent(self):
    """
    Read event data from the memory
    """
    recvd = [['x' for i in range(3)] for j in range(3)]
    siz = self.regRead(REG_ADDR['EVTSIZE']) 
    t_trg = self.regRead(REG_ADDR['TRGTIME'])
    print('TRG time : ',t_trg & 0xffff)
    hits_list = []
    even_list = []
    t_daq = 0
    print('Event size', siz)
    for i in range(siz) :

      b0 = self.memRead(i*4)
      b1 = self.memRead(i*4+1)
      b2 = self.memRead(i*4+2)
      b3 = self.memRead(i*4+3)
      x  = self.getDataX(b0,b1)
      y  = self.getDataY(b0,b1)
      w  = self.getWordType(b0,b1)
      if w == 5 :
        if x in range(3) and y in range(3) :
          recvd[y][x] = 'o'
        even_list.append(self.evtDataConv(b0,b1))
        print(0xffff&b2,': ',hex(b1),hex(b0), 'time0: ', (b0>>16)&0xffff,' time:',b0&0xffff,'X:',x,'Y:',y,"Word type:",w)
      elif w == 1 :
        hits_list.append(self.hitDataConv(b0,b1))
        
      t_daq = b2

    for l in recvd:
      st = ''.join(str(it) for it in l)
      print(st)

    t_readout = t_daq - t_trg if t_daq > t_trg else 0xffffffff - t_trg + t_daq
    print('T_TRG = ',t_trg, 'T_DAQ = ', t_daq, 'T_READOUT = ',t_readout)
    
    hits_list = sorted(hits_list,key = lambda x : x.t)

    print('HITS READ : ', len(hits_list))
    
    evt_data = QpixEvtStats( t_trg = t_trg, 
        t_end    = t_daq, 
        n_hits   = len(hits_list), 
        fifo_cnt = 0, 
        ok       = (len(even_list) == 9), 
        err      = False, 
        hits     = hits_list)

    return evt_data
    # return even_list, hits_list

  def testEvent(self, hits_list_i) :
    """
    Inject list of the hits and check if 
    the one being read out is same
    """
    self.resetRouteState()
    self.injectHits(hits_list_i)
    self.sendTrg()
    ev = self.readEvent()
    if ev.hits == hits_list_i :
      print("\nSuccess!")
    return True

  def injectUniformN(self, n):
    for i in range(n):
      for x in range(3) :
        for y in range(3) :
          self.injectHit(x,y,n,123)

  def procUniform(self, oname='qqq.txt') :
    f = open(oname,"w")
    for n in range(35) : 
      self.resetRouteState()
      self.injectUniformN(n)
      self.sendTrg()
      siz = 0
      while siz != 9*(n+1) :
        siz = self.regRead(REG_ADDR['EVTSIZE']) 
      ev = self.readEvent()
      d_t = ev.t_end - ev.t_trg if ev.t_end > ev.t_trg else 0xffffffff - ev.t_trg + ev.t_end
      f.write("%d %d %d \n" % (d_t, ev.n_hits, ev.fifo_cnt))

  def readMC(self, filename='') :
    """
    Read MC hits from the file
    """
    res = [x.split(',') for x in open(filename).readlines()]
    resort = sorted(res, key = lambda x : int(x[2]))
    x_l = [int(l[0]) for l in res]
    x_avg = round(sum(x_l)/len(x_l))
    y_l = [int(l[1]) for l in res]
    y_avg = round(sum(y_l)/len(y_l))
    rebased = [ [int(t[0])-x_avg+6, int(t[1])-y_avg+6, int(t[2])] for t in resort ]
    hits = [ QpixHitData(t[0]//4, t[1]//4, t[2],(1 << (t[0]%4)+(t[1]%4)*4)) for t in rebased ]
    
    return hits
    # rebased = [ QpixHitData(int(t[0])-x_avg+6, int(t[1])-y_avg+6, int(t[2])]) for t in resort ]

  def procFile(self, fname='') : 
    """
    Process MC data from the file
    """
    print('Processing file : ', fname)
    self.resetRouteState()
    ll = self.readMC(fname)
    self.injectHits(ll)
    self.sendTrg()
    siz = 0
    print('Input Hits : ', len(ll))
    while siz != len(ll)+9 :
      siz = self.regRead(REG_ADDR['EVTSIZE']) 
    ev = self.readEvent()
    return ev

  def procDir(self, path='.', oname='qqq.txt') : 
    """
    Process all MC data files in the dir
    """
    f = open(oname,"w")
    for fn in glob.glob(os.path.join(path, '*.txt')):
      fname = os.path.join(os.getcwd(), fn)
      ev = self.procFile(fname)

      d_t = ev.t_end - ev.t_trg if ev.t_end > ev.t_trg else 0xffffffff - ev.t_trg + ev.t_end

      f.write("%d %d %d \n" % (d_t, ev.n_hits, int(ev.ok)))


if __name__ == '__main__':
  qpc = QPController()
  print(f"0x{qpc.regRead(0):02x}")
  print(f"0x{qpc.regRead(2**18+32):02x}")
  print(f"evtsize: 0x{qpc.regRead(REG_ADDR['EVTSIZE']):02x}")
  print(f"trigTime: 0x{qpc.regRead(REG_ADDR['TRGTIME']):02x}")
  time = 0
  print(f"setting timeout: {time:02x}")
  qpc.setAsicsTimeout(time)
  print(f"timeOut: 0x{qpc.regRead(ASIC_REQ_OFFSET+2):02x}")