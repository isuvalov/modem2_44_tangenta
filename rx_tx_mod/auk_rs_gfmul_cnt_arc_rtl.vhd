-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_gfmul_cnt_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Common_units/auk_rs_gfmul_cnt_arc_rtl.vhd,v $
--
-- $Revision: 1.1 $
-- $Date: 2004/11/15 15:26:22 $
-- Check in by 	 	 : $Author: admanero $
-- Author			:  Alejandro Diaz-Manero
--
-- Project      :  RS
--
-- Description	: GF multiplier with one input constant
--     trying to see if it improves synthesis results
--
-- ALTERA Confidential and Proprietary
-- Copyright 2004 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;
--library ReedS;
--use ReedS.rs_functions.all;


architecture rtl of auk_rs_gfmul_cnt is

Constant	irr: std_logic_vector(m+1 downto 1) :=
	CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => irrpol, SIZE => m+1), SIZE => m+1); 
--natural_2_m(arg => irrpol, size=> m+1);
Constant	b_vec: std_logic_vector(m downto 1) := 
  CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => b_cnt, SIZE => m), SIZE => m);
--natural_2_m(arg => b_cnt, size=> m);


Subtype Vector_m_p_one is std_logic_vector(m+1 downto 1);
Subtype Vector_m is std_logic_vector(m downto 1);
type	vec_2d_nil is array (natural range <>) of Vector_m;
type	vec_2d_one is array (natural range <>) of Vector_m_p_one;


begin

logic : process(a)

	Variable lev, temp_c : vec_2d_nil(m downto 1);
	Variable temp : vec_2d_one(m downto 2);

begin
	lev(1)(m downto 1) := b_vec(m downto 1);

	fg1: For I in 2 to m loop

	  IF lev(I-1)(m) = '1' THEN
	    temp(I)(m+1 downto 1) := (lev(I-1)(m downto 1) & '0') xor irr(m+1 downto 1);
	    lev(I)(m downto 1) := temp(I)(m downto 1);
	  ELSE
			lev(I)(m downto 1) := (lev(I-1)(m-1 downto 1) & '0');
	  END IF;

	END loop fg1;

	temp_c(1)(m downto 1) := lev(1)(m downto 1) and (m downto 1 => a(1));
	fl2: For K in 2 to m loop
		temp_c(K)(m downto 1) := temp_c(K-1)(m downto 1) xor (lev(K)(m downto 1) and (m downto 1 => a(K)));
	end loop fl2;
	c(m downto 1) <= temp_c(m)(m downto 1);

end process logic;

end rtl;
