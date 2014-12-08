library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
library work;
use work.lan_frames_pack.all;

--# Convert back from my blocks to IP-frames
entity block2ip_frame is
	 port(
		 reset : in STD_LOGIC;
		 clk : in STD_LOGIC;

		 frame_start: in std_logic; 
		 data_ce: in std_logic; 
		 datain: in STD_LOGIC_VECTOR(7 downto 0);
		 rd_out: out std_logic;
		
		 tbd1_ce: out std_logic;
	     tbd1_data: out std_logic_vector(7 downto 0);
		 tbd2_ce: out std_logic;
		 tbd2_data: out std_logic_vector(7 downto 0);

		 wr: out std_logic;
		 datawr: out std_logic_vector(8 downto 0);

		 rdcount : in std_logic_vector(13 downto 0) --# FIFO counter

	     );
end block2ip_frame;


architecture block2ip_frame of block2ip_frame is

constant EMPTY_LEN:natural:=FRAME_LEN-DATA_OFFSET;

type Tstm is (WAITING0,WAITING,GET_TBD1,GET_TBD2,RECEIVE_BLOCKS,EMPTY_TEST,DV_FORMING,WRITE_EMPTY);
signal stm:Tstm:=WAITING;

signal get_subframe_start:std_logic;
type Tblocks is array(0 to BLOCKNUM-1) of Tblock_descriptor;
signal blocks:Tblocks;
signal blocks_cnt:std_logic_vector(log2roundup(BLOCKNUM)-1 downto 0);

signal s_wr,have_dv_after: std_logic;
signal s_datawr: std_logic_vector(8 downto 0);

signal big_cnt: std_logic_vector(log2roundup(FRAME_LEN-DATA_OFFSET+1)-1 downto 0);
signal datain_1w: STD_LOGIC_VECTOR(7 downto 0);
signal empty_cnt:std_logic_vector(log2roundup(EMPTY_LEN)-1 downto 0);
signal mark_point:std_logic;
signal frame_cnt:STD_LOGIC_VECTOR(2 downto 0);
signal framelen_cnt:std_logic_vector(log2roundup(FRAME_LEN-DATA_OFFSET)-1 downto 0);
signal s_rd_out: std_logic;

constant half_value:std_logic_vector(rdcount'Length-1 downto 0):='1'&EXT("0",rdcount'Length-1);

signal test_val,test_val_reg:std_logic_vector(7 downto 0):=(others=>'0');
signal test_val_err,test_pre_val:std_logic;

signal less_half:std_logic;

begin

wr<=s_wr;
datawr<=s_datawr;

rd_out<=s_rd_out;
 	
process (clk) is
begin		
	if rising_edge(clk) then
		if unsigned(rdcount)<unsigned(half_value) then
			less_half<='1';
		else
			less_half<='0';
		end if;

		if s_wr='1' then
			test_pre_val<=s_datawr(8);
		end if;
		if s_wr='1' and not(test_pre_val='0' and s_datawr(8)='1') then
			test_val_reg<=s_datawr(7 downto 0);
			if (test_val_reg+1)/=s_datawr(7 downto 0) then
				test_val_err<='1';
			else
				test_val_err<='0';
			end if;
		else
			test_val_err<='0';
		end if;

		datain_1w<=datain;

		if reset='1' then
			frame_cnt<=(others=>'0');
		else
			if frame_start='1' then
				frame_cnt<=frame_cnt+1;
			end if;
		end if;

		if reset='1' then --reset='1' or
			--if frame_start='1' then
			--		frame_cnt<=(others=>'0');
			--		if datain=b8array(0) then
			--			get_subframe_start<='1';
			--			stm<=GET_TBD1;
			--		else
			--			get_subframe_start<='0';
			--		end if;
			--else
			--	stm<=WAITING;			
			--end if;
			stm<=WAITING;
			s_rd_out<='0';
		else  --# reset=frame_start
			if frame_start='1' then
				frame_cnt<=frame_cnt+1;
			end if;
