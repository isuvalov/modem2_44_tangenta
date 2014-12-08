library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
library work;
use work.lan_frames_pack.all;

-- tp0 - MAC RX FIFO empty
-- tp1 - MAX RX FIFO full

entity mac_frame_rx_ver2 is
	generic 
	(
	 CLKQ_SLOW:integer:=1
	);
	 port(
		 reset : in std_logic;
		 clk125 : in std_logic;
		 clkq : in std_logic;
		 Rx_er: in std_logic;
		 Rx_dv: in std_logic;
		 Rxd: in std_logic_vector(7 downto 0);
		 Crs: in std_logic;
		 Col: in std_logic;
		 tp : out std_logic_vector(7 downto 0);
		 
		 reg01: out std_logic_vector(63 downto 0); --# ?????????? ?????????? ???????? ??????? 

		 read_irq: in std_logic; --# look on rising edge
         spi_clk: out std_logic;
		 spi_ce: out std_logic; --# '1' valid
		 spi_data: in std_logic;  --# ????????? ?????? ?? falling edge

		 want_clkq_more: in std_logic;  --#??????????? ???????????? ?????? clkq(????????? ???????? ??????? ??????)

		 fifo_going_full_i: in std_logic;
		 receive_full_i: in std_logic;

		 flow_ctrl_req: out std_logic;  --# Request pause
		 flow_ctrl_ok: out std_logic;   --# Request quick trafic

		 flow_ctrl_req_a: in std_logic;  --# Request pause
		 flow_ctrl_ok_a: in std_logic;   --# Request quick trafic
         pause_mode_i: in std_logic;
		 flow_a_get: out std_logic;

		 flow_ctrl_answer: in std_logic; --# by clkq 

		 data_out: out std_logic_vector(7 downto 0);
		 ce_out: out std_logic
	     );
end mac_frame_rx_ver2;


architecture mac_frame_rx_ver2 of mac_frame_rx_ver2 is
constant SCRAMBLER_OFF:integer:=0;

constant USE_XOR:integer:=1;

signal USE_XORstd:std_logic;


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


signal ttt:integer:=0;
--# rx engine
signal fcnt_1w,fcnt,fcnt_byclk125:std_logic_vector(13 downto 0);
signal Rx_mac_ra,Rx_mac_rd:std_logic;
signal Rx_mac_eop,Rx_mac_pa,Rx_mac_sop: std_logic;
signal Rx_mac_data : std_logic_vector(31 downto 0);
signal Rx_mac_BE : std_logic_vector(1 downto 0);

signal data_byte_ce:std_logic;
signal data_byte:std_logic_vector(7 downto 0);

signal data_eq,data_eq_w1:std_logic_vector(8 downto 0):=(others=>'0');
signal rd_ack:std_logic;
signal sGtx_clk:std_logic;
signal descriptor_data:std_logic_vector(7 downto 0);

signal frame_sync_n: std_logic;
signal frame_sync_p1: std_logic;
signal frame_sync: std_logic;
signal s_ce_out_w2,s_ce_out_w1,bit8ce : std_logic;		 
signal s_data_out_w1,s_data_out_scr,data8bit : std_logic_vector(7 downto 0);
signal my_ceout_pre,my_ceout,rx_dv_w1,frame_sync_n_w2,frame_sync_n_w1,frame_sync_n_w2_2,s_ce_out :std_logic;
signal my_dataout_pre,my_dataout,s_data_out:std_logic_vector(7 downto 0);
signal my_dataout2:std_logic_vector(8 downto 0);

signal frame_cnt:std_logic_vector(63 downto 0);
signal rd_ack2,empty,frame_sync_w1,frame_sync_w2,frame_sync_w3,reset_wait,reset_wait_byclkq:std_logic;
signal data_come_cnt:std_logic_vector(15 downto 0);
signal wrfifo,full,n_frame_sync_w3,n_frame_sync_w2,fifo_have_less,descriptor_ack,hdlc_stream:std_logic;
signal CodedByte:std_logic_vector(7 downto 0);
signal reset_w1,reset_delayed,n_reset_w1,n_reset_delayed,ReadyToIn_w1,ReadyToIn,start_coder:std_logic;
signal fifo_have_more,fifo_have_notmore:std_logic;
signal flow_ctrl_cnt:std_logic_vector(6 downto 0);
type Tflow_ctrl_stm is (WAITING,W_ACK,TIMEOUT,WAITING_SMALL,WAITING_BIG);
signal flow_ctrl_stm:Tflow_ctrl_stm;

