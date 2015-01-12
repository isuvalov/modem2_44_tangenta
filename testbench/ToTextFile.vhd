library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.std_logic_arith.all;
library std;
use std.textio.all;



entity ToTextFile is
	generic(BitLen : natural := 8;
			WriteHex:integer:=1;  -- if need write file in hex format or std_logic_vector too long(>=64)
			NameOfFile: string := "c:\noise.dat");
	 port(
		 clk : in STD_LOGIC;
		 CE : in STD_LOGIC;
		 block_marker: in std_logic;
		 DataToSave : in STD_LOGIC_VECTOR(BitLen-1 downto 0)
	     );
end ToTextFile;


architecture ToTextFile of ToTextFile is

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

FUNCTION rats( value : std_logic_vector ) RETURN std_logic_vector IS
variable rtt:std_logic_vector(value'Range);
  BEGIN					   
    for i in value'Range loop		
		rtt(i):=rat(value(i));
	end loop;
	return rtt;
END rats;

function fliplr(A:std_logic_vector) return std_logic_vector is
variable R:std_logic_vector(A'Range);
begin
  for i in A'Low to A'High loop
	  R(A'High-(i-A'Low)):=A(i);
  end loop; 
  return R;
end function;


function ToHex( value: std_logic_vector) return string is
variable str:string(1 to BitLen/4);
variable a:character;
variable value_h:std_logic_vector(3 downto 0);
begin
	for z in 1 to BitLen/4 loop
	value_h:=fliplr(value(z*4-1 downto (z-1)*4));
	case value_h is
		when "0000" => a:='0';
		when "0001" => a:='1';
		when "0010" => a:='2';
		when "0011" => a:='3';		
		when "0100" => a:='4';
		when "0101" => a:='5';
		when "0110" => a:='6';
		when "0111" => a:='7';		
		when "1000" => a:='8';
		when "1001" => a:='9';
		when "1010" => a:='A';
		when "1011" => a:='B';		
		when "1100" => a:='C';
		when "1101" => a:='D';
		when "1110" => a:='E';
		when "1111" => a:='F';
		when "ZZZZ" => a:='Z';
		when OTHERS =>
			a:='X';
	end case;		
		
	str(z):=a;
	end loop;
 	return str;
end ToHex;

FILE RESULTS: TEXT OPEN WRITE_MODE IS NameOfFile;
signal cnt:integer:=0;

--signal tessst:string(1 to (BitLen/4)*2+1);
begin
--tessst<=ToHex(fliplr(DataToSave));	
wrFile: process (clk) is
VARIABLE TX_LOC : LINE;	
variable dataint:Integer;
variable str1:string(1 to  20);
variable str2:string(1 to  1);
begin
str1:="-------------------/";
str2:=" ";
	if rising_edge(clk) then
		if block_marker='1' then								   
			cnt<=cnt+1;
			STD.TEXTIO.write(TX_LOC,str1);
			STD.TEXTIO.write(TX_LOC,cnt);
			STD.TEXTIO.writeline(results, TX_LOC); 
		end if;
		if CE='1' then				  
			if WriteHex/=1 then
				dataint:=CONV_INTEGER(UNSIGNED(rats(DataToSave)));
				STD.TEXTIO.write(TX_LOC,dataint);	
			else				   				
				STD.TEXTIO.write(TX_LOC,ToHex(fliplr(DataToSave))(1 to 8));
				STD.TEXTIO.write(TX_LOC,str2);
				STD.TEXTIO.write(TX_LOC,ToHex(fliplr(DataToSave))(9 to 16));
			end if;
			STD.TEXTIO.writeline(results, TX_LOC); 
			STD.TEXTIO.Deallocate(TX_LOC);
		end if;
	end if;
end process;

end ToTextFile;
