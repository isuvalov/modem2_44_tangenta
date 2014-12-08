-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_gfmul_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Common_units/auk_rs_gfmul_arc_rtl.vhd,v $
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
use ieee.std_logic_arith.all;
--library ReedS;
--use ReedS.rs_functions.all;


architecture rtl of auk_rs_gfmul is

Constant	irpc: std_logic_vector(m+1 downto 1) :=
  CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => irrpol, SIZE => m+1), SIZE => m+1); 
--natural_2_m(arg => irrpol, size=> m+1);

Subtype Vector_2m is std_logic_vector(((2*m)-1) downto 1);

type	expand_type is array (natural range <>) of Vector_2m;
type	temp_bk_t is array (natural range <>) of std_logic_vector(m downto 1);
type	extra_t is array ((m-1) downto 1) of std_logic_vector((m+1) downto 1);


begin

logic: process(a, b)

variable expand:			expand_type(m downto 2);
variable temp_bk:		temp_bk_t(m downto 2);
variable total:	expand_type(m downto 1);
variable reduce:	expand_type((m-1) downto 1);
variable extra, temp_reduce:	extra_t;
variable left: std_logic_vector((m-1) downto 1);
variable temp_b1:	std_logic_vector (m downto 1);
variable temp_total:	std_logic_vector((m+1) downto 1);
	
begin


left := (others=>'0');
temp_b1	:= (others => b(1));
total(1) := left & (a and temp_b1);

g1: for k in 2 to m loop

	if (k < m) then
		for j in (k+m) to ((2*m)-1) loop
			expand(k)(j) := '0';
		end loop;
	end if;
	for j in 1 to (k-1) loop
		expand(k)(j) := '0';
	end loop;
	temp_bk(k) := (others => b(k));
	expand(k)((k+m-1) downto k)	:= a and temp_bk(k);
	for j in 1 to ((2*m)-1) loop
		total(k)(j) := expand(k)(j) xor total(k-1)(j);
	end loop;
end loop g1;

temp_total	:= (others=>total(m)((2*m)-1));

g2: for k in 1 to (m-1) loop
	if (k = 1) then
		extra(k) := irpc and temp_total;
		for j in 1 to (m-2) loop
			reduce(1)(j) := total(m)(j);
		end loop;
		for j in (m-1) to ((2*m)-1) loop
			reduce(k)(j) := total(m)(j) xor extra(1)(j-(m-2));
		end loop;
	end if;
	if (k > 1) then
		temp_reduce(k)	:=	(others=>reduce(k-1)((2*m)-k));
		extra(k) := irpc and temp_reduce(k);
		for j in (m-k) to ((2*m)-k) loop
			reduce(k)(j) := extra(k)(j-(m-1)+k) xor reduce(k-1)(j);
		end loop;
		reduce(k)((2*m)-k) := '0' and reduce(k-1)((2*m)-1);
		for j in ((2*m)-k+1) to ((2*m)-1) loop
			reduce(k)(j) := '0' and reduce(k)(j-1);
		end loop;
	end if;
	if (k < (m-1) and k/=1) then
		for j in 1 to ((m-1) - k) loop
			reduce(k)(j) := reduce(k-1)(j);
		end loop;
	end if;

end loop g2;

c(m downto 2)	<= reduce(m-1)(m downto 2);
c(1)			<= reduce(m-1)(1) or reduce(m-1)((2*m)-1);

	
end process logic;

end rtl;
