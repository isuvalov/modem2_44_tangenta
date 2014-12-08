library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity changer_freq_rx is
	 port(
		 clk : in std_logic;
		 reset: in std_logic;
		 answer : in std_logic;
		 answer_to_rx: out std_logic
	     );
end changer_freq_rx;


architecture changer_freq_rx of changer_freq_rx is

signal s_answer_to_rx,s_answer_to_rx_1w : std_logic:='0';


begin


answer_to_rx<=s_answer_to_rx;

process (clk) is
begin		
	if rising_edge(clk) then
		if reset='1' then
			s_answer_to_rx<='0';
			s_answer_to_rx_1w<='0';
		else
			s_answer_to_rx_1w<=s_answer_to_rx;
			if answer='1' then
				s_answer_to_rx<=not s_answer_to_rx;
			end if;
		end if;
	end if;
end process;

	 
end changer_freq_rx;
