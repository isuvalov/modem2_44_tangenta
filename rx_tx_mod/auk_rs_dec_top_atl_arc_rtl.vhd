-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_dec_top_atl_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_dec_top_atl_arc_rtl.vhd,v $
--
-- $Revision: 1.16 $
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



library ieee;
use ieee.std_logic_1164.all;
library work;
use work.auk_rs_fun_pkg.all;


Architecture rtl of auk_rs_dec_top_atl is


Constant errs : NATURAL := calc_errs(check, Erasures); --check/2;

COMPONENT auk_rs_syn_atl
	Generic (
		n, check, m, irrpol, genstart, rootspace, wide : NATURAL;
		Erasures : STRING;
		Varcheck : STRING;
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
END COMPONENT;


Component auk_rs_bms_atl
	Generic (
		m, check, irrpol, wide, errs: NATURAL;
		Varcheck : STRING := "false";
		INV_FILE : STRING
	);
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
End Component;


COMPONENT auk_rs_chn_atl
	generic (check, m, irrpol, genstart, rootspace, errs : NATURAL;
					INV_FILE : STRING);
	port ( clk, ena, reset, load_chn: in Std_Logic;
				bd, omega : in vector_2D(errs downto 1);
				errvec : out Std_Logic_Vector(m downto 1);
				polyz : out Std_Logic
				
			);
END COMPONENT;


COMPONENT auk_rs_mem_atl
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
END COMPONENT;


signal synvec, eras_roots : vector_2D(check downto 1);
signal bdhold_d, omegahold_d : vector_2D(errs downto 1);
signal errvec, rsin_q, rsin_shunt : Std_Logic_Vector(m downto 1);
signal numerr_int : Std_Logic_Vector(wide downto 1);
signal load_syn, bypass_q : Std_Logic;
signal polyzero, ena_syn, ena_bms, ena_chn : Std_Logic;
Signal sink_sop_q, sink_eop_q, sink_val_q, sink_sop_shunt : Std_Logic;
Signal bms_done, load_chn, bms_clear : std_logic;
Signal num_eras, numcheck_q, numcheck_bms : Std_Logic_Vector(wide downto 1);
Signal numn_q : Std_Logic_Vector(m downto 1);
Signal eras_sym_shunt, eras_sym_q, ena_syn_q : std_logic;


begin

clk_atl: Process (clk, reset)
	begin
	if reset='1' then
		sink_sop_q <= '0';
		sink_sop_shunt <= '0';
		sink_eop_q <= '0';
		sink_val_q <= '0';
		-- strange !! I left this ... It worked in Quartus but it wouldn't
		--compile in modelsim!! 
		--sink_val_shunt <= '0';
		eras_sym_shunt <= '0';
		eras_sym_q <= '0';
		bypass_q <= '0';
		rsin_q <= (others => '0');
		rsin_shunt <= (others => '0');
	elsif Rising_edge(clk) then
		if ena_syn='1' then
			rsin_q <= (rsin and (m downto 1 => sink_val)) or (rsin_shunt and (m downto 1 => not sink_val));
			eras_sym_q <= (eras_sym and sink_val) or (eras_sym_shunt and not sink_val);
			sink_sop_q <= (sink_sop and sink_val) or (sink_sop_shunt and not sink_val);
		end if;
		if sink_val='1' then
			eras_sym_shunt <= eras_sym;
			rsin_shunt <= rsin;
			sink_sop_shunt <= sink_sop;
		end if;
		if sink_val='1' then
		  --sink_sop_q <= sink_sop;
		  sink_eop_q <= sink_eop;
		else
			--sink_sop_q <= '0';
		  sink_eop_q <= '0';
		end if;
		if sink_sop='1' and sink_val='1' then
			bypass_q <= bypass;
		end if;
		sink_val_q <= sink_val;
	end if;

end process clk_atl;

if_var: if Varcheck="true" generate

	clk_numcheck: Process (clk, reset)
		begin
		if reset='1' then
			numcheck_q <= (others => '0');
		elsif Rising_edge(clk) then
			if sink_sop='1' and sink_val='1' then
				numcheck_q <= numcheck;
			end if;
		end if;
	end process clk_numcheck;
	
	if_eras: if Erasures="true" generate
		clk_numn: Process (clk, reset)
			begin
			if reset='1' then
				numn_q <= (others => '0');
			elsif Rising_edge(clk) then
				if sink_sop='1' and sink_val='1' then
					numn_q <= numn;
				end if;
			end if;
		end process clk_numn;
	end generate if_eras;

end generate if_var;


syn: auk_rs_syn_atl
	Generic map (n => n, check => check, m => m, irrpol => irrpol, genstart => genstart,
	             rootspace => rootspace, wide => wide,
							 first_alpha_file => first_alpha_file,
							 Erasures => Erasures, Varcheck => Varcheck)
	Port map (
		clk => clk, ena => ena_syn, ena_q => ena_syn_q, reset => reset,
		eras_sym => eras_sym_q,
		sink_val => sink_val_q,
		sink_sop => sink_sop,
		sink_sop_q => sink_sop_q, 
		sink_eop => sink_eop_q,
		num_eras => num_eras,
		--numn => numn_q,
		numn => numn,
		rsin => rsin_q,	syn => synvec,
		eras_roots => eras_roots);

key_half: if (keysize = "half") and (check>3) and (Erasures="false") generate
	key: entity work.auk_rs_bms_atl(hal_rtl)
	Generic map (m => m, check => check, irrpol => irrpol, wide => wide, errs => errs,
	             INV_FILE => INV_FILE, Varcheck => Varcheck)
	Port map (
		clk => clk, ena => ena_bms, ena_ng => ena_bms, reset => reset, 
		load_syn => load_syn,	bms_clear => bms_clear, load_chn => load_chn,
		bms_done => bms_done, numcheck => numcheck_bms,
		syn => synvec, num_eras => num_eras, eras_pos => eras_roots,	
		bdout => bdhold_d, omegaout => omegahold_d,
		numerr => numerr_int);
end generate key_half;
key_full: if ((keysize = "full") or (check<4)) and (Erasures="false") generate
	key: entity work.auk_rs_bms_atl(ful_rtl)
	Generic map (m => m, check => check, irrpol => irrpol, wide => wide, errs => errs,
	             INV_FILE => INV_FILE, Varcheck => Varcheck )
	Port map (
		clk => clk, ena => ena_bms, ena_ng => ena_bms, reset => reset, 
		load_syn => load_syn,	bms_clear => bms_clear, load_chn => load_chn,
		bms_done => bms_done, numcheck => numcheck_bms,
		syn => synvec, num_eras => num_eras, eras_pos => eras_roots,
		bdout => bdhold_d, omegaout => omegahold_d,
		numerr => numerr_int);
end generate key_full;

key_half_eras: if (keysize = "half") and (Erasures="true") generate
	key: entity work.auk_rs_bms_atl(hal_era_rtl)
	Generic map (m => m, check => check, irrpol => irrpol, wide => wide, errs => errs,
	             INV_FILE => INV_FILE, Varcheck => Varcheck)
	Port map (
		clk => clk, ena => ena_bms, ena_ng => ena_bms, reset => reset, 
		load_syn => load_syn,	bms_clear => bms_clear, load_chn => load_chn,
		bms_done => bms_done, numcheck => numcheck_bms,
		syn => synvec, num_eras => num_eras, eras_pos => eras_roots,
		bdout => bdhold_d, omegaout => omegahold_d,
		numerr => numerr_int);
end generate key_half_eras;
key_full_eras: if (keysize = "full") and (Erasures="true") generate
	key: entity work.auk_rs_bms_atl(ful_era_rtl)
	Generic map (m => m, check => check, irrpol => irrpol, wide => wide, errs => errs,
	             INV_FILE => INV_FILE, Varcheck => Varcheck )
	Port map (
		clk => clk, ena => ena_bms, ena_ng => ena_bms, reset => reset, 
		load_syn => load_syn,	bms_clear => bms_clear, load_chn => load_chn,
		bms_done => bms_done, numcheck => numcheck_bms,
		syn => synvec, num_eras => num_eras, eras_pos => eras_roots,
		bdout => bdhold_d, omegaout => omegahold_d,
		numerr => numerr_int);
end generate key_full_eras;

-- coverage off
g_error: if ((keysize /= "half") and (keysize /= "full")) generate
	assert FALSE
		report "Bad keysize parameter specification. It should be half or full."
		severity Error;
end generate g_error;
-- coverage on

chnr: auk_rs_chn_atl
	generic map (check => check, m => m, irrpol => irrpol, genstart => genstart,
	             errs => errs, rootspace => rootspace, INV_FILE => INV_FILE)
	port map ( clk => clk, ena => ena_chn, reset => reset, load_chn => load_chn,
				bd => bdhold_d, omega => omegahold_d,	errvec => errvec,
				polyz => polyzero );


mem_ctrl : auk_rs_mem_atl
	Generic map (
		m => m, wide => wide, bitwide => bitwide, Varcheck => Varcheck,
		rserr_connect => rserr_connect, err_bit_connect => err_bit_connect) 
	Port map (
		clk => clk, reset => reset, 
		bypass => bypass_q,
		polyzero => polyzero,
		numcheck => numcheck_q,
		numcheck_bms => numcheck_bms, 
		sink_ena_master => sink_ena,
		sink_val_q => sink_val_q, 
		sink_sop_q => sink_sop_q, 
		sink_eop_q => sink_eop_q,
		sink_val => sink_val, 
		sink_sop => sink_sop, 
		sink_eop => sink_eop,
		bms_done => bms_done,
		numerr_bms => numerr_int,
		rsin => rsin_q,	
		errvec => errvec,
		load_syn => load_syn,
		bms_clear => bms_clear,
		load_chn => load_chn,
		ena_syn => ena_syn,
		ena_syn_q => ena_syn_q,
		ena_bms => ena_bms,
		ena_chn => ena_chn,
		rsout => rsout,
		rserr => rserr,
		num_err_sym => num_err_sym,
		num_err_bit => num_err_bit,
		num_err_bit0 => num_err_bit0,
		num_err_bit1 => num_err_bit1,
		source_ena => source_ena, 
		source_val => source_val, 
		source_sop => source_sop, 
		source_eop => source_eop,
		decfail => decfail );

end architecture rtl;	
