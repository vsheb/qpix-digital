#
#

PWD=$(shell pwd)/../src

TOPLEVEL_LANG ?= vhdl
VHDL_SOURCES = $(PWD)/UtilityPkg.vhd  \
							 $(PWD)/QpixPkg.vhd \
							 $(PWD)/mem.vhd \
							 $(PWD)/EdgeDetector.vhd \
							 $(PWD)/QpixParser.vhd \
							 $(PWD)/QpixTestPatGen.vhd \
							 $(PWD)/QpixDataProc.vhd \
							 $(PWD)/UartRx.vhd \
							 $(PWD)/UartTx.vhd \
							 $(PWD)/UartTop.vhd \
							 $(PWD)/QpixEndeavorRx.vhd \
							 $(PWD)/QpixEndeavorTx.vhd \
							 $(PWD)/QpixEndeavorTop.vhd \
							 $(PWD)/QpixComm.vhd \
							 $(PWD)/QpixRegFile.vhd \
							 $(PWD)/QpixRoute.vhd \
							 $(PWD)/QpixAsicTop.vhd \
							 $(PWD)/imp/QpixAsicArray.vhd \
							 $(PWD)/imp/QpixAsicArrayDaq.vhd 

########################################
# FifoSync generics 
########################################
FWFT_EN_G=True
ADDR_WIDTH_G=8
########################################

SIM ?= questa
GHDL_ARGS   ?= -fsynopsys --std=93c -fexplicit
SIM_ARGS = -t ps
WAVES = 1

# cocotb test module
MODULE = test_qpix
# hdl top level entiry (must be lowercase!)
TOPLEVEL = qpixasicarraydaq

## generics are set through simulator arguments
#SIM_ARGS += -gFWFT_EN_G=$(FWFT_EN_G) -gADDR_WIDTH_G=$(ADDR_WIDTH_G)
#COMPILE_ARGS += -2008

# save waveforms for ghdl (WAVES=1 doesn't work for it)
ifeq ($(SIM),ghdl) 
	SIM_ARGS += --vcd=${TOPLEVEL}.vcd
endif


include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf modelsim.ini transcript __pycache__ results.xml vsim.wlf
