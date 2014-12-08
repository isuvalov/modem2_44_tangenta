-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $Workfile:     $
-- $Archive:     $
--
-- $Revision: 1.12 $
-- $Date: 2005/08/26 11:53:04 $
-- Check in by 	 	 : $Author: admanero $
-- Author			:  Alejandro Diaz-Manero
--
-- Project      :  RS
--
-- Description	:  Entity implements the Berlekamp-Massey algorithm with
--                 erasures for the Atlantic decoder for half keysize
--
-- ALTERA Confidential and Proprietary
-- Copyright 2005 (c) Altera Corporation
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


Architecture hal_era_rtl of auk_rs_bms_atl is

	--Constant vector_one : Std_Logic_Vector(wide downto 1) := natural_2_m(arg => 1, size => wide);
	Constant vector_one_m : Std_Logic_Vector(m downto 1) :=
		CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => 1, SIZE => m), SIZE => m);
	Constant mcmp_cnt : std_logic_vector(wide downto 1) := 
		CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => check, SIZE => wide), SIZE => wide);
	Constant omegacmp : std_logic_vector(wide downto 1) := 
		CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => check-1, SIZE => wide), SIZE => wide);
  Constant nummult : NATURAL := (check/2) + (check mod 2);
  Constant odd : NATURAL := (check mod 2);

	Subtype vector_m is Std_Logic_Vector(m downto 1);
	type matrix_m is array(NATURAL RANGE <>) of vector_m;
	
	Constant binary_table : std_logic_matrix(0 to check, wide downto 1) := Build_binary_table(check);

