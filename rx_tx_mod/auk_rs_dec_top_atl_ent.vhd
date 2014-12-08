-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_dec_top_atl_ent.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_dec_top_atl_ent.vhd,v $
--
-- $Revision: 1.6 $
-- $Date: 2005/03/17 14:50:30 $
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


Entity auk_rs_dec_top_atl is
	Generic (
		n				:		NATURAL :=  63;
		check		:		NATURAL :=  4;
		m				:		NATURAL :=  6;
		irrpol	:		NATURAL := 67;
		genstart:		NATURAL :=  0;
		rootspace :   NATURAL :=  1;
		keysize		:		STRING;
		Erasures : STRING := "false";
		Varcheck : STRING := "false";
		wide		: NATURAL := 3;
		bitwide : NATURAL := 5;
		inv_file		: STRING := "inv_6_67.hex";
		first_alpha_file	: STRING := "alpha_6_67_1.hex";
		rserr_connect	: STRING := "true";
		err_bit_connect	: STRING := "split_count"  --  "split_count, full_count or false"
	);	
	Port (
		clk : in Std_Logic;
		reset : in Std_Logic;
		bypass : in Std_Logic;
		numcheck:		in    Std_Logic_Vector(wide downto 1);
		numn:				in    Std_Logic_Vector(m downto 1);
		rsin : in Std_Logic_Vector(m downto 1);
		eras_sym : in std_logic;
		
		sink_ena 				: out Std_Logic; 
		sink_val        : in  Std_Logic; 
		sink_sop        : in  Std_Logic; 
		sink_eop        : in  Std_Logic;
		
		rsout : out Std_Logic_Vector(m downto 1);
		rserr : out Std_Logic_Vector(m downto 1);
		num_err_sym  : out Std_Logic_Vector(wide downto 1);
		num_err_bit  : out Std_Logic_Vector(bitwide downto 1);
		num_err_bit0 : out Std_Logic_Vector(bitwide downto 1);
		num_err_bit1 : out Std_Logic_Vector(bitwide downto 1);

		decfail : out Std_Logic;
		-- Slave source side control signals
		source_ena : in Std_Logic; 
		source_val : out Std_Logic; 
		source_sop : out Std_Logic; 
		source_eop : out Std_Logic);
end entity auk_rs_dec_top_atl;
