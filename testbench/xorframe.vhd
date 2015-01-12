library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity xorframe is
	 port(
	 	 clk : in std_logic;
		 useit : in std_logic;
		 dv_i : in std_logic;
		 data_i : in std_logic_vector(7 downto 0);
		 dv_o : out std_logic;
		 data_o : out std_logic_vector(7 downto 0)
	     );
end xorframe;


architecture xorframe of xorframe is

FUNCTION gen_lfsr(PSPNum: integer; pol : std_logic_vector; en : std_logic; nb_iter : natural) RETURN std_logic_vector IS
VARIABLE pol_int : std_logic_vector(pol'length-1 DOWNTO 0);
VARIABLE pol_gen : std_logic_vector(pol'length-1 DOWNTO 0);
BEGIN
CASE PSPNum is
when 0 => pol_gen := x"8000000D";
when 1 => pol_gen := x"00400007";
when 2 => pol_gen := x"00086001";
when 3 => pol_gen := x"02800003";
when 4 => pol_gen := x"21000005";
when others => pol_gen := "11"; -- x^2 + x + 1
END CASE;
pol_int := pol;
iteration : FOR i in 1 to nb_iter LOOP
IF en = '1' THEN
IF pol_int(pol'length-1)='1' THEN
pol_int := (pol_int(pol'length-2 DOWNTO 0)&'0') xor pol_gen;
ELSE
pol_int := (pol_int(pol'length-2 DOWNTO 0)&'0');
END IF;
ELSE pol_int := pol_int;
END IF;
END LOOP;
RETURN (pol_int);
END gen_lfsr;

signal lfsr_reg:std_logic_vector(31 downto 0):=x"A1AAAAA5";

begin

process(clk) is
begin
	if rising_edge(clk) then
		dv_o<=dv_i;
		if useit='0' then
			data_o<=data_i;
		else
			if dv_i='0' then
				lfsr_reg<=x"A1AAAAA5";
				data_o<=x"00";
			else
				lfsr_reg<=gen_lfsr(0, lfsr_reg, '1', 8);
				data_o<=data_i xor lfsr_reg(7 downto 0);
			end if;
		end if;
	end if;
end process;

end xorframe;