signal flow_ctrl_req_sent:std_logic;
signal dv_archive,reset_scr:std_logic:='1';
signal dataout_archive:std_logic_vector(7 downto 0);

signal scr_mux,dv_archive_1w,dv_data_eq_1w,fiford:std_logic:='0';
signal fifo_cnt_d,fifo_cnt_out,fifo_cnt_in,fifo_cnt_in_byclkq,fifo_cnt_in_byclkq2:std_logic_vector(7 downto 0);
signal scr_mux_cnt:std_logic_vector(7 downto 0);

signal rx_dv2,insert_mix:std_logic;
signal Rxd2:std_logic_vector(7 downto 0);

signal full_f:std_logic:='0';
signal pre_full,reset_fifo,reset_fifo_byq,want_clkq_more_byclkq,answer_to_rx:std_logic;
signal reset_fifo_cnt:std_logic_vector(3 downto 0):=(others=>'0');

signal frame_cnt_in,frame_cnt_out,frame_cnt_delta,frame_cnt_in_byclkq:std_logic_vector(fcnt'Length-1-2 downto 0):=(others=>'0');

signal fout_timed2,fout_timed,fout_timea,fout_timeb:std_logic_vector(fcnt'Length-1 downto 0):=(others=>'0');
signal fout_timed2_val:std_logic;


signal flow_ctrl_req_a_1w, flow_ctrl_ok_a_1w:std_logic;
signal w_pause, s_flow_ctrl_req, s_flow_ctrl_ok:std_logic:='0';

signal pause_mode_i_1w,pause_mode_i_2w,can_be_real_full_1w,can_be_real_full:std_logic;

signal timecnt:std_logic_vector(4 downto 0):=(others=>'0');
signal flow_ctrl_req_a_cnt,flow_ctrl_ok_a_cnt:std_logic_vector(3 downto 0):=(others=>'0');
signal flow_ctrl_req_a_wide,flow_ctrl_ok_a_wide:std_logic;
signal flow_ctrl_req_a_byclkq,flow_ctrl_ok_a_byclkq:std_logic;

signal full_w:std_logic_vector(10 downto 0):=(others=>'0');
type Treset_states is (WAITING,RESETING,TIMEOUT);
signal reset_states:Treset_states;

signal s_flow_a_get:std_logic;


begin
USE_XORstd<='1' when USE_XOR=1 else '0';

frame_filter_inst: entity work.frame_filter
	 port map(
	 	 clk =>clk125,
	 	 dv_i => rx_dv,
		 datain =>Rxd,
		 dv_o =>rx_dv2,
		 dataout =>Rxd2
	     );

MAC_inst: entity work.simple_mac_rx
	 port map(
		 clk =>clk125,
		 useit=>USE_XORstd,
		 frame_ce =>my_ceout_pre,
		 data_out =>my_dataout_pre,
		 rx_dv =>rx_dv2,
		 rx_er =>rx_er,
		 rxd =>Rxd2
	     ); 

--insert_frames_inst: entity work.insert_frames
--	port map(
--	 clk=>clk125,
--	 reset=>reset,
--  
--	 readed_dv=>data_eq(8),
--	 fifo_read_cnt=>fcnt_byclk125,
--     receive_full_i=>insert_mix,--s_flow_ctrl_req,--receive_full_i,
--
--	 dv_i=>my_ceout_pre,
--	 data_i=>my_dataout_pre,
--
--	 dv_o=>my_ceout,
--	 data_o=>my_dataout
--	);

my_dataout<=my_dataout_pre;
my_ceout<=my_ceout_pre;		

			  

mkstat: process (clk125) is
begin		
	if rising_edge(clk125) then

	 insert_mix<=s_flow_ctrl_req or receive_full_i or fifo_have_more;

     fcnt_byclk125<=fcnt;
	 if reset='1' then
		 frame_cnt<=(others=>'1');
		 rx_dv_w1<=rx_dv;
		 reset_wait<='1';
		 data_come_cnt<=(others=>'0');
		 fifo_cnt_in<=(others=>'0');
		 dv_archive_1w<='0';
--		 reset_fifo<='1';
	 else --# reset

		 if wrfifo='1' then
			if dv_archive_1w='1' and dv_archive='0' then
				frame_cnt_in<=frame_cnt_in+1;
			end if;
		 end if;



		 if wrfifo='1' then
		 	dv_archive_1w<=dv_archive;
		 	if dv_archive='0' and dv_archive_1w='1' then
		 		fifo_cnt_in<=fifo_cnt_in+1;
		 	end if;
		 end if;

		 if rx_dv='0' and rx_dv_w1='1' then
			 frame_cnt<=frame_cnt+1;
		 end if;
		 if unsigned(data_come_cnt)<1024 then
		 	reset_wait<='1';
			data_come_cnt<=data_come_cnt+1;
		 else
		 	reset_wait<='0';
		 end if;
	 end if; --#reset
	end if;
end process;
reg01<=frame_cnt;


frame_fifo_inst : frame_fifo 
PORT MAP (
  	    aclr=>reset_fifo,
		data	 => my_dataout2,
		rdclk	 => clkq,
		rdreq	 => rd_ack2,
		wrclk	 => clk125,
		wrreq	 => wrfifo,
		q	 => data_eq,
		rdempty	 => empty,  --# by clk_out
		rdusedw	 => fcnt,
		wrfull	 => full --# by clk_in
	);
tp(1)<=full;
tp(0)<=empty;

	ce2wr_filter_inst: entity work.ce2wr_filter
	 port map(
		 clk =>clk125,
		 clk_ce=>'1',
		 fifo_read_cnt=>fcnt_byclk125,
		 fifo_going_full_i=>fifo_going_full_i,
		 fifofull =>full_f,
		 datain=>my_dataout,
		 ce =>my_ceout,
		 wr =>wrfifo,
		 dv_out=>dv_archive,
		 dataout=>dataout_archive
	     );
full_f<=full and can_be_real_full_1w;
rd_ack2<=rd_ack and not(empty); 
my_dataout2<=dv_archive&dataout_archive;


to_hdlc_inst: entity work.to_hdlc
	generic map(
		DIV_POW_2=>5
	)
	port map(
		clk =>clkq,
		reset =>reset,
		
		read_irq=>read_irq, --# ?????? ??????? ?? ?????? spi ?????
		spi_clk=>spi_clk,
		spi_ce=>spi_ce,  --# '1' is valid
		spi_data=>spi_data,
		
		fifo_full=>tp(2),          

		hdlc_stream_rd=>descriptor_ack,
		hdlc_stream=>hdlc_stream
		);


changer_freq_rx_inst: entity work.changer_freq_rx
	 port map(
		 clk =>clkq,
		 reset=>reset,
		 answer =>flow_ctrl_answer,
		 answer_to_rx=>answer_to_rx
	     );


descriptor_data<="0000"&fifo_going_full_i&answer_to_rx&want_clkq_more_byclkq&hdlc_stream;


read_frames4fifo_inst: entity work.read_frames4fifo
	 port map(
		 reset =>reset,--reset_fifo_byq,
		 clkwr =>clkq,
		 datain =>data_eq,
		 rd =>rd_ack,
		 rdcount =>fcnt,
		 fifo_empty =>empty,

		 receive_full_i=>receive_full_i,
		 tbd1_ce =>descriptor_ack, --# by clkrd, befor data transfer - can be read strobe
		 tbd2_ce =>open, --# by clkrd
		 tbd1_data =>descriptor_data,
		 tbd2_data =>(others=>'0'),
		 clkrd =>clkq,
		 ce =>bit8ce, --# to upper RS coder block.
		 ce_start_p1 =>frame_sync_p1,
		 ce_start =>frame_sync, --# all of gen like that block have size:
		 ce_stop =>open,  --# (BFRAME_LEN,FRAME_LEN) = (204,188)
		 dataout =>data8bit
	     );
frame_sync_n<=not frame_sync;
flow_ctrl_req<=s_flow_ctrl_req;
flow_ctrl_ok<=s_flow_ctrl_ok;

	process (clkq) is
	begin		
		if rising_edge(clkq) then

		timecnt<=timecnt+1;

		if timecnt=0 then
			fout_timea<=fcnt_1w;
			fout_timeb<=fout_timea;
		end if;
		fout_timed<=fout_timea-fout_timeb;
		if signed(fout_timed)<0 then
			fout_timed2<=0-fout_timed;
		else
			fout_timed2<=fout_timed;
		end if;

		if unsigned(fout_timed2(fcnt'Length-1 downto fcnt'Length-4))>=1 then
			fout_timed2_val<='1';
		else
			fout_timed2_val<='0';
		end if;


            frame_cnt_in_byclkq<=frame_cnt_in;
			frame_cnt_delta<=frame_cnt_in_byclkq-frame_cnt_out;


			reset_fifo_byq<=reset_fifo;
			want_clkq_more_byclkq<=want_clkq_more;
			fcnt_1w<=fcnt;
			can_be_real_full_1w<=can_be_real_full;
			if unsigned(fcnt_1w)>0 then
				can_be_real_full<='1';
			end if;
			if unsigned(fcnt_1w)>16374 then
				pre_full<='1';
			else
				pre_full<='0';
			end if;
--			pre_full<=full;
--type Treset_states is (WAITING,RESETING,TIMEOUT);
--signal reset_states:Treset_states;

		 	if reset='1' then
				reset_fifo<='1';
				reset_fifo_cnt<=(others=>'0');
				full_w<=(others=>'0');
				reset_states<=WAITING;
		 	else
				case reset_states is
				when WAITING=>
					reset_fifo<='0';
					reset_fifo_cnt<=(others=>'1');
					if pre_full='1' or full_w(10)='1' then
						reset_states<=RESETING;
					end if;
				
				when RESETING=>
					reset_fifo<='1';
					if unsigned(reset_fifo_cnt)>0 then
						reset_fifo_cnt<=reset_fifo_cnt-1;
					else
						reset_states<=TIMEOUT;
						reset_fifo_cnt<=(others=>'1');
					end if;
				when TIMEOUT=>
					reset_fifo<='0';
					if unsigned(reset_fifo_cnt)>0 then
						reset_fifo_cnt<=reset_fifo_cnt-1;
					else
						reset_states<=WAITING;
						reset_fifo_cnt<=(others=>'1');
					end if;
				when others=>
				end case;

				full_w<=full_w(full_w'Length-2 downto 0)&full;
--				if pre_full='1' then
--					reset_fifo<='1';
--					reset_fifo_cnt<=(others=>'1');
--			 	else
--					if unsigned(reset_fifo_cnt)>0 then
--						reset_fifo_cnt<=reset_fifo_cnt-1;
--		 				reset_fifo<='1';
--					else
--						reset_fifo<='0';
--					end if;
--		 		end if;
		 	end if;

			if frame_sync='1' then
				ttt<=0;
			else
				ttt<=ttt+1;
			end if;
			pause_mode_i_1w<=pause_mode_i;
			pause_mode_i_2w<=pause_mode_i_1w;
			flow_ctrl_req_a_1w<=flow_ctrl_req_a;
			flow_ctrl_ok_a_1w<=flow_ctrl_ok_a;
            flow_a_get<=s_flow_a_get;

			if reset='1' then
				reset_wait_byclkq<='1';
				fifo_have_less<='0';
				fifo_have_more<='0';
				s_flow_ctrl_req<='0';
				s_flow_ctrl_ok<='0';
				flow_ctrl_stm<=WAITING;
				flow_ctrl_req_sent<='1';
				fifo_cnt_out<=(others=>'0');
				fiford<='0';
				dv_data_eq_1w<='0';
				w_pause<='0';
				flow_a_get<=s_flow_a_get;
				s_flow_a_get<='1';
			else
				if rd_ack2='1' then
					if dv_data_eq_1w='1' and data_eq(8)='0' then
						frame_cnt_out<=frame_cnt_out+1;
					end if;
				end if;


				dv_data_eq_1w<=data_eq(8);
				fifo_cnt_in_byclkq<=fifo_cnt_in;
				fifo_cnt_in_byclkq2<=fifo_cnt_in_byclkq;

                fifo_cnt_d<=fifo_cnt_in_byclkq2-fifo_cnt_out;
				if unsigned(fifo_cnt_d)>0 then
					fiford<='1';
				else
					fiford<='0';
				end if;


				reset_wait_byclkq<=reset_wait;
				if unsigned(fcnt)<1000  then
					fifo_have_less<='1';
				else
					fifo_have_less<='0';
				end if;
				
				if unsigned(fcnt(fcnt'Length-1 downto fcnt'Length-4)) > 10 then
					fifo_have_more<='1';
				else
					fifo_have_more<='0';
				end if;

				if unsigned(fcnt(fcnt'Length-1 downto fcnt'Length-4)) <= 8 then
					fifo_have_notmore<='1';
				else
					fifo_have_notmore<='0';
				end if;



--flow_ctrl_req_a_1w, flow_ctrl_ok_a_1w

				case flow_ctrl_stm is
				when WAITING =>
					if (fifo_have_more='1' or fout_timed2_val='1') and pause_mode_i_1w='0' then --w_pause='0' then
--					if (fifo_have_more='1') and pause_mode_i_1w='0' then --w_pause='0' then
							s_flow_ctrl_req<='1';
							flow_ctrl_req_sent<='1';
							flow_ctrl_stm<=W_ACK;
							s_flow_ctrl_ok<='0';
							s_flow_a_get<='0';
					else
						s_flow_ctrl_req<='0';
						if (fifo_have_notmore='1') and pause_mode_i_1w='1' then --w_pause='1' then --flow_ctrl_req_sent='1' then
							s_flow_ctrl_ok<='1';
							flow_ctrl_req_sent<='0';
							flow_ctrl_stm<=W_ACK;
							s_flow_a_get<='0';
						else
							s_flow_ctrl_ok<='0';
							s_flow_a_get<='1';
						end if;						
					end if;
					flow_ctrl_cnt<=(others=>'1');
					
				when W_ACK=>					  
						if flow_ctrl_ok_a_1w='1' then
							flow_ctrl_stm<=TIMEOUT;
							s_flow_a_get<='1';
							w_pause<='0';
							s_flow_a_get<='0';
						elsif flow_ctrl_req_a_1w='1' then						
							w_pause<='1';
							flow_ctrl_stm<=TIMEOUT;
							s_flow_a_get<='1';
						else
							s_flow_a_get<='0';
						end if;
				when TIMEOUT=>
					s_flow_a_get<='1';
					if pause_mode_i_1w='0' and w_pause='1' then
						flow_ctrl_stm<=WAITING;
					elsif pause_mode_i_1w='1' and w_pause='0' then
						flow_ctrl_stm<=WAITING;
					else
						if unsigned(flow_ctrl_cnt)>0 then
							flow_ctrl_cnt<=flow_ctrl_cnt-1;
						else
							flow_ctrl_stm<=WAITING;
						end if;
					end if;
					s_flow_ctrl_req<='0';
					s_flow_ctrl_ok<='0';
				 when WAITING_SMALL=>
					if fifo_have_notmore='1' then
					--if unsigned(fcnt)<=100 and fout_timed2_val='0' then
						flow_ctrl_stm<=WAITING;
					end if;
				 when WAITING_BIG=>
					if fifo_have_more='1' then --or fout_timed2_val='1' then
						flow_ctrl_stm<=WAITING;
					end if;
					
				when others=>
				end case;

			end if;
		end if;
	end process;

	process (clkq) is
	begin		
		if rising_edge(clkq) then
		 data_eq_w1<=data_eq;
		 n_frame_sync_w2<=not frame_sync_w3;

		 if reset='1' then
			frame_sync_w1<='0';
			frame_sync_w2<='0';
			frame_sync_n_w1<='0';
			reset_w1<='1';
		 else
			if frame_sync_n_w1='0' then
				scr_mux_cnt<=(others=>'0');
			else			
				scr_mux_cnt<=scr_mux_cnt+1;
			end if;
			if unsigned(scr_mux_cnt)<FRAME_LEN-1 then
				scr_mux<='1';
			else
				scr_mux<='0';
			end if;

			frame_sync_n_w1<=frame_sync_n;
			frame_sync_n_w2<=frame_sync_n_w1;
         	frame_sync_w1<=frame_sync;
			frame_sync_w2<=frame_sync_w1;
			frame_sync_w3<=frame_sync_w2;
			reset_w1<=reset;

		 end if;
			

		if reset='1' then
			start_coder<='0';
			ReadyToIn_w1<='0';
			s_ce_out<='0';
		else
			ReadyToIn_w1<=ReadyToIn;
			if ReadyToIn='0' and ReadyToIn_w1='1' then
				start_coder<='1';
			end if;

		 	s_data_out<=data8bit;
		 	s_ce_out<=bit8ce;-- and start_coder;

			s_data_out_w1<=s_data_out;
			s_ce_out_w1<=s_ce_out;
			s_ce_out_w2<=s_ce_out_w1;

		end if;

		if reset='1' then
			reset_scr<='1';
		else
			if frame_sync_n_w1='0' and s_data_out=x"B8" then
				reset_scr<='0';
			end if;
		end if;

		end if;
	end process;

n_reset_w1<=not reset_w1;

codedd2: entity work.RScoder_ver2
	generic map(R =>16, --???-?? ??????????? ????	   
			AmountByte =>187 -- ???-?? ???? ?? ?????
			)
	 port map(
		 reset=>reset,
		 clk =>clkq,
		 CE =>s_ce_out_w2,
		 ByteIn =>s_data_out_scr,
		 StartOfCodePocket =>open,
		 EndOfCodePocket =>open,	  
		 PrevEndOfCodePocket =>open,
		 EndAndStartOfCodePocket =>open,

		 Ready =>open,--  --?????????? ????? ?????????????? ????? ??????
		 CanGetData =>open,	--?????????? ????? ????? ???? ??????????? ???? ??????
		 ByteOut =>CodedByte --open
	     );


data_out<=CodedByte;


scr_inst: entity work.self_scrambler
  generic map(
	SWITCH_OFF=>SCRAMBLER_OFF
  )
  port map( 
	clk =>clkq,
	reset =>reset_scr,
	mux_ce =>scr_mux,
	data_in =>s_data_out_w1,
    data_out =>s_data_out_scr
  );



ce_out<=bit8ce;


process(clkq) is
begin
	if rising_edge(clkq) then
		flow_ctrl_req_a_byclkq<=flow_ctrl_req_a_wide;
		flow_ctrl_ok_a_byclkq<=flow_ctrl_ok_a_wide;
	end if;
end process;


process(clk125) is
begin
	if rising_edge(clk125) then
		if flow_ctrl_req_a='1' then
			flow_ctrl_req_a_cnt<=(others=>'1');
			flow_ctrl_req_a_wide<='1';
		else
			if unsigned(flow_ctrl_req_a_cnt)>0 then
				flow_ctrl_req_a_cnt<=flow_ctrl_req_a_cnt-1;
				flow_ctrl_req_a_wide<='1';
			else
				flow_ctrl_req_a_wide<='0';
			end if;
		end if;

		if flow_ctrl_ok_a='1' then
			flow_ctrl_ok_a_cnt<=(others=>'1');
			flow_ctrl_ok_a_wide<='1';
		else
			if unsigned(flow_ctrl_ok_a_cnt)>0 then
				flow_ctrl_ok_a_cnt<=flow_ctrl_ok_a_cnt-1;
				flow_ctrl_ok_a_wide<='1';
			else
				flow_ctrl_ok_a_wide<='0';
			end if;
		end if;

	end if;
end process;
		 
end mac_frame_rx_ver2;