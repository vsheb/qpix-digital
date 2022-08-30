#!/usr/bin/env python3
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.triggers import RisingEdge, Timer, First, Join, Combine
from cocotb.decorators import coroutine
from cocotb.utils import get_sim_time

from cocotb_test.simulator import run
import pytest
import os
import random
import logging

from collections import namedtuple
import numpy as np
import pprint

log = logging.getLogger("cocotb")

################################################################
# Helper coroutines
################################################################
# wait until condition satisfies
@coroutine
async def WaitClockedCond(clk, cond):
    while True:                       
        await RisingEdge(clk)          
        if cond():                     
            break                      

# wait for a number of clock cycles
@coroutine
async def TimerClk(clk, cnt):
  for _ in range(cnt):
    await RisingEdge(clk)   

# DUT sync reset
@coroutine
async def SyncResetDUT(clk, rst):
  await RisingEdge(clk)
  rst.value = 1
  await RisingEdge(clk)
  rst.value = 0
  await RisingEdge(clk)

# async reset
@coroutine
async def AsyncResetDUT(rst, duration=100, units = 'ns'):
  rst.value = 1
  await Timer(duration, units=units)
  rst.value = 0
################################################################

################################################################
# Qpix data format description
################################################################
QpixHitData = namedtuple('QpixHitData', 'wordType chanMask xPos yPos timestamp')

def QpixDataFormat(data = 0):
  wordType  = (data >> 56) & 0xf
  chanMask  = (data >> 40) & 0xff
  xPos      = (data >> 36) & 0xf
  yPos      = (data >> 32) & 0xf
  timestamp = (data >>  0) & 0xffff

  return QpixHitData(wordType, chanMask, xPos, yPos, timestamp)
################################################################


################################################################
# Send a register request to the Qpix Array
################################################################
@coroutine
async def QpixRegRequest(dut, x = 0, y = 0, dest = 0, opWrite = 0, reqID = 0, addr = 0, data = 0):
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

  await RisingEdge(dut.clk)
  dut.daqTxByte.value = v
  dut.daqTxByteValid.value = 1
  await RisingEdge(dut.clk)
  dut.daqTxByteValid.value = 0 
  await RisingEdge(dut.clk)
################################################################

  

################################################################
# Continuously print FSM states for the array
################################################################
@coroutine 
async def QpixPrintArray(dut):
  """docstring for QpixPrintArray"""

  nX, nY = int(dut.X_NUM_G.value), int(dut.Y_NUM_G.value)

  state_array = [[0 for i in range(nX)] for j in range(nY)]
  
  while True : 
    await RisingEdge(dut.clk)
    trig = False
    for y in range(nY) : 
      for x in range(nX) : 
        v = dut.QpixAsicArray_U.GEN_X[x].GEN_Y[y].QpixAsicTop_U.QpixRoute_U.curReg.state.value;
        if v != state_array[y][x] : trig = True
        state_array[y][x] = v

    if trig :
      print("******FSM*******")
      for r in state_array:
        print(r)
      print("****************")
################################################################
  



   

################################################################
# Receive data from the Qpix array
################################################################
@coroutine
async def QpixReceive(dut) : 

  nX, nY = int(dut.X_NUM_G.value), int(dut.Y_NUM_G.value)

  evtEndCnt = 0
  stat_matrix = [[0 for i in range(nX)] for j in range(nY)] 
  fin_matrix = [[1 for i in range(nX)] for j in range(nY)] 
  
  while True:
    await RisingEdge(dut.clk)
    if dut.daqRxByteValid.value == 1 : 
      hitData = QpixDataFormat(dut.daqRxByte.value)
      print(hitData, int(dut.daqTimestamp.value))
      if hitData.wordType == 5 : 
        stat_matrix[hitData.yPos][hitData.xPos] = 1
        for r in stat_matrix:
          print(r)
        # if hitData.xPos == nX-1 and hitData.yPos == nY-1 : 
        if stat_matrix == fin_matrix: 
          break
    # if evtEndCnt == nX*nY : 

