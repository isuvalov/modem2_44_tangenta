library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity changer_freq_tx is
	 port(
		 clk : in std_logic;
		 reset: in std_logic;
		 ce : in std_logic;
		 mode : in std_logic;
		 mode_ack : in std_logic;
		 answer : out std_logic;
		 need_to_clkq_big : out std_logic
	     );
end changer_freq_tx;


architecture changer_freq_tx of changer_freq_tx is

signal cnt_mode0,cnt_mode1,Acnt_mode0,Acnt_mode1:std_logic_vector(5 downto 0):=(others=>'0');
constant MIDLECNT:std_logic_vector(cnt_mode0'Length-1 downto 0):='1'&EXT("0",cnt_mode0'Length-1);
constant MAXCNT:std_logic_vector(cnt_mode0'Length-1 downto 0):=(others=>'1');
signal state,state_1w:std_logic; --# '0' we in clkq<clk125 now
						--# '1' we in clkq>clk125 now
signal need_to_clkq_big_1p,s_answer,s_answer_wait : std_logic:='0';
signal timeoutcnt: std_logic_vector(12 downto 0):=(others=>'0');

signal ack_state,ack_state_1w:std_logic:='0';

begin


answer<=s_answer;

process (clk) is
begin		
	if rising_edge(clk) then
		need_to_clkq_big<=need_to_clkq_big_1p;
		if reset='1' then
			state_1w<='0';
			state<='0';
			s_answer<='0';
			timeoutcnt<=(others=>'0');
			ack_state<='0';
			ack_state_1w<='0';
		else

			
			state_1w<=state;

			if state_1w/=state then
				s_answer<='1';				
			else
				s_answer<='0';
			end if;


			if (unsigned(Acnt_mode0)>=conv_integer(MAXCNT)-1) and (unsigned(Acnt_mode1)=0) then
				ack_state<='0';
			elsif (unsigned(Acnt_mode1)>=conv_integer(MAXCNT)-1 and unsigned(Acnt_mode0)=0) then
				ack_state<='1';
			end if;

		            ack_state_1w<=ack_state;				
			if s_answer='1' then
				s_answer_wait<='1';
			else			
				 
				if ack_state_1w/=ack_state then
					timeoutcnt<=(others=>'1');
					s_answer_wait<='0';
				else
    
					if unsigned(timeoutcnt)>0 then
						timeoutcnt<=timeoutcnt-1;
					else
						if s_answer_wait='0' then
							need_to_clkq_big_1p<=state;
						end if;
					end if;
				end if;
			end if;
				

			if ce='1' then
				if mode='0' then
					if unsigned(cnt_mode0)<conv_integer(MAXCNT)-1 then
						cnt_mode0<=cnt_mode0+1;
					end if;
					if unsigned(cnt_mode1)>0 then
						cnt_mode1<=cnt_mode1-1;
					end if;
				else
					if unsigned(cnt_mode0)>0 then
						cnt_mode0<=cnt_mode0-1;
					end if;
					if unsigned(cnt_mode1)<conv_integer(MAXCNT)-1 then
						cnt_mode1<=cnt_mode1+1;
					end if;
				end if;				
			end if;



			if ce='1' then
				if mode_ack='0' then
					if unsigned(Acnt_mode0)<conv_integer(MAXCNT)-1 then
						Acnt_mode0<=Acnt_mode0+1;
					end if;
					if unsigned(cnt_mode1)>0 then
						Acnt_mode1<=Acnt_mode1-1;
					end if;
				else
					if unsigned(Acnt_mode0)>0 then
						Acnt_mode0<=Acnt_mode0-1;
					end if;
					if unsigned(Acnt_mode1)<conv_integer(MAXCNT)-1 then
						Acnt_mode1<=Acnt_mode1+1;
					end if;
				end if;				
			end if;


		end if;





		if state='0' then
			if unsigned(cnt_mode1)>=conv_integer(MIDLECNT)-1 then
				state<='1';				
			end if;
		else
			if unsigned(cnt_mode0)>=conv_integer(MIDLECNT)-1 then
				state<='0';				
			end if;
		end if;
	end if;
end process;

	 
end changer_freq_tx;
