library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity simple_mac_rx is
	 port(
		 clk : in STD_LOGIC;
		 useit : in std_logic;
		 frame_ce : out STD_LOGIC;
		 data_out : out STD_LOGIC_VECTOR(7 downto 0);
		 rx_dv : in STD_LOGIC;
		 rx_er : in STD_LOGIC;
		 rxd : in STD_LOGIC_VECTOR(7 downto 0)
	     );
end simple_mac_rx;


architecture simple_mac_rx of simple_mac_rx is

signal vvv:std_logic:='0';
signal rx_dv_1w:std_logic:='0';

signal		 s_frame_ce : STD_LOGIC;
signal		 s_data_out : STD_LOGIC_VECTOR(7 downto 0);


begin
 	
xorframe12_inst: entity work.xorframe
	 port map(
	 	 clk=>clk,
		 useit=>'1',
		 dv_i =>rx_dv,
		 data_i =>rxd,
		 dv_o =>frame_ce,
		 data_o =>data_out
	     );


process (clk) is
begin		
	if rising_edge(clk) then
		
	--	data_out<=rxd;
	--	frame_ce<=rx_dv;
	end if;
end process;	
	


end simple_mac_rx;
