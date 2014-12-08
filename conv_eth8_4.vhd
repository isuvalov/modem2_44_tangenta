library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity conv_eth8_4 is
	 port(
		 reset  :in std_logic;
		 txc2   :in std_logic;
		 tx_dv  :in std_logic;
		 txc    :in std_logic;
		 rxd    :in std_logic_vector(7 downto 0);
		 tx_en  :out std_logic;
		 txd    :out std_logic_vector(3 downto 0)
	       );
end conv_eth8_4;


architecture conv_eth8_4 of conv_eth8_4 is


signal datain:std_logic_vector(8 downto 0);
signal dataout:std_logic_vector(8 downto 0);


begin

process (txc2)
begin
   if rising_edge(txc2)then
			datain(8)<=tx_dv;
			datain(7 downto 0)<=rxd;
		end if;
end process;

process (txc)
begin
   if rising_edge(txc)then
		  if (txc2='1')then
			  txd<=datain(3 downto 0);
		  else
			  txd<=datain(7 downto 4);
		  end if;
		  tx_en<=datain(8);
	end if;
end process;


end conv_eth8_4;
