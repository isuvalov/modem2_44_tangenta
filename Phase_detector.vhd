library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
  
entity Phase_detector is
   port(
	      clk        :in  std_logic;
			sync       :in  std_logic;
			pd_i       :in  std_logic;
			pd_q       :in  std_logic;
			pd_i_and_q :in  std_logic;
			pd_i_or_q  :in  std_logic;
	      pd_loop    :out std_logic;
		   to_ext_pll :out std_logic	
	     );
end entity;

architecture beh of Phase_detector is	

signal step1: std_logic;
signal step2: std_logic;
signal step3: std_logic;
signal  jump: std_logic;
															
begin

   step1 <= not pd_i xor pd_q;
   step2 <= not pd_i_and_q xor pd_i_or_q;
   step3 <= not step1 xor step2;
		
	--pd_loop <= step3; -- or jump;
	to_ext_pll <= pd_i;
	
pd_p: process	(jump) is
begin	
   if(jump='1')then
	   pd_loop <= '0'; -- reset: '0' to right, '1' to left 
	else 
	   pd_loop <= not step3;
	end if;
end process;

jump_p: process (clk) is
variable cnt_clk: std_logic_vector(24 downto 0);
begin
      if rising_edge(clk) then
				cnt_clk := cnt_clk +1;
				if (cnt_clk < x"100000" and (sync = '0')) then
					jump <= '1';
				else 
					jump <= '0';
				end if;
		end if;
end process;
 
 
end beh;