 ///////////////////////////////////////////////////////////////////////////////
 // Project: ieee802d3_rs_fec_v1_0_12
 // Company: Xilinx
 //
 //
 //
 // (c) Copyright 2013 Xilinx, Inc. All rights reserved.
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


`ifndef _global_defs_vh_
`define _global_defs_vh_

 
`define IS_SOFT 1
`define ASYNC_RESET_TX_SEL
`define ASYNC_RESET_RX_SEL


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
`define FRAME_LENGTH_MIN          1024   // Minimum number of blocks per frame
`define DEFAULT_THRESHOLD         70     // Threshold for AM score comparison
`define MAX_SKEW_CYCLES           59     // 180ns, ish
`define TIMEBASE_WIDTH            17     // Enough bits to hold (FRAME_DURATION-1)

// Pipelining:
`define FINE_DESKEW_PIPE_STAGES   1      // Additional pipelining for fine alignment shifter
`define SCORE_WINDOW_PIPE_STAGES  2      // Additional pipelining for window scoring function
`define CORRELATOR_PIPE_STAGES    1      // Additional pipelining for correlators

///////////////////////////////////////////////////////////////////////////////
//  common_defs
///////////////////////////////////////////////////////////////////////////////

`define M0_0 8'hc1 
`define M0_1 8'h68 
`define M0_2 8'h21 
`define M0_4 8'h3e  
`define M0_5 8'h97 
`define M0_6 8'hde 

`define M1_0 8'h9d
`define M1_1 8'h71
`define M1_2 8'h8e
`define M1_4 8'h62
`define M1_5 8'h8e
`define M1_6 8'h71

`define M2_0 8'h59
`define M2_1 8'h4b
`define M2_2 8'he8
`define M2_4 8'ha6
`define M2_5 8'hb4
`define M2_6 8'h17

`define M3_0 8'h4d
`define M3_1 8'h95
`define M3_2 8'h7b
`define M3_4 8'hb2
`define M3_5 8'h6a
`define M3_6 8'h84

`define M4_0 8'hf5
`define M4_1 8'h07
`define M4_2 8'h09
`define M4_4 8'h0a
`define M4_5 8'hf8
`define M4_6 8'hf6
           
`define M5_0 8'hdd
`define M5_1 8'h14
`define M5_2 8'hc2
`define M5_4 8'h22
`define M5_5 8'heb
`define M5_6 8'h3d
           
`define M6_0 8'h9a
`define M6_1 8'h4a
`define M6_2 8'h26
`define M6_4 8'h65
`define M6_5 8'hb5
`define M6_6 8'hd9
           
`define M7_0 8'h7b
`define M7_1 8'h45
`define M7_2 8'h66
`define M7_4 8'h84
`define M7_5 8'hba
`define M7_6 8'h99

`define M8_0 8'ha0
`define M8_1 8'h24
`define M8_2 8'h76
`define M8_4 8'h5f
`define M8_5 8'hdb
`define M8_6 8'h89
           
`define M9_0 8'h68
`define M9_1 8'hc9
`define M9_2 8'hfb
`define M9_4 8'h97
`define M9_5 8'h36
`define M9_6 8'h04
        
`define M10_0 8'hfd
`define M10_1 8'h6c
`define M10_2 8'h99
`define M10_4 8'h02
`define M10_5 8'h93
`define M10_6 8'h66
           
`define M11_0 8'hb9
`define M11_1 8'h91
`define M11_2 8'h55
`define M11_4 8'h46
`define M11_5 8'h6e
`define M11_6 8'haa

`define M12_0 8'h5c
`define M12_1 8'hb9
`define M12_2 8'hb2
`define M12_4 8'ha3
`define M12_5 8'h46
`define M12_6 8'h4d
           
`define M13_0 8'h1a
`define M13_1 8'hf8
`define M13_2 8'hbd
`define M13_4 8'he5
`define M13_5 8'h07
`define M13_6 8'h42
           
`define M14_0 8'h83
`define M14_1 8'hc7
`define M14_2 8'hca
`define M14_4 8'h7c
`define M14_5 8'h38
`define M14_6 8'h35
           
`define M15_0 8'h35
`define M15_1 8'h36
`define M15_2 8'hcd
`define M15_4 8'hca
`define M15_5 8'hc9
`define M15_6 8'h32

