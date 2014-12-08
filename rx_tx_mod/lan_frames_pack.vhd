library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
PACKAGE lan_frames_pack IS

type Tb8array is array(0 to 7) of std_logic_vector(7 downto 0);

constant BFRAME_LEN:natural:=204;
constant FRAME_LEN:natural:=188;
constant b8array:Tb8array:=(x"B8",x"B7",x"78",x"74",x"80",x"01",x"74",x"02");
constant BLOCKNUM:natural:=6;
constant DATA_OFFSET:natural:=3+BLOCKNUM; --# (-1) так как начинаем считать с нуля
constant INFO_LEN:natural:=FRAME_LEN-DATA_OFFSET; --# 1 for sync and two addition bytes, BLOCKNUM for counters by 1 bytes for len


type Tblock_descriptor is record
	dv_value:std_logic;
	block_len:std_logic_vector(6 downto 0);
end record Tblock_descriptor;


function power_of_2(data_value:natural) return integer;
FUNCTION log2roundup (data_value : integer) RETURN integer;
FUNCTION mydivroundup (data_value : integer; divisor : integer) RETURN integer;	
FUNCTION rat( value : std_logic ) RETURN std_logic;
FUNCTION rats( value : std_logic_vector ) RETURN std_logic_vector;
function BusOr(B:std_logic_vector) return std_logic;
function BusAnd(B:std_logic_vector) return std_logic;
function fliplr(A:std_logic_vector) return std_logic_vector;
FUNCTION gen_lfsr(PSPNum: integer; pol : std_logic_vector; en : std_logic; nb_iter : natural) RETURN std_logic_vector;

END lan_frames_pack;


library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

package body lan_frames_pack is

function power_of_2(data_value:natural) return integer is
variable rett:std_logic_vector(data_value downto 0);
begin
	rett:=(others=>'0');
	rett(data_value):='1';
	return conv_integer(rett);
end power_of_2;




FUNCTION log2roundup (data_value : integer)
		RETURN integer IS
		
		VARIABLE width       : integer := 0;
		VARIABLE cnt         : integer := 1;
		CONSTANT lower_limit : integer := 1;
		CONSTANT upper_limit : integer := 8;
		
	BEGIN
		IF (data_value <= 1) THEN
			width   := 0;
		ELSE
			WHILE (cnt < data_value) LOOP
				width := width + 1;
				cnt   := cnt *2;
			END LOOP;
		END IF;
		
		RETURN width;
	END log2roundup;


FUNCTION mydivroundup (data_value : integer; divisor : integer)
		RETURN integer IS
		VARIABLE div                   : integer;
	BEGIN  
		if (divisor>data_value) or (divisor=0) then return 0; else
		div   := data_value/divisor;
		IF ( (data_value MOD divisor) /= 0) THEN
			div := div+1;
		END IF;
		RETURN div;
		end if;
END mydivroundup;


function fliplr(A:std_logic_vector) return std_logic_vector is
variable R:std_logic_vector(A'Range);
begin
  for i in A'Low to A'High loop
	  R(A'High-(i-A'Low)):=A(i);
  end loop; 
  return R;
end function;


FUNCTION rat( value : std_logic )
    RETURN std_logic IS
  BEGIN
    CASE value IS
      WHEN '0' | '1' => RETURN value;
      WHEN 'H' => RETURN '1';
      WHEN 'L' => RETURN '0';
      WHEN OTHERS => RETURN '0';
    END CASE;
END rat;

FUNCTION rats( value : std_logic_vector )
RETURN std_logic_vector IS
variable rtt:std_logic_vector(value'Length-1 downto 0);
  BEGIN					   
	for i in 0 to value'Length-1 loop
		rtt(i):=rat(value(i));
	end loop;
	return rtt;
END rats;

function BusOr(B:std_logic_vector) return std_logic is
    variable R:std_logic;
begin   
    R:='0';
    for i in B'Range Loop
        R:=R or B(i);
    end loop;
    return R;
end function;


function BusAnd(B:std_logic_vector) return std_logic is
    variable R:std_logic;
begin   
    R:='1';
    for i in B'Range Loop
        R:=R and B(i);
    end loop;
    return R;
end function;


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



end package body lan_frames_pack;
