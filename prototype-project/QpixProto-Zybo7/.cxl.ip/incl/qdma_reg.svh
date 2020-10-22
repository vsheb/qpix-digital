//////////////////////////////////////////////////////////////////////////////
// be767e8644eee50b2645307571242b99d62eea726bb276dae1cba7a07fa60690
// Proprietary Note:
// XILINX CONFIDENTIAL
//
// Copyright 2017 Xilinx, Inc. All rights reserved.
// This file contains confidential and proprietary information of Xilinx, Inc.
// and is protected under U.S. and international copyright and other
// intellectual property laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
// US ExportControl: EAR 3E001
//
//       Owner:          cthyamag
//       Revision:       $Id: //depot/icm/proj/everest/7t_n1/rtl/ref_7t_n1_live/header.v#1 $
//                       $Author: djue$
//                       $DateTime: 2016/07/08 17:50:57 $
//                       $Change: 7769758 $
//       Description:
//
//////////////////////////////////////////////////////////////////////////////

`ifndef DMA_REG_SVH
`define DMA_REG_SVH

typedef enum logic [5:0] { // Address       // Struct
    DMA_GLBL1_IDENTIFIER_A= 0,              // dma_reg_identifier_t
    DMA_GLBL1_BUSDEV_A       = 6'h1,        // Busdevfunction
    DMA_GLBL1_PCIE_EFF_MPL_A = 6'h2,        // PCIE effect max payload size
    DMA_GLBL1_PCIE_EFF_MRS_A = 6'h3,        // PCIE effective max read request size
    DMA_GLBL1_SYSTEM_ID_A    = 6'h4,        // System ID 
    DMA_GLBL1_MSI_MSIX_EN_A  = 6'h5,        // MSIX, MSI enable status
    DMA_GLBL1_DAT_WIDTH_A    = 6'h6,        // Effective datapath width
    DMA_GLBL1_PCIE_CFG_A     = 6'h7,        // PCIE relaxed ordering 
    DMA_GLBL1_AXI_EFF_MPL_A  = 6'h10,       // AXI MM effective max payload
    DMA_GLBL1_AXI_EFF_MRS_A  = 6'h11,       // AXI MM effective max read request size
    DMA_GLBL1_DMA_CFG_A      = 6'h13,       // (RQ metering multiplier, num tag, xdma axi fetch/wb)
    DMA_GLBL1_XDMA_WTO_A     = 6'h18,       // Xdma c2h st write timeout
    DMA_GLBL1_SCRATCH0_A     = 6'h20,       // Scratch registers
    DMA_GLBL1_SCRATCH1_A     = 6'h21,       // Scratch registers
    DMA_GLBL1_SCRATCH2_A     = 6'h22,       // Scratch registers
    DMA_GLBL1_SCRATCH3_A     = 6'h23,       // Scratch registers
    DMA_GLBL1_SCRATCH4_A     = 6'h24,       // Scratch registers
    DMA_GLBL1_SCRATCH5_A     = 6'h25,       // Scratch registers
    DMA_GLBL1_SCRATCH6_A     = 6'h26,       // Scratch registers
    DMA_GLBL1_SCRATCH7_A     = 6'h27,       // Scratch registers
    DMA_GLBL1_GIC_A          = 6'h28,       // GIC generation
    DMA_GLBL1_BP0_A          = 6'h30,       // Backpressure ctl RQ
    DMA_GLBL1_BP1_A          = 6'h31,       // Backpressure ctl RC
    DMA_GLBL1_BP2_A          = 6'h32,       // Backpressure ctl CQ
    DMA_GLBL1_BP3_A          = 6'h33,       // Backpressure ctl CC
    DMA_GLBL1_RAM_MSK_SBE_A  = 6'h3c,       // dma_reg_ram_t
    DMA_GLBL1_RAM_STS_SBE_A  = 6'h3d,       // dma_reg_ram_t
    DMA_GLBL1_RAM_MSK_DBE_A  = 6'h3e,       // dma_reg_ram_t
    DMA_GLBL1_RAM_STS_DBE_A  = 6'h3f        // dma_reg_ram_t
} dma_glbl1_csr_addr_e;