COMPONENT auk_rs_gfmul
	generic (
		m: 		natural := 8;		-- Bits per word
		irrpol:	natural	:= 285
	);
    port (
		a, b:		in		std_logic_vector (m downto 1);
		c:			out		std_logic_vector (m downto 1)
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



signal  synreg_q, synreg_d, bd_q, bd_d : matrix_m(check downto 1);
signal  bdprev_q, bdprev_d, bdtemp_d, bdtemp_q, calcsynreg_d, calcsynreg_q : matrix_m(check downto 1);
signal  erasleft, erasright : matrix_m(check downto 1);
signal  omsel, sh_sel, omega_val : Std_Logic_Vector(check downto 1);
signal  synvar : Std_Logic_Vector(check downto 1);

signal  onereg_q, tlm : Std_Logic;
signal  onenode, deltamult_q, deltamult_d, deltazero : Std_Logic_Vector(m downto 1);
signal  delta_q, delta_d, deltaprev_d, predelta_d, predelta_q : Std_Logic_Vector(m downto 1);

signal  deltaleft, deltaright, bdleft, bdright, mulsum, addvec : matrix_m(check downto 1);
signal  mulleft_q, mulleft_d, mulright_q, mulright_d, mulout : matrix_m(nummult downto 1);

signal  llnuma, llnum_q, llnum_d, llnumb, mloop : Std_Logic_Vector(wide downto 1);
signal  omegaloop, mchk, mcmp, omegachk, num_eras_q : Std_Logic_Vector(wide downto 1);
signal  init_syn, eras_zero : Std_Logic_Vector(wide downto 1);
signal  mloop_plus_eras_num : Std_Logic_Vector(wide+1 downto 1);

signal  omegaleft, omegaright : matrix_m(check downto 1);
signal  loadbdleft, loadbdright, loadbdprev, loadbdtemp, multmux, load_llnum : Std_Logic;
signal  shiftsynleft, shiftsynright, clearbd, shiftbdprev_lm, shift_sh_sel : Std_Logic;
signal  deltacalc, newdelta, olddelta, incm, shiftbdprev_ml : Std_Logic;
signal  incomega, initomega, calcomega, deltaprev_ena : Std_Logic;



Type machine_states is (S0, S0c, S0b, S1, S1a, S1b, S1c, S1d, S1e, S2a, S2b, S77a, S77b,
											 	S3, S4, S5, S5a, S6, S7, S8, S10, S11, S12, S13, S14, S98, S99);

signal state, next_state : machine_States;
signal out_fsm : Std_Logic_Vector(18 downto 1);
signal load_syn_q, load_syn_q_short : std_logic;

begin

--bms_clear <= load_syn;

load_syn_reg : Process (clk, reset)
begin
if reset='1' then
	load_syn_q <= '0';
	load_syn_q_short <= '0';
elsif Rising_edge(clk) then
	if load_syn='1' then
		load_syn_q <= '1';
	elsif load_syn='0' and ena='1' then
		load_syn_q <= '0';
	end if;
	if load_syn='1' then
		load_syn_q_short <= '1';
	elsif load_syn='0' then
		load_syn_q_short <= '0';
	end if;
end if;
end process load_syn_reg;

in_connect: For k in 1 to check generate
		bdtemp_d(k)(m downto 1) <= eras_pos(k)(m downto 1);
end generate in_connect;

FSM: process(state, mchk(wide), deltazero(m), tlm, omegachk(wide), init_syn(wide), eras_zero(wide), bms_clear, load_chn )

	begin
		case state is
		when S0 => 
			if bms_clear='1' then
				next_state <= S0b;
			else
				next_state <= S0;
			end if;
		when S0c => 
			if load_chn='1' then
				next_state <= S0b;
			else
				next_state <= S0c;
			end if;
		when S0b => next_state <= S1;
		when S1 => if eras_zero(wide)='1' then
									next_state <= S1a;
								else
									next_state <= S2a;
								end if;
		when S1a => next_state <= S1b;
		when S1b => next_state <= S1c;
		when S1c => next_state <= S1d;
		when S1d => if init_syn(wide)='1' then
									next_state <= S1a;
								else
									next_state <= S1e;
								end if;
		when S1e => next_state <= S2a;
		when S2a => next_state <= S2b;
		when S2b => if mchk(wide)='1' then
									next_state <= S77a;
								else
									next_state <= S10;
								end if;
		when S77a => next_state <= S77b;
		when S77b => next_state <= S3;
		when S3 => if deltazero(m)='1' then
									next_state <= S4;
								else
									next_state <= S8;
								end if;
		when S4 => next_state <= S5;
		when S5 => next_state <= S5a;
		when S5a => if tlm='1' then
									next_state <= S6;
								else
									next_state <= S8;
								end if;
		when S6 => next_state <= S8;
		when S8 => next_state <= S2b;
		when S10 => next_state <= S11;
		when S11 => next_state <= S12;
		when S12 => if omegachk(wide)='1' then
									next_state <= S13;
								else
									next_state <= S14;
								end if;
		when S13 => next_state <= S12;
		when S14 => next_state <= S98;
		when S98 => if load_chn='1' and bms_clear='0' then
									next_state <= S0;
								elsif load_chn='0' and bms_clear='1' then
									next_state <= S0c;
								elsif load_chn='1' and bms_clear='1' then
									next_state <= S0b; --2;
								else
									next_state <= S99;
								end if;
		when S99 => if load_chn='1' and bms_clear='0' then
									next_state <= S0;
								elsif load_chn='0' and bms_clear='1' then
									next_state <= S0c;
								elsif load_chn='1' and bms_clear='1' then
									next_state <= S0b; --2;
								else
									next_state <= S99;
								end if;
-- coverage off
		when others => next_state <= S0;
-- coverage on
		end case;
	end process FSM;

clk_FSM: Process (clk, reset)
	begin
		if reset='1' then
			state <= S0;
		elsif Rising_edge(clk) then
			if ena='1' then
			--if bms_clear='0' then
				state <= next_state;
			--else
			--	state <= S0;
			end if;
		end if;
		
end process clk_FSM;


loadbdleft <= out_fsm(1);
loadbdright <= out_fsm(2);
loadbdprev <= out_fsm(3);
loadbdtemp <= out_fsm(4);
multmux <= out_fsm(5);
shiftsynleft <= out_fsm(6);
shiftsynright <= out_fsm(7);
clearbd <= out_fsm(8);
shiftbdprev_lm <= out_fsm(9);
deltacalc <= out_fsm(10);
newdelta <= out_fsm(11);
olddelta <= out_fsm(12);
incm <= out_fsm(13); 
incomega <= out_fsm(14); 
initomega <= out_fsm(15); 
calcomega <= out_fsm(16);
load_llnum <= olddelta;
shiftbdprev_ml <= out_fsm(17);
shift_sh_sel <= out_fsm(18);



outputs_FSM: process(state)

--  mx : MACHINE OF BITS (mst[18..1])
--	   WITH STATES
--			(s0  = B"001000001000000000",
--
--			 s1  = B"001000001000010000",  -- load syndromes, multmux
--			 s1a = B"001000001000010010",  -- load bdright, multmux
--			 s1b = B"001000001000000000",  -- keep selecting deltacalc calomega
--			 s1c = B"111001001000100001",  -- shift syndrome as num erasures,
--                                         -- incm, load bdleft, shiftbdprev_ml, shift_sh_sel
--			 s1d = B"001000001000010000",  -- multmux
--			 s1e = B"000000000000001000",  -- load bdtemp
--			 s2a = B"000000000000000100",  -- load bdprev not inc mloop
--			 s2b = B"000000011100000000",  -- calc new delta = Sm + (series)B(j)*S(m-j), shiftbdprev_lm

--			 s77a= B"000000011000010000",  -- 1 pipe stage to top of gfmuls, multmux
--			 s77b= B"000000011000010000",  -- 1 pipe stage to top of gfmuls
--
--			 s3  = B"000000000000000000",  -- if new delta <> 0, calc new BD
--
--			 s4  = B"000000000000001000",  -- TD = BD, BD = BD - deltamult*(D^i)*BDprev
--			 s5  = B"000000000000010001",  -- load first half BD  , multmux
--			 s5a = B"000000000000010010",  -- load second half BD, check 2L <= m?
--			 s6  = B"000000100000000100",  -- L = m+1-L, i=1, BDprev = BDtemp, olddelta = delta, load llnum
--			 s8  = B"000001000000100000",  -- inc mloop, shift synregs left
--
--			 s10 = B"001100000010001000",  -- initialize omegaleft, loadbdtemp, clearbd
--			 s11 = B"001100000001010101",  -- initialize omegaright, loadbdprev, shift synregs right
--			
--			 s12 = B"001010000000000010",  -- calc omegaleft, load omegaright, incomega
--			 s13 = B"011000000001010001",  -- calc omegaright, load omegaleft, synshiftright, shiftbdprev_ml
--
--			 s14 = B"010000000000000000",  -- last shiftbdprev_ml
--
--			 s99 = B"000000000000000000");

	begin
		case state is
		when S0 =>
			out_fsm <= "001000001000000000";
		when S0c =>
			out_fsm <= "001000001000000000";
		when S0b =>
			out_fsm <= "001000001000000000";
		when S1 =>
			out_fsm <= "001000001000010000";
		when S1a =>
			out_fsm <= "001000001000010010";
		when S1b =>
			out_fsm <= "001000001000000000";
		when S1c =>
			out_fsm <= "111001001000100001";
		when S1d =>
			out_fsm <= "001000001000010000";
		when S1e =>
			out_fsm <= "000000000000001000";
		when S2a =>
			out_fsm <= "000000000000000100";
		when S2b =>
			out_fsm <= "000000011100000000";
		when S77a =>
			out_fsm <= "000000011000010000";
		when S77b =>
			out_fsm <= "000000011000010000";
		when S3 => 
			out_fsm <= "000000000000000000";
		when S4 => 
			out_fsm <= "000000000000001000";
		when S5 => 
			out_fsm <= "000000000000010001";
		when S5a => 
			out_fsm <= "000000000000010010";
		when S6 => 
			out_fsm <= "000000100000000100";
		when S8 => 
			out_fsm <= "000001000000100000";
		when S10 => 
			out_fsm <= "001100000010001000";
		when S11 => 
			out_fsm <= "001100000001010101";
		when S12 => 
			out_fsm <= "001010000000000010";
		when S13 => 
			out_fsm <= "011000000001010001";
		when S14 => 
			out_fsm <= "010000000000000000";
		when S99 => 
			out_fsm <= "000000000000000000";
-- coverage off
		when others => 
			out_fsm <= "000000000000000000";
-- coverage on
		end case;
		if state=S98 then
			bms_done <= '1';
		else
			bms_done <= '0';
		end if;
end process outputs_FSM;


--mcmp <= natural_2_m(arg => check, size => wide);
--omegacmp <= natural_2_m(arg => check-1, size => wide);


--************************
--*** SYNDROME SECTION ***
--************************

if_var0: if Varcheck="false" generate
	mcmp <= mcmp_cnt;
end generate if_var0;

if_var1: if Varcheck="true" generate
  
	mcmp <= numcheck;
  
	demux : Process(numcheck)

    variable tmp_and_sel : Std_Logic_Vector(numcheck'HIGH downto 0);
		variable ncheck_decoded, omega_val_var : Std_Logic_Vector(check downto 1);

  begin
    acs_loop: for K in 1 to check loop
      tmp_and_sel(0) := '1';
			and_loop: For J in 1 to numcheck'HIGH loop
				if binary_table(K, J)='0' then
					tmp_and_sel(J) := tmp_and_sel(J-1) and not numcheck(J);
				else  --bit J of I-1 is 1
					tmp_and_sel(J) := tmp_and_sel(J-1) and numcheck(J);
				end if;
			end loop and_loop;
			synvar(K) <= tmp_and_sel(numcheck'HIGH);
    end loop acs_loop;
		check_loop: for K in check downto 1 loop
      tmp_and_sel(0) := '1';
			and_loop2: For J in 1 to numcheck'HIGH loop
				if binary_table(K, J)='0' then
					tmp_and_sel(J) := tmp_and_sel(J-1) and not numcheck(J);
				else  --bit J of I-1 is 1
					tmp_and_sel(J) := tmp_and_sel(J-1) and numcheck(J);
				end if;
			end loop and_loop2;
			ncheck_decoded(K) := tmp_and_sel(numcheck'HIGH);
			-- propage down the MSB one
			if K=check then
				omega_val_var(K) := ncheck_decoded(K);
			else
				omega_val_var(K) := omega_val_var(K+1) or ncheck_decoded(K);  
			end if;
    end loop check_loop;
		omega_val <= omega_val_var;
  end process demux;
		
end generate if_var1;

  -- no resets required, loaded after sm reset 
synreg_d(1)(m downto 1) <= (syn(1)(m downto 1) and (m downto 1 => not shiftsynleft) and 
    													(m downto 1 => not shiftsynright)) or 
												  (synreg_q(2)(m downto 1) and (m downto 1 => shiftsynleft)) or
				  								(synreg_q(check)(m downto 1) and (m downto 1 => shiftsynright));
g1: FOR k IN 2 TO check-1 GENERATE
	if_var2: if Varcheck="false" generate
    synreg_d(k)(m downto 1) <= (syn(k)(m downto 1) and (m downto 1 => not shiftsynleft) and 
    													(m downto 1 => not shiftsynright)) or 
				  										(synreg_q(k+1)(m downto 1) and (m downto 1 => shiftsynleft)) or
				  										(synreg_q(k-1)(m downto 1) and (m downto 1 => shiftsynright));
	end generate if_var2;
	
	if_var3: if Varcheck="true" generate
		synreg_d(k)(m downto 1) <= (syn(k)(m downto 1) and (m downto 1 => not shiftsynleft) and 
    													(m downto 1 => not shiftsynright)) or 
				  										(synreg_q(k+1)(m downto 1) and (m downto 1 => shiftsynleft) and
				  										(m downto 1 => not synvar(K))) or
															(synreg_q(1)(m downto 1) and (m downto 1 => shiftsynleft) and
				  										(m downto 1 => synvar(K))) or
				  										(synreg_q(k-1)(m downto 1) and (m downto 1 => shiftsynright));
	end generate if_var3;
END GENERATE g1;


synreg_d(check)(m downto 1) <= (syn(check)(m downto 1) and (m downto 1 => not shiftsynleft) and 
    													(m downto 1 => not shiftsynright)) or
															(synreg_q(1)(m downto 1) and (m downto 1 => shiftsynleft)) or
				  										(synreg_q(check-1)(m downto 1) and (m downto 1 => shiftsynright));
  
synreg_1 : Process (clk, reset)
begin
if reset='1' then
	synreg_q(1)(m downto 1) <= (others => '0');
elsif Rising_edge(clk) then
	if ena='1' or load_syn='1' then
		if load_syn='1' or shiftsynleft='1' then
			synreg_q(1)(m downto 1) <= synreg_d(1)(m downto 1);
		end if;
	end if;
end if;
end process synreg_1;
					
g3 : For k in 2 to check generate
  synreg_2 : Process (clk, reset)
  begin
 	if reset='1' then
		synreg_q(K)(m downto 1) <= (others => '0');
  elsif Rising_edge(clk) then
		if ena='1' or load_syn='1' then
  		if load_syn='1' or shiftsynleft='1' or shiftsynright='1' then
  			synreg_q(k)(m downto 1) <= synreg_d(k)(m downto 1);
  		end if;
		end if;
  end if;
  end process synreg_2;			
end generate g3;

if_var6: if Varcheck="true" generate
	-- use calcsynregs to hold syndromes as if they had been shifted over full set of regs
	calcsynreg_d(1)(m downto 1) <= synreg_q(1)(m downto 1) and (m downto 1 => not bms_clear);
	g4b: FOR k IN 2 TO check GENERATE
		calcsynreg_d(k)(m downto 1) <= calcsynreg_q(k-1)(m downto 1) and (m downto 1 => not bms_clear);
	END GENERATE g4b;
	
	calcsynreg : Process (clk, reset)
	begin
	if reset='1' then
		calcsynreg_q <= (others => (others => '0'));
	elsif Rising_edge(clk) then
		if ena='1' then
			if shiftsynleft='1' or bms_clear='1' then
				calcsynreg_q <= calcsynreg_d;
			end if;
		end if;
	end if;
	end process calcsynreg;

end generate if_var6;


--******************
--*** BD-OMEGA SECTION ***
--******************

-- load onereg with zero after first shift
-- (m..2) bits always zero, use onenode

onereg : Process (clk, reset)
begin
if reset='1' then
	onereg_q <= '0';
elsif Rising_edge(clk) then
	if ena='1' then
		if shiftbdprev_lm='1' or bms_clear='1' or loadbdprev='1' then
			onereg_q <= bms_clear or loadbdprev;
		end if;
	end if;
end if;
end process onereg;
					

onenode(1) <= onereg_q;
onenode(m downto 2) <= (others => '0');

g5: FOR k IN 1 TO check GENERATE
  if_non_var7: if Varcheck="false" generate
		bd_d(k)(m downto 1) <= (addvec(k)(m downto 1) and (m downto 1 => not bms_clear) and
                            (m downto 1 => not clearbd));
  end generate if_non_var7;														
	-- if it is variable I would like to AND this vector with
-- omega_val only when calcomega is asserted
-- that would be ... and (m downto 1 => omega_val(K) or not calcomega) 
	if_var7: if Varcheck="true" generate
    bd_d(k)(m downto 1) <= (addvec(k)(m downto 1) and (m downto 1 => not clearbd) 
                            and (m downto 1 => omega_val(k) or not calcomega) and (m downto 1 => not bms_clear));
  end generate if_var7;
END GENERATE g5;

g51: FOR k IN 1 TO nummult GENERATE

bd_1 : Process (clk, reset)
begin
if reset='1' then
	bd_q(K) <= (others => '0');
elsif Rising_edge(clk) then
	if ena='1' then
		if (omsel(k)='0' and loadbdleft='1') or clearbd='1' or bms_clear='1' then
			bd_q(k) <= bd_d(k);
		end if;
	end if;
end if;
end process bd_1;
END GENERATE g51;

g52: FOR k IN 1 TO (check-nummult) GENERATE

bd_2 : Process (clk, reset)
begin
if reset='1' then
	bd_q(K+nummult) <= (others => '0');
elsif Rising_edge(clk) then
	if ena='1' then
		if (omsel(k+nummult)='0' and loadbdright='1') or clearbd='1' or bms_clear='1' then
			bd_q(k+nummult) <= bd_d(k+nummult);
		end if;
	end if;
end if;
end process bd_2;
END GENERATE g52;


sh_omsel_0 : Process (clk, reset)
begin
if reset='1' then
	omsel(1) <= '0';
elsif Rising_edge(clk) then
	if ena='1' then
		if incomega='1' or bms_clear='1' then
			if bms_clear='0' then
				omsel(1) <= '1';
			else
				omsel(1) <= '0';
			end if;
		end if;
	end if;
end if;
end process sh_omsel_0;

g22: FOR k IN 2 TO check GENERATE

sh_omsel: Process (clk, reset)
begin
if reset='1' then
	omsel(K) <= '0';
elsif Rising_edge(clk) then
	if ena='1' then
		if incomega='1' or bms_clear='1' then
			if bms_clear='0' then
				omsel(K) <= omsel(K-1);
			else
				omsel(K) <= '0';
			end if;
		end if;
	end if;
end if;
end process sh_omsel;

END GENERATE g22;

----------

bdprev_d(1)(m downto 1) <= ((bdtemp_q(1)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm) and (m downto 1 => not load_syn_q_short)) or
													(eras_pos(1)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm) and (m downto 1 => load_syn_q_short)) or
  												(onenode and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => shiftbdprev_lm)) or
													(bdprev_q(2)(m downto 1) and (m downto 1 => shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm)));

gbd :  For K in 2 to check-1 generate
    bdprev_d(k)(m downto 1) <= ((bdtemp_q(k)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm) and (m downto 1 => not load_syn_q_short)) or
													(eras_pos(k)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm) and (m downto 1 => load_syn_q_short)) or
  												(bdprev_q(k-1)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => shiftbdprev_lm)) or
													(bdprev_q(k+1)(m downto 1) and (m downto 1 => shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm)));

