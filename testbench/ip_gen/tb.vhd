LIBRARY ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
--library std;
--use std.textio.all;

entity tb is
end tb;


architecture tb of tb is

-- clkq = 31/25*clk125 

constant CLK_PERIOD_clk125: TIME := 8 ns; 
constant CLK_PERIOD_clkq: TIME := 6.45161290322580645 ns; --# < 1/(125e6*(9/8)*(204/186))
--constant CLK_PERIOD_clkq: TIME := 80 ns; --# < 1/(125e6*(9/8)*(204/186))


constant CLKQ_SLOW:integer:=1;
constant FRAME_LEN:natural:=204;
constant CE_LEN:natural:=188;


component use_ipgen
port (
 clk: in std_logic;
 rd: in std_logic;
 dv: out std_logic;
 dataout: out std_logic_vector(7 downto 0)
);
end component;


component use_ipgen_test
port (
 clk: in std_logic;
 wr: in std_logic;
 dv: in std_logic;
 datain: in std_logic_vector(7 downto 0);
 error: out std_logic
);
end component;

signal clkq,clk125,clk125_div2,clk125_div4:std_logic:='0';
signal reset:std_logic:='1'; 
signal cnt_rd:std_logic_vector(64 downto 0):=(others=>'0');
signal cnt_wr:std_logic_vector(64 downto 0):=(others=>'0');

-- for data_generator
signal Tx_mac_wa,Tx_mac_wr:std_logic;
signal Tx_mac_data:std_logic_vector(31 downto 0);
signal Tx_mac_BE:std_logic_vector(1 downto 0);
signal Tx_mac_eop,Tx_mac_sop:std_logic;
signal Tx_mac_wa_n:std_logic;

--# loop back
signal Tx_en,Tx_er,Rx_clk,Gtx_clk,Tx_clk:std_logic;
signal Rx_er,Rx_dv:std_logic;
signal Txd,Rxd:std_logic_vector(7 downto 0):=(others=>'0');

--# rx engine
signal Rx_mac_ra_tb,Rx_mac_rd_tb:std_logic;
signal Rx_mac_eop_tb,Rx_mac_pa_tb,Rx_mac_sop_tb,Tx_mac_wr_n_tb: std_logic;
signal Rx_mac_data_tb : std_logic_vector(31 downto 0);
signal Rx_mac_BE_tb : std_logic_vector(1 downto 0);


signal data_fromfile,data_fromfile_w1,data_fromfile_w2:std_logic_vector(7 downto 0);
signal ce_fromfile_F,ce_fromfile,ce_fromfile_w1,ce_fromfile_w2:std_logic;

signal tx_coded_data,tx_coded_data_rs:std_logic_vector(7 downto 0);
signal tx_coded_ce,reset_delay:std_logic;
signal cccnt:std_logic_vector(15 downto 0):=(others=>'0');

signal dataout_end:std_logic_vector(7 downto 0);
signal ceout_end:std_logic;

signal err,Tx_er_end,Tx_en_end:std_logic;
signal Txd_end_w1,Txd_end:std_logic_vector(7 downto 0);

signal reset0,locked_sig,ack_out_bus,empty2_bus:std_logic;
signal time_cnt:std_logic_vector(31 downto 0):=(others=>'0');


signal makerr,rd89,empty89,state_value,ce89,ce89_w1,ce98,ce98_w1,empty98:std_logic;
signal data89,data98,DataOutB_2,DataOutB:std_logic_vector(8 downto 0):=(others=>'0');
signal data8:std_logic_vector(7 downto 0):=(others=>'0');
signal useRS:std_logic:='0';

constant SPI_LEN:integer:=8;
signal data_spi:std_logic_vector(SPI_LEN-1 downto 0):="11111101";
signal spi_clk,read_irq,spi_data,spi_ce:std_logic:='0';
signal cnt:std_logic_vector(15 downto 0):=x"0000";
signal spi_cnt,spi_circle:integer:=0;

signal flow_ctrl_req,flow_ctrl_ok:std_logic;
signal reset_W:std_logic_vector(191 downto 0):=(others=>'1');

signal fin_error:std_logic;

begin

reset<='0' after 80 ns;



CLK_GEN125: process(clk125)
begin
	clk125<= not clk125 after CLK_PERIOD_clk125/2; 
end process;

c125div2: process(clk125)
begin
 if rising_edge(clk125) then
  clk125_div2<=not clk125_div2;
 end if;
end process;

c125div4: process(clk125_div2)
begin
 if rising_edge(clk125_div2) then
  clk125_div4<=not clk125_div4;
 end if;
end process;


c125clkq: process(clkq)
begin
	clkq<= not clkq after CLK_PERIOD_clkq/2; 
end process;


use_ipgen_inst:use_ipgen
port map(
 clk=>clk125,
 rd=>'1',
 dv=>ce_fromfile,
 dataout=>data_fromfile
);


process(clk125) is
begin
	if rising_edge(clk125) then
		Txd_end<=data_fromfile;
		Tx_en_end<=ce_fromfile;
	end if;
end process;
  

use_ipgen_test_inst: use_ipgen_test
port map(
 clk=>clk125,
 wr=>'1',
 dv=>Tx_en_end,
 datain=>Txd_end,
 error=>fin_error
);


end tb;
