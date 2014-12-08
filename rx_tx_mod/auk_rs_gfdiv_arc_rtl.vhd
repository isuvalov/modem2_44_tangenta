-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_gfdiv_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Common_units/auk_rs_gfdiv_arc_rtl.vhd,v $
--
-- $Revision: 1.5 $
-- $Date: 2005/04/01 20:11:08 $
-- Check in by 	 	 : $Author: admanero $
-- Author			:  Alejandro Diaz-Manero
--
-- Project      :  RS
--
-- Description	: 
--
-- ALTERA Confidential and Proprietary
-- Copyright 2004 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all; 
use IEEE.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;


architecture rtl of auk_rs_gfdiv is

COMPONENT auk_rs_gfmul
	generic (
		m: 		natural := 8;		-- Bits per word
		irrpol:	natural	:= 285
	);
    port (
		a, b:		in		std_logic_vector (m downto 1);
		c:			out	std_logic_vector (m downto 1)
    );
END COMPONENT;

Constant dev_family : STRING := "Cyclone III";

signal b_d,b_d2, b_q : Std_Logic_Vector(m downto 1); 

type Tinv_mem is array (0 to 255) of std_logic_vector(7 downto 0);
constant inv_mem:Tinv_mem:=(x"00",x"01",x"8E",x"F4",x"47",x"A7",x"7A",x"BA",x"AD",x"9D",x"DD",x"98",x"3D",x"AA",x"5D",x"96",x"D8",
x"72",x"C0",x"58",x"E0",x"3E",x"4C",x"66",x"90",x"DE",x"55",x"80",x"A0",x"83",x"4B",x"2A",x"6C",
x"ED",x"39",x"51",x"60",x"56",x"2C",x"8A",x"70",x"D0",x"1F",x"4A",x"26",x"8B",x"33",x"6E",x"48",
x"89",x"6F",x"2E",x"A4",x"C3",x"40",x"5E",x"50",x"22",x"CF",x"A9",x"AB",x"0C",x"15",x"E1",x"36",
x"5F",x"F8",x"D5",x"92",x"4E",x"A6",x"04",x"30",x"88",x"2B",x"1E",x"16",x"67",x"45",x"93",x"38",
x"23",x"68",x"8C",x"81",x"1A",x"25",x"61",x"13",x"C1",x"CB",x"63",x"97",x"0E",x"37",x"41",x"24",
x"57",x"CA",x"5B",x"B9",x"C4",x"17",x"4D",x"52",x"8D",x"EF",x"B3",x"20",x"EC",x"2F",x"32",x"28",
x"D1",x"11",x"D9",x"E9",x"FB",x"DA",x"79",x"DB",x"77",x"06",x"BB",x"84",x"CD",x"FE",x"FC",x"1B",
x"54",x"A1",x"1D",x"7C",x"CC",x"E4",x"B0",x"49",x"31",x"27",x"2D",x"53",x"69",x"02",x"F5",x"18",
x"DF",x"44",x"4F",x"9B",x"BC",x"0F",x"5C",x"0B",x"DC",x"BD",x"94",x"AC",x"09",x"C7",x"A2",x"1C",
x"82",x"9F",x"C6",x"34",x"C2",x"46",x"05",x"CE",x"3B",x"0D",x"3C",x"9C",x"08",x"BE",x"B7",x"87",
x"E5",x"EE",x"6B",x"EB",x"F2",x"BF",x"AF",x"C5",x"64",x"07",x"7B",x"95",x"9A",x"AE",x"B6",x"12",
x"59",x"A5",x"35",x"65",x"B8",x"A3",x"9E",x"D2",x"F7",x"62",x"5A",x"85",x"7D",x"A8",x"3A",x"29",
x"71",x"C8",x"F6",x"F9",x"43",x"D7",x"D6",x"10",x"73",x"76",x"78",x"99",x"0A",x"19",x"91",x"14",
x"3F",x"E6",x"F0",x"86",x"B1",x"E2",x"F1",x"FA",x"74",x"F3",x"B4",x"6D",x"21",x"B2",x"6A",x"E3",
x"E7",x"B5",x"EA",x"03",x"8F",x"D3",x"C9",x"42",x"D4",x"E8",x"75",x"7F",x"FF",x"7E",x"FD");

attribute ramstyle : string;
attribute ramstyle of inv_mem : constant is "M9K";

begin

rom: altsyncram 
   GENERIC map (
      operation_mode => "ROM", 
      width_a => m, 
      widthad_a => m,
			numwords_a => 2**m,
      outdata_reg_a => "UNREGISTERED", 
      --address_aclr_a => "CLEAR0",
      outdata_aclr_a => "NONE", 
			width_byteena_a => 1,
      init_file => inv_file, 
      intended_device_family => dev_family,
      lpm_type => "altsyncram")
   PORT map (
      address_a => d, clock0 => clk,
      clocken0 => ena_one, --aclr0 => reset,
      q_a => b_d );



b_reg : Process(clk, reset)
begin
if reset='1' then
  b_q <= (others => '0');
elsif Rising_edge(clk) then
	if ena_one='1' then
--		b_d<=inv_mem(conv_integer(d));
	end if;
  if ena_two='1' then
    b_q <= b_d;
  end if;
end if;
end process b_reg;          

gf_mul: auk_rs_gfmul	generic map (m => m, irrpol => irrpol	)
    		port map (a => a, b => b_q, c => c );	

end rtl;