`define M16_0 8'hc4
`define M16_1 8'h31
`define M16_2 8'h4c
`define M16_4 8'h3b
`define M16_5 8'hce
`define M16_6 8'hb3
           
`define M17_0 8'had
`define M17_1 8'hd6
`define M17_2 8'hb7
`define M17_4 8'h52
`define M17_5 8'h29
`define M17_6 8'h48
           
`define M18_0 8'h5f
`define M18_1 8'h66
`define M18_2 8'h2a
`define M18_4 8'ha0
`define M18_5 8'h99
`define M18_6 8'hd5
           
`define M19_0 8'hc0
`define M19_1 8'hf0
`define M19_2 8'he5
`define M19_4 8'h3f
`define M19_5 8'h0f
`define M19_6 8'h1a


`define AM_PCS_L0  {8'd0, `M0_6, `M0_5, `M0_4, 8'd255, `M0_2, `M0_1, `M0_0}
`define AM_PCS_L1  {8'd0, `M1_6, `M1_5, `M1_4, 8'd255, `M1_2, `M1_1, `M1_0}
`define AM_PCS_L2  {8'd0, `M2_6, `M2_5, `M2_4, 8'd255, `M2_2, `M2_1, `M2_0}
`define AM_PCS_L3  {8'd0, `M3_6, `M3_5, `M3_4, 8'd255, `M3_2, `M3_1, `M3_0}
`define AM_PCS_L4  {8'd0, `M4_6, `M4_5, `M4_4, 8'd255, `M4_2, `M4_1, `M4_0}
`define AM_PCS_L5  {8'd0, `M5_6, `M5_5, `M5_4, 8'd255, `M5_2, `M5_1, `M5_0}
`define AM_PCS_L6  {8'd0, `M6_6, `M6_5, `M6_4, 8'd255, `M6_2, `M6_1, `M6_0}
`define AM_PCS_L7  {8'd0, `M7_6, `M7_5, `M7_4, 8'd255, `M7_2, `M7_1, `M7_0}
`define AM_PCS_L8  {8'd0, `M8_6, `M8_5, `M8_4, 8'd255, `M8_2, `M8_1, `M8_0}
`define AM_PCS_L9  {8'd0, `M9_6, `M9_5, `M9_4, 8'd255, `M9_2, `M9_1, `M9_0}
`define AM_PCS_L10 {8'd0,`M10_6,`M10_5,`M10_4, 8'd255,`M10_2,`M10_1,`M10_0}
`define AM_PCS_L11 {8'd0,`M11_6,`M11_5,`M11_4, 8'd255,`M11_2,`M11_1,`M11_0}
`define AM_PCS_L12 {8'd0,`M12_6,`M12_5,`M12_4, 8'd255,`M12_2,`M12_1,`M12_0}
`define AM_PCS_L13 {8'd0,`M13_6,`M13_5,`M13_4, 8'd255,`M13_2,`M13_1,`M13_0}
`define AM_PCS_L14 {8'd0,`M14_6,`M14_5,`M14_4, 8'd255,`M14_2,`M14_1,`M14_0}
`define AM_PCS_L15 {8'd0,`M15_6,`M15_5,`M15_4, 8'd255,`M15_2,`M15_1,`M15_0}
`define AM_PCS_L16 {8'd0,`M16_6,`M16_5,`M16_4, 8'd255,`M16_2,`M16_1,`M16_0}
`define AM_PCS_L17 {8'd0,`M17_6,`M17_5,`M17_4, 8'd255,`M17_2,`M17_1,`M17_0}
`define AM_PCS_L18 {8'd0,`M18_6,`M18_5,`M18_4, 8'd255,`M18_2,`M18_1,`M18_0}
`define AM_PCS_L19 {8'd0,`M19_6,`M19_5,`M19_4, 8'd255,`M19_2,`M19_1,`M19_0}

  //CMAC usue big endia word order, with little endian byte order?
  //the byte order is reversed in the aligner to match the transition order as defined in the spec.
