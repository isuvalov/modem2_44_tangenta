----------------------------------------------------------
-- Company:   		DOK ltd.
-- Engineer:  		Sergey Petrov
-- Create Date:    	16.sep.2010
-- Module Name:    	Device_manager
-- Project Name:   	DDS_Radar_Controller
-- Target Devices: 	Altera Cyclone III 	 
-- Description:  	Manager device process
-- Revisions: 
-- Revision 0.01 - File Created 
-- Additional Comments: 
----------------------------------------------------------

  library IEEE;
  use IEEE.STD_LOGIC_1164.ALL;
  use IEEE.STD_LOGIC_ARITH.ALL;
  use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Device_manager is

port (Clk     	   : in  std_logic;
	  RST          : out std_logic;
	  LAN_nRST     : out std_logic;
	  enable   	   : out std_logic;
	  pll_load     : out std_logic

	  );
end entity;

architecture beh of Device_manager is	

constant delay_en   : std_logic_vector (23 downto 0) := x"F000F0";		-- time to enable		 		x"F00000"
constant delay_rst  : std_logic_vector (23 downto 0) := x"800080";		-- time to RST; LAN_nRST 	x"800000"

signal p_en       : std_logic;
signal p_rst      : std_logic;	
signal p_pll      : std_logic;
signal p_work     : std_logic;															
																		
begin

         
init_p : process (Clk)
variable cnt_time : std_logic_vector (31 downto 0);
begin
    if rising_edge (Clk) then  
        if (p_en = '0') then
           cnt_time := cnt_time +1;
        end if;
    
        if   ((cnt_time > delay_rst) and (cnt_time < delay_rst + 10)) then
              p_rst <= '1';
        elsif (cnt_time = delay_en) then
              p_en  <= '1';
        else  p_en  <= '0'; 
              p_rst <= '0';  
        end if; 
            
    RST      <= p_rst;
    LAN_nRST <= not p_rst;    
    enable   <= p_en;     
    end if;         
end process;	

pll_load_p: process (clk)
variable cnt_pll: std_logic_vector(23 downto 0);
begin
     if(p_rst='1')then
	     p_work<='0';
     elsif rising_edge(clk) then
	     if((p_en='1')and(p_work='0')) then
		     cnt_pll:=cnt_pll +1;
	     end if;
		  
		  if((cnt_pll>x"F00000")and(cnt_pll<x"F00010")) then
		     p_pll <= '1';
		  elsif (cnt_pll=x"FF0000") then
	        p_work <= '1';	  
		  else 	  
		     p_pll <= '0';
		  end if;	  
	  pll_load <= p_pll;	  
     end if;
end process;


end beh;