end generate gbd;	

bdprev_d(check)(m downto 1) <= ((bdtemp_q(check)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm) and (m downto 1 => not load_syn_q_short)) or
													(eras_pos(check)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm) and (m downto 1 => load_syn_q_short)) or
  												(bdprev_q(check-1)(m downto 1) and (m downto 1 => not shiftbdprev_ml) and
													(m downto 1 => shiftbdprev_lm)) or
													(bdprev_q(1)(m downto 1) and (m downto 1 => shiftbdprev_ml) and
													(m downto 1 => not shiftbdprev_lm)));

bdprev : Process (clk, reset)
begin
if reset='1' then
	bdprev_q <= (others => (others => '0'));
elsif Rising_edge(clk) then
	if ena='1' or load_syn_q_short='1' then
		if loadbdprev='1' or shiftbdprev_ml='1' or shiftbdprev_lm='1' or load_syn_q_short='1' then
			bdprev_q <= bdprev_d;
		end if;
	end if;
end if;
end process bdprev;


sh_sh_sel_0 : Process (clk, reset)
begin
if reset='1' then
	sh_sel(1) <= '0';
elsif Rising_edge(clk) then
	if ena='1' then
		if shift_sh_sel='1' or bms_clear='1' then
			if bms_clear='0' then
				sh_sel(1) <= '1';
			else
				sh_sel(1) <= '0';
			end if;
		end if;
	end if;
