//--------------------------------------------------------
// Company:   		DOK ltd.
// Engineer:  		Sergey Petrov
// Create Date:    	03.feb.2011
// Module Name:    	PLL_init
// Project Name:   	Gigabit_modem_v7.1P
// Target Devices: 	Altera Cyclone III 	 
// Description:  	Download ADF4108 registers
// Revisions: 
// Revision 0.01 - File Created 
// Additional Comments: 
//--------------------------------------------------------

module PLL_init    (input  clk,
                    input  syncRst,
                    output htrdData,
                    output htrdClk,
                    output txHtrdWr
                   ); 


  reg  [2:0] powerUpState;
  wire spiRdy;
  reg  wrStrb;
  reg  [17:0] timeOut;
  reg  [23:0] loadDat;
  wire [23:0] spiDat = {loadDat[7:0],loadDat[15:8],loadDat[23:16]}; 	//exchanged bytes as SPI sends lowest first
  

  always@(posedge clk) begin 
       if (syncRst)
          begin 
          powerUpState<=0;
          wrStrb <= 1'b0;                                             
		    timeOut <= 18'd0;
          end
       else if (wrStrb) wrStrb <= 1'b0;
       else if (spiRdy) 
                case (powerUpState)
                             
               3'h0: begin if (!timeOut[1]) timeOut <= timeOut+18'h1; //required time-out
                            else
								begin
								  powerUpState   <= powerUpState+3'h1;
                                loadDat[1:0]   <= 2'b01;   	//access to R-counter
                                loadDat[15:2]  <= 14'h2;		//R-counter 14-bits
										  loadDat[17:16] <= 2'b00;		//Antibacklach pulse with												
                                loadDat[18]    <= 1'b0;  	//Lock detect precision
                                loadDat[19]    <= 1'b0;   	//Test mode
                                loadDat[21:20] <= 2'b11;		//Band select clock divider
                                loadDat[23:22] <= 2'b00;		//Reserved
                          wrStrb <= 1'b1; timeOut <= 18'd0;
								end
                     end        
                            
					3'h1: begin if (!timeOut[1]) timeOut <= timeOut+18'h1; //required time-out
                            else
								begin
								  powerUpState   <= powerUpState+3'h1;
										  loadDat[1:0]   <= 2'b00;   	//access to Control latch
										  loadDat[3:2]   <= 2'b01;    //Core power level
										  loadDat[4]     <= 1'b0; 		//Counter operation
										  loadDat[7:5]	  <= 3'b001;	//Muxout output
										  loadDat[8]	  <= 1'b1;		//Phase detector polarity
										  loadDat[9]     <= 1'b0;		//Charge pump output
										  loadDat[10]    <= 1'b0;		//CP gaiN
										  loadDat[11]    <= 1'b0;		//MTLD
										  loadDat[13:12] <= 2'b11;		//Output power level
										  loadDat[16:14] <= 3'b000;	//Current setting 1
										  loadDat[19:17] <= 3'b000;   //Current setting 2
										  loadDat[21:20] <= 2'b00;		//Mode
										  loadDat[23:22] <= 2'b01;		//Prescaler value
								  wrStrb <= 1'b1;	timeOut <= 18'd0;
								end													
							end
							
					3'h2: begin if (!timeOut[1]) timeOut <= timeOut+18'h1; //required time-out
                            else
								begin
								powerUpState   <= powerUpState+3'h1;
								        loadDat[1:0]   <= 2'b10;   	//access to N-counter latch
										  loadDat[6:2]   <= 5'h0;		//A-counter value Lo-h4; Hi-hF
										  loadDat[7]     <= 1'b0;		//Reserved
										  loadDat[20:8]  <= 13'h14;	//B-counter value Lo-h12; Hi-h13
										  loadDat[21]    <= 1'b0;		//CP gaiN
										  loadDat[22]    <= 1'b0;		//Divide by-2
										  loadDat[23]    <= 1'b0;		//Divide by-2 select
                          wrStrb <= 1'b1; timeOut <= 18'd0;          
								end
                     end
							
					3'h3: begin if (!timeOut[1]) timeOut <= timeOut+18'h1; //required time-out
                            else
								begin
								  powerUpState   <= powerUpState+3'h1;
                                loadDat[1:0]   <= 2'b10;   	//access to N-counter latch
										  loadDat[6:2]   <= 5'h0;		//A-counter value Lo-h4; Hi-hF
										  loadDat[7]     <= 1'b0;		//Reserved
										  loadDat[20:8]  <= 13'h14;	//B-counter value Lo-h12; Hi-h13
										  loadDat[21]    <= 1'b0;		//CP gaiN
										  loadDat[22]    <= 1'b0;		//Divide by-2
										  loadDat[23]    <= 1'b0;		//Divide by-2 select
                          wrStrb <= 1'b1; timeOut <= 18'd0;  
								end                                               
							end
					                                  
					default:; //end of power-up sequence
                    endcase
                                            
       end
  
 assign txHtrdWr = !(powerUpState==3'h1 || 
                     powerUpState==3'h2 ||
                     powerUpState==3'h3 ||
                     powerUpState==3'h4)|| spiRdy;
  
  
  SPImaster iSPImaster (.syncRst(syncRst),
                        .clk(clk),
                        .wrEn(wrStrb),
                        .data(spiDat),
                        .datBack(),
                        .MOSI(htrdData),
                        .MISO(1'b0),
                        .SCK(htrdClk), //don't care value maybe applied to unused serial input (now zero is applied)
                        .spiRdy(spiRdy)
                       );
 
endmodule 