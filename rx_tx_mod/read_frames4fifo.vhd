library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
library work;
use work.lan_frames_pack.all;

--# [sync][tbd1][tbd2][2 bytes '1'][2 bytes '0']|[181 bytes]
--# [sync][tbd1][tbd2][6 blocks with 1bit+7bit]|[179 bytes]
--# 1bit - show dv
--# 7bit show len of block

--# |-------_-------_-----|
--#    64   1   64  1  51

--# Read frames from fifo
entity read_frames4fifo is
	 port(
		 reset : in std_logic;
		 clkwr : in std_logic;
		 datain: in std_logic_vector(8 downto 0);
		 rd : out std_logic;
		 rdcount : in std_logic_vector(13 downto 0);
		 fifo_empty: in std_logic;

		 receive_full_i: in std_logic;

		 tbd1_ce : out std_logic; --# by clkrd, befor data transfer - can be read strobe
		 tbd2_ce : out std_logic; --# by clkrd
		 tbd1_data : in std_logic_vector(7 downto 0);
		 tbd2_data : in std_logic_vector(7 downto 0);
		 clkrd : in std_logic;
		 ce : out std_logic; --# to upper RS coder block.
		 ce_start_p1 : out std_logic;
		 ce_start : out std_logic; --# all of gen like that block have size:
		 ce_stop : out std_logic;  --# (BFRAME_LEN,FRAME_LEN) = (204,188)
		 dataout : out std_logic_vector(7 downto 0)
	     );
end read_frames4fifo;


architecture read_frames4fifo of read_frames4fifo is

constant SIMULATION:integer:=1;
--component calclens_framer is --use_gen_framer is
component use_gen_framer is -- is
port(
	clk: in std_logic;
	start: in std_logic;
	dv: in std_logic;
	ce: in std_logic;
	havereg: in std_logic;
	out_ce: out std_logic;
	dv_vals: out std_logic_vector(5 downto 0);
	len1: out std_logic_vector(6 downto 0);
	len2: out std_logic_vector(6 downto 0);
	len3: out std_logic_vector(6 downto 0);
	len4: out std_logic_vector(6 downto 0);
	len5: out std_logic_vector(6 downto 0);
	len6: out std_logic_vector(6 downto 0);
	state_monitor: out std_logic_vector(7 downto 0);
	blk_num_monitor: out std_logic_vector(7 downto 0)
 
);
end component;

constant PAUSE_LEN:natural:=50;

type Tstm is (PRE_RD,WAITING,GET_REG,WRITE_BLOCKS,WRITE_AFTER,CONVEER_START1,CONVEER_START2,DETECTING_PRE,DETECTING,
WRITE_ZEROBLOCKS,FRAME_FIN,WAITING_PRE);
signal stm:Tstm;

type Tstmrd is (SEE_AND_MK_PAUSE,MAKING_EMPTY1,MAKING_EMPTY1_D1,MAKING_ZEROHEAD,MAKING_EMPTY1_D2,
			   READ_MEM1,READ_MEM1_D1,READ_MEM1_D2,MAKING_EMPTY2,READ_MEM2,LAST_BYTE);
signal stmrd:Tstmrd;

signal s_ce_start : std_logic;
signal ttt:integer:=0;

constant middle_value:STD_LOGIC_VECTOR (rdcount'Length-1 DOWNTO 0):='1'&EXT("0",rdcount'Length-1);
constant small_value:STD_LOGIC_VECTOR (rdcount'Length-1 DOWNTO 0):="01"&EXT("0",rdcount'Length-2);

signal s_dataout,datawr,datard1,datard2:std_logic_vector(7 downto 0);
signal s_rd_w1,s_rd,local_wr:std_logic:='0';
signal datain_reg: STD_LOGIC_VECTOR(8 downto 0);
signal have_reg:std_logic;

signal input_cnt:std_logic_vector(log2roundup(FRAME_LEN-DATA_OFFSET+1)-1 downto 0);

type Tmem is array(0 to FRAME_LEN-1) of std_logic_vector(7 downto 0);
signal mem1,mem2:Tmem;
signal have_free_mem:std_logic;
signal mem1_fin,mem2_fin:std_logic; --# флаги указывающие какие блоки пам€ти заполнены
									--# и какие соответственно можно считывать. ѕри этом надо смотерть на mem_num
