-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_mem_atl_ent.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_mem_atl_ent.vhd,v $
--
-- $Revision: 1.11 $
-- $Date: 2005/04/21 14:08:38 $
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

Entity auk_rs_mem_atl is
	Generic (
		m, wide, bitwide : NATURAL;
		Varcheck : STRING := "false";
		rserr_connect	: STRING := "true";
		err_bit_connect	: STRING := "split_count"
	);
	Port (
		clk, reset, bypass, polyzero : in Std_Logic;
		bms_done : in std_logic;
		numerr_bms, numcheck : in std_logic_vector(wide downto 1);
		numcheck_bms:		out Std_Logic_Vector(wide downto 1);
		sink_ena_master : out Std_Logic; 
		sink_val, sink_val_q : in  Std_Logic; 
		sink_sop, sink_sop_q : in  Std_Logic; 
		sink_eop, sink_eop_q : in  Std_Logic;
		rsin : in Std_Logic_Vector(m downto 1);
		errvec : in Std_Logic_Vector(m downto 1);
		load_syn, bms_clear, load_chn : out Std_Logic;
		ena_syn, ena_syn_q : out std_logic; 
		ena_bms, ena_chn : out std_logic;
		rsout, rserr : out Std_Logic_Vector(m downto 1);
		num_err_sym : out Std_Logic_Vector(wide downto 1);
		num_err_bit  : out Std_Logic_Vector(bitwide downto 1);
		num_err_bit0 : out Std_Logic_Vector(bitwide downto 1);
		num_err_bit1 : out Std_Logic_Vector(bitwide downto 1);
		source_ena : in Std_Logic; 
		source_val : out Std_Logic; 
		source_sop : out Std_Logic; 
		source_eop : out Std_Logic;
		decfail : out Std_Logic
	);	
end entity auk_rs_mem_atl;	
