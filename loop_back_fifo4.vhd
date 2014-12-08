library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity loop_back_fifo4 is
	 port(
		 reset  :in std_logic;
		 clk_rx :in std_logic; --# with rxd
		 clk_tx :in std_logic; --# with txd
		 rx_dv  :in STD_LOGIC;
		 rxd    :in STD_LOGIC_VECTOR(3 downto 0);
		 tx_en  :out STD_LOGIC;
		 txd    :out STD_LOGIC_VECTOR(3 downto 0);
		 wrfull_out :out std_logic;
		 rdempty_out:out std_logic
	       );
end loop_back_fifo4;


architecture loop_back_fifo4 of loop_back_fifo4 is


component frame_fifo
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		   : OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdempty  : OUT STD_LOGIC ;
		rdusedw	: OUT STD_LOGIC_VECTOR (13 DOWNTO 0);
		wrfull	: OUT STD_LOGIC 
	);
end component;

signal datain:std_logic_vector(8 downto 0);
signal dataout:std_logic_vector(8 downto 0);
signal rd,rd_w1,rdempty,wrreq,wrfull,wr,rd_out: std_logic;

signal counter,counter_out: STD_LOGIC_VECTOR (13 DOWNTO 0);

--signal inner_data,inner_data_reg,inner_data_reg_w1:std_logic_vector(8 downto 0);

begin

wrreq<=not wrfull;

wrfull_out	<= wrfull;
rdempty_out <= rdempty;

process (clk_rx)
begin
   if rising_edge(clk_rx)then
	  datain(3 downto 0)<=rxd;
	  datain(7 downto 4)<= x"0";
     datain(8)<=rx_dv;
   end if;
end process;

process (clk_tx) is
begin
	if rising_edge(clk_tx)then
		if reset='1' then
			rd_out<='0';
		else --# reset
		   txd<=dataout(3 downto 0);
         tx_en<=dataout(8);
			--if unsigned(counter_out)>unsigned('1'&EXT("0",counter_out'Length-1)) then			
				rd_out<='1';
			--end if;
		end if; --# reset
	end if;
end process;


--getdata: frame_fifo
--	PORT map
--	(
--		aclr		=>reset,
--		data		=>datain,
--		rdclk		=>clkq,
--		rdreq		=>rd,
--		wrclk		=>clk_rx,
--		wrreq		=>wrreq,
--		q		=>inner_data, --#data on clkq
--		rdempty		=>errors(1),
--		rdusedw		=>counter,
--		wrfull		=>wrfull1
--	);


--process (clkq) is
--begin
--	if rising_edge(clkq) then
--		if reset='1' then
--			inner_data_reg<=(others=>'0');
--			rd<='0';
--			rd_w1<='0';
--		else --# reset
--			rd_w1<=rd;
--			if unsigned(counter)>unsigned('1'&EXT("0",counter'Length-1)) then
--				rd<='1';
--			else
--				rd<='0';
--			end if;
--			if rd_w1='1' then
--				inner_data_reg<=inner_data;
--			end if;

--			inner_data_reg_w1<=inner_data_reg;
--			wr<=rd_w1;
			
--		end if; --# reset
--	end if;
--end process;


outdata: frame_fifo
	PORT map
	(
		aclr		=>reset,
		data		=>datain,
		rdclk		=>clk_tx,
		rdreq		=>'1',  --rd_out,
		wrclk		=>clk_rx,
		wrreq		=>'1',  --wrreq,
		q		   =>dataout,
		rdempty	=>rdempty,
		rdusedw	=>counter_out,
		wrfull	=>wrfull
	);

end loop_back_fifo4;
