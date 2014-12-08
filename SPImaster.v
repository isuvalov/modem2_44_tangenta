  
module SPImaster (clk,syncRst,wrEn,
                  data,datBack,
                  spiRdy, 
                  MOSI,MISO,SCK
                 ); 

  parameter DAT_WIDTH = 3; //data width in bytes
  parameter LOG_WIDTH = 2; //binary logarithm of data width in bytes

   input         clk;           // clock
   input         syncRst;			    // Reset 
   input      [DAT_WIDTH*8-1:0] data;              // Input data 
   output reg [DAT_WIDTH*8-1:0] datBack;           // Output data 
   input         wrEn;		        // Write enable


   output        MOSI;			       // Master-out slave-in data line
   input         MISO;			       // Master-in slave-out data line 
   output        SCK;			        // SPI clock line
   output  reg   spiRdy;        // "SPI transaction finished" flag(cleared automatically during buffer filling),


//--------------------------- internal declaratons ----------------------------

   //  Division coefficient (its binary logarithm-1) for SPI clock
   parameter SCK_DIV = 1; 

   // still transferred/received (counter length is determined by SPI buffer double size for its full refresh)
   reg  [LOG_WIDTH:0]  byteCnt;           // Byte counter itself with one extra bit for defining transaction end 
   reg  [7:0]  SPI_buf [DAT_WIDTH-1:0];   // combined buffer for storing data to/from SPI
   reg 	[SCK_DIV:0] clkDivider;  // SCK clock generator
   reg  [2:0]  SCK_cnt;          // counter of SPI pulses to define end of byte transaction 
   reg  [7:0]  rxShiftRg;        // shift register for accumulating data from SPI  
   wire [7:0]  txShiftRg;        // actually the lowest byte in SPI_buf, serving as SPI output shift register,
      //  it is so because MOSI should be valid right after writing of even one word (for case of SPE=1) 
      //  without any byte shifting in the whole base buffer (SPI_buf), as next words may follow to be 
      //  written to adjacent places 
   

//---------------------------------------------------------------------

   wire rxEn = (clkDivider == {1'b0,{SCK_DIV{1'b1}}});
   wire txEn = (clkDivider == {1'b1,{SCK_DIV{1'b1}}});


   // clock divider 
   always @(posedge clk)
      if (syncRst) clkDivider <= 0;
      else if (!spiRdy && (!byteCnt[LOG_WIDTH] || !rxEn)) clkDivider <= clkDivider+{{SCK_DIV{1'b0}},1'b1};
           else clkDivider <= 0;

   assign SCK = clkDivider[SCK_DIV];


   always @(posedge clk)
      if (syncRst) SCK_cnt <= 3'h0;
      else if (txEn) SCK_cnt <= SCK_cnt+3'h1; 

   assign txShiftRg = SPI_buf[0];

//   always @(posedge clk)
//     if (syncRst) spiRdy <= 1'b1;
//     else if (!byteCnt[LOG_WIDTH]) spiRdy <= 1'b0;
          // time-out for setting spiRdy after transaction to satisfy SPI Memory spec., 
          // meaning needed delay releasing of Slave select signal (SS_N) (CS_n hold time)
//          else if (rxEn) spiRdy <= 1'b1;  


   integer i;
   always @(posedge clk)
     if (syncRst) begin byteCnt <= {(LOG_WIDTH+1){1'b1}};     // default value - transaction finished with counter roll-over   
                        spiRdy <= 1'b1;
                  end
     else begin 
            if (txEn) begin if (SCK_cnt==3'h7) begin for (i=0; i<(DAT_WIDTH-1); i=i+1) SPI_buf[i] <= SPI_buf[i+1];
	                                                    SPI_buf[DAT_WIDTH-1] <= rxShiftRg;
	                                                    byteCnt <= byteCnt-{{LOG_WIDTH{1'b0}},1'b1};
                                                end
                             else SPI_buf[0] <= {txShiftRg[6:0],txShiftRg[0]};
                       end
            if (wrEn) begin for (i=0; i<DAT_WIDTH; i=i+1) SPI_buf[i] <= data[i*8 +: 8]; //store data for transmission
   	                        byteCnt <= DAT_WIDTH-1; //start transmission
   	                        spiRdy <= 1'b0;
                      end
                   // time-out for setting spiRdy after transaction to satisfy SPI Memory spec., 
                   // meaning needed delay releasing of Slave select signal (SS_N) (CS_n hold time)
            else if (byteCnt[LOG_WIDTH] && rxEn) spiRdy <= 1'b1;
   	      end
                  
                     	
   always @(posedge clk)
      if (syncRst) rxShiftRg <= 8'h0;
      else if (rxEn) rxShiftRg <= {rxShiftRg[6:0],MISO};
   
   assign MOSI = txShiftRg[7];

   always @* for (i=0; i<DAT_WIDTH; i=i+1) datBack[i*8 +: 8] = SPI_buf[i];  //data output to read
 
endmodule 