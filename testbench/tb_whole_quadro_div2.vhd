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
--constant CLK_PERIOD_clk125_B: TIME := 8 ns; 
--constant CLK_PERIOD_clkq: TIME := 8 ns; --# < 1/(125e6*(9/8)*(204/186))
--onstant CLK_PERIOD_clkq: TIME := 6.41 ns; --# < 1/(125e6*(9/8)*(204/186))
constant CLK_PERIOD_clkq: TIME := 64.10 ns; --# < 1/(125e6*(9/8)*(204/186))
--constant CLK_PERIOD_clkq: TIME := 152.00 ns; --# < 1/(125e6*(9/8)*(204/186))
--constant CLK_PERIOD_clkq: TIME := 200.00 ns; --# < 1/(125e6*(9/8)*(204/186))


constant CLKQ_SLOW:integer:=1;
constant FRAME_LEN:natural:=204;
constant CE_LEN:natural:=188;



component CRC_chk
port (
 Reset: in std_logic;
 Clk: in std_logic;
 CRC_data: in std_logic_vector(7 downto 0);
 CRC_init : in std_logic;
 CRC_en : in std_logic;
 CRC_chk_en : in std_logic;
 CRC_err: out std_logic
);
end component;


component phy_emu
generic(
		num:integer:=0
	);
port (
 clk: in std_logic;
 rd: in std_logic;
 dv: out std_logic;
 dataout: out std_logic_vector(7 downto 0);
 rx_dv: in std_logic;
 datain: in std_logic_vector(7 downto 0);
 rx_state: out std_logic
);
end component;

signal clkq,clk125,clk125_B,clk125_div2,clk125_div4:std_logic:='0';
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
signal Rx_er12,Rx_dv12,Rx_er21,Rx_dv21:std_logic;
signal Txd12,Rxd12,Txd21,Rxd21:std_logic_vector(7 downto 0):=(others=>'0');

--# rx engine
signal Rx_mac_ra_tb,Rx_mac_rd_tb:std_logic;
signal Rx_mac_eop_tb,Rx_mac_pa_tb,Rx_mac_sop_tb,Tx_mac_wr_n_tb: std_logic;
signal Rx_mac_data_tb : std_logic_vector(31 downto 0);
signal Rx_mac_BE_tb : std_logic_vector(1 downto 0);


signal data_fromfile12_I,data_fromfile12,data_fromfile21,data_fromfile_w1,data_fromfile_w2:std_logic_vector(7 downto 0);
signal ce_fromfile12_I,ce_fromfile_F,ce_fromfile12,ce_fromfile21,ce_fromfile_w1,ce_fromfile_w2:std_logic;

signal tx_coded_data12,tx_coded_data21,tx_coded_data_rs:std_logic_vector(7 downto 0);
signal tx_coded_ce,reset_delay:std_logic;
signal cccnt:std_logic_vector(15 downto 0):=(others=>'0');

signal dataout_end12_1w,dataout_end12,dataout_end21:std_logic_vector(7 downto 0);
signal ceout_end12_1w,ceout_end12,ceout_end21:std_logic;

signal err,Tx_er_end12,Tx_en_end12,Tx_er_end21,Tx_en_end21:std_logic;
signal Txd_end_w1,Txd_end12,Txd_end21:std_logic_vector(7 downto 0);

signal reset0,locked_sig,ack_out_bus,empty2_bus:std_logic;
signal time_cnt:std_logic_vector(31 downto 0):=(others=>'0');


signal makerr,rd89,empty89,state_value,ce89,ce89_w1,ce98,ce98_w1,empty98:std_logic:='1';
signal data89,data98,DataOutB_2,DataOutB:std_logic_vector(8 downto 0):=(others=>'0');
signal data8:std_logic_vector(7 downto 0):=(others=>'0');
signal useRS:std_logic:='0';

constant SPI_LEN:integer:=8;
signal data_spi:std_logic_vector(SPI_LEN-1 downto 0):="11111101";
signal spi_clk,read_irq,spi_data,spi_ce:std_logic:='0';
signal cnt:std_logic_vector(15 downto 0):=x"0000";
signal spi_cnt,spi_circle:integer:=0;

signal flow_ctrl_req12,flow_ctrl_ok12,flow_ctrl_req21,flow_ctrl_ok21:std_logic;
signal reset_W:std_logic_vector(191 downto 0):=(others=>'1');

signal fin_error12,fin_error21,last_data:std_logic;


signal rx_state12,rx_state21,flow_ctrl_answer12,flow_ctrl_answer21:std_logic;
signal RF_1_2,RF_2_1:std_logic_vector(7 downto 0);

signal clkq_mode_led12,clkq_mode_led21:std_logic;
signal clkq_SW:std_logic:='0';

