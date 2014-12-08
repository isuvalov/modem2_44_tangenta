-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_chn_atl_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_chn_atl_arc_rtl.vhd,v $
--
-- $Revision: 1.10 $
-- $Date: 2005/10/03 09:02:18 $
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
--use ReedS.rs_interface.all;
use work.auk_rs_fun_pkg.all;


Architecture rtl of auk_rs_chn_atl is
	
	--Constant errs : NATURAL := check/2;
	Constant drv : NATURAL := errs/2 + (errs mod 2);
	Constant even : NATURAL := errs/2;
	constant errs_cut : NATURAL := Get_max_of_three(errs-1, 1, 0);
	-- size as n generic no longer needed
	--Constant size : NATURAL := log2_ceil_table(n+1);
	--Constant vector_one : Std_Logic_Vector(m downto 1) := natural_2_m(arg => 1, size => m);

	Constant gf_n_max : NATURAL := 2**m-1;

	Constant alpha_to_power: NATURAL_ARRAY(gf_n_max downto 0) := 
         	  generate_gf_alpha_to_power (m => m, irrpol => irrpol);

	Constant index_of_alpha: NATURAL_ARRAY(gf_n_max downto 0) := 
				 	 generate_gf_index_of_alpha (alpha_to_power => alpha_to_power);
	
	Constant negroots_nat : NATURAL_ARRAY(gf_n_max downto 0) := 
					 make_chain(size => gf_n_max, m => m, rootspace => rootspace,
					 						Index_of => index_of_alpha, alpha_to_power => alpha_to_power);

  -- oh no!! this function is using n, need to analyze why ... Otherwise I am a bit screwed up!!
	-- this constants are obsoleted and not used since I did some long time past enhancement 
	--I don't need this constant any more
	--Constant controots_nat : NATURAL_ARRAY(gf_n_max downto 0) := 
	--				 make_cont_exp(size => gf_n_max, m => m, n => n, rootspace => rootspace,
	--				 						Index_of => index_of_alpha, alpha_to_power => alpha_to_power);

	Constant negrootspacing_nat: NATURAL :=
         GFdiv (A => 1, D => alpha_to_power((genstart*rootspace) mod gf_n_max),
         				Index_of => index_of_alpha, alpha_to_power => alpha_to_power);

	Constant negrootspacing: Std_Logic_Vector(m downto 1) :=
		CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => negrootspacing_nat, SIZE => m), SIZE => m);
	--natural_2_m(arg => negrootspacing_nat, size=> m);


COMPONENT auk_rs_gfmul
	generic (
		m: 		natural := 8;		
		irrpol:	natural	:= 285
	);
    port (
		a, b:		in		std_logic_vector (m downto 1);
		c:			out		std_logic_vector (m downto 1)
    );
END COMPONENT;


COMPONENT auk_rs_gfmul_cnt
	generic (
		m: 		natural := 8;		
		irrpol:	natural := 285;
		b_cnt:	natural := 16
	);
    port (
		a:		in		std_logic_vector (m downto 1);
		c:			out	std_logic_vector (m downto 1)
    );
END COMPONENT;


COMPONENT auk_rs_gfdiv
	generic (
		m: 		natural := 8;		-- Bits per word
		irrpol:	natural	:= 285;
		INV_FILE : STRING := "inv_8_285.hex"
	);
    port (
    clk, ena_one, ena_two, reset : in Std_Logic;
		a, d:		in		std_logic_vector (m downto 1);
		c:			out	std_logic_vector (m downto 1)
    );
END COMPONENT;

