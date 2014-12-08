 library IEEE;
 use IEEE.STD_LOGIC_1164.ALL;
 use IEEE.STD_LOGIC_ARITH.ALL;
 use IEEE.STD_LOGIC_UNSIGNED.ALL;
  

entity Conv8_4 is
   port(
	      RST    : in  std_logic;
	      clk    : in  std_logic;
			clk_d4 : in  std_logic;
			din    : in  std_logic_vector(7 downto 0);
	      dout   : out std_logic_vector(1 downto 0);
			d_check: out  std_logic_vector(7 downto 0)
	     );
end entity;

architecture beh of Conv8_4 is	
	
signal  di: std_logic_vector(7 downto 0);
signal  do: std_logic_vector(1 downto 0);
signal seq: std_logic_vector (1 downto 0) := b"00";


begin

upload: process (clk_d4) is
variable cnt_ch: std_logic_vector (1 downto 0) := b"00";

begin
     if rising_edge (clk_d4) then
		di <= din;
	  end if;
		
end process;

download: process (clk) is
begin
        if rising_edge(clk) then
				if RST = '1' then
					seq <= b"00";
				end if;
				
					if (clk_d4 = '1' and seq = b"00") then
						dout <= di(5 downto 4);
						seq <= seq +1;
					end if;
					if (seq = b"01") then
						dout <= di(3 downto 2);
						seq <= seq +1;
					end if;
					if (seq = b"10") then
						dout <= di(1 downto 0);
						seq <= seq +1;
					end if;
					if (seq = b"11") then
						dout <= di(7 downto 6);
						seq <= seq +1;
					end if;
		  end if;
end process;  



end beh;