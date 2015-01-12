library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;

entity tangenta_manager_master is
	 port(
		 reset: in std_logic;
		 clk : in std_logic;

		 time_of_work: in std_logic_vector(23 downto 0);
		 time_of_switchoff: in std_logic_vector(23 downto 0);
		 time_of_fake_translation: in std_logic_vector(23 downto 0);    --# time_of_switchoff >> time_of_fake_translation

		 tangenta_to_slave: out std_logic; --# Send it by RF. if it '0' we cut trafic. Stop work RF transiver on slave site
		 tangenta: out std_logic --# if it '0' we cut trafic. Stop work RF transiver
	     );
end tangenta_manager_master;


architecture tangenta_manager_master of tangenta_manager_master is

type Tstm is (WORKING,PRE_STOPING,STOPING);
signal stm:Tstm;
signal time_cnt:std_logic_vector(time_of_switchoff'Length-1 downto 0);
signal time_cnt_pre:std_logic_vector(10+2 downto 0);
signal s_tangenta,s_tangenta_to_slave:std_logic;

begin

process (clk) is
begin		
	if rising_edge(clk) then

		tangenta<=s_tangenta;
		tangenta_to_slave<=s_tangenta_to_slave;

		if reset='1' then
			time_cnt<=time_of_work;
			stm<=WORKING;
			s_tangenta<='1';
			s_tangenta_to_slave<='0';
		else --# reset
			case stm is
			when WORKING=>				
				time_cnt<=time_cnt-1;
				if time_cnt=0 then
					stm<=PRE_STOPING;
				end if;
                s_tangenta<='1';
				s_tangenta_to_slave<='0';
				time_cnt_pre<=(others=>'1');
			when PRE_STOPING=>
				if unsigned(time_cnt_pre)>0 then
					time_cnt_pre<=time_cnt_pre-1;					
				else
					stm<=STOPING;
				end if;
				s_tangenta_to_slave<='1';
				s_tangenta<='1';
				time_cnt<=time_of_switchoff-time_of_fake_translation;
			when STOPING=>
				s_tangenta<='0';
				s_tangenta_to_slave<='1';

				if unsigned(time_cnt)>0 then
					time_cnt<=time_cnt-1;
				else
					time_cnt<=time_of_work;
					stm<=WORKING;
				end if;
			end case;	
		end if; --# reset
	end if;
end process;



end tangenta_manager_master;
