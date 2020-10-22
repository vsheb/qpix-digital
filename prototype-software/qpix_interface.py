#!/usr/bin/env python3

import socket
import struct
import sys

import time
  

QP_IP      = '192.168.1.10'
QP_PORT    = 7
BUFFER_SIZE = 1024

REG_ADDR    = {
  'CMD'           : 0x0a,
  'EVTSIZE'       : 0x4,
  'ASICMASK'      : 0x2,
  'HITTS'         : 0x3,
  'TRGTIME'       : 0x5
}

################################################

class QPController:
  def __init__(self, ip = QP_IP, port = QP_PORT, buf_sz = BUFFER_SIZE):
    self.s = QPInterface(ip, port, buf_sz)

  def sendTrg(self) :
    self.s.regWrite(REG_ADDR['CMD'],0x1);

  def resetAsicState(self) :
    s.regWrite((0x3<<10) + 1,2);

  ##############
  # data format
  def getDataY(self, lsb, msb) : 
    return msb & 0xf

  def getDataX(self, lsb, msb) : 
    return (msb >> 4) & 0xf

  def getWordType(self, lsb,msb) : 
    return (msb >> 24) & 0xf 
  #############

  def injectHit(self, x, y, ts) : 
    self.s.regWrite(REG_ADDR['HITTS'],ts)
    self.s.regWrite(REG_ADDR['ASICMASK'], (x << 16) + y)

  def resetRouteState(self) : 
    self.s.regWrite((0x3<<10) + (0<<4) + 1,2)

  def setAsicDirMask(self, x = 0, y = 0, mask = 0) :
    self.s.regWrite((0x3<<10) + (1<<9) + ((x&0b111)<<6) + ((y&0b111)<<3) + 3,0x10 + (mask&0xf))

  def clearAsicDirMask(self, x = 0, y = 0) :
    self.s.regWrite((0x3<<10) + (1<<9) + ((x&0b111)<<6) + ((y&0b111)<<3) + 3,0)

  def setAsicsTimeout(self, timeout = 0) :
    self.s.regWrite((0x3<<10) + 2,timeout)

  def readEvent(self):
    recvd = [['x' for i in range(3)] for j in range(3)]
    siz = self.s.regRead(REG_ADDR['EVTSIZE']) 
    trgt = self.s.regRead(REG_ADDR['TRGTIME'])
    print('TRG time : ',trgt & 0xffff)
    for i in range(siz) :
      b0 = self.s.memRead(i*4)
      b1 = self.s.memRead(i*4+1)
      b2 = self.s.memRead(i*4+2)
      b3 = self.s.memRead(i*4+3)
      x  = self.getDataX(b0,b1)
      y  = self.getDataY(b0,b1)
      w  = self.getWordType(b0,b1)
      if w == 5 :
        recvd[y][x] = 'o'
      # print(hex(b0),hex(b1))
      print(0xffff&b2,': ',hex(b1),hex(b0), 'time0: ', (b0>>16)&0xffff,' time:',b0&0xffff,'X:',x,'Y:',y,"Word type:",w)
    for l in recvd :
      st = ''.join(str(it) for it in l)
      print(st)

  def readFifoCnt(self, x = 0, y = 0) :
    s.regRead((0x2<<10) + ((y&0xf)<<4) + (0xf&x))



################################################

class QPInterface:
  def __init__(self, ip = QP_IP, port = QP_PORT, buf_sz = 1024, socket = None):
    self.ip     = ip
    self.port   = port
    self.buf_sz = buf_sz

    if socket is None:
      self._connect()
    else:
      self.socket = socket

  def memRead(self, addr) :
    v = self.regRead((0x1<<10) + addr)
    return int(v)

  # Register read
  def regRead(self, addr):
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

  ################################################
  # Private methods
  ################################################

  # Convert short to big-endian
  def _shortToBigEndian(self, short_val):
    return struct.pack('>H', short_val)
  # Convert int to big-endian
  def _intToBigEndian(self, int_val):
    return struct.pack('>I', int_val)
  def _intToLittleEndian(self, int_val):
    return struct.pack('<I', int_val)

  # Receive int from socket and convert it from big-endian
  def _recvInt(self):
    val = self.socket.recv(4)
    # print(val)
    return struct.unpack('<I', val)[0]

  def _connect(self):
    try:
      self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
      self.socket.connect((self.ip, self.port))
    except Exception as exc:
      print(exc)
      sys.exit(0)

################################################

if __name__ == '__main__':
  print(QPInterface(QP_IP, QP_PORT).performCmd('REGRE 32'))
  # main()

