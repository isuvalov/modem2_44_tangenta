`define BLOCK_LEN	(188)

module calclens_framer
(
input wire clk,

input wire start,
input wire dv,
input wire ce,
output wire out_ce,
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

integer blocks_len[5:0];
integer blocks_dv[5:0];
integer all_len;
integer state=0;
integer fin,i,cur_blk_num;


initial begin
//	all_len=0;
//	state=0;
//	for (i=0;i<6;i=i+1)
//	begin
//		blocks_len[i]=0;
//		blocks_dv[i]=0;	
//	end
//	fin=0;
end

assign out_ce=fin;

always @ ( posedge clk ) begin
//always @ ( negedge  clk ) begin
	if (ce==1'b1) begin //# ce
		case (state)
		0: begin 
			if (start==1'b1)
			begin
				state=1;
			end
			all_len=0;
			state=0;
			for (i=0;i<6;i=i+1)
			begin
				blocks_len[i]=0;
				blocks_dv[i]=0;	
			end
			fin=0;
			cur_blk_num=0;
		  end
		1:  begin
			blocks_dv[cur_blk_num]=dv;
			blocks_len[cur_blk_num]=1;
			all_len=all_len+1;
			fin=0;
			if (dv==0) state=2;
			else state=3;
			end

		 2: begin
			if (dv==0)
				begin	
					blocks_len[cur_blk_num]++;
					if (blocks_len[cur_blk_num]>=64)
					begin
						cur_blk_num=cur_blk_num+1;			
						if (cur_blk_num<6)
						begin			
							blocks_dv[cur_blk_num]=0;
							blocks_len[cur_blk_num]=1;
						end
					end
				end
			else
				begin
				 cur_blk_num=cur_blk_num+1;
				 if (cur_blk_num<6)
				 begin
				 	blocks_dv[cur_blk_num]=1;
				 	blocks_len[cur_blk_num]=1;
				 end
				 state=3;
				end
			all_len=all_len+1;

			if ((all_len>=`BLOCK_LEN) || (cur_blk_num>=6)) 
			begin
				for (i=0;i<6;i=i+1)
				begin
				dv_vals[i]=blocks_dv[i];
				end
				len1=blocks_len[0]; len2=blocks_len[1]; len3=blocks_len[2]; len4=blocks_len[3]; 
				len5=blocks_len[4]; len6=blocks_len[5]; 
				fin=1;
				state=0;
			end else fin=0;
			end 

		 3: begin
			if (dv==1)
				begin	
					blocks_len[cur_blk_num]++;
					if (blocks_len[cur_blk_num]>=64)
					begin
						cur_blk_num=cur_blk_num+1;			
						if (cur_blk_num<6)
						begin			
							blocks_dv[cur_blk_num]=0;
							blocks_len[cur_blk_num]=1;
						end
					end
				end
				else
				begin
					 cur_blk_num=cur_blk_num+1;
					 state=2;
					 if (cur_blk_num<6)
					 begin
					 	blocks_dv[cur_blk_num]=1;
					 	blocks_len[cur_blk_num]=1;
					 end
				end

				all_len=all_len+1;

				if ((all_len>=`BLOCK_LEN) || (cur_blk_num>=6)) 
				begin
					for (i=0;i<6;i=i+1)
					begin
					dv_vals[i]=blocks_dv[i];
					end

					len1=blocks_len[0]; len2=blocks_len[1]; len3=blocks_len[2]; len4=blocks_len[3]; 
					len5=blocks_len[4]; len6=blocks_len[5]; 
					fin=1;
					state=0;
				end 
				else fin=0;
			end 


//		default: 
		endcase
	end //# ce
//		$calc_lens(start,dv,out_ce,dv_vals[0],len1,dv_vals[1],len2,dv_vals[2],len3,dv_vals[3],len4,dv_vals[4],len5,dv_vals[5],len6,state_monitor,blk_num_monitor);
end



endmodule 
