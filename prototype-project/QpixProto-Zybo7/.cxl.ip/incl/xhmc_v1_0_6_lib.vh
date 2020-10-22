`ifndef LIB_VH
`define LIB_VH
`define XSRREG(clk, reset, q,d,rstval)	\
    always @(posedge clk )			\
    begin					\
     if (reset == 1'b1)			\
         q <= rstval;				\
     else					\
	 `ifdef FOURVALCLKPROP			\
	    q <= clk ? d : q;			\
	  `else					\
	    q <=  d;				\
	  `endif				\
     end
`endif
