-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_gfmul_ent.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Common_units/auk_rs_gfmul_ent.vhd,v $
--
-- $Revision: 1.1 $
-- $Date: 2004/11/15 15:26:22 $
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


entity auk_rs_gfmul is
	generic (
		m: 		natural := 4;
		irrpol:	natural := 19
	);
    port (
		a, b:		in		std_logic_vector (m downto 1);
		c:			out	std_logic_vector (m downto 1)
    );
end auk_rs_gfmul;


