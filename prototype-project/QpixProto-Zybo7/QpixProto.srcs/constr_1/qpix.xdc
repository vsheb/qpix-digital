#Clock signal
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports sysClk]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports sysClk]

#set_false_path -from [get_clocks -include_generated_clocks sys_clk_pin] -to [get_clocks clk_fpga_0]
#set_false_path -from [get_clocks -include_generated_clocks clk_fpga_0] -to [get_clocks sys_clk_pin]
#set_false_path -from [get_clocks -include_generated_clocks clk_out1_design_1_clk_wiz_0_0_1] -to [get_clocks clk_fpga_0]
#set_false_path -from [get_clocks -include_generated_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_fpga_0]
#set_false_path -from [get_clocks -include_generated_clocks clk_fpga_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0]
#set_false_path -from [get_clocks -include_generated_clocks clk_fpga_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0_1]
set_multicycle_path 2 -setup -from [get_clocks clk_out1_design_1_clk_wiz_0_0_1 ] -to [get_clocks clk_fpga_0] 
set_multicycle_path 1 -hold -from [get_clocks clk_out1_design_1_clk_wiz_0_0_1 ] -to [get_clocks clk_fpga_0]
set_multicycle_path 2 -setup -from [get_clocks clk_out1_design_1_clk_wiz_0_0] -to [get_clocks clk_fpga_0] 
set_multicycle_path 1 -hold -from [get_clocks clk_out1_design_1_clk_wiz_0_0 ] -to [get_clocks clk_fpga_0]

set_multicycle_path 2 -setup -from [get_clocks clk_fpga_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0_1] 
set_multicycle_path 2 -setup -from [get_clocks clk_fpga_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0]
set_multicycle_path 1 -hold  -from [get_clocks clk_fpga_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0]
set_multicycle_path 1 -hold  -from [get_clocks clk_fpga_0] -to [get_clocks clk_out1_design_1_clk_wiz_0_0_1]

#set_false_path -through [get_nets daqRx]
#set_false_path -through [get_nets daqTx]

#LEDs
#set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
#set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
#set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
#set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