type Ttest_stm is (P_DELAY,P_FRAME);
signal test_stm:Ttest_stm:=P_DELAY;
signal f_number,f_data:std_logic_vector(7 downto 0):=(others=>'0');
signal p_test_err:std_logic;
signal fifo_going_full_12b,fifo_going_full_12,fifo_going_full_21,receive_full_12,receive_full_21:std_logic;

signal syncfind12,flow_ctrl_req_a12,flow_ctrl_ok_a12,pause_mode12,flow_ctrl_ok_a12b:std_logic;
signal flow_a_get12:std_logic;

signal tangenta_12get,tangenta_12,SyncFindLED:std_logic;

signal tangenta_to_slave,tangenta12:std_logic;

signal rx_dv12_buf:std_logic;
signal rxd12_buf:std_logic_vector(7 downto 0);



begin

reset<='0' after 2*CLK_PERIOD_clkq;
clkq_SW<='1' after 4 ms;


CLK_GEN125: process(clk125)
begin
	clk125<= not clk125 after CLK_PERIOD_clk125/2; 
end process;

CLK_GEN125B: process(clk125_B)
begin
--	clk125_B<= not clk125_B after CLK_PERIOD_clk125_B/2; 
end process;
clk125_B<=clk125;

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


--mult31_25_inst : mult31_25 PORT MAP (
--		areset	 => reset0,
--		inclk0	 => clk125,
--		c0	 => clkq,
--		locked	 => locked_sig
--	);

