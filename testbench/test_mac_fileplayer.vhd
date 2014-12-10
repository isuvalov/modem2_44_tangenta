library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;
library std;
use std.textio.all;

entity test_mac_fileplayer is 
   generic (
      NameOfFile: string := "c:\noise.dat";
	  NameOfFile_CE: string := "c:\noise.dat");
  port (
	clk : in std_logic;
    data_out: out std_logic_vector(7 downto 0);
  	data_ce: out std_logic
  );
end test_mac_fileplayer;

architecture test_mac_fileplayer of test_mac_fileplayer is
constant BitLen:natural:=8;
signal ce_fromfile:std_logic_vector(1 downto 0);
signal rx_data_valid_p1,valids:std_logic_vector(7 downto 0);
signal data_fromfile:std_logic_vector(7 downto 0);	
signal cntlen:std_logic_vector(13 downto 0):=(others=>'0');

FILE results: TEXT OPEN READ_MODE IS NameOfFile;
FILE results_ces: TEXT OPEN READ_MODE IS NameOfFile_CE;
begin


process (clk) is
VARIABLE RX_LOC : LINE;
variable dataint:Integer;
variable parcece:std_logic_vector(1 downto 0);
variable stat_ce:std_logic;
begin		
 if rising_edge(clk) then
	 	STD.TEXTIO.readline(results, RX_LOC); 
		STD.TEXTIO.read(RX_LOC,dataint);	
		data_fromfile<=std_logic_vector(unsigned(CONV_STD_LOGIC_VECTOR(dataint,BitLen)));
		
		stat_ce:='0';
		STD.TEXTIO.readline(results_ces, RX_LOC); 
		STD.TEXTIO.read(RX_LOC,dataint);	
		ce_fromfile<=std_logic_vector(unsigned(CONV_STD_LOGIC_VECTOR(dataint,2)));

data_out<=data_fromfile;
data_ce<=ce_fromfile(0);

 end if; --#clk
end process; 



end test_mac_fileplayer;


