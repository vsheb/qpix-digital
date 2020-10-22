 ///////////////////////////////////////////////////////////////////////////////
 // Project: flexo_100g_rs_fec_v1_0_6
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

`define ASYNC_RESET_TX_SEL
`define ASYNC_RESET_RX_SEL

// `include "ieee802d3_rs_fec_v1_0_12.vh"
`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC,NAME)  generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1)  begin :NAME assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end endgenerate

///////////////////////////////////////////////////////////////////////////////
//  adr_defs
///////////////////////////////////////////////////////////////////////////////
`define DEFAULT_THRESHOLD         20     // Threshold for AM score comparison
`define ADR_FIFO_REWIND           11     // Distance to rewind FIFO when starting search
`define SHIFTER_PIPE_STAGES       2      // Pipelining for barrel shifter
`define SCORE_WINDOW_PIPE_STAGES  2      // Additional pipelining for window scoring function
`define CORRELATOR_PIPE_STAGES    1      // Additional pipelining for correlators
`define DELAY_WIDTH               14     // Width of data bus for reporting lane delay
`define FIFO_SYNC_DELAY           5      // Time taken for data out of FIFO to settle in search mode
`define REORDER_PIPE_STAGES       5      // Cycles taken to re-order and gearbox lane data
`define TS1588_ADJUST_PIPE_STAGES 6      // Cycles taken to adjust 1588 timestamp for gearboxing

///////////////////////////////////////////////////////////////////////////////
//  adr_decoder_ctrl
///////////////////////////////////////////////////////////////////////////////
`define DEFAULT_DECODE_THRESHOLD    8'd07
`define DEFAULT_PACKET_LENGTH       8'd17
`define DEFAULT_KP4_FIFO_DEPTH_LOG2 8
`define FINE_SHIFT_BITS             7
`define FRAME_LENGTH_MIN            1024   // Minimum number of blocks per frame
`define MAX_SKEW_CYCLES             160    // 450 ns, ish for KP4
`define TIMEBASE_WIDTH              17     // Enough bits to hold (FRAME_DURATION-1)

// Pipelining:
`define FINE_DESKEW_PIPE_STAGES     1      // Additional pipelining for fine alignment shifter
`define SCORE_WINDOW_PIPE_STAGES    2      // Additional pipelining for window scoring function
`define CORRELATOR_PIPE_STAGES      1      // Additional pipelining for correlators

///////////////////////////////////////////////////////////////////////////////
//  rs_fec
///////////////////////////////////////////////////////////////////////////////
`define N_SYMBOLS          32
`define N_CONST           544
`define R_WIDTH             4
`define SYMBOL_WIDTH       10
`define T_CONST            15
`define R_CONST            2* `T_CONST
`define WIDTH_4T            6
`define COUNT_PE_LIMIT     `R_CONST

`define NO_REG              0
`define REG_ONLY            1
`define REG_AND_NO_REG      2
`define NO_OF_LANES         8

///////////////////////////////////////////////////////////////////////////////
// For hi_ser testing
///////////////////////////////////////////////////////////////////////////////

`define HI_SER_FLGC_WIDTH 22      // Flag-generation counter width
`define HI_SER_WINC_WIDTH 12      // Window counter width
`define HI_SER_ERRC_WIDTH 13      // Error counter width



///////////////////////////////////////////////////////////////////////////////
// Flag for For hi_ser Questa Simulation testing
///////////////////////////////////////////////////////////////////////////////
//`define HI_SER_TESTING

///////////////////////////////////////////////////////////////////////////////
// Flag for For hi_ser DEBUG
///////////////////////////////////////////////////////////////////////////////
//`define DEBUG_HI_SER 1

// SETUP HI SER module for DEBUG
`ifdef DEBUG_HI_SER
 `define HI_SER_COUNT_MAX   22'h0000ff // Duration of HI SER Signal HIGH = 256 codeword pairs
 `define K_COUNT                   128 // hi ser error count window period = 128 codeword pairs
 `define K_INDICATION              128 // symbol errors to trigger hi ser signal HIGH
// SETUP HI SER module for Questa SIMULATION Testing
`elsif HI_SER_TESTING
 `define HI_SER_COUNT_MAX   22'h0003ff // Duration of HI SER Signal HIGH = 1024 codeword pairs = approx 52.5 us
 `define K_COUNT                   512 //  hi ser error count window period = 512 codeword pairs
 `define K_INDICATION              256 //  symbol errors to trigger hi ser signal HIGH
// SETUP HI SER Module for normal use
`else
// `define HI_SER_COUNT_MAX   22'h27ffff  // Duration of HI SER Signal HIGH =  5*2^19 codeword pairs = 67.1ms
 `define HI_SER_COUNT_MAX   22'h13ffff  // Duration of HI SER Signal HIGH = 1,310,720 codeword pairs = 67.1ms
// `define HI_SER_COUNT_MAX   22'h0003ff // Duration of HI SER Signal HIGH = 1024 codeword pairs 
 `define K_COUNT                  4096  // hi ser error count window period = 2048 codeword pairs
 `define K_INDICATION             5560  // symbol errors to trigger hi ser signal HIGH
`endif




/////////////////////////////////////////////////////
// defines for the top levels
/////////////////////////////////////////////////////
`define BMA_PIPE_C                 2
`define RS_DECODE_LATENCY_DEPTH  128
`define ERROR_GEN_LATENCY          5
`define LOC_DELAY                `CHIEN_FORNEY_LATENCY + `ERROR_GEN_LATENCY

//  Used in the galois field multiplier
`define SW    `SYMBOL_WIDTH
`define SWM1  (`SW-1)
`define TSWM1 (2*`SW-1)
`define INT_INP_MSB  (qterm_num_pterms(qi) - 1)
`define INT_QQ_MSB   (qterm_num_suboutputs(qi) - 1)
`define INT_CINP_MSB (cterm_num_sterms(ci) - 1)

// used in bma top2
`define CHIEN_ARRAY_LEN (`SYMBOL_WIDTH*(`T_CONST+1))
`define SYND_ARRAY_LEN  (`SYMBOL_WIDTH*`R_CONST)

// for ECC error handling
`define PARITY_WIDTH    5

// width of timestamp bus
`define TIMESTAMP_WIDTH 80

///////////////////////////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////////////////////////

`endif // _global_defs_vh_
