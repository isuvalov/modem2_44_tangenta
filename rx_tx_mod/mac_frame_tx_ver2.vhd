library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
library work;
use work.lan_frames_pack.all;

-- tp0 - MAC TX FIFO empty
-- tp1 - MAX TX FIFO full

--# Receive data from RF and push it to PHY
entity mac_frame_tx_ver2 is
	generic 
	(
	 CLKQ_SLOW:integer:=1 --# установить в 1 если clkq<clk125, иначе 0
	);
	 port(
		 reset : in std_logic;
		 clk125 : in std_logic;
		 clkq : in std_logic;
		 rs_reset_i : in std_logic;

		 clkq_more_than_clk125: in std_logic; --# Установить в '1' если clkq>clk125
		 need_to_clkq_big: out std_logic; --# Если '1' требуется переключить в режим clkq>clk125

		 Tx_er: out std_logic;
		 Tx_en: out std_logic;
		 Txd: out std_logic_vector(7 downto 0);		 
		 Crs: in std_logic;
		 Col: in std_logic;
		 tp : out std_logic_vector(7 downto 0);

		 write_irq: out std_logic;  --# выставляет rising_edge
		 spi_clk: out std_logic;  --# 
		 spi_ce: out std_logic;  --# '1' is valid
		 spi_data: out std_logic;

		 fifo_going_full: out std_logic;
		 receive_full: out std_logic;
		 flow_ctrl_req: in std_logic; --# by clkq 
		 flow_ctrl_ok: in std_logic; --# by clkq 

		 flow_ctrl_req_a: out std_logic; 
		 flow_ctrl_ok_a: out std_logic;   
		 pause_mode_o: out std_logic;
		 flow_a_get: in std_logic;
		 dv_in: in std_logic;

		 flow_ctrl_answer: out std_logic; --# by clkq 

		 useRS : in std_logic;		 
		 frames_reg01: out std_logic_vector(63 downto 0); --# Счетчик пакетов, на clk125
		 ErrRS_reg02: out std_logic_vector(31 downto 0); --# Счетчик корректируемых ошибок Рида-Соломона, на clkq
		 failRS_reg03: out std_logic_vector(31 downto 0); --# Счетчик корректируемых ошибок Рида-Соломона, на clkq
		 SyncFindLED : out std_logic;    --# показывает захват синхронизации byte и frame align
		 bad_channelLED : out std_logic;  --# показывает расширенный импульс неисправимой ошибки Рида-Соломона
		 start_correct : out std_logic; --# Если будет '1', то что говорит о том что внутренние стробы синхронизации не верны.
		 sync_for_test : out std_logic; --# Если '1' то значит на выходе с декодера Рида-Соломона данные все так-же имеют правельный фреймовый вид.

		 data_in: in std_logic_vector(7 downto 0);
		 ce_in: in std_logic
	     );
end mac_frame_tx_ver2;


architecture mac_frame_tx_ver2 of mac_frame_tx_ver2 is
constant WATCH_DOG:integer:=0;
constant SCRAMBLER_OFF:integer:=0;

component frame_fifo IS
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

constant CLKQ_SLOW_N:integer:=1-CLKQ_SLOW;
constant SHFT:integer:=0;
constant USE_XOR:integer:=1;

signal USE_XORstd:std_logic;

