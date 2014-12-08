-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_syn_atl_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_syn_atl_arc_rtl.vhd,v $
--
-- $Revision: 1.9 $
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.auk_rs_fun_pkg.all;
library altera_mf;
use altera_mf.altera_mf_components.all;


Architecture rtl of auk_rs_syn_atl is


Constant errs : NATURAL := check / 2;

Constant gf_n_max : NATURAL := 2**m-1;
--Constant log2m   : NATURAL := log2_ceil_table(m+1);
--constant two_pow_m		: NATURAL := 2**m;

Constant alpha_to_power: NATURAL_ARRAY(gf_n_max downto 0) := 
         generate_gf_alpha_to_power (m => m, irrpol => irrpol);

Constant index_of_alpha: NATURAL_ARRAY(gf_n_max downto 0) := 
			 	 generate_gf_index_of_alpha (alpha_to_power => alpha_to_power);

Constant roots: NATURAL_ARRAY(check downto 1) :=
				 generate_roots (m => m, check => check, genstart => genstart, rootspace => rootspace,
												 Index_of => index_of_alpha, alpha_to_power => alpha_to_power);

Constant first_root_index : NATURAL := (rootspace*(n-1)) mod gf_n_max;

Constant first_rootpos: Std_Logic_Vector(m downto 1) := 
                        --natural_2_m(arg => alpha_to_power(first_root_index), size => m);
												CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => alpha_to_power(first_root_index), SIZE => m), SIZE => m);

Constant rootspace_inv_nat: NATURAL :=
         GFdiv (A => 1, D => alpha_to_power(rootspace), Index_of => index_of_alpha, alpha_to_power => alpha_to_power);

--Constant rootspace_inv: Std_Logic_Vector(m downto 1) := 
--												CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => rootspace_inv_nat, SIZE => m), SIZE => m);
												 
--Constant num_bit_err_matrix : std_logic_matrix(two_pow_m downto 1, m+log2m downto 1) := 
--				 gen_num_bit_errors(m => m);

COMPONENT auk_rs_gfmul_cnt
	generic (
		m: 		natural := 8;		-- Bits per word
		irrpol:	natural := 285;
		b_cnt:	natural := 16
	);
    port (
		a:		in		std_logic_vector (m downto 1);
		c:			out	std_logic_vector (m downto 1)
    );
END COMPONENT;

Subtype vector_m is Std_Logic_Vector(m downto 1);
type matrix_m is array(NATURAL RANGE <>) of vector_m;

signal multroot, rootpos_d, rootpos_q, first_rootpos_rom : Std_Logic_Vector(m downto 1);
signal reg_q, synin, mulout, sh_alpha : matrix_m(check downto 1);

signal ena_int, start_syn_int : std_logic;

begin

ena_int <= ena;
-- still remains to sort out what happens if sink_eop comes along 
-- and bms is not yet ready  -> that has been sorted in mem block with controller
start_syn_int <= sink_sop_q;

g1: For K in 1 to check generate

	reg : Process (clk, reset)
	begin
	if reset='1' then
		reg_q(k)(m downto 1) <= (others => '0');
	elsif Rising_edge(clk) then
		if ena_int='1' then
			reg_q(k)(m downto 1) <= synin(k)(m downto 1);
		end if;
	end if;
	end process reg;

	synin(k)(m downto 1) <= rsin xor (mulout(k)(m downto 1) and (m downto 1 => not start_syn_int));

	gf_mul1: auk_rs_gfmul_cnt	generic map	(m=>m, irrpol=>irrpol, b_cnt => roots(K))
				port map	(a => reg_q(K)(m downto 1), c => mulout(K)(m downto 1));

end generate g1;

connect: For k in 1 to check generate
		syn(k)(m downto 1) <= synin(k)(m downto 1);
		eras_roots(k)(m downto 1) <= sh_alpha(k)(m downto 1);
		-- for readability in simulation and to avoid warnings 
		-- in unencrypted synthesis
		gr : If M_max > m generate
			syn(k)(M_max downto m+1) <= (others => '0');
			eras_roots(k)(M_max downto m+1) <= (others => '0');
		end generate gr;
end generate connect;


-------
-- Erasures processing
---------

Erasures_proc: if Erasures="true" generate 

gf_mul2: auk_rs_gfmul_cnt	generic map	(m=>m, irrpol=>irrpol, b_cnt => rootspace_inv_nat)
				port map	(a => rootpos_q, c => multroot);

non_variable: if Varcheck="false" generate
	rootpos_d <= (first_rootpos and (m downto 1 => start_syn_int)) or
							 (multroot and (m downto 1 => not start_syn_int));
end generate non_variable;

---------
-- in varcheck="true"

is_variable: if Varcheck="true" generate

rootpos_d <= (first_rootpos_rom and (m downto 1 => start_syn_int)) or
							 (multroot and (m downto 1 => not start_syn_int));

rom: altsyncram 
   GENERIC map (
      operation_mode => "ROM", 
      width_a => m, 
      widthad_a => m,
			numwords_a => 2**m,
      outdata_reg_a => "UNREGISTERED", 
      --address_aclr_a => "NONE",
      outdata_aclr_a => "UNUSED", 
			width_byteena_a => 1,
      init_file => first_alpha_file, 
      lpm_type => "altsyncram")
   PORT map (
      address_a => numn, clock0 => clk,
      clocken0 => sink_sop, --ena_int, --aclr0 => reset,
      q_a => first_rootpos_rom );
			
end generate is_variable;
			----------------------
			
rootpos : Process (clk, reset)
begin
if reset='1' then
	rootpos_q <= (others => '0');
elsif Rising_edge(clk) then
  if ena_int='1' then
	  rootpos_q <= rootpos_d;
	end if;
end if;
end process rootpos;

cnt_eras : Process (clk, reset)
begin
	if reset='1' then
		num_eras <= (others => '0');
	elsif Rising_edge(clk) then
		--if ena_int='1' then
		if ena_q='1' then
			if eras_sym='1' and start_syn_int='0' then
				num_eras <= unsigned(num_eras) + natural(1);
			elsif eras_sym='1' and start_syn_int='1' then
				num_eras(1) <= '1'; --vector_one_wide;
				num_eras(wide downto 2) <= (others => '0');
			elsif eras_sym='0' and start_syn_int='1' then
				num_eras <= (others => '0');
			end if;		
		end if;
	end if;
end process cnt_eras;

sh_reg1 : process(clk, reset)
begin
	if reset='1' then
		sh_alpha <= (others => (others => '0'));
	elsif Rising_edge(clk) then
		--if ena_int='1' then
		if ena_q='1' then
			if eras_sym='1' then
				sh_alpha(1) <= rootpos_d; --rootpos_q
			elsif eras_sym='0' and start_syn_int='1' then
				sh_alpha(1) <= (others => '0');
			end if;
			if eras_sym='1' and start_syn_int='0' then
				sh_alpha(check downto 2) <= sh_alpha(check-1 downto 1);
			elsif start_syn_int='1' then
				sh_alpha(check downto 2) <= (others => (others => '0'));
			end if;
		end if;
	end if;
end process sh_reg1;

end generate Erasures_proc;

end architecture rtl;
