connect -url tcp:127.0.0.1:3121
source /home/shebalin/work/q-pix/qpix-digital/prototype/QpixProto/QpixProto.sdk/QpixProtoTop_hw_platform_0/ps7_init.tcl
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zybo Z7 210351A77F8AA"} -index 0
rst -system
after 3000
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zybo Z7 210351A77F8AA"} -index 0
loadhw -hw /home/shebalin/work/q-pix/qpix-digital/prototype/QpixProto/QpixProto.sdk/QpixProtoTop_hw_platform_0/system.hdf -mem-ranges [list {0x40000000 0xbfffffff}]
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*" && jtag_cable_name =~ "Digilent Zybo Z7 210351A77F8AA"} -index 0
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zybo Z7 210351A77F8AA"} -index 0
dow /home/shebalin/work/q-pix/qpix-digital/prototype/QpixProto/QpixProto.sdk/qpix_ctrl/Debug/qpix_ctrl.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "ARM*#0" && jtag_cable_name =~ "Digilent Zybo Z7 210351A77F8AA"} -index 0
con
