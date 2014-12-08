library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity frame_filter is
	 port(
	 	 clk : in std_logic;
	 	 dv_i : in std_logic;
		 datain : in std_logic_vector(7 downto 0);
		 dv_o : out std_logic;
		 dataout : out std_logic_vector(7 downto 0)
	     );
end frame_filter;


architecture frame_filter of frame_filter is

 constant MIN_FRAME_LEN:natural:=64;
 constant PIPELINE_LEN:natural:=3;
 signal dv_array:std_logic_vector(PIPELINE_LEN+MIN_FRAME_LEN-1 downto 0);
 type Tmem is array(0 to PIPELINE_LEN+MIN_FRAME_LEN-1) of std_logic_vector(7 downto 0);
 signal mem:Tmem;

 type Tsum_a is array(0 to 15) of std_logic_vector(2 downto 0);
 signal sum_a:Tsum_a;
 type Tsum_b is array(0 to 3) of std_logic_vector(2+2 downto 0);
 signal sum_b:Tsum_b;
 signal sum_c,local_cnt:std_logic_vector(2+4 downto 0):=(others=>'0');
 signal action:std_logic;
 signal muxed_dv:std_logic;
begin
	
process (clk) is
begin		
	if rising_edge(clk) then

		if dv_i='0' then
			local_cnt<=(others=>'0');
			if unsigned(local_cnt)<64 and unsigned(local_cnt)>0 then
				for i in 0 to PIPELINE_LEN+MIN_FRAME_LEN-3 loop
					if i=local_cnt then
						dv_array(i+2 downto 0)<=(others=>'0');
					end if;
				end loop;
				if unsigned(local_cnt)>0 then
					action<='1';
				else
					action<='0';
				end if;
			else
				action<='0';
				dv_array<=dv_array(dv_array'Length-2 downto 0)&dv_i;
			end if;
		else
			action<='0';
			if unsigned(local_cnt)<64 then
				local_cnt<=local_cnt+1;
			end if;
			dv_array<=dv_array(dv_array'Length-2 downto 0)&dv_i;
		end if;

		mem(0)<=datain;
        for i in 1 to PIPELINE_LEN+MIN_FRAME_LEN-1 loop
			mem(i)<=mem(i-1);
		end loop;
	

        dataout<=mem(PIPELINE_LEN+MIN_FRAME_LEN-1);
        dv_o<=dv_array(PIPELINE_LEN+MIN_FRAME_LEN-1);
	end if;
end process;

end frame_filter;
