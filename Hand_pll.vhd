library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity Hand_pll is
	port (
		clk_input		:in std_logic;
		clk_output		:out std_logic;
		clk_input2		:in std_logic;
		clk_output2		:out std_logic
	);
end entity;
	
architecture Hand_pll of Hand_pll is

signal clk : std_logic := '0';

begin


process (clk_input)

variable cnt1 : std_logic := '0';

	begin
	if rising_edge (clk_input) then
		cnt1 := not cnt1;
		clk_output <= cnt1;
	end if;

	
end process;

process (clk_input2)

variable cnt2 : std_logic := '0';

	begin
	if rising_edge (clk_input2) then
		cnt2 := not cnt2;
		clk_output2 <= cnt2;
	end if;

	
end process;
	

end Hand_pll;