////////////////////////////////////////////////////////////////////
//  (c) Copyright 2014 Xilinx, Inc. All rights reserved.
//
//  This file contains confidential and proprietary information
//  of Xilinx, Inc. and is protected under U.S. and
//  international copyright and other intellectual property
//  laws.
//
//  DISCLAIMER
//  This disclaimer is not a license and does not grant any
//  rights to the materials distributed herewith. Except as
//  otherwise provided in a valid license issued to you by
//  Xilinx, and to the maximum extent permitted by applicable
//  law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
//  WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
//  AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
//  BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
//  INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
//  (2) Xilinx shall not be liable (whether in contract or tort,
//  including negligence, or under any other theory of
//  liability) for any loss or damage of any kind or nature
//  related to, arising under or in connection with these
//  materials, including for any direct, or any indirect,
//  special, incidental, or consequential loss or damage
//  (including loss of data, profits, goodwill, or any type of
//  loss or damage suffered as a result of any action brought
//  by a third party) even if such damage or loss was
//  reasonably foreseeable or Xilinx had been advised of the
//  possibility of the same.
//
//  CRITICAL APPLICATIONS
//  Xilinx products are not designed or intended to be fail-
//  safe, or for use in any application requiring fail-safe
//  performance, such as life-support or safety devices or
//  systems, Class III medical devices, nuclear facilities,
//  applications related to the deployment of airbags, or any
//  other applications that could lead to death, personal
//  injury, or severe property or environmental damage
//  (individually and collectively, "Critical
//  Applications"). Customer assumes the sole risk and
//  liability of any use of Xilinx products in Critical
//  Applications, subject only to applicable laws and
//  regulations governing limitations on product liability.
//
//  THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
//  PART OF THIS FILE AT ALL TIMES.
////////////////////////////////////////////////////////////////////
// Unit     : ieee802d3_200g_rs_fec_v1_0_2_dec_func_gfinv_ecc_gen.vh
// Function : 
// 5 bit hamming code generator for 10 bit input
////////////////////////////////////////////////////////////////////
//---------------------------------------------------------------------------
// Function: func_gfinv_ecc_gen
// Generates a 5 bit hamming code and appends it to the 10 bit input data
// Hamming code is compatable with the ECC core
//---------------------------------------------------------------------------
  function [14:0] func_gfinv_ecc_gen;
     input [ 9:0] din;
     reg   [14:0] tmp;
  begin

     // Copy the data across
     tmp[9:0] = din[9:0];

     tmp[11]  = din[00] ^ din[01] ^ din[03] ^ din[04] ^ din[06] ^ din[08];
     tmp[12]  = din[00] ^ din[02] ^ din[03] ^ din[05] ^ din[06] ^ din[09];
     tmp[13]  = din[01] ^ din[02] ^ din[03] ^ din[07] ^ din[08] ^ din[09];
     tmp[14]  = din[04] ^ din[05] ^ din[06] ^ din[07] ^ din[08] ^ din[09];

     tmp[10]  = (^din) ^ (^tmp[14:11]);

     // Assign the output
     func_gfinv_ecc_gen = tmp;

  end
  endfunction