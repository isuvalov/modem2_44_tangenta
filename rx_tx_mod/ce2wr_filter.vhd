library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity ce2wr_filter is
	 port(
		 clk : in STD_LOGIC;
		 clk_ce : in STD_LOGIC;
		 fifofull : in STD_LOGIC;
		 fifo_going_full_i: in std_logic;
		 fifo_read_cnt: in std_logic_vector(13 downto 0);
		 datain: in STD_LOGIC_VECTOR(7 downto 0);
		 ce : in STD_LOGIC;
		 wr : out STD_LOGIC;
		 dv_out: out STD_LOGIC;
		 dataout: out STD_LOGIC_VECTOR(7 downto 0)
	     );
end ce2wr_filter;


architecture ce2wr_filter of ce2wr_filter is

type Tstm is (WRITE,WRITE_PAUSE,PAUSE);
signal stm:Tstm:=PAUSE;

signal cnt_p:std_logic_vector(2 downto 0):=(others=>'0');


signal ce_W:std_logic_vector(3 downto 0);
signal datain_1w,datain_2w:std_logic_vector(datain'Length-1 downto 0);
signal s_wr,wrempty:std_logic:='0';


begin

 	
process (clk) is
begin		
	if rising_edge(clk) then

		if clk_ce='1' then

			case stm is
			when PAUSE=>
				cnt_p<=(others=>'0');
				if ce='1' then
					dataout<=datain;	
					s_wr<='1';
				    dv_out<='1';
					stm<=WRITE;
				else 
				    dv_out<='0';
					s_wr<='0';
					dataout<=(others=>'0');
				end if;
			when WRITE=>
				wrempty<='0';
				if ce='1' then
					dataout<=datain;	
					s_wr<='1';
					dv_out<='1';
				else
					dv_out<='0'; --# +1
					s_wr<='1';
					dataout<=(others=>'0');
					stm<=WRITE_PAUSE;
				end if;
				cnt_p<=(others=>'0');
			when WRITE_PAUSE=>
				if ce='1' then
					dataout<=datain;	
					s_wr<='1';
				    dv_out<='1';
					stm<=WRITE;
				else
					dataout<=(others=>'0');
					if unsigned(cnt_p)<2 then
						dv_out<='0';
						s_wr<='1';
						cnt_p<=cnt_p+1;
					else
						s_wr<='0';
						dv_out<='0';
						stm<=PAUSE;
					end if;
				end if;
			when others=> stm<=PAUSE;
			end case;

		end if; --# clk_ce
	end if;
end process;	
wr<=s_wr when fifofull='0' else '0';	


end ce2wr_filter;