end if;
end process sh_sh_sel_0;

g6: FOR k IN 2 TO check GENERATE

sh_sh_sel: Process (clk, reset)
begin
if reset='1' then
	sh_sel(K) <= '0';
elsif Rising_edge(clk) then
	if ena='1' then
		if shift_sh_sel='1' or bms_clear='1' then
			if bms_clear='0' then
				sh_sel(K) <= sh_sel(K-1);
			else
				sh_sel(K) <= '0';
			end if;
		end if;
	end if;
end if;
end process sh_sh_sel;

END GENERATE g6;

bdtemp : Process (clk, reset)
begin
if reset='1' then
	bdtemp_q <= (others => (others => '0'));
elsif Rising_edge(clk) then
	if ena='1'or load_syn_q_short='1' then
		if loadbdtemp='1' or load_syn_q_short='1' then
			if load_syn_q_short='1' then
			  bdtemp_q <= bdtemp_d;
			else
		  	bdtemp_q <= bd_q;
			end if;
		end if;
	end if;
end if;
end process bdtemp;


--********************
--*** CORE SECTION ***
--********************

--*** calculate new delta ***

bdleft <= bdprev_q;
erasright(1)(m downto 1) <= vector_one_m;

g11b: FOR K IN 2 TO check GENERATE
  erasright(K)(m downto 1) <= bd_q(K-1)(m downto 1);
