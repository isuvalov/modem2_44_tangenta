library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity stob_scale is
	generic 
	(
	 newwidth:natural:=26
	);
	 port(
		 reset : in std_logic;
	 	 clk : in std_logic;
		 strob_in : in std_logic;
		 strob_out : out std_logic
	     );
end stob_scale;


architecture stob_scale of stob_scale is

signal cnt:std_logic_vector(newwidth-1 downto 0);
begin

process(clk) is
begin
	if rising_edge(clk) then
		if reset='1' then
			cnt<=conv_std_logic_vector(0,cnt'Length);
			strob_out<='0';
		else
			if strob_in='1' then
				cnt<=SXT("1",cnt'Length);
				strob_out<='1';
			else
				if unsigned(cnt)>0 then
					cnt<=cnt-1;
					strob_out<='1';
				else
					strob_out<='0';
				end if;
			end if;
		end if;
	end if;
end process;

end stob_scale;