`define AM_CMACPCS_L0 {`M0_0,`M0_1,`M0_2,8'd0,`M0_4,`M0_5,`M0_6,8'd0}
`define AM_CMACPCS_L1 {`M1_0,`M1_1,`M1_2,8'd0,`M1_4,`M1_5,`M1_6,8'd0}
`define AM_CMACPCS_L2 {`M2_0,`M2_1,`M2_2,8'd0,`M2_4,`M2_5,`M2_6,8'd0}
`define AM_CMACPCS_L3 {`M3_0,`M3_1,`M3_2,8'd0,`M3_4,`M3_5,`M3_6,8'd0}
`define AM_CMACPCS_L4 {`M4_0,`M4_1,`M4_2,8'd0,`M4_4,`M4_5,`M4_6,8'd0}
`define AM_CMACPCS_L5 {`M5_0,`M5_1,`M5_2,8'd0,`M5_4,`M5_5,`M5_6,8'd0}
`define AM_CMACPCS_L6 {`M6_0,`M6_1,`M6_2,8'd0,`M6_4,`M6_5,`M6_6,8'd0}
`define AM_CMACPCS_L7 {`M7_0,`M7_1,`M7_2,8'd0,`M7_4,`M7_5,`M7_6,8'd0}
`define AM_CMACPCS_L8 {`M8_0,`M8_1,`M8_2,8'd0,`M8_4,`M8_5,`M8_6,8'd0}
`define AM_CMACPCS_L9 {`M9_0,`M9_1,`M9_2,8'd0,`M9_4,`M9_5,`M9_6,8'd0}
`define AM_CMACPCS_L10 {`M10_0,`M10_1,`M10_2,8'd0,`M10_4,`M10_5,`M10_6,8'd0}
`define AM_CMACPCS_L11 {`M11_0,`M11_1,`M11_2,8'd0,`M11_4,`M11_5,`M11_6,8'd0}
`define AM_CMACPCS_L12 {`M12_0,`M12_1,`M12_2,8'd0,`M12_4,`M12_5,`M12_6,8'd0}
`define AM_CMACPCS_L13 {`M13_0,`M13_1,`M13_2,8'd0,`M13_4,`M13_5,`M13_6,8'd0}
`define AM_CMACPCS_L14 {`M14_0,`M14_1,`M14_2,8'd0,`M14_4,`M14_5,`M14_6,8'd0}
`define AM_CMACPCS_L15 {`M15_0,`M15_1,`M15_2,8'd0,`M15_4,`M15_5,`M15_6,8'd0}
`define AM_CMACPCS_L16 {`M16_0,`M16_1,`M16_2,8'd0,`M16_4,`M16_5,`M16_6,8'd0}
`define AM_CMACPCS_L17 {`M17_0,`M17_1,`M17_2,8'd0,`M17_4,`M17_5,`M17_6,8'd0}
`define AM_CMACPCS_L18 {`M18_0,`M18_1,`M18_2,8'd0,`M18_4,`M18_5,`M18_6,8'd0}
`define AM_CMACPCS_L19 {`M19_0,`M19_1,`M19_2,8'd0,`M19_4,`M19_5,`M19_6,8'd0}

///////////////////////////////////////////////////////////////////////////////
//  rs_fec
///////////////////////////////////////////////////////////////////////////////

`define N_CONST           528
`define R_WIDTH             4
`define SYMBOL_WIDTH       10
`define T_CONST             7
`define R_CONST            14
`define SYMBOLS_PER_ROW    32
`define WIDE_ROW          128 // 4* SYMBOLS_PER_ROW
`define WIDTH_4T            5
`define COUNT_PE_LIMIT     14
`define ROW_WIDTH         320
`define WIDE_ROW_88        88
`define WIDE_ROW_44        44
`define ROWS_2RS_WIDTH      6

`define NO_REG              0
`define REG_ONLY            1
`define REG_AND_NO_REG      2

`define NO_OF_LANES         4

`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC,NAME)  generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1)  begin :NAME assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end endgenerate

/////////////////////////////////////////////////////
// defines for the asic and soft top levels
/////////////////////////////////////////////////////

// if set to 1 process data on 88 symbol wide for reduced latency
// if set to 0 process data on 132 symbol wide for reduced latency
`define PROCESS_88             1
// width of timestamp bus
`define TIMESTAMP_WIDTH         80
// extra latency to move the delay flag to decoded output to 5 for the FPGA case
`define FAIL_DETECT_LATENCY    10
// alignment delay
`define ALIGN_DEL              9 //`ERROR_GEN_LATENCY_SOFT+`FAIL_DETECT_LATENCY-4