END GENERATE g11b;

expand_check: FOR k IN 1 to check GENERATE

  erasleft(K)(m downto 1) <= (bdprev_q(1)(m downto 1) and (m downto 1 => sh_sel(k))) or
	    										(bdtemp_q(k)(m downto 1) and (m downto 1 => not sh_sel(K)));

	if_non_var1: if Varcheck="false" generate
		deltaleft(k)(m downto 1) <= synreg_q(check+1-k)(m downto 1);
	end generate if_non_var1;
	if_var10: if Varcheck="true" generate
		deltaleft(k)(m downto 1) <= calcsynreg_q(k)(m downto 1);
	end generate if_var10;
	--deltaleft(k)(m downto 1) <= synreg_q(check+1-k)(m downto 1);
  deltaright(k)(m downto 1) <= bd_q(k)(m downto 1);

  bdright(k)(m downto 1) <= deltamult_q;

  -- calculate omega
	omegaleft(k)(m downto 1) <= synreg_q(k)(m downto 1);
	omegaright(k)(m downto 1) <= (bdprev_q(1)(m downto 1) and (m downto 1 => not initomega)) or
    													(vector_one_m and (m downto 1 => initomega));
END GENERATE expand_check;

g9: FOR k IN 1 TO nummult-odd GENERATE
  addvec(k)(m downto 1) <= bd_q(k)(m downto 1) xor mulout(k)(m downto 1); -- GFadd

	addvec(k+nummult)(m downto 1) <= bd_q(k+nummult)(m downto 1) xor mulout(k)(m downto 1);