Subtype vector_m is Std_Logic_Vector(m downto 1);
type matrix_m is array(NATURAL RANGE <>) of vector_m;

	signal reg_d, reg_q : matrix_m(errs downto 1);
	signal deldrv_q : Std_Logic_Vector(m downto 1);

	signal rootreg_d, rootreg_q, omega_one : Std_Logic_Vector(m downto 1);
	signal delroot : matrix_m(3 downto 1);
	signal rootmul, omadder_q, drvadder_shunt, drvadder_in : Std_Logic_Vector(m downto 1);
	
	signal mulout : matrix_m(errs downto 1);
	signal evadder : matrix_m(even downto 1);
	signal drvadder : matrix_m(drv downto 1);

	signal halfadd, poly, polyzero: Std_Logic_Vector(m downto 1);
	signal polyzero_del : Std_Logic_Vector(3 downto 1);
	
	-- eval signals
	signal omadder, omreg_d, omreg_q, omegamul: matrix_m(errs_cut downto 1);
	signal delom_d, delom_q, omadder_shunt : Std_Logic_Vector(m downto 1);

	signal divfield_d, divfield_q, vecfield : Std_Logic_Vector(m downto 1);
	signal delsync, start, load_chn_q_tail, polyz_shunt : Std_Logic;
	

begin 	

load_chn_reg : Process (clk, reset)
begin
if reset='1' then
	load_chn_q_tail <= '0';
elsif Rising_edge(clk) then
	if ena='1' and load_chn_q_tail='1' then
		load_chn_q_tail <= '0';
	elsif load_chn='1' and ena='0' then
		load_chn_q_tail <= '1';
	end if;
end if;
end process load_chn_reg;

start <= load_chn and not load_chn_q_tail;

g4: For K in 1 to errs generate
	reg_d(K)(m downto 1) <= (mulout(k)(m downto 1) and (m downto 1 => not start)) or
													 (bd(k)(m downto 1) and (m downto 1 => start));

	clk_reg : Process (clk, reset)
	begin
		if reset='1' then
			reg_q(k) <= (others => '0');
		elsif Rising_Edge(clk) then
			if (ena='1' and load_chn_q_tail='0') or start='1' then
		  	reg_q(k) <= reg_d(k);
			end if;
		end if;
	end process clk_reg;
end generate g4;

g5: For I in 1 to errs generate

	gf_mul2: auk_rs_gfmul_cnt	generic map (m => m, irrpol => irrpol, b_cnt => negroots_nat(I)	)
    		port map (a => reg_q(I)(m downto 1), c => mulout(I)(m downto 1) );
	
end generate g5;

ifg1: if errs>1 generate
	evadder(1)(m downto 1) <= reg_q(2)(m downto 1);
end generate ifg1;

gif1: if (even >= 2) generate
	gif_g1: for J in 2 to even generate
		evadder(J)(m downto 1) <= evadder(J-1)(m downto 1) xor reg_q(2*J)(m downto 1);  -- GFadd
	end generate gif_g1;
end generate gif1;

-- do derivative
drvadder(1)(m downto 1) <= reg_q(1)(m downto 1);
gif2: if (drv >= 2) generate
	gif2_g1: For J in 2 to drv generate
		drvadder(J)(m downto 1) <= drvadder(J-1)(m downto 1) xor reg_q(2*J-1)(m downto 1);  -- GFadd
	end generate gif2_g1;
end generate gif2;

--deldrv : Process (clk, reset)
--	begin
--		if reset='1' then
--			deldrv_q <= (others => '0');
--		elsif Rising_Edge(clk) then
--			if ena='1' then
--		  	deldrv_q(m downto 1) <= drvadder(drv)(m downto 1);
--			end if;
--		end if;
--	end process deldrv;

ifg2: if errs>1 generate
	halfadd(m downto 1) <= evadder(even)(m downto 1) xor drvadder(drv)(m downto 1); -- gfadd
end generate ifg2;
ifg3: if errs=1 generate
	halfadd(m downto 1) <= drvadder(drv)(m downto 1); -- evadder is zero or not used
end generate ifg3;
-- this line below could be simplified by doing
  poly(m downto 2) <= halfadd(m downto 2);
  poly(1) <= not halfadd(1);
