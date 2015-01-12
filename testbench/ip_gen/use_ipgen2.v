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
module use_ipgen2
(
input wire clk,

input wire rd,
output reg dv,
output reg [7:0] dataout
);

reg reset_1w;

initial begin
end


always @ ( posedge clk ) begin
	if (rd==1'b1)
		$ipgen2(8'd1,dv,dataout);
end



endmodule 