END GENERATE g9;

g93: if odd=1 GENERATE
		addvec(nummult)(m downto 1) <= bd_q(nummult)(m downto 1) xor mulout(nummult)(m downto 1);
END GENERATE g93;

  -- multiply

g121: FOR k IN 1 TO nummult-odd GENERATE

    mulleft_d(k)(m downto 1) <= ((m downto 1 => not multmux) and 
    													((erasleft(k)(m downto 1) and (m downto 1 => deltacalc) and
  														(m downto 1 => calcomega)) or
    													(deltaleft(k)(m downto 1) and	(m downto 1 => deltacalc) and
    													(m downto 1 => not calcomega)) or
    													(bdleft(k)(m downto 1) and (m downto 1 => not deltacalc) and
    													(m downto 1 => not calcomega)) or
      	 											(omegaleft(k)(m downto 1) and (m downto 1 => not deltacalc) and 
      	 											(m downto 1 => calcomega)))) or
				     									((m downto 1 => multmux) and
															((erasleft(k+nummult)(m downto 1) and (m downto 1 => deltacalc) and
  														(m downto 1 => calcomega)) or
				     									(deltaleft(k+nummult)(m downto 1) and	(m downto 1 => deltacalc) and
				     									(m downto 1 => not calcomega)) or 
                       				(bdleft(k+nummult)(m downto 1) and (m downto 1 => not deltacalc) and
                       				(m downto 1 => not calcomega)) or
                       				(omegaleft(k+nummult)(m downto 1) and (m downto 1 => not deltacalc) and
                       				(m downto 1 => calcomega))));

    mulright_d(k)(m downto 1) <= ((m downto 1 => not multmux) and
    													((erasright(k)(m downto 1) and (m downto 1 => deltacalc) and
    													(m downto 1 => calcomega)) or
    													(deltaright(k)(m downto 1) and (m downto 1 => deltacalc) and
    													(m downto 1 => not calcomega)) or  
                        			(bdright(k)(m downto 1) and (m downto 1 => not deltacalc) and 
                        			(m downto 1 => not calcomega)) or
                        			(omegaright(k)(m downto 1) and (m downto 1 => not deltacalc) and
                        			(m downto 1 => calcomega)))) or
				      								((m downto 1 => multmux) and 
															((erasright(k+nummult)(m downto 1) and (m downto 1 => deltacalc) and
  														(m downto 1 => calcomega)) or
				      								(deltaright(k+nummult)(m downto 1) and	(m downto 1 => deltacalc) and
				      								(m downto 1 => not calcomega)) or 
                        			(bdright(k+nummult)(m downto 1) and (m downto 1 => not deltacalc) and
                        			(m downto 1 => not calcomega)) or
                        			(omegaright(k+nummult)(m downto 1) and (m downto 1 => not deltacalc) and
                        			(m downto 1 => calcomega))));

  END GENERATE g121;


