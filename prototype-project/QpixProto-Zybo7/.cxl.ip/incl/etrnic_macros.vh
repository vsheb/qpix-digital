// /////////////////////////////////////////////////////////////////
// (c) Copyright 2013 - 2014 Xilinx, Inc. All rights reserved.	 
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
// ////////////////////////////////////////////////////////////////////
//-----------------------------------------------------------------------------
// nvmof_macros.h
//-----------------------------------------------------------------------------
//
// Filename        : bnvmof_macros.h
// Version         : v1.0
// Description     : Common macros file for nvmof
// Verilog-Standard: Verilog'2001
//-----------------------------------------------------------------------------
//-- Structure:
//--               -- top.v 
//-----------------------------------------------------------------------------
// Naming Conventions:
//      active low signals:                     "*_n"
//      clock signals:                          "clk", "clk_div#", "clk_#x" 
//      reset signals:                          "rst", "rst_n" 
//      parameters:                             "C_*" 
//      user defined types:                     "*_TYPE" 
//      state machine next state:               "*_ns" 
//      state machine current state:            "*_cs" 
//      combinatorial signals:                  "*_com" 
//      pipelined or register delay signals:    "*_d#" 
//      counter signals:                        "*cnt*"
//      clock enable signals:                   "*_ce" 
//      internal version of output port         "*_i"
//      device pins:                            "*_pin" 
//      component instantiations:               "<MODULE>I_<#|FUNC>
//-----------------------------------------------------------------------------

///////////////////////////////////////////////////////////////////////////////
// Macros for Flip Flops
///////////////////////////////////////////////////////////////////////////////

// Master Slave flip-flop w/ Async_reset_n
`define MSFF_ARN(q, d, clk, rst_n) \
always @(posedge clk, negedge rst_n) begin \
    if (!rst_n) q <= 'b0; \
    else        q <= (d); \
end

// Master Slave flip-flop w/ Async_reset_p
`define MSFF_AR(q, d, clk, rst_p) \
always @(posedge clk, posedge rst_p) begin \
    if (rst_p)  q <= 'b0; \
    else        q <= (d); \
end

// Master Slave flip-flop w/ Sync_reset_n
`define MSFF_RN(q, d, clk, rst_n) \
always @(posedge clk) begin \
    if (!rst_n) q <= 'b0; \
    else        q <= (d); \
end

// Master Slave flip-flop w/ Sync_reset_p
`define MSFF_R(q, d, clk, rst_p) \
always @(posedge clk) begin \
    if (rst_p)  q <= 'b0; \
    else        q <= (d); \
end

// Master Slave flip-flop w/ Sync_reset_p and initial load value on reset
`define MSFF_RL(q, d, clk, rst_p, rst_load) \
always @(posedge clk) begin \
    if (rst_p)  q <= (rst_load); \
    else        q <= (d); \
end


// Master Slave flip-flop w/o rest 
`define MSFF(q, d, clk) \
always @(posedge clk) begin \
    q <= (d); \
end

//------------------------------------------------------------------------------
// Function clogb2
// This function returns the integer ceiling of the base 2 logarithm of x,
// i.e., the least integer greater than or equal to log2(x).
//------------------------------------------------------------------------------
// coverage off
  function integer clog2;
    input [31:0] value; // Input value
    begin
    value = (value == 1) ? value : (value - 1);
    for (clog2 = 0; value > 0; clog2 = clog2 + 1)
      value = value >> 1;
    end
  endfunction
// coverage on
`ifdef SIMULATION
// Assertion definitions
`define assert_prop(check, pa, mesg, dc = ~core_rstn, clk = core_clk) \
ERROR_``check``: assert property (@(posedge clk) disable iff (dc) (pa)) else `error({`"``check``: `",mesg})

`define cover_prop(check, pc, dc = ~core_rstn, clk = core_clk) \
``check``: cover property (@(posedge clk) disable iff (dc) (pc))

`define cover_point(check, pc, dc = ~core_rstn) \
``check``: coverpoint (pc) iff (!(dc))
///
`endif

