-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_enc_top_atl_ent.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Enc_atlantic/auk_rs_enc_top_atl_ent.vhd,v $
--
-- $Revision: 1.2 $
-- $Date: 2005/09/14 13:59:28 $
-- Check in by  :  $Author: admanero $
-- Author 			:  Alejandro Diaz-Manero
--
-- Project      :  RS
--
-- Description	:  Top entity declaration for RS Encoder (including variable)
--
-- ALTERA Confidential and Proprietary
-- Copyright 2004 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;


entity auk_rs_enc_top_atl is
	generic (
		n:		NATURAL	:= 255; -- to be obsoleted
		check:	NATURAL	:= 50; -- to string?
		m: 		NATURAL := 8;
		irrpol:	NATURAL	:= 285;
		genstart: NATURAL := 0;
		rootspace : NATURAL := 1;
		wide : NATURAL := 8;
		Varcheck : STRING := "false"
			);
    port (
		clk:				in 		std_logic;
		reset:			in		std_logic;
		rsin:				in		std_logic_vector (m downto 1);
		--
		sink_ena 				: out Std_Logic; 
		sink_val        : in  Std_Logic; 
		sink_sop        : in  Std_Logic; 
		sink_eop        : in  Std_Logic;
		--
		numcheck:		in    Std_Logic_Vector(wide downto 1);
		
		rsout:			out	std_logic_vector (m downto 1);
		source_ena : in Std_Logic; 
		source_val : out Std_Logic; 
		source_sop : out Std_Logic; 
		source_eop : out Std_Logic
    );
end entity auk_rs_enc_top_atl;


