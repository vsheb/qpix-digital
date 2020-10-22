`ifndef PCIE4_IF_DBG_PCIE_PORT
`define PCIE4_IF_DBG_PCIE_PORT 1
interface pciea_port_dbg_if();

  wire [255:0]         dbg_data0_out;
  wire [31:0]          dbg_ctrl0_out;
  wire [5:0]           dbg_sel0;
  wire [255:0]         dbg_data1_out;
  wire [31:0]          dbg_ctrl1_out;
  wire [5:0]           dbg_sel1;
  wire [129:0]         dbg_ccix_out;
  
  modport m (

     output            dbg_data0_out
    ,output            dbg_ctrl0_out
    ,input             dbg_sel0
    ,output            dbg_data1_out
    ,output            dbg_ctrl1_out
    ,input             dbg_sel1
    ,output            dbg_ccix_out
   
  );

  modport s (

     input             dbg_data0_out
    ,input             dbg_ctrl0_out
    ,output            dbg_sel0
    ,input             dbg_data1_out
    ,input             dbg_ctrl1_out
    ,output            dbg_sel1
    ,input             dbg_ccix_out

 );

endinterface : pciea_port_dbg_if
`endif // PCIE4_IF_DBG_PCIE_PORT