--poly <= halfadd xor vector_one;

-- use process for this?
polyzero(1) <= poly(1);
g8: For K in 2 to m generate
	polyzero(K) <= polyzero(K-1) or poly(K);
end generate g8;

-- under ena toggling if polynomials loaded early that
-- makes chn fail to calculate the last errvec  (the error correction of the first symbol)
-- solution: under load_chn, if polyz is zero it has to be kept propagated through!!
polyz <= (polyzero(m) and not load_chn_q_tail) or (polyz_shunt and load_chn_q_tail);
del_polyzero : Process (clk, reset)
begin
if reset='1' then
	polyzero_del <= (others => '0');
	polyz_shunt <= '0';
elsif Rising_edge(clk) then
	if ena='0' and load_chn='1' and load_chn_q_tail='0' then
		polyz_shunt <= polyzero(m);
	end if;
	if ena='1' then
		--polyzero_del(1) <= not polyzero(m);
		polyzero_del(1) <=  ((not polyzero(m)) and not load_chn_q_tail) or ((not polyz_shunt) and load_chn_q_tail);
		polyzero_del(3 downto 2) <= polyzero_del(2 downto 1);
	end if;
end if;
end process del_polyzero;

------------
-- OMEGA --
------------

---  carefull!!  Omega(1) has to be kept!!

clk_omreg1 : Process (clk, reset)
begin
	if reset='1' then
		omega_one <= (others => '0');
	elsif Rising_Edge(clk) then
		--if ena='1' and start='1' then
		if start='1' then
	  	omega_one <= omega(1)(m downto 1);
		end if;
	end if;
end process clk_omreg1;

ifg4: if errs>1 generate
	g9: For K in 1 to errs-1 generate
	omreg_d(K)(m downto 1) <= (omegamul(k)(m downto 1) and (m downto 1 => not start)) or
														 (omega(k+1)(m downto 1) and (m downto 1 => start));
	clk_omreg : Process (clk, reset)
	begin
		if reset='1' then
			omreg_q(k)(m downto 1) <= (others => '0');
		elsif Rising_Edge(clk) then
			if (ena='1' and load_chn_q_tail='0') or start='1' then
		  	omreg_q(k)(m downto 1) <= omreg_d(k)(m downto 1);
			end if;
		end if;
	end process clk_omreg;

	gf_mul3: auk_rs_gfmul_cnt	generic map (m => m, irrpol => irrpol, b_cnt => negroots_nat(K)	)
    		port map (a => omreg_q(K)(m downto 1), c => omegamul(K)(m downto 1) );	

	end generate g9;

	omadder(1)(m downto 1) <= omreg_q(1)(m downto 1);
end generate ifg4;

gif10: if errs > 2 generate
  --  add all omega terms together
	gif10_g1: For J in 2 to errs-1 generate
		omadder(J)(m downto 1) <= omadder(J-1)(m downto 1) xor omreg_q(J)(m downto 1);  -- GFadd
	end generate gif10_g1;
end generate gif10;

ifg5: if errs=1 generate
  delom_d <= omega_one; --omadder logic not generated
end generate ifg5;
ifg6: if errs>1 generate
  delom_d(m downto 1) <= omadder(errs_cut)(m downto 1) xor omega_one; --gfadd
--	delom_d <= omadder_q xor omega_one; --gfadd
end generate ifg6;

delom : Process (clk, reset)
	begin
		if reset='1' then
			delom_q <= (others => '0');
			omadder_q <= (others => '0');
			omadder_shunt <= (others => '0');
			drvadder_shunt <= (others => '0');
		elsif Rising_Edge(clk) then
			if ena='0' and load_chn='1' and load_chn_q_tail='0' then
				drvadder_shunt <= drvadder(drv)(m downto 1);
			end if;
			if ena='0' and load_chn='1' and load_chn_q_tail='0' then
				omadder_shunt <= delom_d;
			end if;
			-- still I need the value to be loaded. This seems wrong not to let the value load now
			-- by reviewing the testcase at hand
			-- I need to undersand fully better the fault to implement the correct solution 
			--if ena='1' and load_chn_q_tail='0' then
			if ena='1' then
		  	--omadder_q <= delom_d;
				omadder_q <= (delom_d and (m downto 1 => not load_chn_q_tail)) or (omadder_shunt and (m downto 1 => load_chn_q_tail));
			end if;
			if ena='1' then
