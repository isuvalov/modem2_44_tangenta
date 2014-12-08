library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity simple_mac_tx is
	 port(
		 clk : in STD_LOGIC;
		 useit : in std_logic;
		 frame_ce : in STD_LOGIC;
		 data_in : in STD_LOGIC_VECTOR(7 downto 0);
		 tx_en : out STD_LOGIC;
		 tx_er : out STD_LOGIC;
		 txd : out STD_LOGIC_VECTOR(7 downto 0)
	     );
end simple_mac_tx;


architecture simple_mac_tx of simple_mac_tx is
begin
 
xorframe12_inst: entity work.xorframe
	 port map(
	 	 clk=>clk,
		 useit=>'1',
		 dv_i =>frame_ce,
		 data_i =>data_in,
		 dv_o =>tx_en,
		 data_o =>txd
	     );


process (clk) is
begin		
	if rising_edge(clk) then
		tx_er<='0';
--		txd<=data_in;
--		tx_en<=frame_ce;
	end if;
end process;	


end simple_mac_tx;
