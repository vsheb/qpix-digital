vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xilinx_vip
vlib modelsim_lib/msim/xil_defaultlib
vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/lib_cdc_v1_0_2
vlib modelsim_lib/msim/proc_sys_reset_v5_0_12

vmap xilinx_vip modelsim_lib/msim/xilinx_vip
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib
vmap xpm modelsim_lib/msim/xpm
vmap lib_cdc_v1_0_2 modelsim_lib/msim/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_12 modelsim_lib/msim/proc_sys_reset_v5_0_12

vlog -work xilinx_vip -64 -incr -sv -L smartconnect_v1_0 -L axi_protocol_checker_v2_0_2 -L axi_vip_v1_1_2 -L processing_system7_vip_v1_0_4 -L xilinx_vip "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/02c8/hdl/verilog" "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/b193/hdl" "+incdir+/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/include" "+incdir+/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/include" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/axi_vip_if.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/clk_vip_if.sv" \
"/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xil_defaultlib -64 -incr -sv -L smartconnect_v1_0 -L axi_protocol_checker_v2_0_2 -L axi_vip_v1_1_2 -L processing_system7_vip_v1_0_4 -L xilinx_vip "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/02c8/hdl/verilog" "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/b193/hdl" "+incdir+/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/include" "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/02c8/hdl/verilog" "+incdir+../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/b193/hdl" "+incdir+/opt/Xilinx/Vivado/2018.1/data/xilinx_vip/include" \
"/opt/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/opt/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/opt/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -64 -93 \
"/opt/Xilinx/Vivado/2018.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work xil_defaultlib -64 -93 \
"/home/shebalin/work/q-pix/qpix-digital/prototype-project/QpixProto-Minized/QpixProto.srcs/sources_1/bd/design_1/ip/design_1_processing_system7_0_0/design_1_processing_system7_0_0_sim_netlist.vhdl" \

vcom -work lib_cdc_v1_0_2 -64 -93 \
"../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_12 -64 -93 \
"../../../../QpixProto.srcs/sources_1/bd/design_1/ipshared/f86a/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -64 -93 \
"../../../bd/design_1/ip/design_1_proc_sys_reset_0_0/sim/design_1_proc_sys_reset_0_0.vhd" \
"../../../bd/design_1/sim/design_1.vhd" \
"/home/shebalin/work/q-pix/qpix-digital/prototype-project/QpixProto-Minized/QpixProto.srcs/sources_1/bd/design_1/ip/design_1_auto_pc_0/design_1_auto_pc_0_sim_netlist.vhdl" \

vlog -work xil_defaultlib \
"glbl.v"