################################################################
# Send a hit to the specific ASIC
################################################################
@coroutine
async def QpixInjectHits(dut, x, y, chanMask) : 
  await TimerClk(dut.clk, 10)
  dut.inPortsArr[y][x].value = chanMask
  await RisingEdge(dut.clk)
  await RisingEdge(dut.clk)
  dut.inPortsArr[y][x].value = 0
  await TimerClk(dut.clk, 10)

  

################################################################
# Perform tests
################################################################
@cocotb.test()
async def test_qpix(dut):
  # dut._log.setLevel(logging.DEBUG)
  """ test """

  nX = dut.X_NUM_G.value
  nY = dut.Y_NUM_G.value

  # daq clock
  clock = Clock(dut.clk, 100, units='ns')  # 
  cocotb.start_soon(clock.start())

  vv = dut.daqTimestamp.value

  # independent clock for every ASIC in the array
  clocks = [[0]*nX]*nY
  freq = np.random.normal(100,10,(nY,nX)).astype(int) 
  print(freq)
  for j in range(nY) : 
    for i in range(nX) : 
      clocks[j][i] = Clock(dut.clkVec[j*nX+i], freq[j][i], units='ns')
      cocotb.start_soon(clocks[j][i].start())

  # start monitoring 
  qpix_receive = cocotb.start_soon(QpixReceive(dut))
  qpix_print   = cocotb.start_soon(QpixPrintArray(dut))
  
  # set initial values for the input ports
  for i in range(nX) : 
    for j in range(nY) :
      dut.inPortsArr[i][j].value = 0

  await TimerClk(dut.clk, 10)

  print("Inject hits");
  for i in range(10) : 
    await QpixInjectHits(dut, x = 2, y = 2, chanMask = 1)

  print("Interrogation")
  await QpixRegRequest(dut, x = 0, y = 0, dest = 0, opWrite = 1, reqID = 1, addr = 1, data = 1)

  # wait until all ASIC responses's been collected
  await qpix_receive

  # reset state
  await QpixRegRequest(dut, x = 0, y = 0, dest = 0, opWrite = 1, reqID = 2, addr = 1, data = 2) 

  await Timer(1000, 'ns')

################################################################


#************************************************
# GENERICS
#************************************************
TopLevelGenerics = {
    "X_NUM_G" : "5", 
    "Y_NUM_G" : "5", 
    "INDIVIDUAL_CLK_G" : "False",
    "N_ZER_CLK_G" : "2",  #"8", 
    "N_ONE_CLK_G" : "5", #"24",
    "N_GAP_CLK_G" : "4", #"16",
    "N_FIN_CLK_G" : "7", #"40",
    "N_ZER_MIN_G" : "1",  #"4", 
    "N_ZER_MAX_G" : "3", #"12",
    "N_ONE_MIN_G" : "4", #"16",
    "N_ONE_MAX_G" : "6", #"32",
    "N_GAP_MIN_G" : "3",  #"8", 
    "N_GAP_MAX_G" : "5", #"32",
    "N_FIN_MIN_G" : "6"  #"32"
  }

#************************************************

def run_test_fifo():

  source_dir = "../src"
  source_files = ["UtilityPkg.vhd", "QpixPkg.vhd", "mem.vhd", "EdgeDetector.vhd", "QpixParser.vhd", 
  "QpixTestPatGen.vhd", "QpixDataProc.vhd", "UartRx.vhd", "UartTx.vhd", "UartTop.vhd", 
  "QpixEndeavorRx.vhd", "QpixEndeavorTx.vhd", "QpixEndeavorTop.vhd", 
  "QpixComm.vhd", "QpixRegFile.vhd", "QpixRoute.vhd", "QpixAsicTop.vhd", 
  "imp/QpixAsicArray.vhd", "imp/QpixAsicArrayDaq.vhd"]
  vhdl_sources = [os.path.join(source_dir, f) for f in source_files]

  print(vhdl_sources)

  run(
    vhdl_sources  = vhdl_sources,
    toplevel      = "qpixasicarraydaq",
    module        = "test_qpix",
    toplevel_lang = "vhdl",
    waves         = 1,
    sim_args      = ["-t","ps","-voptargs=+acc"],
    extra_args    = [],
    compile_args  = [],
    parameters    = TopLevelGenerics,
    force_compile = True )
 
if __name__ == "__main__":
  run_test_fifo()