g12b: If odd=1 GENERATE

	mulleft_d(nummult)(m downto 1) <= ((m downto 1 => not multmux) and
    													((erasleft(nummult)(m downto 1) and (m downto 1 => deltacalc) and
  														(m downto 1 => calcomega)) or
    													(deltaleft(nummult)(m downto 1) and	(m downto 1 => deltacalc) and
    													(m downto 1 => not calcomega)) or 
    													(bdleft(nummult)(m downto 1) and (m downto 1 => not deltacalc) and
    													(m downto 1 => not calcomega)) or
      	 											(omegaleft(nummult)(m downto 1) and (m downto 1 => not deltacalc) and 
      	 											(m downto 1 => calcomega))));

  mulright_d(nummult)(m downto 1) <= ((m downto 1 => not multmux) and
    													((erasright(nummult)(m downto 1) and (m downto 1 => deltacalc) and
    													(m downto 1 => calcomega)) or
    													(deltaright(nummult)(m downto 1) and (m downto 1 => deltacalc) and
    													(m downto 1 => not calcomega)) or
                        			(bdright(nummult)(m downto 1) and (m downto 1 => not deltacalc) and 
                        			(m downto 1 => not calcomega)) or
                        			(omegaright(nummult)(m downto 1) and (m downto 1 => not deltacalc) and
                        			(m downto 1 => calcomega))));

END GENERATE g12b;


mults : Process (clk, reset)
begin
if reset='1' then
	mulleft_q <= (others => (others => '0'));
	mulright_q <= (others => (others => '0'));
elsif Rising_edge(clk) then
	if ena='1' then
		mulleft_q <= mulleft_d;
		mulright_q <= mulright_d;
	end if;
end if;
end process mults;

g13: FOR k IN 1 TO nummult GENERATE

gf_mul1: auk_rs_gfmul
	generic map (m => m, irrpol => irrpol)
  port map (a => mulleft_q(k)(m downto 1), b => mulright_q(k)(m downto 1), c => mulout(k)(m downto 1));

END GENERATE g13;

  -- calculate new delta
mulsum(1) <= mulout(1);
g14: IF (nummult>1) GENERATE
  g141: FOR k IN 2 TO nummult GENERATE
     mulsum(k)(m downto 1) <= mulout(k)(m downto 1) xor mulsum(k-1)(m downto 1);
  END GENERATE g141;
END GENERATE g14;

predelta_d <= mulsum(nummult)(m downto 1) xor synreg_q(1)(m downto 1);

delta_d <= mulsum(nummult)(m downto 1) xor predelta_q(m downto 1);

predelta_clk : Process (clk, reset)
begin
if reset='1' then
	predelta_q <= (others => '0');
elsif Rising_edge(clk) then
  if ena='1' then
		predelta_q <= predelta_d;
	end if;
end if;
end process predelta_clk;

delta_clk : Process (clk, reset)
begin
if reset='1' then
	delta_q <= (others => '0');
elsif Rising_edge(clk) then
	if ena='1' then
		if newdelta='1' then
			delta_q <= delta_d;
		end if;
	end if;
end if;
end process delta_clk;


--delta_prev : Process (clk, reset)
--begin
--if reset='1' then
--	deltaprev_q <= (others => '0');
--elsif Rising_edge(clk) then
--	if ena='1' then
--		if olddelta='1' or bms_clear='1' then
--			deltaprev_q(m downto 2) <= delta_q(m downto 2) and (m downto 2 => not bms_clear);
--	  	deltaprev_q(1) <= delta_q(1) or bms_clear;
--		end if;
--	end if;
--end if;
--end process delta_prev;

deltaprev_d(m downto 2) <= delta_q(m downto 2) and (m downto 2 => not bms_clear);
deltaprev_d(1) <= delta_q(1) or bms_clear;
deltaprev_ena <= olddelta or bms_clear;

