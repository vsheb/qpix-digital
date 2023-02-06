import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, First, Join, Combine
from cocotb.decorators import coroutine

import pytest
import os
import random
import logging

from collections import namedtuple
import numpy as np

from mycocolib import *

log = logging.getLogger("cocotb")

################################################################
# Qpix data format description
################################################################
QpixHitData = namedtuple('QpixHitData', 'wordType chanMask xPos yPos timestamp')

def QpixDataFormat(data = 0):
  wordType  = (data >> 56) & 0xf
  chanMask  = (data >> 40) & 0xff
  xPos      = (data >> 36) & 0xf
  yPos      = (data >> 32) & 0xf
  timestamp = (data >>  0) & 0xffffffff

  return QpixHitData(wordType, chanMask, xPos, yPos, timestamp)

QpixRegData = namedtuple('QpixRegData', 'wordType reqID x y addr data')
def QpixRegFormat(data = 0) : 
  wordType  = (data >> 56) & 0xf
  reqID     = (data >> 49) & 0xf
  xPos      = (data >> 36) & 0xf
  yPos      = (data >> 32) & 0xf
  addr      = (data >> 16) & 0xffff
  regData   = (data >>  0) & 0xffff
  return QpixRegData(wordType, reqID, xPos, yPos, addr, regData)

def QpixGetWordType(data = 0) : 
  wordType  = (data >> 56) & 0xf
  return wordType
################################################################

################################################################
def QpixReqFormat(x = 0, y = 0, dest = 0, reqID = 0, opWrite = 0, addr = 0, data = 0):
  v =  0x3 << 56 # word type
  v |= (opWrite & 1) << 55 
  v |= (1 - (opWrite&1)) << 54
  v |= dest << 53
  v |= (0xf & reqID) << 49
  v |= 0x1 << 48
  v |= x << 36
  v |= y << 32
  v |= addr << 16
  v |= data

  return v
################################################################
  
f = open("qpix_sim.txt","w")  

################################################################
# Continuously print FSM states for the array
################################################################
@coroutine 
async def QpixPrintArray(dut):
  """docstring for QpixPrintArray"""

  nX, nY = int(dut.X_NUM_G.value), int(dut.Y_NUM_G.value)

  state_array = [[0 for i in range(nX)] for j in range(nY)]
  fifoext_array = [[0 for i in range(nX)] for j in range(nY)]
  fifoloc_array = [[0 for i in range(nX)] for j in range(nY)]
  
  while True : 
    await RisingEdge(dut.clk)
    trig = False
    for y in range(nY) : 
      for x in range(nX) : 
        v = dut.QpixAsicArray_U.GEN_X[x].GEN_Y[y].QpixAsicTop_U.QpixRoute_U.curReg.state.value
        fl = int(dut.QpixAsicArray_U.GEN_X[x].GEN_Y[y].QpixAsicTop_U.QpixRoute_U.FIFO_LOC_U.i_cnt.value)
        fe = int(dut.QpixAsicArray_U.GEN_X[x].GEN_Y[y].QpixAsicTop_U.QpixRoute_U.FIFO_EXT_U.i_cnt.value)
        if v != state_array[y][x]    : trig = True
        if fl != fifoloc_array[y][x] : trig = True
        if fe != fifoext_array[y][x] : trig = True
        state_array[y][x]   = v
        fifoloc_array[y][x] = fl 
        fifoext_array[y][x] = fe 

    if trig :
      dut._log.debug("******FSM / FIFO_LOC / FIFO_EXT *******")
      for i in range(nY):
        dut._log.debug(f'{state_array[i]}, \t {fifoloc_array[i]}, \t {fifoext_array[i]}' )
        f.write(f'{state_array[i]}, \t {fifoloc_array[i]}, \t {fifoext_array[i]} \n' )
      dut._log.debug("****************")
      f.write('\n')
  f.close()
################################################################
  

