//////////////////////////////////////////////////////////////////////////////-
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
// Unit     : ieee802d3_200g_fs_fec_v1_0_dec_func_gfmul
// Function : galois field multiplier modifed for use in ieee802
////////////////////////////////////////////////////////////////////

//---------------------------------------------------------------------------
// Function: func_gfmul
//---------------------------------------------------------------------------
  function [9:0] func_gfmul(input [9:0] aa, input [9:0] bb);
    reg [36:0] terms;
  begin
    terms[36] = (aa[7]&bb[2])^((aa[0]^aa[7])&bb[9])^(aa[3]&bb[6]);
    terms[35] = ((aa[1]^aa[8])&bb[8])^(aa[8]&bb[1])^(aa[4]&bb[5]);
    terms[34] = ((aa[2]^aa[9])&bb[7])^(aa[9]&bb[0])^(aa[5]&bb[4]);

    terms[33] = ((aa[0]^aa[7])&bb[8])^(aa[7]&bb[1]);
    terms[32] = ((aa[1]^aa[8])&bb[7])^(aa[6]&bb[2])^(aa[8]&bb[0]);
    terms[31] = ((aa[2]^aa[9])&bb[6])^((aa[6]^aa[9])&bb[9]);
    terms[30] = (aa[3]&bb[5])^(aa[4]&bb[4])^(aa[5]&bb[3]);

    terms[29] = ((aa[0]^aa[7])&bb[7])^(aa[7]&bb[0]);
    terms[28] = ((aa[1]^aa[8])&bb[6])^((aa[5]^aa[8])&bb[9])^(aa[5]&bb[2]);
    terms[27] = ((aa[2]^aa[9])&bb[5])^((aa[6]^aa[9])&bb[8])^(aa[6]&bb[1]);
    terms[26] = (aa[3]&bb[4])^(aa[4]&bb[3]);

    terms[25] = ((aa[6]^aa[9])&bb[7])^(aa[6]&bb[0])^((aa[2]^aa[9])&bb[4]);
    terms[24] = ((aa[0]^aa[7])&bb[6])^(aa[3]&bb[3]);
    terms[23] = ((aa[5]^aa[8])&bb[8])^(aa[5]&bb[1])^((aa[1]^aa[8])&bb[5]);
    terms[22] = ((aa[4]^aa[7])&bb[9])^(aa[4]&bb[2]);

    terms[21] = ((aa[4]^aa[7])&bb[8])^((aa[0]^aa[7])&bb[5]);
    terms[20] = ((aa[5]^aa[8])&bb[7])^((aa[1]^aa[8])&bb[4])^(aa[5]&bb[0]);
    terms[19] = ((aa[6]^aa[9])&bb[6])^((aa[2]^aa[9])&bb[3]);
    terms[18] = ((aa[3]^aa[6])&bb[9])^(aa[3]&bb[2])^(aa[4]&bb[1]);
    
    terms[17] = ((aa[2]^aa[5]^aa[9])&bb[9])^((aa[5]^aa[8])&bb[6]);
    terms[16] = ((aa[3]^aa[6])&bb[8])^((aa[6]^aa[9])&bb[5])^(aa[3]&bb[1]);
    terms[15] = ((aa[0]^aa[7])&bb[4])^((aa[4]^aa[7])&bb[7])^(aa[4]&bb[0]);
    terms[14] = ((aa[1]^aa[8])&bb[3])^((aa[2]^aa[9])&bb[2]);

    terms[13] = ((aa[2]^aa[9])&bb[1])^((aa[6]^aa[9])&bb[4]);
    terms[12] = ((aa[1]^aa[4]^aa[8])&bb[9])^((aa[1]^aa[8])&bb[2]);
    terms[11] = ((aa[4]^aa[7])&bb[6])^((aa[0]^aa[7])&bb[3]);
    terms[10] = ((aa[3]^aa[6])&bb[7])^(aa[3]&bb[0]);
    terms[ 9] = ((aa[5]^aa[8])&bb[5])^((aa[2]^aa[5]^aa[9])&bb[8]);

    terms[ 8] = (aa[0]&bb[2])^(aa[1]&bb[1])^(aa[2]&bb[0]);
    terms[ 7] = (aa[3]&bb[9])^(aa[4]&bb[8])^(aa[5]&bb[7]);
    terms[ 6] = (aa[6]&bb[6])^(aa[7]&bb[5])^(aa[8]&bb[4]);

    terms[ 5] = ((aa[2]^aa[9])&bb[9])^(aa[9]&bb[2])^(aa[0]&bb[1]);
    terms[ 4] = (aa[1]&bb[0])^(aa[3]&bb[8])^(aa[4]&bb[7]);
    terms[ 3] = (aa[5]&bb[6])^(aa[6]&bb[5])^(aa[7]&bb[4]);

    terms[ 2] = ((aa[1]^aa[8])&bb[9])^(aa[8]&bb[2])^(aa[5]&bb[5]);
    terms[ 1] = ((aa[2]^aa[9])&bb[8])^(aa[9]&bb[1])^(aa[3]&bb[7]);
    terms[ 0] = (aa[4]&bb[6])^(aa[6]&bb[4])^(aa[7]&bb[3]);

    func_gfmul[9] = terms[36] ^ terms[35] ^ terms[34] ^ (aa[6]&bb[3]);
    func_gfmul[8] = terms[33] ^ terms[32] ^ terms[31] ^ terms[30];
    func_gfmul[7] = terms[29] ^ terms[28] ^ terms[27] ^ terms[26];
    func_gfmul[6] = terms[25] ^ terms[24] ^ terms[23] ^ terms[22];
    func_gfmul[5] = terms[21] ^ terms[20] ^ terms[19] ^ terms[18];
    func_gfmul[4] = terms[17] ^ terms[16] ^ terms[15] ^ terms[14];
    func_gfmul[3] = terms[13] ^ terms[12] ^ terms[11] ^ terms[10] ^ terms[9];
    func_gfmul[2] = terms[ 8] ^ terms[ 7] ^ terms[ 6] ^ (aa[9]&bb[3]);
    func_gfmul[1] = terms[ 5] ^ terms[ 4] ^ terms[ 3] ^ (aa[8]&bb[3]);
    func_gfmul[0] = terms[ 2] ^ terms[ 1] ^ terms[ 0] ^ (aa[0]&bb[0]);
  end
  endfunction