--			if data_ce='1' then
			case stm is
			when WAITING0=>
				if frame_start='1' then
					frame_cnt<=(others=>'0');
					if datain=b8array(0) then
						get_subframe_start<='1';
						stm<=GET_TBD1;
					else
						get_subframe_start<='0';
					end if;
				end if;
			when WAITING=>
				if frame_start='1' then
					if datain=b8array(conv_integer(frame_cnt)) then
						get_subframe_start<='1';
					else
						get_subframe_start<='0';
					end if;					
					stm<=GET_TBD1;
					s_rd_out<='1';
				else
					s_rd_out<='0';
					get_subframe_start<='0';
				end if;
				tbd1_ce<='0';
				blocks_cnt<=(others=>'0');
				s_wr<='0';
				big_cnt<=(others=>'0');
			when GET_TBD1=>
				get_subframe_start<='0';
				tbd1_ce<='1';
				tbd1_data<=datain;
				have_dv_after<=datain(7);
				stm<=GET_TBD2;
			when GET_TBD2=>
				tbd1_ce<='0';
				tbd2_ce<='1';
				tbd2_data<=datain;
				stm<=RECEIVE_BLOCKS;
			when RECEIVE_BLOCKS=>
				tbd2_ce<='0';
				blocks(conv_integer(blocks_cnt)).dv_value<=datain(7);
				blocks(conv_integer(blocks_cnt)).block_len<=datain(6 downto 0);
				big_cnt<=big_cnt+EXT(datain(6 downto 0),big_cnt'Length);
				if unsigned(blocks_cnt)<BLOCKNUM-1 then
					blocks_cnt<=blocks_cnt+1;
				else
					blocks_cnt<=(others=>'0');
					if unsigned(big_cnt)=0 then
						stm<=EMPTY_TEST;
					else
						stm<=DV_FORMING;
					end if;
				end if;
				framelen_cnt<=(others=>'0');
			when EMPTY_TEST=>
--				if unsigned(big_cnt)>0 then
--					stm<=DV_FORMING;
--				else
					--# проверяем на заполнение FIFO и вгоняем пустой блок
					--if unsigned(rdcount)<unsigned(half_value) then
					if less_half='1' then
						if have_dv_after='0' then
							stm<=WRITE_EMPTY;
						else
							stm<=WAITING;--DV_FORMING;
						end if;
					else
						stm<=WAITING;--DV_FORMING;
					end if;
--				end if;
				empty_cnt<=(others=>'0');
			when DV_FORMING=>

				if unsigned(framelen_cnt)<FRAME_LEN-DATA_OFFSET then
					framelen_cnt<=framelen_cnt+1;
					if unsigned(blocks(conv_integer(blocks_cnt)).block_len)>1 then
						if less_half='0' and blocks(conv_integer(blocks_cnt)).dv_value='0' then
							s_wr<='0';
						else
							s_wr<='1';
						end if;
						s_datawr(7 downto 0)<=datain;
						blocks(conv_integer(blocks_cnt)).block_len<=blocks(conv_integer(blocks_cnt)).block_len-1;
						s_datawr(8)<=blocks(conv_integer(blocks_cnt)).dv_value;
					else					
						if unsigned(blocks_cnt)<BLOCKNUM-1 then
							blocks_cnt<=blocks_cnt+1;
							--if less_half='0' and blocks(conv_integer(blocks_cnt)).dv_value='0' then
							--	s_wr<='0';
							--else
								s_wr<='1';
							--end if;
							s_datawr(7 downto 0)<=datain;
							s_datawr(8)<=blocks(conv_integer(blocks_cnt)).dv_value;
						else
							s_wr<='0';
							stm<=WAITING;
						end if;
					end if;
				else  --# framelen_cnt
						s_wr<='0';
						stm<=WAITING;
				end if;
			when WRITE_EMPTY=>
				if unsigned(empty_cnt)<EMPTY_LEN-1 then
					empty_cnt<=empty_cnt+1;
				else
					stm<=WAITING;
				end if;
				s_datawr<=(others=>'0');
				s_wr<='0';
			when others=>
			end case;
--			else
--				s_wr<='0';
--			end if; --# data_ce
		end if; --#reset
	end if;
end process;	

mark_point<='1' when s_datawr='1'&x"E1" and s_wr='1' else '0';

end block2ip_frame;
