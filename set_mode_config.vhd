  library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.STD_LOGIC_ARITH.ALL;
  use IEEE.STD_LOGIC_UNSIGNED.ALL;
  
  entity set_mode_config is
	
		port(
			enable	:in std_logic;
			reset		:in std_logic;
			Clk		:in std_logic;
			
			to_Rxd	:out std_logic_vector (1 downto 0);
			to_coll	:out std_logic;
			mode_cfg	:out std_logic
		
		);
		
end entity;

architecture set_mode_config of set_mode_config is

begin

process (Clk)
	begin
		if rising_edge(Clk) then
			if (reset = '1') then
				mode_cfg <= '1';
				to_Rxd <= b"11";
				to_coll <= '1';
			end if;
			if (enable = '0') then
				mode_cfg <= '0';
--				to_Rxd <= b"00";
--				to_coll <= '0';
			end if;
		end if;
end process;

end set_mode_config;
			