// latencies through various parts of the decoder
// delay through syndrome from first row in to syndrome tstart 
// this is tvalid based
`define SYNDROME_LATENCY_SOFT     19 
`define SYNDROME_LATENCY_ASIC     17 
`define BYPASS_LATENCY_SOFT       15
`define BYPASS_LATENCY_ASIC       13
// delay through bma
// not valid based
`define BMA_LATENCY_SOFT          16
`define BMA_LATENCY_ASIC          7
// delay between the bma start and the output of the error locators
// not valid based
`define CHIEN_FORNEY_LATENCY_SOFT 4
`define CHIEN_FORNEY_LATENCY_ASIC 1
// again not tvalid based
`define ERROR_GEN_LATENCY_SOFT   5
`define ERROR_GEN_LATENCY_ASIC   1
// full latency
`define RS_DECODE_LATENCY_SOFT   `SYNDROME_LATENCY_SOFT + `BMA_LATENCY_SOFT + `CHIEN_FORNEY_LATENCY_SOFT + `ERROR_GEN_LATENCY_SOFT
`define RS_DECODE_LATENCY_ASIC   `SYNDROME_LATENCY_ASIC + `BMA_LATENCY_ASIC + `CHIEN_FORNEY_LATENCY_ASIC + `ERROR_GEN_LATENCY_ASIC
`define TRANSCODE_LATENCY  7

// latencies decoder and transcode for timesatmp
`define SOFT_TIMESTAMP_LATENCY_FULL `RS_DECODE_LATENCY_SOFT + `FAIL_DETECT_LATENCY +`TRANSCODE_LATENCY + 2
`define SOFT_TIMESTAMP_LATENCY_BYPASS_CORRECTION `BYPASS_LATENCY_SOFT + `TRANSCODE_LATENCY + 2
//`define SOFT_TIMESTAMP_LATENCY_INDICATION `TRANSCODE_LATENCY



`define SYND_PIPE_C_SOFT  1
`define SYND_PIPE_C_ASIC  0
`define BMA_PIPE_C_SOFT   2
`define BMA_PIPE_C_ASIC   0
`define CHIEN_I_PIPE_C_SOFT 1
`define CHIEN_I_PIPE_C_ASIC 0
`define CHIEN_M_PIPE_C_SOFT 1
`define CHIEN_M_PIPE_C_ASIC 0
`define RS_DECODE_LATENCY_DEPTH_SOFT  128
`define RS_DECODE_LATENCY_DEPTH_ASIC  32
`define LOC_DELAY_SOFT  `CHIEN_FORNEY_LATENCY_SOFT + `ERROR_GEN_LATENCY_SOFT
`define LOC_DELAY_ASIC  `CHIEN_FORNEY_LATENCY_ASIC + `ERROR_GEN_LATENCY_ASIC

//  Used in the galois field multiplier
`define SW    `SYMBOL_WIDTH
`define SWM1  (`SW-1)
`define TSWM1 (2*`SW-1)
`define INT_INP_MSB (qterm_num_pterms(qi) - 1)
`define INT_QQ_MSB  (qterm_num_suboutputs(qi) - 1)
`define INT_CINP_MSB (cterm_num_sterms(ci) - 1)

// used in bma top2
`define CHIEN_ARRAY_LEN (`SYMBOL_WIDTH*(`T_CONST+1))
`define SYND_ARRAY_LEN  (`SYMBOL_WIDTH*`R_CONST)

// for ECC error handling
`define PARITY_WIDTH 5

///////////////////////////////////////////////////////////////////////////////
//  tcd_rx_defs
///////////////////////////////////////////////////////////////////////////////

`ifdef DEBUG_HI_SER
`define HI_SER_COUNT_MAX   21'h00007f //128 FEC word pairs
`define K_COUNT                256
`define K_INDICATION           64
`endif

`ifndef DEBUG_HI_SER
`define HI_SER_COUNT_MAX 21'h09ffff //5*2^17 FEC word pairs == 67.5ms - equivalent to the ASIC.
`define K_COUNT                8192
`define K_INDICATION           417
`endif

`endif // _global_defs_vh_
