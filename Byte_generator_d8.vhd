  library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.STD_LOGIC_ARITH.ALL;
  use IEEE.STD_LOGIC_UNSIGNED.ALL;
  
  library altera; 
  use altera.altera_primitives_components.all;

  LIBRARY altera_mf; 
  USE altera_mf.altera_mf_components.all; 

entity Byte_generator_d8 is

port (Clk     	   : in  std_logic;
	  enable       : in  std_logic;
	  dv           : out std_logic;
	  data         : out std_logic_vector (7 downto 0)
	  );
end entity;

architecture beh of Byte_generator_d8 is	
												
																		
begin
     
byte_p : process (Clk, enable)
variable cnt_data: std_logic;
variable       ce: std_logic;
begin
     if rising_edge(Clk) then
        if (enable='1') then
				 if  (cnt_data = '0') then --1
						data <= b"00011011";
						cnt_data := not cnt_data;
				 else data <= b"00111001";
						cnt_data := '0'; --6
				 end if;
        else cnt_data := '0'; --(others =>'0');
				 data <= b"00000000";
        end if;
		  
--		  if (cnt_data<x"0F") then
--		       dv  <= '0';
--				 data<= x"00";
--		  else dv <= '1';
--		       data <= cnt_data;
--		  end if;
     end if;
end process;

end beh;