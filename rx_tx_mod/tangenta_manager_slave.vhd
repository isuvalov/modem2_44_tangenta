library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity tangenta_manager_slave is
	 port(
		 clk : in std_logic;

		 tangenta_from_master: in std_logic; --# Send it by RF. if it '0' we cut trafic. Stop work RF transiver on slave site
		 tangenta: out std_logic --# if it '0' we cut trafic. Stop work RF transiver
	     );
end tangenta_manager_slave;


architecture tangenta_manager_slave of tangenta_manager_slave is

begin

process (clk) is
begin		
	if rising_edge(clk) then
        tangenta<=tangenta_from_master;
	end if;
end process;



end tangenta_manager_slave;
