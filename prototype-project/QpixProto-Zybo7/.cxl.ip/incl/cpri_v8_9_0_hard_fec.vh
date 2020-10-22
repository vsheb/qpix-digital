 ///////////////////////////////////////////////////////////////////////////////
 // Project: ieee802d3_rs_fec_v1_0_12
 // Company: Xilinx
 //
 // (c) Copyright 2015 Xilinx, Inc. All rights reserved.
 //
 // This file contains confidential and proprietary information
 // of Xilinx, Inc. and is protected under U.S. and
 // international copyright and other intellectual property
 // laws.
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
 ///////////////////////////////////////////////////////////////////////////////

`ifdef FASTSIM
  `timescale 1ns/1ns
`else
  `timescale 1ps/1ps
`endif


`ifndef _cpri_hard_fec_vh_
`define _cpri_hard_fec_vh_


`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC,NAME)  generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1)  begin :NAME assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end endgenerate

///////////////////////////////////////////////////////////////////////////////
//  rs_fec
///////////////////////////////////////////////////////////////////////////////

`define N_CONST           528
`define R_WIDTH             4
`define SYMBOL_WIDTH       10
`define T_CONST             7
`define R_CONST            14
`define WIDTH_4T            5
`define COUNT_PE_LIMIT     14

`define NO_REG              0
`define REG_ONLY            1
`define REG_AND_NO_REG      2

`define N_25                7
`define BASE_WIDTH         66

`define K_COUNT                8192
`define K_INDICATION           417


`ifdef DEBUG_HI_SER
`define HI_SER_COUNT_MAX   21'h00007f //128 FEC word pairs
`endif

`ifndef DEBUG_HI_SER
`define HI_SER_COUNT_MAX 21'h09ffff //5*2^17 FEC word pairs == 67.5ms - equivalent to the ASIC.
`endif


/////////////////////////////////////////////////////
// defines for the top levels
/////////////////////////////////////////////////////


//  Used in the galois field multiplier
`define SW    `SYMBOL_WIDTH
`define SWM1  (`SW-1)
`define TSWM1 (2*`SW-1)
`define INT_INP_MSB (qterm_num_pterms(qi) - 1)
`define INT_QQ_MSB  (qterm_num_suboutputs(qi) - 1)
`define INT_CINP_MSB (cterm_num_sterms(ci) - 1)

// for ECC error handling
`define PARITY_WIDTH 5

///////////////////////////////////////////////////////////////////////////////
// Timestamp
///////////////////////////////////////////////////////////////////////////////

`define TIMESTAMP_WIDTH         80

// Timestamp latencies
// These values include the whole datapath, from alignment to transcode.
`define TIMESTAMP_LATENCY_FULL                 193
`define TIMESTAMP_LATENCY_LOW_LATENCY          129 
`define TIMESTAMP_LATENCY_BYPASS_INDICATION    121 
`define TIMESTAMP_LATENCY_BYPASS_CORRECTION     38 
`define TIMESTAMP_LATENCY_XILINX_SPECIAL_MODE   18 


///////////////////////////////////////////////////////////////////////////////
//  axi_defs
///////////////////////////////////////////////////////////////////////////////

// The AXI block is in the soft core only, so give it a synchronous reset by
// defining this macro as null
`define ASYNC_RESET_AXI_SEL

// Response codes for AXI4
`define AXI_RESP_OKAY    2'b00
`define AXI_RESP_EXOKAY  2'b01
`define AXI_RESP_SLVERR  2'b10
`define AXI_RESP_DECERR  2'b11


///////////////////////////////////////////////////////////////////////////////
//  adr_defs
///////////////////////////////////////////////////////////////////////////////
`define SHIFTER_PIPE_STAGES       3     // Pipelining for barrel shifter

///////////////////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////////////////

`endif // _cpri_hard_fec_vh_