################################################################
# DAQ-node implementation
################################################################
class QpixDaq : 
  def __init__(self, dut):
    self.hits    = []
    self.markers = []
    self.inHits  = []
    self.regRsps = []

    self.reqID = 1
    self.dut = dut
    dut.rst.value = 0

    self.log = logging.getLogger("cocotb.tb")
    self.log.setLevel(logging.INFO)

    dut.EndeavorScale.value = 4

    self.nX, self.nY = int(dut.X_NUM_G.value), int(dut.Y_NUM_G.value)

    self.transact_time = (self.dut.N_ONE_CLK_G.value + self.dut.N_GAP_CLK_G.value) * 64 + self.dut.N_FIN_CLK_G.value 
    self.timeout0 = self.transact_time*(self.nX + self.nY + self.nX*self.nY) + 100 
    # set initial values for the input ports
    for i in range(self.nX) : 
      for j in range(self.nY) :
        dut.inPortsArr[i][j].value = 0

    self.rsp_matrix = [[0 for i in range(self.nX)] for j in range(self.nY)] 
    self.stat_matrix = [[0 for i in range(self.nX)] for j in range(self.nY)] 
    self.fin_matrix = [[1 for i in range(self.nX)] for j in range(self.nY)] 
    self.expected_martix = [[1 for i in range(self.nX)] for j in range(self.nY)]

  def ResetEvent(self):
    self.hits = []
    self.markers = []
    self.inHits  = []
    self.regRsps = []


  @coroutine
  async def Reset(self) : 
    await RisingEdge(self.dut.clk)
    self.dut.rst.value = 1
    await TimerClk(self.dut.clk, 3)
    self.dut.rst.value = 0
    await RisingEdge(self.dut.clk)


  # Receive data from the Qpix array
  @coroutine
  async def QpixReceive(self) : 

    while True:
      self.dut.daqRxByteAck.value = 1
      await RisingEdge(self.dut.clk)
      if self.dut.daqRxByteValid.value == 1 : 
        self.dut.daqRxByteAck.value = 1
        dat = self.dut.daqRxByte.value
        w   = QpixGetWordType(dat) 
        if w  == 5 : 
          hitData = QpixDataFormat(dat)
          self.log.debug(f'{hitData} {int(self.dut.daqTimestamp.value)}')
          self.markers.append(hitData)
          self.stat_matrix[hitData.yPos][hitData.xPos] += 1
          assert self.stat_matrix[hitData.yPos][hitData.xPos] < 2, "ASIC finish word received twice"
        elif w  == 1 : 
          hitData = QpixDataFormat(dat)
          self.hits.append(hitData)
        elif w == 4 : 
          regData = QpixRegFormat(dat)
          self.log.debug(regData)
          self.stat_matrix[regData.y][regData.x] += 1
          self.rsp_matrix[regData.y][regData.x]  += 1
          self.regRsps.append(regData) 
        else : 
          assert "Wrong word type received by DAQ node" 

        self.log.debug("******** DAQ *********")
        for r in self.stat_matrix:
          self.log.debug(r)
        self.log.debug("**********************")


  @coroutine
  async def WaitAllHitsCollected(self) : 
    timeout_cnt = 0
    timeout = 2*(self.timeout0 + self.transact_time * len(self.inHits))
    while self.stat_matrix != self.fin_matrix: 
      await RisingEdge(self.dut.clk)
      timeout_cnt += 1
      if timeout_cnt > timeout : 
        print("WaitAllHitsCollected :: timed out")
        break
    if self.stat_matrix != self.expected_martix : assert "Missing responses"
    print("All hits collected, CLK_CNT =",timeout_cnt)

  @coroutine
  async def WaitRegResponse(self) : 
    while len(self.regRsps) != 9: 
      await RisingEdge(self.dut.clk)


  # Send a register request to the Qpix Array
  @coroutine
  async def QpixRegRequest(self, x = 0, y = 0, dest = 0, opWrite = 0, addr = 0, data = 0):

    self.reqID += 1
    v = QpixReqFormat(x, y, dest, self.reqID, opWrite, addr, data)

    self.rsp_matrix = [[0 for i in range(self.nX)] for j in range(self.nY)] 
    self.stat_matrix = [[0 for i in range(self.nX)] for j in range(self.nY)] 

    # wait until TX is ready
    while True:
      if self.dut.daqTxByteReady.value == 1 : break
      await RisingEdge(self.dut.clk)

    self.dut.daqTxByte.value = v
    self.dut.daqTxByteValid.value = 1
    await RisingEdge(self.dut.clk)
    self.dut.daqTxByteValid.value = 0 
    await RisingEdge(self.dut.clk)

  @coroutine
  async def Interrogation(self) : 
    # send interrogation comman
    await self.QpixRegRequest(opWrite = 1, addr = 1, data = 1)
    # wait until all the hits are collected
    await self.WaitAllHitsCollected()
    # reset ASIC sates
    # await self.QpixRegRequest(opWrite = 1, addr = 1, data = 2) 

  async def RegRead(self, x = -1, y = -1, addr = 0) : 
    self.regRsps = []
    if x >= 0 and y >= 0 : 
      xx, yy, dd, n = x, y, 1, 1
    else :  
      xx, yy, dd, n = 0, 0, 0, self.nX*self.nY

    await self.QpixRegRequest(x = xx, y = yy, dest = dd, opWrite = 0, addr = addr)

    cnt = 0

    while cnt < self.timeout0 :
      if len(self.regRsps) == n : break
      await RisingEdge(self.dut.clk)
      cnt += 1
    print("******** REG RSP *********")
    for r in self.rsp_matrix:
      print(r)
    print("**********************")

  async def RegWrite(self, x = -1, y = -1, addr = 0, value = 0) : 
    self.regRsps = []
    if x >= 0 and y >= 0 : 
      xx, yy, dd, n = x, y, 1, 1
    else :  
      xx, yy, dd, n = 0, 0, 0, self.nX*self.nY

    await self.QpixRegRequest(x = xx, y = yy, dest = dd, opWrite = 1, addr = addr, data = value)
    await TimerClk(self.dut.clk, 1000)


  # Send a hit to the specific ASIC
  @coroutine
  async def QpixInjectHits(self, x, y, chanMask, n = 1) : 
    clk = self.dut.QpixAsicArray_U.clkVec_s[y*self.nX + x]
    for _ in range(n) : 
      await RisingEdge(clk)
      self.dut.inPortsArr[x][y].value = chanMask
      await RisingEdge(clk)
      await RisingEdge(clk)
      self.dut.inPortsArr[x][y].value = 0
      t = int(self.dut.QpixAsicArray_U.GEN_X[x].GEN_Y[y].QpixAsicTop_U.QpixDataProc_U.TimeStamp.value) + 3
      self.inHits.append(QpixHitData(0x1, chanMask, x, y, t))
      await RisingEdge(clk)

  def CheckHits(self) : 
    assert len(self.hits) == len(self.inHits), "Wrong number of hits received"
    [print(q) for q in self.markers]
    hits_sorted = sorted(self.hits, key = lambda d : d.timestamp)
    for i in range(len(hits_sorted)) : 
      hit = hits_sorted[i]
      print(self.inHits[i], ' : ', hit)
      assert hit.wordType  == self.inHits[i].wordType, "Wrong word type"
      assert hit.xPos      == self.inHits[i].xPos, "Wrong x pos"
      assert hit.yPos      == self.inHits[i].yPos, "Wrong y pos"
      assert hit.chanMask  == self.inHits[i].chanMask, "Wrong chan mask"
      # assert hit.timestamp == self.inHits[i].timestamp, "Wrong timestamp"
    print("QPIX DAQ : All hits Okay")
    # [print(q) for q in daq.hits]
    # [print(q) for q in daq.markers]
################################################################


################################################################
# Wait until all ASICs comes into the IDLE state
################################################################
@coroutine
async def QpixWaitUntilAllIdle(dut) : 
  nX = dut.X_NUM_G.value
  nY = dut.Y_NUM_G.value
  state_array = [[0 for i in range(nX)] for j in range(nY)]
  state_idle  = [[0 for i in range(nX)] for j in range(nY)]
  while True : 
    await RisingEdge(dut.clk)
    for x in range(nX) : 
      for y in range(nY) : 
        state_array[y][x] = dut.QpixAsicArray_U.GEN_X[x].GEN_Y[y].QpixAsicTop_U.QpixRoute_U.curReg.state.value
    if state_array == state_idle : break 


  

