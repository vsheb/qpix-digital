#!/usr/bin/env python3
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.triggers import RisingEdge, Timer, First, Join, Combine 
from cocotb.decorators import coroutine
from cocotb.utils import get_sim_time
from cocotb.handle import Force, Freeze

from cocotb_test.simulator import run
import pytest
import os
import random
import logging

from collections import namedtuple
import numpy as np
import pprint

from termcolor import colored

from qpix_cocotb import *
from mycocolib import *

log = logging.getLogger("cocotb")

################################################################
# Initialize clocks
################################################################
def QpixStartClocks(dut):
  nX = dut.X_NUM_G.value
  nY = dut.Y_NUM_G.value

  # daq clock
  clock = Clock(dut.clk, 20, units='ns')  # 
  cocotb.start_soon(clock.start())

  vv = dut.daqTimestamp.value

  # generate independent clock for every ASIC in the array
  if dut.INDIVIDUAL_CLK_G.value : 
    clocks = [[0]*nX]*nY
    freq = np.random.normal(20,1,(nY,nX)).astype(int) 
    print(freq)
    for j in range(nY) : 
      for i in range(nX) : 
        clocks[j][i] = Clock(dut.clkVec[j*nX+i], freq[j][i], units='ns')
        cocotb.start_soon(clocks[j][i].start())
  ####
################################################################


################################################################
# Perform tests
################################################################
@cocotb.test()
async def test_hits_readout(dut):
  """ test """

  QpixStartClocks(dut)

  daq = QpixDaq(dut)

  # start monitoring 
  qpix_receive = cocotb.start_soon(daq.QpixReceive())
  qpix_print   = cocotb.start_soon(QpixPrintArray(dut))
  
  await TimerClk(dut.clk, 10)

  daq.log.info(colored("Inject hits",'cyan'));

  for x in range(dut.X_NUM_G.value):
    for y in range(dut.Y_NUM_G.value):
      await daq.QpixInjectHits(x, y, chanMask = 1,  n = 7)
  # await daq.QpixInjectHits(x = 2, y = 2, chanMask = 1,  n = 10)
  # await daq.QpixInjectHits(x = 1, y = 0, chanMask = 15, n = 10)
  # await daq.QpixInjectHits(x = 0, y = 1, chanMask = 7,  n = 10)
  # await daq.QpixInjectHits(x = 13, y = 9, chanMask = 7,  n = 50)
  
  daq.log.info("Interrogation")
  await daq.Interrogation()

  daq.CheckHits()

  await QpixWaitUntilAllIdle(dut)

  daq.log.info('All ASICs are idle at : %d ' % (get_sim_time('ns')))

  await Timer(2000, 'ns')
################################################################

################################################################
################################################################
@cocotb.test()
async def test_register_access(dut):
  # dut._log.setLevel(logging.DEBUG)
  """ test """

  QpixStartClocks(dut)


  daq = QpixDaq(dut)
  await daq.Reset()
  
  # start monitoring 
  qpix_receive = cocotb.start_soon(daq.QpixReceive())
  qpix_print   = cocotb.start_soon(QpixPrintArray(dut))

  await RisingEdge(dut.clk)  

  print('Send interrogation')
  await daq.Interrogation()

  await RisingEdge(dut.clk)
  await QpixWaitUntilAllIdle(dut)

  print("SEND REG REQUEST 1")
  for x in range(dut.X_NUM_G.value):
    for y in range(dut.Y_NUM_G.value):
      await daq.RegRead(x = x, y = y, addr = 3)

  print("SEND REG REQUEST 2")
  for x in range(dut.X_NUM_G.value):
    for y in range(dut.Y_NUM_G.value):
      await daq.RegRead(x = x, y = y, addr = 4)

  await TimerClk(dut.clk, 10)


################################################################


################################################################
# Test manual routing map
################################################################
@cocotb.test()
async def test_manual_routing(dut):

  QpixStartClocks(dut)

  daq = QpixDaq(dut)
  await daq.Reset()
  
  # start monitoring 
  qpix_receive = cocotb.start_soon(daq.QpixReceive())
  qpix_print   = cocotb.start_soon(QpixPrintArray(dut))

  await RisingEdge(dut.clk)  

  print('Send interrogation')
  await daq.Interrogation()

  daq.ResetEvent()

  await RisingEdge(dut.clk)
  await QpixWaitUntilAllIdle(dut)
  
  manUp    = 16 + 1 
  manRight = 16 + 2
  manDown  = 16 + 4
  manLeft  = 16 + 8
  
  print('Set up manual routing')
  await daq.RegWrite(0, 0, 3, manUp)
  await daq.RegWrite(1, 0, 3, manLeft)
  await daq.RegWrite(2, 0, 3, manLeft)
  await daq.RegWrite(0, 1, 3, manUp)
  await daq.RegWrite(1, 1, 3, manUp)
  await daq.RegWrite(2, 1, 3, manUp)
  await daq.RegWrite(0, 2, 3, manUp)
  await daq.RegWrite(1, 2, 3, manUp)
  await daq.RegWrite(2, 2, 3, manUp)

  await TimerClk(dut.clk, 1000)

  print("Inject hits");
  await daq.QpixInjectHits(x = 2, y = 2, chanMask = 1, n = 5)

  print('Interrogation')
  await daq.Interrogation()

  daq.CheckHits()

  await QpixWaitUntilAllIdle(dut)

  await TimerClk(dut.clk, 10)


################################################################

################################################################
# Test a single point failure
################################################################
@cocotb.test()
async def test_single_point_failure(dut):

  QpixStartClocks(dut)

  daq = QpixDaq(dut)
  await daq.Reset()
  
  # start monitoring 
  qpix_receive = cocotb.start_soon(daq.QpixReceive())
  qpix_print   = cocotb.start_soon(QpixPrintArray(dut))

  await RisingEdge(dut.clk)  

  for i in range(4):
    dut.QpixAsicArray_U.GEN_X[1].GEN_Y[1].QpixAsicTop_U.QpixComm_U.TxPortsArr[i].value = Force(0)
    dut.QpixAsicArray_U.GEN_X[1].GEN_Y[1].QpixAsicTop_U.QpixComm_U.RxPortsArr[i].value = Force(0)

  await daq.RegRead(-1, -1, 5)
  await TimerClk(dut.clk, 1000)

  await daq.RegWrite(2, 1, 3, 17)

  print('Send interrogation')
  await daq.Interrogation()
  

  await RisingEdge(dut.clk)
  await QpixWaitUntilAllIdle(dut)
  
  # await TimerClk(dut.clk, 1000)

  # print("Inject hits");
  # await daq.QpixInjectHits(x = 2, y = 2, chanMask = 1)

  # print('Interrogation')
  # await daq.Interrogation()

  # daq.CheckHits()

  # await QpixWaitUntilAllIdle(dut)

  # await TimerClk(dut.clk, 10)
################################################################

