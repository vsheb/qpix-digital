import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge
from cocotb.triggers import RisingEdge, Timer, First, Join, Combine
from cocotb.decorators import coroutine
from cocotb.utils import get_sim_time

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
