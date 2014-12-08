 library IEEE;
 use IEEE.STD_LOGIC_1164.ALL;
 use IEEE.STD_LOGIC_ARITH.ALL;
 use IEEE.STD_LOGIC_UNSIGNED.ALL;
  
  
  entity ext_pll_set is
	port(
	
		enable:in std_logic;
		clk	:in std_logic;
		
		SDA	:out std_logic;
		SCK	:out std_logic
		);
	end entity;
	
	
	architecture ext_pll_set of ext_pll_set is
	
	constant addr : std_logic_vector (7 downto 0) := x"08";
	constant f_range : std_logic_vector (1 downto 0) := b"00";
	constant d_rate : std_logic_vector (3 downto 0) := b"0000";
	constant m_dr : std_logic := '1';
	constant lock : std_logic := '1';

	type select_byte is (first, two, three);
	signal sel_byte	:select_byte;
	
	signal clk_out	: std_logic := '1';
	signal end_d	: std_logic	:= '0';
	signal bgn_sck : std_logic := '0';
	
	begin
	
	---------process down frequency----------
	process(clk)
	
	variable clk_div	:std_logic_vector (3 downto 0) := x"0";
	
	begin
		if rising_edge(clk) then		
			if (enable = '1') then
				if (end_d = '0') then
						clk_div := clk_div+1;
						clk_out <= clk_div(3);
						SCK <= clk_out;
				else 
					SCK <= '1';
				end if;
			end if;
		end if;
	end process;
			
	
	---------download registers------------
	process(clk_out)
	
	variable data_send :std_logic_vector(7 downto 0) := x"00";
	variable cnt_pulse :std_logic_vector(3 downto 0) :=b"0000";
		
		
	begin
	
		if (enable = '1') then
			if rising_edge (clk_out) then
				
				case sel_byte is
				--send addr pll 8 bit and ack 1 bit--
				when first =>  if (cnt_pulse = x"8") then
										cnt_pulse := x"0";
										sel_byte <= two;
									else
										SDA <= '0';
										cnt_pulse := cnt_pulse +1;
									end if;
									
				--send addr reg CLKA--					
				when two =>		if (cnt_pulse = x"8") then
										cnt_pulse := x"0";
										sel_byte <= three;
									else
										if (cnt_pulse = x"4") then
											SDA <= '1';
											cnt_pulse := cnt_pulse +1;
										else
											SDA <= '0';
											cnt_pulse := cnt_pulse +1;
										end if;
									end if;
									
				
				--send data--
				when three =>	if (cnt_pulse = x"9") then
										cnt_pulse := x"0";
										sel_byte <= first;
										SDA <= '1';
										end_d <= '1';
									else 
										if (cnt_pulse = x"6" or cnt_pulse = x"7") then
											SDA <= '1';
											cnt_pulse := cnt_pulse +1;
										else
											SDA <='0';
											cnt_pulse := cnt_pulse +1;
										end if;
									end if;
									
				end case;
				
			end if;
		end if;
	end process;
	
end ext_pll_set;
										
				
				
			
			
			
			
			
			
			
	
	
	
	
	
	