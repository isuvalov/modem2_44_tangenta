library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.std_logic_arith.all;


entity show_frame_error is
	 port(
	 	 clk : in std_logic;
		 ce : in std_logic;
		 dv : in std_logic;
		 data : in std_logic_vector(7 downto 0);
		 error: out std_logic
	     );
end show_frame_error;


architecture show_frame_error of show_frame_error is

type Ttest_stm is (P_DELAY,P_FRAME,P_FLOWC,P_TEST_FLOWC);
signal test_stm:Ttest_stm:=P_DELAY;
signal f_number,f_data:std_logic_vector(7 downto 0):=(others=>'0');
signal p_test_err:std_logic;

begin

process(clk) is
begin
	if rising_edge(clk) then
		if ce='1' then
		 case test_stm is 
		 when P_DELAY=>
			if dv='1' then
				if data/=x"55" then
					if f_number+1/=data then
						f_number<=data;
						p_test_err<='1';
					else
						f_number<=f_number+1;
						p_test_err<='0';					
					end if;
					test_stm<=P_FRAME;
				else
				    test_stm<=P_TEST_FLOWC;
				end if;
			end if;
		 when P_TEST_FLOWC=>
			if dv='1' then
				if data=x"55" then
					test_stm<=P_FLOWC;	
					p_test_err<='0';
				else
					f_number<=f_number+1;
					if f_data+1/=data then
						f_data<=data;
						p_test_err<='1';
					else
						f_data<=f_data+1;
						p_test_err<='0';
					end if;
					test_stm<=P_FRAME;
				end if;
			else
				p_test_err<='1';
				test_stm<=P_DELAY;
			end if;
		 when P_FLOWC=>
			if dv='0' then
				test_stm<=P_DELAY;
			end if;
			p_test_err<='0';
		 when P_FRAME=>
			if dv='1' then
				if f_data+1/=data then
					f_data<=data;
					p_test_err<='1';
				else
					f_data<=f_data+1;
					p_test_err<='0';
				end if;
			else
				test_stm<=P_DELAY;
				p_test_err<='0';
			end if;
		when others=>
		end case;
		end if;
	end if;
end process;

error<=p_test_err;

end show_frame_error;