process (clkq) is
begin
	if rising_edge(clkq) then
		reset_W<=reset_W(reset_W'Length-2 downto 0)&reset;
		time_cnt<=time_cnt+1;
		if locked_sig='1' then
--			reset<='0';
		else
--			reset<='1';
		end if;
	end if;
end process;

process (clk125) is
begin
	if rising_edge(clk125) then
		ceout_end12_1w<=ceout_end12;
		dataout_end12_1w<=dataout_end12;
	end if;
end process;




makerr<='0';-- after 5 ms; --when time_cnt(5 downto 0)=00 else '0';
useRS<='1';

RF_1_2<=tx_coded_data12 xor (SXT(makerr&makerr,tx_coded_data_rs'Length)) when tangenta12='1' else (others=>'0');
RF_2_1<=tx_coded_data21 xor (SXT(makerr&makerr,tx_coded_data_rs'Length));


fifo_going_full_12b<=fifo_going_full_12 and not(makerr);

 flow_ctrl_ok_a12b<=flow_ctrl_ok_a12 xor time_cnt(15);

--# #############################################################
--# #########  1->2 #############################################
--# #############################################################


phy_emu12: phy_emu
generic map(
	num=>0
	)
port map(
 clk=>clk125,
 rd=>'1',
 dv=>ce_fromfile12,
 dataout=>data_fromfile12,
 rx_dv=>ceout_end12,
 datain=>dataout_end12,
 rx_state=>rx_state12
);


tangenta_manager_master_i:entity work.tangenta_manager_master
	 port map(
		 reset=>reset,
		 clk => clk125,

		 time_of_work=>x"00BB00",
		 time_of_switchoff=>x"00BB00",
		 time_of_fake_translation=>x"0000AA",    --# time_of_switchoff >> time_of_fake_translation

		 tangenta_to_slave=>tangenta_to_slave, --# Send it by RF. if it '0' we cut trafic. Stop work RF transiver on slave site
		 tangenta=>tangenta12 --# if it '0' we cut trafic. Stop work RF transiver
	     );



trafic_buf_i: entity work.trafic_buf
	 port map(
		 reset =>reset,

		 time_of_fake_translation=>x"0000AA",
		 tangenta =>tangenta12, --# if it '0' we cut trafic. RF transiver to work

		 clk_phy =>clk125,
		 i_rx_dv =>ce_fromfile12,
		 i_rxd =>data_fromfile12,

		 clk_phyq =>clk125,  --# clk_phyq >= clk_phy 
		 o_rx_dv =>rx_dv12_buf,
		 o_rxd =>rxd12_buf
	     );


mac_frame_rx_inst: entity work.mac_frame_rx_ver2
	generic map
	(
	 CLKQ_SLOW=>CLKQ_SLOW
	)
	 port map(
		 reset =>reset,
		 clk125 =>clk125,
		 clkq =>clkq,
		 Rx_er=>'0',
		 Rx_dv=>rx_dv12_buf,--ce_fromfile12,
		 Rxd=>rxd12_buf,--data_fromfile12,
		 Crs=>'0',
		 Col=>'0',
		 tp=>open,
		 
		 i_tangenta=>tangenta_to_slave,

		 reg01 =>open,
		 read_irq=>read_irq, --# look on rising edge
         spi_clk=>spi_clk,
		 spi_ce=>spi_ce, --# '1' valid
		 spi_data=>spi_data,  --# принимает данные по falling edge

		 want_clkq_more=>'1',--clkq_SW,

		 fifo_going_full_i=>fifo_going_full_12b,
		 receive_full_i=>receive_full_12,

		 flow_ctrl_req =>flow_ctrl_req12,
		 flow_ctrl_ok =>flow_ctrl_ok12,

		 flow_ctrl_req_a=>flow_ctrl_req_a12,
		 flow_ctrl_ok_a=>flow_ctrl_ok_a12,
		 pause_mode_i=>pause_mode12,
		 flow_a_get=>flow_a_get12,

		 flow_ctrl_answer=>flow_ctrl_answer12,

		 data_out=>tx_coded_data12,
		 ce_out=>open
	     );


mac_frame_tx_inst: entity work.mac_frame_tx_ver2
	generic map
	(
	 CLKQ_SLOW=>CLKQ_SLOW
	)
	 port map(
		 reset =>reset,
		 clk125 =>clk125,
		 clkq =>clkq,

		 rs_reset_i=>'0',
		 Tx_er=>Tx_er_end12,
		 Tx_en=>ceout_end12,--Tx_en_end12,
		 Txd=>dataout_end12,--Txd_end12,
		 Crs=>'0',
		 Col=>'0',
		 tp=>open,
		
		 clkq_more_than_clk125=>'1',--clkq_mode_led12, --# Установить в '1' если clkq>clk125
		 need_to_clkq_big=>open,--clkq_mode_led12, --# Если '1' требуется переключить в режим clkq>clk125

		 o_tangenta=>tangenta_12get, -- it comes from tangenta_12 by RF channel

		 write_irq=>open,  --# выставляет rising_edge
		 spi_clk=>open,  --# 
		 spi_ce=>open,  --# '1' is valid
		 spi_data=>open,

		 fifo_going_full=>fifo_going_full_12, --# показывает что поток RF_2_1 некуда складывать
		 receive_full=>receive_full_12,

		 flow_ctrl_req=>flow_ctrl_req12, --# in 
		 flow_ctrl_ok=>flow_ctrl_ok12,   --# in 

		 flow_ctrl_req_a=>flow_ctrl_req_a12,
		 flow_ctrl_ok_a=>flow_ctrl_ok_a12,
         flow_a_get=>flow_a_get12,

		 flow_ctrl_answer=>flow_ctrl_answer12, --#out
		 dv_in=>ce_fromfile12,
		 pause_mode_o=>pause_mode12,

		 useRS => useRS, 
		 frames_reg01 =>open, --# Счетчик пакетов, на clk125
		 ErrRS_reg02 =>open, --# Счетчик корректируемых ошибок Рида-Соломона, на clkq
		 failRS_reg03 =>open, --# Счетчик корректируемых ошибок Рида-Соломона, на clkq
		 SyncFindLED =>SyncFindLED,    --# показывает захват синхронизации byte и frame align
		 bad_channelLED =>open,  --# показывает расширенный импульс неисправимой ошибки Рида-Соломона

		 start_correct =>open, --# Если будет '1', то что говорит о том что внутренние стробы синхронизации не верны.
		 sync_for_test =>open, --# Если '1' то значит на выходе с декодера Рида-Соломона данные все так-же имеют правельный фреймовый вид.
		
		 
		 data_in=>RF_1_2,
		 ce_in=>'1'
	     );


tangenta_manager_slave_i: entity work.tangenta_manager_slave
	 port map(
		 clk =>clk125,

		 tangenta_from_master=>tangenta_12get, --# Send it by RF. if it '0' we cut trafic. Stop work RF transiver on slave site
		 tangenta=>open --# if it '0' we cut trafic. Stop work RF transiver
	     );


--testMAC_inst_rx: entity work.simple_mac_rx
--	 port map(
--		 clk =>clk125,
--		 frame_ce =>ceout_end12,
--		 data_out =>dataout_end12,
--		 rx_dv =>Tx_en_end12,
--		 rx_er =>Tx_er_end12,
--		 rxd =>Txd_end12
--	     );




ser: entity work.show_frame_error
	 port map(
	 	 clk =>clk125,
		 ce => '1',
		 dv =>ceout_end12,
		 data =>dataout_end12,
		 error=>p_test_err
	     );


last_data<=ceout_end12_1w and ceout_end12;

CRC_chk_inst: CRC_chk
port map(
 Reset=>reset,
 Clk=>clk125,
 CRC_data=>dataout_end12_1w,
 CRC_init =>'1',
 CRC_en =>ceout_end12_1w,
 CRC_chk_en => last_data,
 CRC_err=>open
);



end tb;