signal mem1_fin_byclkrd,mem2_fin_byclkrd,mem1_fin_byclkrd_1w,mem2_fin_byclkrd_1w:std_logic;
signal mem_num,mem_num_byclkrd,mem_num_byclkrd_1w:std_logic; --# указывает номер текущего записываемого буфера
signal mem1_wr,mem2_wr,needread_mem:std_logic;
signal rd_ptr,wr_ptr:std_logic_vector(log2roundup(FRAME_LEN)-1 downto 0);

type Tblocks is array(0 to BLOCKNUM-1) of Tblock_descriptor;
signal blocks,blocks_test,blocks_test2:Tblocks;
signal blocks_cnt,blocks_cnt_have,zerohead_cnt:std_logic_vector(log2roundup(BLOCKNUM)-1 downto 0);
signal cur_dv:std_logic;
signal cur_len:std_logic_vector(blocks(0).block_len'Length-1 downto 0);
signal pause_cnt:std_logic_vector(log2roundup(BFRAME_LEN-FRAME_LEN)-1 downto 0);
signal datas_cnt:std_logic_vector(log2roundup(FRAME_LEN)-1 downto 0);

signal sync_cnt:std_logic_vector(2 downto 0):=(others=>'0');
signal s_ce,memory_have_read_stb_byclkwr,memory_have_1w:std_logic;
signal memory_have_read_stb,memory_have_read,memory_have_read_byclkwr,memory_have_read_byclkwr_1w:std_logic;
signal mem_have_rd_cnt:std_logic_vector(3 downto 0):=(others=>'0');

signal read_memstart,read_memstart_byclkwr:std_logic;
signal mem_num_rd,mem_num_rd_byclkwr:std_logic; --# дл€ запоминани€ номера выводимого блока
signal mem1_fin_flag,mem2_fin_flag:std_logic; --# флаги указывающие наполненность блоков, которые обьедин€ют
											  --# процессы в разных клоковых доменах
signal mem1_fin_flag_byclkrd,mem2_fin_flag_byclkrd:std_logic;
signal dv_down,dv_state,stm_run:std_logic;

signal start_st,blk_fin,mark_point,very_need,cant_cut:std_logic:='0';
signal dv_vals: std_logic_vector(5 downto 0);
signal state_monitor,blk_num_monitor: std_logic_vector(7 downto 0);

signal lfsr_reg_1w,lfsr_reg:std_logic_vector(31 downto 0):=x"12345678";
signal lfsr_reg2_1w,lfsr_reg2:std_logic_vector(31 downto 0):=x"12345678";

signal notfinish,notfinish_1w:std_logic;
signal datain_1w:std_logic_vector(datain'Length-1 downto 0);

signal too_low:std_logic;

signal t_all_len:integer:=0;
signal receive_full_i_1w:std_logic;

begin

mark_point<='1' when s_dataout=x"5B" and s_ce='1' else '0';

dataout<=s_dataout;
rd<=s_rd;
ce<=s_ce;


-- огда данных в FIFO достаточно и есть свободный буффер, 
--то начинаетс€ вычитывание.
--ƒанные читаютс€ из большого FIFO и складываютс€ в один из отправл€емых буферов.
--ѕри этом идет последовательный счет в нутри BLOCKNUM счетчиков
--Ќа р€ду со счетчиками запоминаетс€ значение dv
--
--ѕосле этого блок считаетс€ завершенным и индицируетс€ как заполненный.
--Ќачинаетс€ вывод, при этом в выходной блок вставл€етс€ нужный синхро-байт.
--
--≈сли данных нет, то генерируетс€ пустой блок с нулевыми счетчиками и dv=0


--use_gen_framer_inst: calclens_framer --use_gen_framer
--sim01: if SIMULATION=1 generate
--use_gen_framer_inst: use_gen_framer
--port map(
--	clk=>clkwr,
--	start=>start_st,
--	dv=>datain(8),
--	ce=>s_rd_w1,
--	out_ce=>blk_fin,
--	havereg=>have_reg,
--	dv_vals=>dv_vals,
--	len1=>blocks_test(0).block_len,
--	len2=>blocks_test(1).block_len,
--	len3=>blocks_test(2).block_len,
--	len4=>blocks_test(3).block_len,
--	len5=>blocks_test(4).block_len,
--	len6=>blocks_test(5).block_len,
--	state_monitor=>state_monitor,
--	blk_num_monitor=>blk_num_monitor
--);
--mkt: for i in 0 to 5 generate
-- cell: blocks_test(i).dv_value<=dv_vals(i);
--end generate;
--end generate;


process (clkwr) is
begin		
	if rising_edge(clkwr) then
        datain_1w<=datain;
		lfsr_reg<=gen_lfsr(0,lfsr_reg,'1', 8);
		lfsr_reg_1w<=lfsr_reg;
        receive_full_i_1w<=receive_full_i;

		if blk_fin='1' then
			blocks_test2<=blocks_test;
		end if;
		if reset='1' then
			stm<=PRE_RD;--WAITING;
			s_rd<='0';
			s_rd_w1<='0';
			have_reg<='0';
			local_wr<='0';
			mem_num<='0';
			mem1_fin<='0';
			mem2_fin<='0';
			blocks_cnt<=(others=>'0');
			have_free_mem<='1';
			mem1_fin_flag<='0';
			mem2_fin_flag<='0';
			dv_state<='0';
			start_st<='0';
			very_need<='0';
			notfinish<='0';
		else --# reset
			s_rd_w1<=s_rd;
			notfinish_1w<=notfinish;
			memory_have_read_byclkwr<=memory_have_read;
			memory_have_1w<=memory_have_read;
			memory_have_read_byclkwr_1w<=memory_have_read_byclkwr;
			read_memstart_byclkwr<=read_memstart;
			mem_num_rd_byclkwr<=mem_num_rd;

			have_free_mem<='1';
			
		 	

			if mem1_fin='1' then
				mem1_fin_flag<='1';
			else
				if mem_num_rd='0' and (memory_have_read='1' and memory_have_1w='0') then
					mem1_fin_flag<='0';
				end if;
			end if;


			if mem2_fin='1' then
				mem2_fin_flag<='1';
			else
				if mem_num_rd='1' and (memory_have_read='1' and memory_have_1w='0') then
					mem2_fin_flag<='0';
				end if;
			end if;


			if unsigned(rdcount)>conv_integer(middle_value) and have_free_mem='1' and receive_full_i_1w='0' then
				stm_run<='1';
				dv_state<='1';
			else
				stm_run<='0';
			end if;
				
			if unsigned(rdcount)<conv_integer(small_value) then
				too_low<='1';
			else
				too_low<='0';
			end if;

			if stm=WAITING	then
				t_all_len<=0;
			else
                if local_wr='1' then
					t_all_len<=t_all_len+1;
				end if;
			end if;
			--if ce='1' then
				case stm is
				when PRE_RD=>
					if fifo_empty='0' then
						s_rd<='1';
						stm<=WAITING;
					else
						s_rd<='0';
					end if;
					local_wr<='0';	
				when WAITING=>
					if stm_run='1' or notfinish_1w='1' then 
						start_st<='1';
						stm<=CONVEER_START1;
					end if;
					s_rd<='0';
					local_wr<='0';
					wr_ptr<=conv_std_logic_vector(DATA_OFFSET,wr_ptr'Length);
					blocks_cnt<=(others=>'0');					
					cur_len<=(others=>'0');
					input_cnt<=(others=>'0');
				when CONVEER_START1=>
					stm<=CONVEER_START2;
					if have_reg='1' then
						s_rd<='0';
					else
						s_rd<='1';
					end if;
					start_st<='0';
					blocks(conv_integer(blocks_cnt)).block_len<=conv_std_logic_vector(0,blocks(0).block_len'Length); --(others=>'0');
				when CONVEER_START2=>
					s_rd<='1';
					blocks(conv_integer(blocks_cnt)).block_len<=blocks(conv_integer(blocks_cnt)).block_len+1;
					blocks(conv_integer(blocks_cnt)).dv_value<=datain(8);
					if have_reg='0' then
						datawr<=datain(7 downto 0);
						cur_dv<=datain(8);
					else
						datawr<=datain_reg(7 downto 0);
						cur_dv<=datain_reg(8);
					end if;
					have_reg<='0';
					local_wr<='1';
					wr_ptr<=wr_ptr+0;
					input_cnt<=input_cnt+1;
					stm<=DETECTING;
				when GET_REG=>
					start_st<='0';
					if datain_reg(8)='0' then
			        	dv_down<='1';
					else
						dv_down<='0';
					end if;

					cur_dv<=datain_1w(8);
					blocks(conv_integer(blocks_cnt)).dv_value<=datain_1w(8);
					local_wr<='0';
					blocks(conv_integer(blocks_cnt)).block_len<=conv_std_logic_vector(1,blocks(0).block_len'Length);


					if (unsigned(input_cnt)>(FRAME_LEN-DATA_OFFSET-PAUSE_LEN) or too_low='1') and 
							((datain_1w(8)='0' and have_reg='0')  ) then
						stm<=WRITE_BLOCKS;
						blocks_cnt_have<=blocks_cnt;
						blocks_cnt<=(others=>'0');
						wr_ptr<=conv_std_logic_vector(DATA_OFFSET-BLOCKNUM-1,wr_ptr'Length);
 	      	            s_rd<='0';
						notfinish<='0';						
					else
						stm<=DETECTING;
						if input_cnt/=179 then
        	            	s_rd<='1';
						else
							s_rd<='0';
						end if;
					end if;
					
					cur_len<=conv_std_logic_vector(0,blocks(0).block_len'Length);
				when DETECTING_PRE=>
					cur_dv<=datain(8);
					blocks(conv_integer(blocks_cnt)).block_len<=blocks(conv_integer(blocks_cnt)).block_len+1;
					local_wr<='1';
					datawr<=datain(7 downto 0);
					wr_ptr<=wr_ptr+1;
					input_cnt<=input_cnt+1;
					stm<=DETECTING;
				when DETECTING=>
				     

					if unsigned(input_cnt)<(FRAME_LEN-DATA_OFFSET) then
							if (cur_dv/=datain(8)) or (cur_len>=62) or (too_low='1' and datain(8)='0') then								
									if unsigned(blocks_cnt)<BLOCKNUM-1 then
										blocks_cnt<=blocks_cnt+1;
										stm<=GET_REG;
										datawr<=datain(7 downto 0);
	                                    local_wr<='1';
										wr_ptr<=wr_ptr+1;
										input_cnt<=input_cnt+1;						
									else
										blocks(conv_integer(blocks_cnt)).block_len<=blocks(conv_integer(blocks_cnt)).block_len+1;
										stm<=WRITE_BLOCKS;
										notfinish<=datain(8);
										blocks_cnt_have<=blocks_cnt;
										blocks_cnt<=(others=>'0');
										wr_ptr<=conv_std_logic_vector(DATA_OFFSET-BLOCKNUM-1,wr_ptr'Length); --# (-1) потому что адрес потом инкрементируетс€
										datain_reg<=datain;
										have_reg<='1';
										local_wr<='0';
									end if;
								s_rd<='0';							
							else   --#   (cur_dv/=datain(8)) or (cur_len>=63-1)
								if datain(8)='0' then
					        		dv_down<='1';
								else
									dv_down<='0';
								end if;

								datawr<=datain(7 downto 0);
								local_wr<='1';
								wr_ptr<=wr_ptr+1;
								cur_len<=cur_len+1;
                            	blocks(conv_integer(blocks_cnt)).block_len<=blocks(conv_integer(blocks_cnt)).block_len+1;
								input_cnt<=input_cnt+1;
								if unsigned(input_cnt)<(FRAME_LEN-DATA_OFFSET-1) then
									s_rd<='1';
								else
									s_rd<='0';
								end if;
						end if;  --# (cur_dv/=datain(8)) or (cur_len>=63-1)
					else   --# unsigned(input_cnt)<(FRAME_LEN-DATA_OFFSET+2)
						local_wr<='1';
						s_rd<='0';
						datawr<=datain(7 downto 0);
						notfinish<=datain(8);
						wr_ptr<=wr_ptr+1;
						blocks(conv_integer(blocks_cnt)).block_len<=blocks(conv_integer(blocks_cnt)).block_len+1;					
						stm<=WRITE_BLOCKS;
						blocks_cnt_have<=blocks_cnt;
						blocks_cnt<=(others=>'0');
						wr_ptr<=conv_std_logic_vector(DATA_OFFSET-BLOCKNUM-1,wr_ptr'Length);
					end if;

				when WRITE_AFTER=>
						datawr<=(others=>'0');
	                    
						wr_ptr<=wr_ptr+1;
						input_cnt<=input_cnt+1;						
	                    if unsigned(input_cnt)<(FRAME_LEN-DATA_OFFSET-1) then
							local_wr<='1';
						else
							local_wr<='0';
							blocks_cnt_have<=blocks_cnt;
							blocks_cnt<=(others=>'0');
							wr_ptr<=conv_std_logic_vector(DATA_OFFSET-BLOCKNUM-1,wr_ptr'Length);
							stm<=WRITE_BLOCKS;
						end if;
				when WRITE_BLOCKS=>
					if unsigned(blocks_cnt)<=unsigned(blocks_cnt_have) then
						local_wr<='1';
						datawr<=blocks(conv_integer(blocks_cnt)).dv_value&blocks(conv_integer(blocks_cnt)).block_len;
						blocks_cnt<=blocks_cnt+1;
						wr_ptr<=wr_ptr+1;
					else
						local_wr<='0';
						stm<=WRITE_ZEROBLOCKS;
					end if;
				when WRITE_ZEROBLOCKS=>
					if unsigned(blocks_cnt)<BLOCKNUM then
						local_wr<='1';
						datawr<=(others=>'0');
						blocks_cnt<=blocks_cnt+1;
						wr_ptr<=wr_ptr+1;
					else
						local_wr<='0';
						stm<=FRAME_FIN;						
					end if;
				when FRAME_FIN=>
					if mem_num='0' then
						mem1_fin<='1';
					else
						mem2_fin<='1';
					end if;
						local_wr<='0';					
					stm<=WAITING_PRE;
				when WAITING_PRE=>
					mem1_fin<='0';
					mem2_fin<='0';
					if (stmrd=READ_MEM1 or stmrd=READ_MEM1_D1 or stmrd=READ_MEM1_D2 or stmrd=READ_MEM2) and mem_num_rd=mem_num then
						stm<=WAITING;
						mem_num<=not mem_num;
					end if;
                    blocks_cnt<=(others=>'0');
				when others =>
				end case;
		end if; -- reset	
	end if;
end process;

mem1_wr<=local_wr and not(mem_num);  --# будем писать по очередно то в один, то в другой
mem2_wr<=local_wr and    (mem_num);

process (clkwr) is
begin
	if rising_edge(clkwr) then
	   if mem1_wr='1' then
			mem1(conv_integer(wr_ptr))<=datawr;
	   end if;   

	   if mem2_wr='1' then
			mem2(conv_integer(wr_ptr))<=datawr;
	   end if;   
	end if;
end process;	


process (clkrd) is
begin
	if rising_edge(clkrd) then
		datard1<=mem1(conv_integer(rd_ptr));

		datard2<=mem2(conv_integer(rd_ptr));
	end if;
end process;	


process (clkrd) is
begin
	if rising_edge(clkrd) then

		lfsr_reg2<=gen_lfsr(0,lfsr_reg2,'1', 8);
		lfsr_reg2_1w<=lfsr_reg2;

		mem1_fin_byclkrd<=mem1_fin;
		mem1_fin_byclkrd_1w<=mem1_fin_byclkrd;
		mem2_fin_byclkrd<=mem2_fin;
		mem2_fin_byclkrd_1w<=mem2_fin_byclkrd;
		mem_num_byclkrd<=mem_num;
		mem_num_byclkrd_1w<=mem_num_byclkrd;
		memory_have_read_stb_byclkwr<=memory_have_read_stb;

		mem1_fin_flag_byclkrd<=mem1_fin_flag;
		mem2_fin_flag_byclkrd<=mem2_fin_flag;

		--# ¬ этот момент € mem_num еще не помен€л
		if (mem_num_byclkrd_1w='0' and mem1_fin_flag_byclkrd='1') or (mem_num_byclkrd_1w='1' and mem2_fin_flag_byclkrd='1') then
			needread_mem<='1';
		else			
			needread_mem<='0';
		end if;


	    if reset='1' then
			stmrd<=SEE_AND_MK_PAUSE;
			pause_cnt<=(others=>'0');
			cant_cut<='0';
			mem_num_rd<='1';						
		else  --# reset
			case stmrd is
			when SEE_AND_MK_PAUSE=>
				 ce_start_p1<='0';
				 datas_cnt<=(others=>'0');
				 if unsigned(pause_cnt)<(BFRAME_LEN-FRAME_LEN-1) then
					pause_cnt<=pause_cnt+1;
					read_memstart<='0';
					ce_start_p1<='0';
				 else
					 if needread_mem='1' then
						stmrd<=READ_MEM1;
						read_memstart<='1';
						mem_num_rd<=mem_num;
						cant_cut<='0';--(have_reg and datain_reg(8));
					 else						
						stmrd<=MAKING_EMPTY1;
						read_memstart<='0';
					 end if; 
					 ce_start_p1<='1';
				 end if;
				 s_ce_start<='0';
			     ce_stop<='0';				 
				 s_dataout<=(others=>'0');
				 s_ce<='0';
				 rd_ptr<=conv_std_logic_vector(DATA_OFFSET-BLOCKNUM,rd_ptr'Length);
                 memory_have_read_stb<='0';
				 tbd1_ce<='0';
				 tbd2_ce<='0';
			when MAKING_EMPTY1=>
				ce_start_p1<='0';
				s_dataout<=b8array(conv_integer(sync_cnt));
				sync_cnt<=sync_cnt+1;
				datas_cnt<=datas_cnt+1;
				s_ce<='1';
				s_ce_start<='1';
				stmrd<=MAKING_EMPTY1_D1;--MAKING_EMPTY2;
				tbd1_ce<='1';
			when MAKING_EMPTY1_D1=>
				s_ce_start<='0';
				s_ce<='1';
				tbd1_ce<='0';
				tbd2_ce<='1';
				datas_cnt<=datas_cnt+1; --
				s_dataout<=cant_cut&tbd1_data(6 downto 0);
				stmrd<=MAKING_EMPTY1_D2;
			when MAKING_EMPTY1_D2=>
				s_ce<='1';
				tbd2_ce<='0';
				s_dataout<=tbd2_data;
				datas_cnt<=datas_cnt+1; --
				stmrd<=MAKING_ZEROHEAD; --MAKING_EMPTY2;
				zerohead_cnt<=(others=>'0');
			when MAKING_ZEROHEAD=>
				if unsigned(zerohead_cnt)<BLOCKNUM-1 then
					zerohead_cnt<=zerohead_cnt+1;
				else
					stmrd<=MAKING_EMPTY2;
				end if;
				datas_cnt<=datas_cnt+1;
				s_ce<='1';
				s_dataout<=(others=>'0');
			when MAKING_EMPTY2=>
				s_ce<='1';
				datas_cnt<=datas_cnt+1;
					s_dataout<='0'&lfsr_reg2_1w(6 downto 0);
				if unsigned(datas_cnt)<(FRAME_LEN-1) then
					ce_stop<='0';
				else
					stmrd<=SEE_AND_MK_PAUSE;
					ce_stop<='1';
				end if;
				s_ce_start<='0';
                pause_cnt<=(others=>'0');
			when READ_MEM1=>
				s_ce_start<='1';
				ce_start_p1<='0';
				s_dataout<=b8array(conv_integer(sync_cnt));
				sync_cnt<=sync_cnt+1;
				datas_cnt<=datas_cnt+1;
				s_ce<='1';
				stmrd<=READ_MEM1_D1;
				tbd1_ce<='1';
			when READ_MEM1_D1=>
				s_ce_start<='0';
				s_ce<='1';
				tbd1_ce<='0';
				tbd2_ce<='1';
				s_dataout<=tbd1_data;
				stmrd<=READ_MEM1_D2;
				--rd_ptr<=rd_ptr+1;
                datas_cnt<=datas_cnt+1;
			when READ_MEM1_D2=>
				s_ce<='1';
				tbd2_ce<='0';
				s_dataout<=tbd2_data;
				stmrd<=READ_MEM2;
				rd_ptr<=rd_ptr+1; --# начинаем уже переключать потому что до стейта READ_MEM2 данные будут долго доходить
				datas_cnt<=datas_cnt+1;
			when READ_MEM2=>
				if mem_num_rd='0' then
                	s_dataout<=datard1;
				else
					s_dataout<=datard2;
	            end if;
				s_ce_start<='0';
				s_ce<='1';
				ce_stop<='0';
				datas_cnt<=datas_cnt+1;
				if unsigned(datas_cnt)<(FRAME_LEN-2) then
					rd_ptr<=rd_ptr+1;
				else
					stmrd<=LAST_BYTE;
					memory_have_read_stb<='1';
				end if;
				s_ce_start<='0';
                pause_cnt<=(others=>'0');
			when LAST_BYTE=>
				 if mem_num_rd='0' then
                 	s_dataout<=datard1;
				 else
					s_dataout<=datard2;
	             end if;
				 ce_stop<='1';
				 s_ce<='1';
				 stmrd<=SEE_AND_MK_PAUSE;
			when others=>
			end case;
		end if; --# reset

		if memory_have_read_stb='1' then
			mem_have_rd_cnt<=(others=>'1');
			memory_have_read<='1';
		else
			if unsigned(mem_have_rd_cnt)>0 then
				mem_have_rd_cnt<=mem_have_rd_cnt-1;
				memory_have_read<='1';
			else
				memory_have_read<='0';
			end if;
		end if;

		if s_ce_start='1' then
			ttt<=0;
		else
			ttt<=ttt+1;
		end if;

	end if;
end process;	
ce_start<=s_ce_start;

end read_frames4fifo;