signal shift:std_logic_vector(2 downto 0):=(others=>'0');
signal fout_timed2,fout_timed,fout_timea,fout_timeb,fout_cnt_w1,fout_cnt:std_logic_vector(13 downto 0):=(others=>'0');
signal fout_timed2_val:std_logic;
signal ce_in_w2,ce_in_w1:std_logic;
signal start_frame_p1,start_frame,SyncFind:std_logic;
signal data_in_shift_w4,data_in_shift_w3,data_in_shift_w1,data_in_shift_w2,data_in_shift_descr_w1,data_in_shift_descr,data_in_shift:std_logic_vector(data_in'Length-1 downto 0);
signal start_frame_n:std_logic;			  
signal data9,data9_w1,data9_w2:std_logic_vector(8 downto 0);
signal DecodData_w1,DecodData:std_logic_vector(7 downto 0);

-- for data_generator
signal Tx_mac_wa,Tx_mac_wr:std_logic;
signal Tx_mac_data:std_logic_vector(31 downto 0);
signal Tx_mac_BE:std_logic_vector(1 downto 0);
signal Tx_mac_eop,Tx_mac_sop:std_logic;
signal Tx_mac_wa_n,sGtx_clk:std_logic;
signal reset_with_sync_w1,reset_with_sync_n,reset_with_sync,err,decfail:std_logic;
signal Bdata9_shift_w1,Bdata9_3,Bdata9_shift,Bdata9,Bdata9_w1,Bdata9_w2:std_logic_vector(8 downto 0);
signal have_to_start_w1,have_to_start2,have_to_start2_1w,e_full,e_empty,start_frame_not,have_to_start,data9_ce2,data9_ce,new_ce9:std_logic;

signal frame_cnt:std_logic_vector(63 downto 0);
signal dout_cnt_forstart:std_logic_vector(11 downto 0);
signal start_frame_w1,start_frame_n_w1,start_frame_p1_w2,start_frame_p1_w1:std_logic;
signal start_frame_p1_w3,start_frame_p1_w4,start_frame_p1_w5:std_logic;
signal start_frm_cnt:std_logic_vector(2 downto 0);
signal num_err_sym:std_logic_vector(4 downto 0);
signal s_ErrRS_reg02: std_logic_vector(31 downto 0);
signal s_failRS_reg03: std_logic_vector(31 downto 0);
signal reset_with_sync_by125,source_sop_w1,source_sop,source_eop_w1,source_eop:std_logic;
signal d_to_design:std_logic_vector(7 downto 0);
signal start_frame_p1_rs_p1,start_frame_p1_rs,scr_ce,scr_ce_w1,scr_ce_w2:std_logic;
signal new_start_p1_1w,new_start,new_start_w1,start_frame_p1_rs_w1,start_frame_p1_rs_w2:std_logic;
signal cnt_for_ce,cnt_for_ce2:std_logic_vector(8 downto 0);
signal reset_with_sync_add,rs_reset_i_byclkq:std_logic;
signal reset_by_fifofull,reset_by_fifofull_byclkq:std_logic;
signal reset_by_decfail,decfail2,can_remove:std_logic;
signal decfail_cnt:std_logic_vector(1 downto 0);
signal decfail_scale:std_logic;
signal useRS_w1,useRS_w2:std_logic:='0';
signal decfail_scale_cnt:std_logic_vector(9 downto 0);
type Tfifo_monitor is (STARTING,UPING,DOWNING);
signal fifo_monitor:Tfifo_monitor;
signal reset_by_RSmode,rs_reset_i_byclkq2:std_logic;
signal start_frame_p1_test,descriptor_ce:std_logic;
signal descriptor:std_logic_vector(7 downto 0);
signal flow_ctrl_req_reg,flow_ctrl_ok_reg:std_logic;
signal flow_ctrl_req_byclk125,flow_ctrl_ok_byclk125:std_logic;
signal flow_ctrl_req_byclk125_s,flow_ctrl_ok_byclk125_s:std_logic;
signal flow_ctrl_req_byclk125_m,flow_ctrl_ok_byclk125_m:std_logic;
signal empty_space,empty_space_start,dv_delayed,dv_mux,pause_mode,pause_mode_1w:std_logic;
signal delayed_data,data_mux:std_logic_vector(7 downto 0);
signal flow_ctrl_mux_cnt:std_logic_vector(6 downto 0);

signal first_start,have_datainfifo:std_logic:='0';

signal reset_descr:std_logic:='1';
signal fiford:std_logic:='0';
signal fiford_cnt:std_logic_vector(7 downto 0);
signal fifo_cnt_d,fifo_cnt_out,fifo_cnt_in,fifo_cnt_in_byclkq,fifo_cnt_in_byclkq2:std_logic_vector(7 downto 0);
signal data9_8_1w,Bdata9_shift_8_1w:std_logic:='0';

constant middle_value:STD_LOGIC_VECTOR (fout_cnt'Length-1 DOWNTO 0):="10"&EXT("0",fout_cnt'Length-2);	
signal have_to_start_state:std_logic:='0';
      
type Tstm_reader is (WAITING,FLOW_START0,FLOW_START,FLOW_GO,READ_START,READING,GET_REG_ADDPAUSE1,GET_REG_ADDPAUSE1_W,GET_REG_ADDPAUSE2,READ_REG,GET_REG,GET_REG_ADDPAUSE1_REG);
signal stm_reader:Tstm_reader;
signal stm_reader_havereg:std_logic;
signal stm_reader_reg:std_logic_vector(8 downto 0);
signal clkq_more_than_clk125_1w: std_logic;
signal empty_space_start_1w,empty_space_start_2w,empty_space_start_3w:std_logic;
signal someflowneed,go_flow1,go_flow2,s_fifo_going_full_state:std_logic;

signal flow_ctrl_req_1w,flow_ctrl_ok_1w: std_logic; 
signal s_flow_ctrl_req_a,s_flow_ctrl_ok_a: std_logic;

signal tx_cnt_timeout:std_logic_vector(4 downto 0);
signal dv_in_timeout:std_logic_vector(18 downto 0):=(others=>'1');
signal dv_in_timeout_event_1w,dv_in_timeout_event,dv_in_1w:std_logic;
signal addpause_w_cnt:std_logic_vector(3 downto 0):=(others=>'0');

type Txor_packet is array (0 to 71) of integer;
constant xor_packet:Txor_packet:=(
 165,205,103,103,59,19,143,143,29,67,75,92,221,154,42,136,74,43
,139,127,255,191,81,102,124,41,47,182,157,178,112,117,208,65,14
,245,206,79,158,25,19,209,221,49,78,22,93,117,203,96,171,58,242
,87,83,51,214,212,212,160,56,47,206,244,223,165,42,14,71,2,94,75);


type Tflow_ctrl_packet is array (0 to 71) of std_logic_vector(7 downto 0);
constant flow_ctrl_packet_pause:Tflow_ctrl_packet:=
 (x"55",x"55",x"55",x"55",x"55",x"55",x"55",x"D5",

  x"01",x"80",x"C2",x"00",x"00",x"01",x"43",x"41",
  x"4D",x"00",x"00",x"00",x"88",x"08",x"00",x"01",

  x"FF",x"FF",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"EC",x"C1",x"B2",x"4E"
);

constant flow_ctrl_packet_ok:Tflow_ctrl_packet:=
 (x"55",x"55",x"55",x"55",x"55",x"55",x"55",x"D5",

  x"01",x"80",x"C2",x"00",x"00",x"01",x"43",x"41",
  x"4D",x"00",x"00",x"00",x"88",x"08",x"00",x"01",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",

  x"00",x"00",x"00",x"00",x"00",x"00",x"00",x"00",
  x"00",x"00",x"00",x"00",x"68",x"AA",x"BD",x"37"
);

signal test_val,test_val_reg:std_logic_vector(7 downto 0):=(others=>'0');
signal test_val_err,test_pre_val:std_logic;

signal qtest_val,qtest_val_reg:std_logic_vector(7 downto 0):=(others=>'0');
signal qtest_val_err,qtest_pre_val:std_logic;
signal test_in_pause_mode,flow_ctrl_req2,s_receive_full,s_receive_full_1w:std_logic:='0';
signal flow_ctrl_ok2,add_flow_ok:std_logic:='0';
signal add_flow_ok_cnt:std_logic_vector(3 downto 0):=(others=>'0');

signal reset_flow_ok,reset_flow_pause:std_logic:='0';
signal reset_with_sync_with_full,s_fifo_going_full:std_logic;

signal timecnt:std_logic_vector(4 downto 0):=(others=>'0');
signal pause_mode_cnt:std_logic_vector(10 downto 0):=(others=>'1');
signal pause_mode_cnt_more,cntflow,ok_made,stop_made:std_logic:='0';

begin

--fnd_empty_inst: entity work.find_empty_space_flowc
--	generic map
--	(
--	 NEED_SPACE=>80
--	)
--	 port map(
--		 reset => reset,
--		 use_delay=>'1',
--	 	 clk =>clk125,
--		 dv =>Bdata9_3(8),
--		 data =>Bdata9_3(7 downto 0),
--		 empty_space =>empty_space,
--		 empty_space_start =>empty_space_start,
--		 delayed_data =>delayed_data,
--		 dv_delayed =>dv_delayed
--	     );
USE_XORstd<='1' when USE_XOR=1 else '0';


muxit: process(clk125) is
begin
	if rising_edge(clk125) then
		empty_space_start_1w<=empty_space_start;
		empty_space_start_2w<=empty_space_start_1w;
		empty_space_start_3w<=empty_space_start_2w;

		delayed_data<=Bdata9_3(7 downto 0);
		dv_delayed<=Bdata9_3(8);
		data_mux<=delayed_data;
		dv_mux<=dv_delayed;
	end if;
end process;


MAC_inst: entity work.simple_mac_tx
	 port map(
		 clk =>clk125,
		 useit=>USE_XORstd,
		 frame_ce =>dv_mux,
		 data_in =>data_mux,
		 tx_en => tx_en,
		 tx_er =>tx_er,
		 txd =>Txd
	     );

process (clkq) is
variable v_decfail_cnt:std_logic_vector(decfail_cnt'Length-1 downto 0);
begin		
	if rising_edge(clkq) then
	 s_receive_full_1w<=s_receive_full;

	 if s_receive_full='0' and s_receive_full_1w='1' then
		 add_flow_ok_cnt<=(others=>'1');
		 add_flow_ok<='0';
	 else
		if unsigned(add_flow_ok_cnt)>0 then
			add_flow_ok_cnt<=add_flow_ok_cnt-1;
			add_flow_ok<='1';
		else
			add_flow_ok<='0';
		end if;
	 end if;


	 v_decfail_cnt:=(others=>'1');
	 ce_in_w1<=ce_in;
	 ce_in_w2<=ce_in_w1;
	 if reset='1' then
		decfail_cnt<=(others=>'0');
		reset_by_decfail<='0';
	 else
		if source_sop='1' and decfail='1' then
			decfail_cnt<=decfail_cnt+1;
			if decfail_cnt=v_decfail_cnt then
				reset_by_decfail<='1' and useRS;
			else
				reset_by_decfail<='0';
			end if;
		else
			if source_sop='1' and decfail='0' then 
				decfail_cnt<=(others=>'0');
			end if;
			reset_by_decfail<='0';
		end if;
	 end if;
	end if;
end process;

shifit_it: entity work.flowbyte_shifter
	 port map(
	 	 clk =>clkq,
	 	 ce =>ce_in,
		 datain =>data_in,
		 shift =>shift,
		 dataout =>data_in_shift
		 );
		 
process (clkq) is
begin		
	if rising_edge(clkq) then
	 SyncFindLED<=SyncFind;
	end if;
end process;		 

synccc: entity work.find_synchro
	generic map(
		PERIOD=>BFRAME_LEN,--FRAME_LEN, --# This is only when RS not include FRAME_LEN,--
		CE_LEN=>FRAME_LEN
	)
	 port map(
		 clk =>clkq,
		 ce =>ce_in_w1,
		 reset =>reset,		 
		 datain =>data_in_shift,
		 start_frame_n=>start_frame_n,
		 start_frame =>start_frame,
		 start_frame_p1 =>start_frame_p1,
		 SyncFind =>SyncFind
	     );	



shifyff: entity work.shift_finder
	 port map(
		 clk =>clkq,
		 ce =>ce_in_w2,
		 SyncFind =>SyncFind,
		 reset =>reset,
		 shift =>shift
	     );		 

start_frame_p1_rs<=source_eop when useRS='1' else start_frame_p1_w2;

process (clkq) is
begin		
	if rising_edge(clkq) then


	if data9_ce2='1' then
		qtest_pre_val<=data9(8);
	end if;
	if data9_ce2='1' then
		qtest_val_reg<=data9(7 downto 0);
		if (qtest_val_reg+1)/=data9(7 downto 0) then
			qtest_val_err<='1';
		else
			qtest_val_err<='0';
		end if;
	else
		qtest_val_err<='0';
	end if;

--    		 tbd1_ce=>descriptor_ce,
--	     tbd1_data=>descriptor,
	
	 rs_reset_i_byclkq<=rs_reset_i;
	 reset_by_fifofull_byclkq<=reset_by_fifofull;
     reset_with_sync_w1<=reset_with_sync;

     source_sop_w1<=source_sop;
	 DecodData_w1<=DecodData;

     if useRS='1' then
		d_to_design<=DecodData;
     else
		d_to_design<=data_in_shift_w1;	
	 end if;

	 if reset_with_sync='1' then
		cnt_for_ce2<=(others=>'0');
		new_start<='0';
		new_start_w1<='0';
	    decfail2<='0';
		first_start<='0';
		reset_descr<='1';
		s_receive_full<='0';
	 else --# reset_with_sync

        if descriptor_ce='1' then
  			s_receive_full<=descriptor(3);
	    end if;


		new_start_w1<=new_start;
		if useRS='1' then
			if source_sop='1' then
				cnt_for_ce2<=(others=>'0');
			else
				cnt_for_ce2<=cnt_for_ce2+1;
			end if;
			decfail2<=decfail or not(can_remove) or decfail_scale or decfail_scale;
	 		
		else  --# useRS
			if start_frame_p1_w2='1' then
				cnt_for_ce2<=(others=>'0');
			else
				cnt_for_ce2<=cnt_for_ce2+1;
			end if;

			decfail2<='0' or not(can_remove);

			if unsigned(cnt_for_ce2)>=BFRAME_LEN-1 and data_in_shift_w1=x"B8" then
			   reset_descr<='0';
			end if;
		end if; --# useRS

		if cnt_for_ce2=0 then
			new_start<='1';
		else
			new_start<='0';
		end if;

	 	if unsigned(cnt_for_ce2)>=FRAME_LEN-1 then
			scr_ce<='0';
	 	else
			scr_ce<='1';
	 	end if;

	 end if; --# reset_with_sync


	 if reset_with_sync='1' then
		decfail_scale_cnt<=(others=>'0');
		decfail_scale<='0';
		start_correct<='0';
	 else


		if decfail='1' then
			decfail_scale_cnt<=conv_std_logic_vector(204*4,decfail_scale_cnt'Length);
			decfail_scale<='1';
		else
			if unsigned(decfail_scale_cnt)>0 then
				decfail_scale_cnt<=decfail_scale_cnt-1;
				decfail_scale<='1';
			else
				decfail_scale<='0';
			end if;
		end if;

	 	scr_ce_w1<=scr_ce;
	 	scr_ce_w2<=scr_ce_w1;
		source_eop_w1<=source_eop;
		start_correct<=start_frame_p1_test xor source_sop;
	 end if;

	 start_frame_n_w1<=start_frame_n;
     start_frame_p1_w1<=start_frame_p1;
	 start_frame_p1_w2<=start_frame_p1_w1;
	 start_frame_p1_w3<=start_frame_p1_w2;
	 start_frame_p1_w4<=start_frame_p1_w3;
	 start_frame_p1_w5<=start_frame_p1_w4;
	 start_frame_w1<=start_frame;

	 data_in_shift_w1<=data_in_shift;
	 data_in_shift_w2<=data_in_shift_w1;
	 data_in_shift_w3<=data_in_shift_w2;
	 data_in_shift_w4<=data_in_shift_w3;

	 useRS_w1<=useRS;
	 useRS_w2<=useRS_w1;
	 if (useRS_w2='0' and useRS_w1='1') or (useRS_w2='1' and useRS_w1='0') then
		reset_by_RSmode<='1';
	 else
		reset_by_RSmode<='0';
	 end if;
	 rs_reset_i_byclkq2<=rs_reset_i_byclkq or reset_by_RSmode;
     
	 start_frame_p1_rs_w1<=start_frame_p1_rs;
	 start_frame_p1_rs_w2<=start_frame_p1_rs_w1;
	 data_in_shift_descr_w1<=data_in_shift_descr;

	 if SyncFind='0' or reset='1' or rs_reset_i_byclkq2='1' or reset_by_fifofull_byclkq='1' then
		start_frm_cnt<=(others=>'0');
		reset_with_sync<='1';
		reset_with_sync_with_full<='1';
	 else
		if start_frame_p1='1' then
--			if unsigned(start_frm_cnt)<3 then
--    			start_frm_cnt<=start_frm_cnt+1;
				reset_with_sync<='0';

				if e_full='1' then
					reset_with_sync_with_full<='0';
				else
					reset_with_sync_with_full<='0';
				end if;
--			else
--				reset_with_sync<='0';
--			end if;
		else
			reset_with_sync_with_full<='0';
		end if;
	end if;

	end if;
end process;		 
		 

start_frame_not<=not start_frame;		 

scr_inst: entity work.self_descrambler
  generic map(
	SWITCH_OFF=>SCRAMBLER_OFF
  )
  port map( 
	clk =>clkq,
	reset =>reset_with_sync_w1,
	mux_ce =>scr_ce,
	data_in =>d_to_design,
    data_out =>data_in_shift_descr
  );

reset_with_sync_n<=not reset_with_sync;



synccc_test: entity work.find_synchro
	generic map(
		PERIOD=>BFRAME_LEN, --# This is only when RS not include FRAME_LEN,--
		CE_LEN=>FRAME_LEN
	)
	 port map(
		 clk =>clkq,
		 ce =>'1',
		 reset =>reset,		 
		 datain =>d_to_design,
		 start_frame_n=>open,
		 start_frame =>open,
		 start_frame_p1 =>start_frame_p1_test,
		 SyncFind =>sync_for_test
	     );	


RS_altera: entity work.rs_decoder 
	PORT map (                    
		clk	=>clkq,
		reset	=>reset_with_sync,
		rsin	=>data_in_shift,
		sink_val	=>reset_with_sync_n,
		sink_sop	=>start_frame,  -- указывает на первый байт последовательности
		sink_eop	=>start_frame_p1,--stop,

		source_ena	=>'1',
		bypass	=>'0',
		rsout	=>DecodData,
		sink_ena	=>open,
		source_val	=>open,
		source_sop	=>source_sop,
		source_eop	=>source_eop,
		decfail	=>decfail,
		num_err_sym	=>num_err_sym,
		num_err_bit0	=>open,
		num_err_bit1	=>open
	);


--find_bytes_ist: entity work.find_bytes
--	 port map(
--		 clk =>clkq,
--		 ce =>'1',
--		 datain =>data_in_shift_descr,
--		 find=>open
--	     );

		 
block2ipf_inst: entity work.block2ip_frame
	 port map(
		 reset =>reset_with_sync,
		 clk =>clkq,

		 frame_start=>new_start,
		 data_ce=>'1',
		 datain=>data_in_shift_descr,
		
		 tbd1_ce=>descriptor_ce,
	     tbd1_data=>descriptor,
		 tbd2_ce=>open,
		 tbd2_data=>open,

		 wr=>data9_ce,
		 datawr=>data9,

		 rdcount =>fout_cnt --# FIFO counter

	     );


changer_freq_tx_inst: entity work.changer_freq_tx
	 port map( 
		 clk =>clkq,
		 reset => reset_with_sync,
		 ce => descriptor_ce,
		 mode =>descriptor(1),
		 mode_ack =>descriptor(2),
		 answer =>flow_ctrl_answer,
		 need_to_clkq_big=>need_to_clkq_big
	     );


--# descriptor(0) = HDLC for SPI
--# descriptor(1) = mode for clkq: '1' we need clkq>clk125 now
--# descriptor(2) = answer "mode for clkq"

from_hdlc_inst: entity work.from_hdlc
	generic map(
		DIV_POW_2=>5
	)
	port map(
		clk =>clkq,
		reset =>reset_with_sync,
		
		write_irq=>write_irq, --# провод квитирования выставления информации в SPIный буфер
		spi_clk =>spi_clk,
		spi_ce =>spi_ce,  --# '1' is valid
		spi_data =>spi_data,
		
		fifo_full=>tp(2),

		hdlc_stream_ce=>descriptor_ce,
		hdlc_stream=>descriptor(0)
		);


frame_fifo_inst : frame_fifo 
PORT MAP (
	aclr	 => reset_with_sync_with_full,
	data	 => data9,
	rdclk	 => clk125,
	rdreq	 => have_to_start2,
	wrclk	 => clkq,
	wrreq	 => data9_ce2,
	q	 => Bdata9_shift,
	rdempty	 => e_empty,  --# by clk_out
	rdusedw	 => fout_cnt,
	wrfull	 => e_full --# by clk_in
);

data9_ce2<=data9_ce and not(e_full);

have_to_start2<=have_to_start and not(e_empty);


Bdata9<=Bdata9_shift;


flow_ctrl_req2<=flow_ctrl_req or s_receive_full;
flow_ctrl_ok2<=flow_ctrl_ok or add_flow_ok;


mkstat: process (clk125) is
begin		
	if rising_edge(clk125) then
		flow_ctrl_req_byclk125_m<=flow_ctrl_req2;
		flow_ctrl_ok_byclk125_m<=flow_ctrl_ok2;
		flow_ctrl_req_byclk125_s<=flow_ctrl_req;
        flow_ctrl_ok_byclk125_s<=flow_ctrl_ok;

		flow_ctrl_req_byclk125<=flow_ctrl_req_byclk125_m;
		flow_ctrl_ok_byclk125<=flow_ctrl_ok_byclk125_m;




		if have_to_start2_1w='1' then
			test_pre_val<=Bdata9_shift(8);
		end if;
		if have_to_start2_1w='1' then
			test_val_reg<=Bdata9_shift(7 downto 0);
			if (test_val_reg+1)/=Bdata9_shift(7 downto 0) then
				test_val_err<='1';
			else
				test_val_err<='0';
			end if;
		else
			test_val_err<='0';
		end if;



	 clkq_more_than_clk125_1w<=clkq_more_than_clk125;
	 have_to_start2_1w<=have_to_start2;
	 fifo_going_full<=s_fifo_going_full;
	 if reset='1' then
		s_fifo_going_full<='0';
		reset_by_fifofull<='0';
		fifo_monitor<=STARTING;
		can_remove<='1';
		--flow_ctrl_req_reg<='0';
		--flow_ctrl_ok_reg<='0';
		fifo_cnt_out<=(others=>'0');
		fifo_cnt_in_byclkq<=(others=>'0');
		fifo_cnt_d<=(others=>'0');
		fiford<='0';
		s_fifo_going_full_state<='0';
	 else

		Bdata9_shift_8_1w<=Bdata9_shift(8);
		if Bdata9_shift(8)='0' and Bdata9_shift_8_1w='1' then 
			fifo_cnt_out<=fifo_cnt_out+1;
		end if;

		fifo_cnt_in_byclkq<=fifo_cnt_in;
		fifo_cnt_d<=fifo_cnt_in_byclkq-fifo_cnt_out;
		if unsigned(fifo_cnt_d)>0 then
			fiford<='1';
		else
			fiford<='0';
		end if;

		if unsigned(fout_cnt)>1500 then
			have_datainfifo<='1';
		else
		    have_datainfifo<='0';
		end if;
	
--		if flow_ctrl_req_byclk125='1' then
--			flow_ctrl_req_reg<='1';
--		else
--			if reset_flow_pause='1' then
--				flow_ctrl_req_reg<='0';
--			end if;				
--		end if;

--		if flow_ctrl_ok_byclk125='1' then
--			flow_ctrl_ok_reg<='1';
--		else
--			if reset_flow_ok='1' then
--				flow_ctrl_ok_reg<='0';
--			end if;
--		end if;

		timecnt<=timecnt+1;

		if timecnt=0 then
			fout_timea<=fout_cnt_w1;
			fout_timeb<=fout_timea;
		end if;
		fout_timed<=fout_timea-fout_timeb;
		if signed(fout_timed)<0 then
			fout_timed2<=0-fout_timed;
		else
			fout_timed2<=fout_timed;
		end if;

		if unsigned(fout_timed2(fout_cnt'Length-1 downto fout_cnt'Length-6))>=1 or e_full='1' then
--		if unsigned(fout_timed2(fout_cnt'Length-1 downto fout_cnt'Length-7))>=1 or e_full='1' then
			fout_timed2_val<='1';
		else
			fout_timed2_val<='0';
		end if;

        reset_by_fifofull<='0';
		if s_fifo_going_full_state='0' then
			if unsigned(fout_cnt_w1(fout_cnt'Length-1 downto fout_cnt'Length-4))>8 or fout_timed2_val='1' then
				s_fifo_going_full<='1';
				s_fifo_going_full_state<='1';
			end if;
		else
			if unsigned(fout_cnt_w1(fout_cnt'Length-1 downto fout_cnt'Length-4))<=7 and fout_timed2_val='0' then
				s_fifo_going_full<='0';
				s_fifo_going_full_state<='0';
			end if;
		end if;

	 end if;


	 Bdata9_shift_w1<=Bdata9_shift;
	 

     flow_ctrl_ok_1w<=flow_ctrl_ok;
     flow_ctrl_req_1w<=flow_ctrl_req;
	 flow_ctrl_req_a<=s_flow_ctrl_req_a;
	 flow_ctrl_ok_a<=s_flow_ctrl_ok_a;
     pause_mode_o<=pause_mode_1w;--stop_made;
     dv_in_1w<=dv_in;
	 if reset_with_sync='1' then
		 Bdata9_w1<=(others=>'0');
		 dout_cnt_forstart<=(others=>'0');
		 have_to_start<='0';
		 fout_cnt_w1<=(others=>'0');
		 have_to_start_w1<='0';
		 stm_reader<=WAITING;
		 stm_reader_havereg<='0';
		 cntflow<='1';
		 s_flow_ctrl_req_a<='0';
		 s_flow_ctrl_ok_a<='0';
		 ok_made<='0';
		 stop_made<='0';
		 pause_mode<='0';
		 dv_in_timeout<=(others=>'1');
		 dv_in_timeout_event_1w<='0';
		 dv_in_timeout_event<='0';
	 else --# reset         
		 if dv_in_1w='1' then
			dv_in_timeout<=(others=>'1');
		 else
			dv_in_timeout<=dv_in_timeout-1;
		 end if;
		 if dv_in_timeout=0 then
			dv_in_timeout_event<='1';
		 else
			dv_in_timeout_event<='0';
		 end if;
		 if WATCH_DOG=1 then
		 	dv_in_timeout_event_1w<=dv_in_timeout_event;
		 else
			dv_in_timeout_event_1w<='0';
		 end if;

		 if unsigned(pause_mode_cnt)>0 then
			pause_mode_cnt_more<='0';
		 else
			pause_mode_cnt_more<='1';
		 end if;

		 fout_cnt_w1<=fout_cnt;
		 pause_mode_1w<=pause_mode;
		 have_to_start_w1<=have_to_start;
         someflowneed<=flow_ctrl_ok_1w or flow_ctrl_req_1w;

--		 flow_ctrl_req: in std_logic; --# by clkq 
--		 flow_ctrl_ok: in std_logic; --# by clkq 


         go_flow1<=flow_ctrl_ok_reg and test_in_pause_mode;
		 go_flow2<=flow_ctrl_req_reg and not(test_in_pause_mode);
		case stm_reader is
		when WAITING=>
			tp(4)<='1';
			reset_flow_ok<='0';
			reset_flow_pause<='0';
			if (flow_a_get='0' and flow_ctrl_ok_1w='1') or dv_in_timeout_event_1w='1' then
				stop_made<='1';
				pause_mode<='0';
				test_in_pause_mode<='0';

				if USE_XOR=1 then
					Bdata9_3<='1'&(flow_ctrl_packet_ok(0) xor conv_std_logic_vector(xor_packet(0),8));
				else
					Bdata9_3<='1'&flow_ctrl_packet_ok(0);
				end if;

				flow_ctrl_mux_cnt<=conv_std_logic_vector(1,flow_ctrl_mux_cnt'Length);
				empty_space_start<='0';
                stm_reader<=FLOW_GO;
			elsif  --# flow_ctrl_ok_1w
                 (flow_ctrl_req_1w='1' and flow_a_get='0') then
					pause_mode<='1';
					stop_made<='0';
					test_in_pause_mode<='0';
					if USE_XOR=1 then
						Bdata9_3<='1'&(flow_ctrl_packet_ok(0) xor conv_std_logic_vector(xor_packet(0),8));
					else
						Bdata9_3<='1'&flow_ctrl_packet_ok(0);
					end if;
					flow_ctrl_mux_cnt<=conv_std_logic_vector(1,flow_ctrl_mux_cnt'Length);
					empty_space_start<='0';
                	stm_reader<=FLOW_GO;
				else
					if unsigned(fout_cnt_w1)>unsigned(middle_value) then
						stm_reader<=READING;
						have_to_start<='1';
					else
						have_to_start<='0';
					end if;
					Bdata9_3<=(others=>'0');
				end if;

			--end if; --# flow_ctrl_ok_1w
		when FLOW_START0=>
			tp(4)<='0';
			cntflow<=not cntflow;
			pause_mode_cnt<=(others=>'1');
			Bdata9_3<=(others=>'0');
			stm_reader<=FLOW_START;
			empty_space_start<='0';
		when FLOW_START=>
			tp(4)<='0';
				if flow_ctrl_req_reg='1' then
					pause_mode<='1';
					test_in_pause_mode<='1';
					if USE_XOR=1 then
						Bdata9_3<='1'&(flow_ctrl_packet_pause(0) xor conv_std_logic_vector(xor_packet(0),8));
					else
						Bdata9_3<='1'&flow_ctrl_packet_pause(0);
					end if;
				elsif flow_ctrl_ok_reg='1' then
					pause_mode<='0';
					test_in_pause_mode<='0';
					if USE_XOR=1 then
						Bdata9_3<='1'&(flow_ctrl_packet_ok(0) xor conv_std_logic_vector(xor_packet(0),8));
					else
						Bdata9_3<='1'&flow_ctrl_packet_ok(0);
					end if;
			    end if;
				flow_ctrl_mux_cnt<=conv_std_logic_vector(1,flow_ctrl_mux_cnt'Length);
				empty_space_start<='0';
                stm_reader<=FLOW_GO;
		when FLOW_GO=>
			tp(4)<='0';
				cntflow<=not cntflow;
				empty_space_start<='0';
				if unsigned(flow_ctrl_mux_cnt)<72 then
					if USE_XOR=1 then
						if pause_mode='1' then
							Bdata9_3<='1'&( flow_ctrl_packet_pause(conv_integer(flow_ctrl_mux_cnt))  xor conv_std_logic_vector(xor_packet(conv_integer(flow_ctrl_mux_cnt)),8) );
						else
							Bdata9_3<='1'&( flow_ctrl_packet_ok(conv_integer(flow_ctrl_mux_cnt)) xor conv_std_logic_vector(xor_packet(conv_integer(flow_ctrl_mux_cnt)),8) );
						end if;
					else
						if pause_mode='1' then
							Bdata9_3<='1'&flow_ctrl_packet_pause(conv_integer(flow_ctrl_mux_cnt));
						else
							Bdata9_3<='1'&flow_ctrl_packet_ok(conv_integer(flow_ctrl_mux_cnt));
						end if;
					end if;
					flow_ctrl_mux_cnt<=flow_ctrl_mux_cnt+1;
				else
					if pause_mode='1' then
						reset_flow_pause<='1';
					else
						reset_flow_ok<='1';
					end if;
					stm_reader<=GET_REG_ADDPAUSE1;
					empty_space_start<='1';
					Bdata9_3<=(others=>'0');
					--pause_mode<='0';
				end if;
		when READ_START=>
			tp(4)<='0';
			have_to_start<='1';
			stm_reader<=READING;
		when READING=>
			tp(4)<='0';
			s_flow_ctrl_req_a<='0';
			s_flow_ctrl_ok_a<='0';

			pause_mode_cnt<=(others=>'1');
			if Bdata9_shift(8)='0' then
					have_to_start<='0';
					stm_reader_havereg<='1';
					stm_reader<=GET_REG;
					Bdata9_3<=(others=>'0');
			else
                have_to_start<='1'; 
				stm_reader_havereg<='0';
				Bdata9_3<=Bdata9;				
			end if;
		when GET_REG_ADDPAUSE1=>
			tp(4)<='0';
			reset_flow_ok<='0';
			reset_flow_pause<='0';
			Bdata9_3<=(others=>'0');
			stm_reader<=GET_REG_ADDPAUSE1_W;--GET_REG_ADDPAUSE2;
			if pause_mode_1w='1' then
				s_flow_ctrl_req_a<='1';
				s_flow_ctrl_ok_a<='0';
			else
				s_flow_ctrl_req_a<='0';
				s_flow_ctrl_ok_a<='1';
			end if;
			tx_cnt_timeout<=(others=>'1');
			addpause_w_cnt<=(others=>'0');
		when GET_REG_ADDPAUSE1_W=>
			if unsigned(addpause_w_cnt)<9 then
				addpause_w_cnt<=addpause_w_cnt+1;
			else
				stm_reader<=GET_REG_ADDPAUSE2;
			end if;
			tp(4)<='0';
			reset_flow_ok<='0';
			reset_flow_pause<='0';
			Bdata9_3<=(others=>'0');

		when GET_REG_ADDPAUSE1_REG=>
			tp(4)<='0';
			reset_flow_ok<='0';
			reset_flow_pause<='0';
			Bdata9_3<=(others=>'0');
			stm_reader<=GET_REG_ADDPAUSE2;
			tx_cnt_timeout<=(others=>'1');

		when GET_REG_ADDPAUSE2=>
			tp(4)<='0';
			Bdata9_3<=(others=>'0');
			--if unsigned(tx_cnt_timeout)>0 then
			--	tx_cnt_timeout<=tx_cnt_timeout-1;
			--else
--			if flow_a_get='1' then
				stm_reader<=WAITING;
--			end if;
			--end if;
		when GET_REG=>
			tp(4)<='0';
			stm_reader_reg<=Bdata9_shift;
			stm_reader<=GET_REG_ADDPAUSE1_REG;
			cntflow<=not cntflow;
		when others=>
			tp(4)<='0';
			stm_reader<=WAITING;
		end case;
	 end if; --#reset

	if reset='1' then
		frame_cnt<=(others=>'0');
		reset_with_sync_by125<='1';
	else
		reset_with_sync_by125<=reset_with_sync;
		if Bdata9_w1(8)='1' and Bdata9(8)='0' and reset_with_sync_by125='0' then
			frame_cnt<=frame_cnt+1;
		end if;
	end if;

	tp(0)<=e_empty;
	tp(1)<=e_full;
	tp(3)<=test_in_pause_mode;

	end if;
end process;


mkstat2: process (clkq) is
begin		
	if rising_edge(clkq) then
		if reset='1' then
			s_ErrRS_reg02<=(others=>'0');
			s_failRS_reg03<=(others=>'0');
		else
			if start_frame_p1_rs='1' then
				s_ErrRS_reg02<=s_ErrRS_reg02+num_err_sym;
				s_failRS_reg03<=s_failRS_reg03+decfail;
			end if;

		end if;
	end if;
end process;
ErrRS_reg02<=s_ErrRS_reg02;
failRS_reg03<=s_failRS_reg03;

frames_reg01<=frame_cnt;

stob_scale_inst: entity work.stob_scale
	generic map
	(
	 newwidth=>26
	) 
	 port map(
		 reset =>reset,
	 	 clk =>clkq,
		 strob_in =>decfail,
		 strob_out =>bad_channelLED
	     );
receive_full<='0';--s_receive_full;		 
		 

end mac_frame_tx_ver2;