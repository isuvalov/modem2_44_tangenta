//
// Copyright 1991-2010 Mentor Graphics Corporation
//
// All Rights Reserved.
//
// THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION WHICH IS THE
// PROPERTY OF MENTOR GRAPHICS CORPORATION OR ITS LICENSORS AND IS SUBJECT TO
// LICENSE TERMS.
//
// Simple Verilog PLI Example - Verilog test module for fibonacci seq.
//
module use_ipgen_test
(
input wire clk,

input wire wr,
input wire dv,
input wire [7:0] datain,
output reg error
);

reg reset_1w;

initial begin
end


always @ ( posedge clk ) begin
	if (wr==1'b1)
		error<=$ipgen_test(dv,datain);
	else
		error<=1'b0;
end



endmodule 
