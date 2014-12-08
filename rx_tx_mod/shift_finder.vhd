LIBRARY ieee;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity shift_finder is
	 port(
		 clk : in std_logic;
		 ce : in std_logic;
		 SyncFind : in std_logic;
		 reset : in std_logic;
		 shift : out std_logic_vector(2 downto 0)
	     );
end shift_finder;


architecture shift_finder of shift_finder is
signal cnt:std_logic_vector(18 downto 0):=(others=>'0');
signal s_shift:std_logic_vector(shift'Length-1 downto 0):=(others=>'0');
begin

process (clk) is
begin					 
 if rising_edge(clk) then
  if reset='1' then
	  s_shift<=(others=>'0');
  else
	  if ce='1' then
		  if SyncFind='0' then
		  	  cnt<=cnt+1;
			  if cnt=SXT("1",cnt'Length) then
			   	s_shift<=s_shift+1; 	
			  end if;	
		  end if;
	  end if; --#ce
  end if; --#reset
 end if; --#clk
end process;
shift<=s_shift;
	
end shift_finder;