typedef enum logic [5:0] { // Address            // Struct
    DMA_GLBL2_IDENTIFIER_A= 0,      // dma_reg_identifier_t
    DMA_GLBL2_PF_BARLITE_INT_A,     // dma_reg_barlite_map_t
    DMA_GLBL2_PF_VF_BARLITE_INT_A,  // dma_reg_barlite_map_t
    DMA_GLBL2_PF_BARLITE_EXT_A,     // dma_reg_barlite_map_t
    DMA_GLBL2_PF_VF_BARLITE_EXT_A,  // dma_reg_barlite_map_t
    DMA_GLBL2_CHANNEL_INST_A,       // dma_reg_channel_t     // Which engines are instantiated.  1 bit per engine (see struct)
    DMA_GLBL2_CHANNEL_MDMA_A,       // dma_reg_channel_t     // The dma mode of each engine  1: mdma; 0: xdma.  Valid if engine instantiated. 1 bit per engine.
    DMA_GLBL2_CHANNEL_STRM_A,       // dma_reg_channel_t     // The interface mode of each engine 1: stream: 0: MM.   1 bit per engine.
    DMA_GLBL2_MDMA_CAP_A,           // dma_reg_mdma_cap_t
    DMA_GLBL2_XDMA_CAP_A,           // dma_reg_xdma_cap_t
    DMA_GLBL2_PASID_CAP_A,          // dma_reg_pasid_cap_t
    DMA_GLBL2_FUNC_RET_A,           // function[7:0]         // Returns function number

    DMA_GLBL2_DBG_MATCH_SEL_A = 6'h3d,      
    DMA_GLBL2_DBG_MATCH_MSK_A = 6'h3e,      
    DMA_GLBL2_DBG_MATCH_PAT_A = 6'h3f      
} dma_glbl2_csr_addr_e;

typedef struct packed {
    logic [10:0] id;
    logic        mdma;
    logic [3:0] target; 
    logic [7:0] rsv;
    logic [7:0] version;
}  dma_reg_identifier_t;

typedef struct packed {
    logic [1:0]   rsv;
    logic [5:0]   pf3_bar_map;
    logic [5:0]   pf2_bar_map;
    logic [5:0]   pf1_bar_map;
    logic [5:0]   pf0_bar_map;
}  dma_reg_barlite_map_t;

typedef struct packed {
    logic         c2h_mdma_chnl;
    logic         h2c_mdma_chnl;
    logic [3:0]   rsv1;
    logic [3:0]   c2h_xdma_chnl;
    logic [3:0]   rsv0;
    logic [3:0]   h2c_xdma_chnl;
} dma_reg_channel_t;

typedef struct packed {
    logic [31:12] rsv;
    logic [11:0]  max_queue;
} dma_mdma_cap_t;

typedef struct packed {
    logic [31:2]  rsv;
    logic         xdma_axi_wbk;
    logic         xdma_axi_fetch;
} dma_xdma_cap_t;

typedef struct packed {
    logic [11:0]  brg_pasid_wr_base;     // Only used if brg_share_pasid_dis == 1
    logic [11:0]  brg_pasid_base;
    logic         brg_shared_pasid_dis;
    logic         dma_shared_pasid_dis;
    logic         brg_pasid_en;
    logic         dma_pasid_en;
} dma_pasid_cap_t;

typedef struct packed {
    logic          pfch_ll_ram;
    logic          wrb_ctxt_ram;
    logic          pfch_ctxt_ram;
    logic          desc_req_fifo_ram;
    logic          int_ctxt_ram;
    logic          int_qid2vec_ram;
    logic          wrb_coal_data_ram;
    logic          tuser_fifo_ram;
    logic          qid_fifo_ram;
    logic          payload_fifo_ram;
    logic [3:0]    timer_fifo_ram;
    logic          pasid_ctxt_ram; 
    logic          mi_h2c_pcie_dsc_cpld; //  XDMA DSC RAM; MDMA DSC RAM
    logic          mi_h2c_pcie_dsc_cpli; //  XDMA unused;  MDMA DSC INFO
    logic          mi_sw_ctxt;
    logic          mi_dsc_crd_rcv;
    logic          mi_hw_ctxt;
    logic          mi_func_map;   // use ony 256 entries
    logic          mi_c2h_wr_brg_dat; // Bridge Slave
    logic          mi_c2h_rd_brg_dat; // Bridge Slave
    logic          mi_h2c_wr_brg_dat; // Bridge Master
    logic          mi_h2c_rd_brg_dat; // Bridge Master
    logic          xdma_dsc_ram;
    logic          mi_c2h3_dat;  // XDMA C2H3
    logic          mi_c2h2_dat;  // XDMA C2H2
    logic          mi_c2h1_dat;  // XDMA C2H1; MDMA MM1
    logic          mi_c2h0_dat;  // XDMA C2H0; MDMA MM0
    logic          mi_h2c3_dat;  // XDMA H2C3  MDMA C2H ST PAYLOAD
    logic          mi_h2c2_dat;  // XDMA H2C2  MDMA H2C ST
    logic          mi_h2c1_dat;  // XDMA H2C1; MDMA MM1
    logic          mi_h2c0_dat;
} dma_reg_ram_t;


`endif
