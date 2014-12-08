library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity flowbyte_shifter is
	 port(
	 	 clk : in std_logic;
	 	 ce : in std_logic;
		 datain : in std_logic_vector(7 downto 0);
		 shift : in std_logic_vector(2 downto 0);
		 dataout : out std_logic_vector(7 downto 0)
	     );
end flowbyte_shifter;


architecture flowbyte_shifter of flowbyte_shifter is
 signal reg:std_logic_vector(datain'Length-1 downto 0);
begin
	
process (clk) is
begin		
	if rising_edge(clk) then
	 if ce='1' then
		 for i in 0 to 7 loop
			 if conv_integer(shift)=i then
				 dataout<=reg(reg'Length-1 downto i)&datain(datain'Length-1 downto datain'Length-i);
				 if i>0 then
				 	reg<=datain(datain'Length-i-1 downto 0)&EXT("0",i);
				 else
					 reg<=datain(datain'Length-1 downto 0);
				 end if;
			 end if; --# shift value
		 end loop;
	 end if; --#ce
	end if;
end process;

end flowbyte_shifter;
