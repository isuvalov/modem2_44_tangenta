library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
library work;
use work.lan_frames_pack.all;


entity find_synchro is
	generic (
		PERIOD:integer:=204;
		CE_LEN:integer:=188
	);
	 port(
		 clk : in std_logic;
		 reset : in std_logic;
		 ce : in std_logic;
		 datain : in std_logic_vector(7 downto 0);
		 start_frame_n : out std_logic;
		 start_frame : out std_logic;
		 start_frame_p1 : out std_logic;
		 SyncFind: out std_logic
	     );
end find_synchro;


architecture find_synchro of find_synchro is

constant POROG_HI:integer:=10;
constant POROG_LO:integer:=5;


constant SYNCRO:std_logic_vector:=b8array(0);--x"B8";
constant KONV_POS:integer:=PERIOD-3; --2; 

signal cnt204,sync_cnt,not_sync_cnt:std_logic_vector(7 downto 0);
signal local_syncfind,local_reset,sync:std_logic;
             
type Tstm is (WAITING,WAIT_NEXT0,WAIT_NEXT,WAIT_NEXT2,LOSE,FIND);
signal stm_w1,stm:Tstm;


signal cnt_b8:std_logic_vector(2 downto 0);

signal sync_extended:std_logic;


begin

process (clk) is
begin		
	if rising_edge(clk) then
		stm_w1<=stm;
		if reset='1' then
			cnt204<=(others=>'0');
			local_syncfind<='1';
			sync_cnt<=(others=>'0');
			not_sync_cnt<=(others=>'0');
			stm<=WAITING;
			SyncFind<='0';
			cnt_b8<=(others=>'0');
			sync_extended<='0';
		else --#reset

			case stm is
			when WAITING=>
				sync_cnt<=(others=>'0');
				if sync='1' then
					local_reset<='1';
					stm<=WAIT_NEXT0;
					cnt_b8<="001";
				else
					local_reset<='0';
				end if;
				SyncFind<='0';
				cnt_b8<="001";
			when WAIT_NEXT0=>
				stm<=WAIT_NEXT;
				local_reset<='0';
			when WAIT_NEXT=>
    				local_reset<='0';
				if cnt204=1 then --KONV_POS then
					cnt_b8<=cnt_b8+1;
				end if;
				if sync_extended='1' and cnt204=1 then --KONV_POS then
					--if unsigned(sync_cnt)<10 then
						sync_cnt<=sync_cnt+1;
					--	stm<=WAIT_NEXT2;
					--end if;
					if unsigned(sync_cnt)>=POROG_HI then
						stm<=FIND;
					--	cnt_b8<="011";						
					end if;	
					--local_reset<='1';
				else
					if cnt204=1 then --KONV_POS then
						stm<=WAITING;
						--local_reset<='1';
					else
						--local_reset<='0';
					end if;
				end if;
				SyncFind<='0';
			when WAIT_NEXT2=>
    				local_reset<='0';
				if cnt204=0 then --KONV_POS then
					cnt_b8<=cnt_b8+1;
				end if;
				if sync_extended='1' and cnt204=PERIOD-1 then --KONV_POS then
					--if unsigned(sync_cnt)<10 then
						sync_cnt<=sync_cnt+1;
					--end if;
					if unsigned(sync_cnt)>=POROG_HI then
						stm<=FIND;
					--	cnt_b8<="011";						
					end if;	
					--local_reset<='1';
				else
					if cnt204=PERIOD-1 then --KONV_POS then
						stm<=WAITING;
						--local_reset<='1';
					else
						--local_reset<='0';
					end if;
				end if;
				SyncFind<='0';

			 when FIND =>
				local_reset<='0';
				if cnt204=1 then
					cnt_b8<=cnt_b8+1;
				end if;
				if sync_extended='0' and cnt204=1 then 
				    sync_cnt<=sync_cnt-1;
					if unsigned(sync_cnt)<=POROG_LO then
						stm<=WAITING;
					end if;
				end if;
				SyncFind<='1';
			when others=>
			end case;

			if local_reset='1' then
				if stm_w1=WAIT_NEXT0 then
					cnt204<=conv_std_logic_vector(3,cnt204'Length);--(others=>'0');
				else
					cnt204<=conv_std_logic_vector(3,cnt204'Length);--(others=>'0');
				end if;
				local_syncfind<='0';
			else --# local_reset
				if unsigned(cnt204)<PERIOD-1 then
					cnt204<=cnt204+1;
				else
					cnt204<=(others=>'0');
				end if;
			end if; --# local_reset
				

			if datain=SYNCRO then
				sync<='1';
			else
				sync<='0';
			end if;

			if datain=b8array(conv_integer(cnt_b8)) then
				sync_extended<='1';
			else
				sync_extended<='0';
			end if;			

			if cnt204=PERIOD-1 then
				start_frame<='1';
			else
				start_frame<='0';
			end if;

			if cnt204=PERIOD-2 then
				start_frame_p1<='1';
			else
				start_frame_p1<='0';
			end if;



		end if; --# reset
	end if;
end process;

	 
end find_synchro;
