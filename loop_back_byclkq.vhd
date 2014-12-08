library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity loop_back_byclkq is
	 port(
		 reset : in std_logic;
		 clk_rx : in std_logic; --# with rxd
		 clk_tx : in std_logic; --# with txd
		 clkq   : in std_logic;
		 rx_dv : in STD_LOGIC;
		 rxd : in STD_LOGIC_VECTOR(7 downto 0);
		 errors: out std_logic_vector(3 downto 0);
		 tx_en : out STD_LOGIC;
		 txd : out STD_LOGIC_VECTOR(7 downto 0)
	     );
end loop_back_byclkq;


architecture loop_back_byclkq of loop_back_byclkq is


component frame_fifo
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (8 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		rdusedw		: OUT STD_LOGIC_VECTOR (13 DOWNTO 0);
		wrfull		: OUT STD_LOGIC 
	);
end component;

signal datain:std_logic_vector(8 downto 0);
signal dataout:std_logic_vector(8 downto 0);
signal rdempty, rd, rd_w1, wrreq, wrfull1, wrfull, wr, rd_out: std_logic;

signal counter,counter_out: STD_LOGIC_VECTOR (13 DOWNTO 0);

signal inner_data,inner_data_reg,inner_data_reg_w1:std_logic_vector(8 downto 0);

begin

wrreq<=not wrfull; --wrfull1
errors(0)<=wrfull1;

datain<=rx_dv&rxd;
txd<=dataout(7 downto 0);
tx_en<=dataout(8);


getdata: frame_fifo
	PORT map
	(
		aclr		=>reset,
		data		=>datain,
		rdclk		=>clkq,
		rdreq		=>rd,
		wrclk		=>clk_rx,
		wrreq		=>wrreq,
		q		=>inner_data, --#data on clkq
		rdempty		=>errors(1),
		rdusedw		=>counter,
		wrfull		=>wrfull1
	);


process (clkq) is
begin
	if rising_edge(clkq) then
		if reset='1' then
			inner_data_reg<=(others=>'0');
			rd<='0';
			rd_w1<='0';
		else --# reset
			rd_w1<=rd;
			if unsigned(counter)>unsigned('1'&EXT("0",counter'Length-1)) then
				rd<='1';
			else
				rd<='0';
			end if;
			if rd_w1='1' then
				inner_data_reg<=inner_data;
			end if;

			inner_data_reg_w1<=inner_data_reg;
			wr<=rd_w1;
			
		end if; --# reset
	end if;
end process;


outdata: frame_fifo
	PORT map
	(
		aclr		=>reset,
		data		=>inner_data_reg_w1,
		rdclk		=>clk_tx,
		rdreq		=>rd_out,
		wrclk		=>clkq,
		wrreq		=>wr,
		q		=>dataout, --#data on clk_tx
		rdempty		=>errors(3),
		rdusedw		=>counter_out,
		wrfull		=>errors(2)
	);



process (clk_tx) is
begin
	if rising_edge(clk_tx) then
		if reset='1' then
			rd_out<='0';
		else --# reset
			if unsigned(counter_out)>unsigned('1'&EXT("0",counter_out'Length-1)) then			
				rd_out<='1';
			end if;
		end if; --# reset
	end if;
end process;


end loop_back_byclkq;
