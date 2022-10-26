#!/usr/bin/env python3
from cocotb_test.simulator import run
import pytest
import os

#************************************************
# GENERICS
#************************************************
TopLevelGenericsFull = {
    "X_NUM_G" : "14", 
    "Y_NUM_G" : "10", 
    "INDIVIDUAL_CLK_G" : "True",
    "N_ZER_CLK_G" : "8", 
    "N_ONE_CLK_G" : "24",
    "N_GAP_CLK_G" : "16",
    "N_FIN_CLK_G" : "40",
    "N_ZER_MIN_G" : "4", 
    "N_ZER_MAX_G" : "12",
    "N_ONE_MIN_G" : "16",
    "N_ONE_MAX_G" : "32",
    "N_GAP_MIN_G" : "8", 
    "N_GAP_MAX_G" : "32",
    "N_FIN_MIN_G" : "32"
  }

TopLevelGenericsFast = {
    "X_NUM_G" : "3", 
    "Y_NUM_G" : "3", 
    # "X_NUM_G" : "14", 
    # "Y_NUM_G" : "10", 
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

def test_qpix():

  if os.environ.get('FASTSIM') == '1' :
    TopLevelGenerics = TopLevelGenericsFast;
    print('FAST!!')
  else :
    TopLevelGenerics = TopLevelGenericsFull;
    print('FULL!!')

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
    # sim_args      = ["-voptargs=+acc"],
    sim_args      = ["-t","ps","-voptargs=+acc"],
    extra_args    = [],
    compile_args  = [],
    # testcase      = "test_manual_routing",
    # testcase      = "test_single_point_failure",
    testcase      = "test_hits_readout",
    parameters    = TopLevelGenerics,
    force_compile = True )
 
if __name__ == "__main__":
  test_qpix()