-- I have to watch out with this gfdiv if it is valid for the current implementation
-- or if futher mods are required
gf_div1: auk_rs_gfdiv
	generic map (m => m, irrpol => irrpol, INV_FILE => INV_FILE)
  port map (clk => clk, ena_one => deltaprev_ena, ena_two => ena_ng, reset => reset,
--gf_div1: auk_rs_gfdiv
--	generic map (m => m, irrpol => irrpol,
--			 INV_FILE => INV_FILE, dev_family => dev_family)
--  port map (clk => clk, ena => deltaprev_ena, reset => reset,
  			a => delta_q(m downto 1), d => deltaprev_d(m downto 1), c => deltamult_d(m downto 1));

delta_mul : Process (clk, reset)
begin
if reset='1' then
	deltamult_q <= (others => '0');
elsif Rising_edge(clk) then
	if ena='1' then
		deltamult_q <= deltamult_d;
	end if;
end if;
end process delta_mul;

deltazero(1) <= delta_q(1);
g17: FOR k IN 2 TO m GENERATE
  deltazero(k) <= delta_q(k) or deltazero(k-1);
END GENERATE g17;

--****************
--*** COUNTERS ***
--****************

cnt_mloop : Process (clk, reset)
begin
	if reset='1' then
		mloop <= (others => '0');
	elsif Rising_edge(clk) then
		if ena='1' then
			if incm='1' or bms_clear='1' then
				if bms_clear='0' then
					mloop <= unsigned(mloop) + natural(1);
				else
					mloop <= (others => '0');
				end if;
			end if;
		end if;
	end if;
end process cnt_mloop;

mchk(1) <= mloop(1) xor mcmp(1);
eras_zero(1) <= num_eras_q(1);
init_syn(1) <= mloop(1) xor num_eras_q(1);
omegachk(1) <= omegaloop(1) xor omegacmp(1);

expand_wide: FOR k IN 2 TO wide GENERATE
  mchk(k) <= mchk(k-1) or (mloop(k) xor mcmp(k));

  eras_zero(k) <= num_eras_q(k) or eras_zero(k-1);

  init_syn(k) <= init_syn(k-1) or (mloop(k) xor num_eras_q(k));

  omegachk(k) <= omegachk(k-1) or (omegaloop(k) xor omegacmp(k));
END GENERATE expand_wide;

-- L <= M+1-L
llnuma <= mloop-llnum_q;
llnumb <= unsigned(num_eras_q) + natural(1);
llnum_d <= llnuma+llnumb;

store_num_eras: Process (clk, reset)
begin
if reset='1' then
	num_eras_q <= (others => '0');
elsif Rising_edge(clk) then
	--if ena='1' then
		if load_syn_q_short='1' then
			num_eras_q <= num_eras;
		end if;
	--end if;
end if;
end process store_num_eras;

llnum : Process (clk, reset)
begin
if reset='1' then
	llnum_q <= (others => '0');
elsif Rising_edge(clk) then
	if ena='1' then --or load_syn_q='1' then
		if load_llnum='1' or load_syn_q='1' then
			if load_syn_q='0' then
				llnum_q <= llnum_d;
			else
				llnum_q <= (num_eras and (wide downto 1 => load_syn_q_short)) or (num_eras_q and (wide downto 1 => not load_syn_q_short));
			end if;
		end if;
	end if;
end if;
end process llnum;


mloop_plus_eras_num <= unsigned('0'&mloop)+unsigned('0'&num_eras_q);

cmp_2ll_m : Process (llnum_q, mloop_plus_eras_num)
begin
	if unsigned(llnum_q&'0') > unsigned(mloop_plus_eras_num) then
		tlm <= '0';
	else
		tlm <= '1';
	end if;
end process cmp_2ll_m;	

-- 2L <= m?

cnt_omegaloop : Process (clk, reset)
begin
	if reset='1' then
		omegaloop <= (others => '0');
	elsif Rising_edge(clk) then
		if ena='1' then
			if incomega='1' or bms_clear='1' then
				if bms_clear='0' then
					omegaloop <= unsigned(omegaloop) + natural(1);
				else
					omegaloop <= (others => '0');
				end if;
			end if;
		end if;
	end if;
end process cnt_omegaloop;


-- this is only for readability
-- synthesis translate_off

-- gr : If M_max > m generate
	-- grf: For k in 1 to check generate
		-- omegaleft(k)(M_max downto m+1) <= (others => '0');
		-- omegaright(k)(M_max downto m+1) <= (others => '0');
		-- bd_d(k)(M_max downto m+1) <= (others => '0');
		-- bdprev_d(k)(M_max downto m+1) <= (others => '0');
-- --		bdtemp_q(k)(M_max downto m+1) <= (others => '0');
		-- deltaleft(k)(M_max downto m+1) <= (others => '0');
		-- deltaright(k)(M_max downto m+1) <= (others => '0');
		-- bdleft(k)(M_max downto m+1) <= (others => '0');
		-- bdright(k)(M_max downto m+1) <= (others => '0');
		-- addvec(k)(M_max downto m+1) <= (others => '0');
		-- synreg_q(k)(M_max downto m+1) <= (others => '0');
		-- synreg_d(k)(M_max downto m+1) <= (others => '0');
		-- erasleft(k)(M_max downto m+1) <= (others => '0');
		-- erasright(k)(M_max downto m+1) <= (others => '0');
		-- mulsum(k)(M_max downto m+1) <= (others => '0');
	-- end generate grf;
	-- grg: For k in 1 to nummult generate	-- nummult
		-- mulleft_d(k)(M_max downto m+1) <= (others => '0');
		-- mulright_d(k)(M_max downto m+1) <= (others => '0');
		-- mulout(k)(M_max downto m+1) <= (others => '0');
	-- end generate grg;	
-- end generate gr;
-- synthesis translate_on
-- end for readability only


 --***************
--*** OUTPUTS ***
--***************

out_connect: For k in 1 to check generate
		bdout(k)(m downto 1) <= bdprev_q(k)(m downto 1);
		omegaout(k)(m downto 1) <= bd_q(k)(m downto 1);
		-- for readability in simulation and to avoid warnings 
		-- in unencrypted synthesis
		gr : If M_max > m generate
			bdout(k)(M_max downto m+1) <= (others => '0');
			omegaout(k)(M_max downto m+1) <= (others => '0');
		end generate gr;
end generate out_connect;

numerr <= llnum_q;
	
end architecture hal_era_rtl;	
