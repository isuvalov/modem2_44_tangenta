-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_chn_atl_ent.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_chn_atl_ent.vhd,v $
--
-- $Revision: 1.3 $
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


Entity auk_rs_chn_atl is
	generic (check, m, irrpol, genstart, rootspace, errs : NATURAL;
					INV_FILE : STRING);
	port ( clk, ena, reset, load_chn: in Std_Logic;
				bd, omega : in vector_2D(errs downto 1);
				errvec : out Std_Logic_Vector(m downto 1);
				polyz : out Std_Logic
				
			);
end entity auk_rs_chn_atl;	
