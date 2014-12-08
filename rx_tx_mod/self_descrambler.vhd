library ieee; 
use ieee.std_logic_1164.all;

entity self_descrambler is 
  generic(
	SWITCH_OFF:integer:=0
  );
  port ( 
	clk : in std_logic;
	reset : in std_logic;
	mux_ce : in std_logic;
	data_in : in std_logic_vector (7 downto 0);    
    data_out : out std_logic_vector (7 downto 0)
  );
end self_descrambler;

architecture self_descrambler of self_descrambler is	
  signal lfsr_c: std_logic_vector (23 downto 0);	
  signal test_cnt:integer;
begin	


    process (clk)  
	variable xored:std_logic;
    begin
      if rising_edge(clk) then 
		if reset='1' then
			lfsr_c<=(others=>'0');
			test_cnt<=0;
		else --# reset
			if SWITCH_OFF=1 then
				data_out<=data_in;
			else --# SWITCH_OFF
				if mux_ce='0' then
					data_out<=data_in;
					test_cnt<=0;
				else
					test_cnt<=test_cnt+1;
					for i in 0 to data_in'Length-1 loop
					xored:=lfsr_c(23) xor lfsr_c(18) xor data_in(i);  --# polinom here
					data_out(i)<=xored;
					lfsr_c<=lfsr_c(lfsr_c'Length-2 downto 0)&data_in(i);
					end loop;
				end if;
			end if; --# SWITCH_OFF
		end if; --# reset
      end if; 
    end process; 
end architecture self_descrambler; 