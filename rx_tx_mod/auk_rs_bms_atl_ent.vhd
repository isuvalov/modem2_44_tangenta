-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_bms_atl_ent.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_bms_atl_ent.vhd,v $
--
-- $Revision: 1.6 $
-- $Date: 2005/08/26 11:53:05 $
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

library ieee;
use ieee.std_logic_1164.all;
library work;
use work.auk_rs_fun_pkg.all;


Entity auk_rs_bms_atl is
	Generic (
		m, check, irrpol, wide, errs: NATURAL;
		Varcheck : STRING := "false";
		INV_FILE : STRING );
	Port (
		clk, ena, ena_ng, reset : in std_logic; 
		load_syn, bms_clear, load_chn : in Std_Logic;
		numcheck:		in    Std_Logic_Vector(wide downto 1);
		syn : in vector_2D(check downto 1);
		num_eras : in Std_Logic_Vector(wide downto 1);
		eras_pos : in Vector_2D(check downto 1);
		bms_done : out std_logic;
		bdout : out vector_2D(errs downto 1);
		omegaout : out vector_2D(errs downto 1);
		numerr : out Std_Logic_Vector(wide downto 1)
	);	
end entity auk_rs_bms_atl;
