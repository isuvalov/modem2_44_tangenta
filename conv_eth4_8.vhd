library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity conv_eth4_8 is
	 port(
		 reset  :in std_logic;
		 rxc    :in std_logic;
		 txc	  :in std_logic;
		 rx_dv  :in std_logic;
		 rxd    :in std_logic_vector(3 downto 0);
		 rdiv2  :out std_logic;
		 tdiv2  :out std_logic;
		 tx_dv  :out std_logic;
		 txd    :out std_logic_vector(7 downto 0)
	       );
end conv_eth4_8;


architecture conv_eth4_8 of conv_eth4_8 is

	signal datain :std_logic_vector(8 downto 0);
	signal dataout :std_logic_vector(8 downto 0);
	signal clkd2  :std_logic;
	signal rxc2  :std_logic;
	signal txc2  :std_logic;

begin


process (rxc)
begin
   if rising_edge(rxc)then
		  if txc='1' then
			  datain(3 downto 0)<=rxd;
			  datain(8)<=rx_dv;
		  else
			  datain(7 downto 4)<=rxd;
		  end if;
   end if;
end process;


process (txc)
begin
   if rising_edge(txc)then
		  dataout<=datain;
		  tx_dv  <=dataout(8);
		  txd    <=dataout(7 downto 0);
   end if;
end process;

end conv_eth4_8;