--		  	delom_q <= delom_d;
				delom_q <= omadder_q;
			end if;
		end if;
	end process delom;

---------------
--  Evaluate Error --
-------------

drvadder_in <= (drvadder_shunt and (m downto 1 => load_chn_q_tail)) or (drvadder(drv)(m downto 1) and (m downto 1 => not load_chn_q_tail));  

gf_div: auk_rs_gfdiv	generic map (m => m, irrpol => irrpol, INV_FILE => INV_FILE	)
 		port map (clk => clk, ena_one => ena, ena_two => ena, reset => reset,
 				a => delom_q, d => drvadder_in, c => divfield_d );
				--a => delom_q, d => drvadder(drv)(m downto 1), c => divfield_d );

clk_divfield : Process (clk, reset)
begin
	if reset='1' then
		divfield_q <= (others => '0');
	elsif Rising_edge(clk) then
		if ena='1' then
			divfield_q <= divfield_d;
		end if;
	end if;
end process clk_divfield;

gif11 : If genstart=0 generate

	vecfield <= divfield_q;

end generate gif11;

gs0:if genstart > 0 generate

-- a delayed delsync(3) or delayed start is required here
	--rootreg_d(1) <= (rootmul(1) and (not start)) or start;
	--rootreg_d(m downto 2) <= rootmul(m downto 2) and (m downto 2 => not start);
	rootreg_d(1) <= (rootmul(1) and (not load_chn)) or load_chn;
	rootreg_d(m downto 2) <= rootmul(m downto 2) and (m downto 2 => not load_chn);

	root : Process (clk, reset)
	begin
		if reset='1' then
			rootreg_q <= (others => '0');
			delroot <= (others => (others => '0'));
		elsif Rising_Edge(clk) then
		  --if ena='1' or start='1' then
		  	--rootreg_q <= rootreg_d;
			--end if;
			if ena='1' then
				rootreg_q <= rootreg_d;
				delroot(1)(m downto 1) <= rootreg_q(m downto 1); 
				delroot(2)(m downto 1) <= delroot(1)(m downto 1);
				delroot(3)(m downto 1) <= delroot(2)(m downto 1);
			end if;
		end if;
	end process root;

	gf_mul1: auk_rs_gfmul_cnt	generic map (m => m, irrpol => irrpol, b_cnt => negroots_nat(genstart))
    	port map (a => rootreg_q, c => rootmul );
			
			
	-- there is a mis-alignment here!!
	gf_mul2: auk_rs_gfmul	generic map (m => m, irrpol => irrpol	)
    		--port map (a => divfield_q, b => rootreg_q, c => vecfield );
				port map (a => divfield_q, b => delroot(3)(m downto 1), c => vecfield );
	
end generate gs0;
			
			
------------
-- outputs --
------------

errvec <= vecfield and (m downto 1 => polyzero_del(3));
	-- del : Process (clk, reset)
	-- begin
		-- if reset='1' then
			-- delroot(1)(m downto 1) <= (others => '0');
			-- delroot(2)(m downto 1) <= (others => '0');
		-- elsif Rising_Edge(clk) then
			-- if ena='1' then
		  	-- delroot(1)(m downto 1) <= rootreg_q(m downto 1);
				-- delroot(2)(m downto 1) <= delroot(1)(m downto 1);
			-- end if;
		-- end if;
	-- end process del;


end architecture rtl;	
