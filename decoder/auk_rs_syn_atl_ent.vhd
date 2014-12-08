-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_syn_atl_ent.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_syn_atl_ent.vhd,v $
--
-- $Revision: 1.7 $
-- $Date: 2005/08/26 11:53:05 $
-- Check in by  :  $Author: admanero $
-- Author  			:  Alejandro Diaz-Manero
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

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.auk_rs_fun_pkg.all;

Entity auk_rs_syn_atl is
	Generic (
		n, check, m, irrpol, genstart, rootspace, wide : NATURAL;
		Erasures : STRING := "false";
		Varcheck : STRING := "false";
		first_alpha_file	: STRING := "alpha_6_67_1.hex"
	);
	Port (
		clk, ena, ena_q, reset : in Std_Logic;
		eras_sym        : in std_logic;
		sink_val        : in  Std_Logic; 
		sink_sop, sink_sop_q  : in  Std_Logic; 
		sink_eop        : in  Std_Logic;
		rsin : in Std_Logic_Vector(m downto 1);
		numn:				in    Std_Logic_Vector(m downto 1);
		num_eras : buffer Std_Logic_Vector(wide downto 1);
		syn, eras_roots : out Vector_2D(check downto 1)
	);	
end entity auk_rs_syn_atl;	
