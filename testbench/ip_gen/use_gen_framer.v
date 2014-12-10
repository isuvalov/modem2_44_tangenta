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
module use_gen_framer
(
input wire clk,

input wire start,
input wire dv,
input wire ce,
input wire havereg,
output reg out_ce,
output reg[5:0] dv_vals,
output reg[6:0] len1,
output reg[6:0] len2,
output reg[6:0] len3,
output reg[6:0] len4,
output reg[6:0] len5,
output reg[6:0] len6,
output reg[7:0] state_monitor,
output reg[7:0] blk_num_monitor
);

reg reset_1w;

initial begin
end


always @ ( posedge clk ) begin
//always @ ( negedge  clk ) begin
	if (start==1)
			$calc_lens(start,dv,out_ce,dv_vals[0],len1,dv_vals[1],len2,dv_vals[2],len3,dv_vals[3],len4,dv_vals[4],len5,dv_vals[5],len6,state_monitor,blk_num_monitor,havereg);
	else if (ce==1'b1)
		$calc_lens(start,dv,out_ce,dv_vals[0],len1,dv_vals[1],len2,dv_vals[2],len3,dv_vals[3],len4,dv_vals[4],len5,dv_vals[5],len6,state_monitor,blk_num_monitor,0);
end



endmodule 
