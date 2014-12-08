-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_enc_top_atl_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Enc_atlantic/auk_rs_enc_top_atl_arc_rtl.vhd,v $
--
-- $Revision: 1.12 $
-- $Date: 2005/09/15 15:58:21 $
-- $Author			:  Alejandro Diaz-Manero
--
-- Project      :  RS
--
-- Description	:  Archicture for RS v4 , includes both standard and variable
--
-- ALTERA Confidential and Proprietary
-- Copyright 2004 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
library work;
use work.auk_rs_fun_pkg.all;

architecture rtl of auk_rs_enc_top_atl is


Constant gf_n_max : NATURAL := 2**m-1;
Constant vector_one : Std_Logic_Vector(m downto 1) := 
		CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => 1, SIZE => m), SIZE => m);
-- startadd_cnt has to be removed eventually
Constant startadd_cnt : Std_Logic_Vector(wide downto 1) :=
		CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => check-1, SIZE => wide), SIZE => wide); 
constant two_pow_wide : NATURAL := 2**wide;

Constant alpha_to_power: NATURAL_ARRAY(gf_n_max downto 0) :=
				 generate_gf_alpha_to_power (m => m, irrpol => irrpol);

Constant index_of_alpha: NATURAL_ARRAY(gf_n_max downto 0) := 
				 generate_gf_index_of_alpha (alpha_to_power => alpha_to_power);

Constant gg:	NATURAL_ARRAY(check downto 0) := 
					generate_pol_coeficients (m => m, check => check, genstart => genstart,
									 rootspace => rootspace, Index_of => index_of_alpha, alpha_to_power => alpha_to_power);

Constant alphamatrix : std_logic_cube(check downto 1, two_pow_wide downto 1, m+wide downto 1) := 
    		 gen_all_pol_coefs( check, m, genstart, rootspace, wide,  Index_of_alpha, alpha_to_power);


COMPONENT auk_rs_gfmul_cnt
	generic (
		m: 		natural := 8;		-- Bits per word
		irrpol:	natural	:= 285;
		b_cnt:	natural := 16
	);
    port (
		a :	in	std_logic_vector (m downto 1);
		c :	out	std_logic_vector (m downto 1)
    );
END COMPONENT;

COMPONENT auk_rs_gfmul
	generic (
		m: 		natural := 8;		-- Bits per word
		irrpol:	natural	:= 285
	);
    port (
		a, b:		in		std_logic_vector (m downto 1);
		c:			out	std_logic_vector (m downto 1)
    );
END COMPONENT;


SubType vector_m is std_logic_vector(m downto 1);
type matrix_m is array(NATURAL RANGE <>) of vector_m;

signal point :	std_logic_vector(m downto 1);
signal reg_q, reg_d, alphareg_q, alphareg_d :	matrix_m(check downto 1);
signal mul:	matrix_m(check-1 downto 1);
signal numcheck_q, count, count_del, startadd : Std_Logic_Vector(wide downto 1);
Signal enable, eop_source_gen :	std_logic;
----
signal sink_val_pipe, sink_val_pipe_bk : std_logic_vector(3 downto 1);
signal sink_sop_pipe, sink_sop_pipe_bk : std_logic_vector(3 downto 1);
signal sink_eop_pipe, sink_eop_pipe_bk : std_logic_vector(3 downto 1);
Signal rsin_pipe, rsin_pipe_bk : matrix_m(3 downto 1);
Signal shift3, shift3_bk, shift_point, source_ena_q, source_ena_q_val : std_logic;

begin


enable <= (sink_val_pipe(2) and shift_point) or (source_ena and not shift_point);

sink_ena <= source_ena and shift3; 


process(clk, reset)
  begin
  if reset = '1' then
		sink_val_pipe <= (others => '0'); 
		sink_val_pipe_bk <= (others => '0');
		rsin_pipe <= (others => (others => '0'));
		rsin_pipe_bk <= (others => (others => '0'));
		sink_sop_pipe <= (others => '0'); 
		sink_sop_pipe_bk <= (others => '0');
		sink_eop_pipe <= (others => '0'); 
		sink_eop_pipe_bk <= (others => '0');
		
	elsif rising_edge(clk) then
		if sink_val='1' and source_ena='1' and shift3='1' then
			sink_val_pipe(1) <= '1';
			rsin_pipe(1) <= rsin;
			sink_sop_pipe(1) <= sink_sop;
		elsif sink_val='1' and source_ena='1' and shift3='0' then
			sink_val_pipe(1) <= '0';
			rsin_pipe(1) <= (others => '0');
			sink_sop_pipe(1) <= '0';
		elsif sink_val='0' and source_ena='1' and shift3='1' then
			sink_val_pipe(1) <= sink_val_pipe_bk(1);
			rsin_pipe(1) <= rsin_pipe_bk(1);
			sink_sop_pipe(1) <= sink_sop_pipe_bk(1);
		--elsif (sink_val='1' and source_ena='0' and source_ena_q='1') or (sink_val='0' and source_ena='1') then
		elsif source_ena='0' then 
			sink_val_pipe(1) <= '0';
			rsin_pipe(1) <= (others => '0');
			sink_sop_pipe(1) <= '0';
		end if;
		if sink_val='1' and source_ena='1' then --and shift3='1' then
			sink_eop_pipe(1) <= sink_eop;
		--elsif sink_val='1' and source_ena='1' and shift3='0' then
			--sink_eop_pipe(1) <= '0';
		elsif sink_val='0' and source_ena='1' then --and shift3='1' then
			sink_eop_pipe(1) <= sink_eop_pipe_bk(1);
		--elsif (sink_val='1' and source_ena='0' and source_ena_q='1') or (sink_val='0' and source_ena='1') then
		elsif source_ena='0' then 
			sink_eop_pipe(1) <= '0';
		end if;
		if sink_val='1' and (source_ena='0' or (source_ena='1' and shift3='0')) and source_ena_q='1' then
			sink_val_pipe_bk(1) <= '1';
			rsin_pipe_bk(1) <= rsin;
			sink_sop_pipe_bk(1) <= sink_sop;
			sink_eop_pipe_bk(1) <= sink_eop;
		elsif sink_val='0' and source_ena='1' and shift3='1' then
			sink_val_pipe_bk(1) <= '0';
			rsin_pipe_bk(1) <= (others => '0');
			sink_sop_pipe_bk(1) <= '0';
			sink_eop_pipe_bk(1) <= '0';
		end if;
		
		if sink_val_pipe(1)='1' and source_ena='1' then
			sink_val_pipe(2) <= '1';
			rsin_pipe(2) <= rsin_pipe(1);
			sink_sop_pipe(2) <= sink_sop_pipe(1);
			sink_eop_pipe(2) <= sink_eop_pipe(1);
		elsif sink_val_pipe(1)='0' and source_ena='1' then
			sink_val_pipe(2) <= sink_val_pipe_bk(2);
			rsin_pipe(2) <= rsin_pipe_bk(2);
			sink_sop_pipe(2) <= sink_sop_pipe_bk(2);
			sink_eop_pipe(2) <= sink_eop_pipe_bk(2);
		--elsif (sink_val_pipe(1)='1' and source_ena='0') or (sink_val_pipe(1)='0' and source_ena='0') then
		elsif source_ena='0' then
			sink_val_pipe(2) <= '0';
			rsin_pipe(2) <= (others => '0');
			sink_sop_pipe(2) <= '0';
			sink_eop_pipe(2) <= '0';
		end if;
		if sink_val_pipe(1)='1' and source_ena='0' then
			sink_val_pipe_bk(2) <= '1';
			rsin_pipe_bk(2) <= rsin_pipe(1);
			sink_sop_pipe_bk(2) <= sink_sop_pipe(1);
			sink_eop_pipe_bk(2) <= sink_eop_pipe(1);
		elsif sink_val_pipe(1)='0' and source_ena='1' then
			sink_val_pipe_bk(2) <= '0';
			rsin_pipe_bk(2) <= (others => '0');
			sink_sop_pipe_bk(2) <= '0';
			sink_eop_pipe_bk(2) <= '0';
		end if;
		
		if sink_val_pipe(2)='1' and source_ena='1' then
			sink_val_pipe(3) <= '1';
			sink_sop_pipe(3) <= sink_sop_pipe(2);
			sink_eop_pipe(3) <= sink_eop_pipe(2);
		elsif sink_val_pipe(2)='0' and source_ena='1' then
			sink_val_pipe(3) <= sink_val_pipe_bk(3);
			sink_sop_pipe(3) <= sink_sop_pipe_bk(3);
			sink_eop_pipe(3) <= sink_eop_pipe_bk(3);
		elsif (sink_val_pipe(2)='1' and source_ena='0') or (sink_val_pipe(2)='0' and source_ena='0') then
			sink_val_pipe(3) <= '0';
			sink_sop_pipe(3) <= '0';
			sink_eop_pipe(3) <= '0';
		end if;
		if sink_val_pipe(2)='1' and source_ena='1' and shift_point='1' then
			rsin_pipe(3) <= rsin_pipe(2);
		elsif sink_val_pipe(2)='0' and source_ena='1' and shift_point='1' then
			rsin_pipe(3) <= rsin_pipe_bk(3);
		elsif                          source_ena='1' and shift_point='0' then
			rsin_pipe(3) <= reg_q(1);
		--elsif (sink_val_pipe(2)='1' and source_ena='0') or (sink_val_pipe(2)='0' and source_ena='0') then
		--elsif source_ena='0' then
			--rsin_pipe(3) <= (others => '0');
		end if;
		if sink_val_pipe(2)='1' and source_ena='0' then
			sink_val_pipe_bk(3) <= '1';
			rsin_pipe_bk(3) <= rsin_pipe(2);
			sink_sop_pipe_bk(3) <= sink_sop_pipe(2);
			sink_eop_pipe_bk(3) <= sink_eop_pipe(2);
		elsif sink_val_pipe(2)='0' and source_ena='1' then
			sink_val_pipe_bk(3) <= '0';
			rsin_pipe_bk(3) <= (others => '0');
			sink_sop_pipe_bk(3) <= '0';
			sink_eop_pipe_bk(3) <= '0';
		end if;

	end if;
end process;


clk_atl_src: Process (clk, reset)
	begin
		if reset='1' then
			source_ena_q <= '0';
			source_ena_q_val <= '0';
			source_eop <= '0';
		elsif Rising_edge(clk) then
			source_ena_q <= source_ena;
			source_ena_q_val <= source_ena and not shift_point;
			if source_ena='1' then
				source_eop <= eop_source_gen;
			end if;
		end if;
end process clk_atl_src;


source_val <= sink_val_pipe(3) or source_ena_q_val;
source_sop <= sink_sop_pipe(3);
rsout <= rsin_pipe(3);


-- Common encoder logic

process(clk, reset)
  begin
  if reset = '1' then
		count <= (others => '1');
		count_del <= (others => '1');
		shift3 <= '1';
		shift3_bk <= '1';
		shift_point <= '1';
	elsif rising_edge(clk) then
	
		if sink_eop='1' and sink_eop_pipe(1)='0' and sink_eop_pipe_bk(1)='0' and sink_val='1' and source_ena='0' then
			shift3_bk <= '0';
		elsif shift3_bk='0' and source_ena='1' then
			shift3_bk <= '1';
		end if;
		if sink_eop='1' and sink_eop_pipe(1)='0' and sink_eop_pipe_bk(1)='0' and sink_val='1' and source_ena='1' then
			shift3 <= '0';
		elsif shift3_bk='0' and source_ena='1' then
			shift3 <= '0';
		elsif unsigned(count)=natural(0) and source_ena='1' then
			shift3 <= '1';
		end if;
		
		if (sink_eop_pipe(2)='1' or sink_eop_pipe_bk(3)='1') and source_ena='1' then 
			shift_point <= '0';
		elsif shift_point='0' and (sink_sop_pipe(1)='1' or sink_sop_pipe_bk(2)='1' or --) and source_ena='1' then 
		      unsigned(count_del)=natural(0)) and source_ena='1' then
			shift_point <= '1';
		end if;
	
		if sink_eop='1' and sink_val='1' then
			count <= startadd;
		elsif shift3='0' and source_ena='1' then
			count <= unsigned(count) - natural(1);
		end if;
		if sink_eop_pipe(3)='1' and source_ena='0' then
			count_del <= startadd;
		elsif sink_eop_pipe(3)='1' and source_ena='1' then
			count_del <= unsigned(startadd) - natural(1);
		elsif shift_point='0' and source_ena='1' then
			count_del <= unsigned(count_del) - natural(1);
		end if;
	end if;
end process;

process(count_del, shift_point) --, sink_eop_pipe(3))
begin
	if unsigned(count_del)=natural(0) and shift_point='0' then --and sink_eop_pipe(3)='0') then
		eop_source_gen <= '1';
	else
		eop_source_gen <= '0';
	end if;
end process;


point <= (rsin_pipe(2) and (m downto 1 => shift_point)) xor (reg_q(1)(m downto 1) and (m downto 1 => shift_point));

process(clk, reset)
begin
	if reset='1' then
		reg_q(check downto 1) <= (check downto 1 => (others => '0'));
	elsif rising_edge(clk) then
		if enable='1' then
			reg_q(check downto 1) <= reg_d(check downto 1);
		end if;
	end if;
end process;

-- End common encoder logic

ifg_std: if Varcheck="false" generate

startadd <= startadd_cnt;

g4: for k in 1 to (check - 1) generate
	cmul:	auk_rs_gfmul_cnt
		generic map	(m => m, irrpol => irrpol, b_cnt => gg(k))
		port map	(a => point, c => mul(k)(m downto 1));

	reg_d(k)(m downto 1) <= reg_q(k+1)(m downto 1) xor mul(k)(m downto 1);

end generate g4;

cmuln:	auk_rs_gfmul_cnt
	generic map	(m=>m, irrpol=>irrpol, b_cnt => gg(check))
	port map	(a => point, c => reg_d(check)(m downto 1));

end generate ifg_std; 

ifg_var: if Varcheck="true" generate

process(clk, reset)
  begin
  if reset = '1' then
		startadd <= (others => '1');
		numcheck_q <= (others => '0');
	elsif rising_edge(clk) then
		if sink_val='1' and sink_sop='1' then
			numcheck_q <= numcheck;
		end if;
		if sink_sop_pipe(1)='1' then
			startadd <= unsigned(numcheck_q) - natural(1);
		end if;
	end if;
end process;

g2: for K in 1 to check generate

cnt_2_signals: process(numcheck_q)
	variable tmp: std_logic_matrix(two_pow_wide downto 1, m+wide downto 1);
begin
	tmp := get_matrix_from_cube(alphamatrix, K);
	pla_table ( numcheck_q(wide downto 1), alphareg_d(K)(m downto 1), tmp);
end process cnt_2_signals;

clk_alphas: process(clk)
begin
  if reset = '1' then
    alphareg_q(K) <= (others => '0');
	elsif Rising_edge(clk) then
		if sink_sop_pipe(1)='1' then
			alphareg_q(K) <= alphareg_d(K);
		end if;
	end if;	
end process clk_alphas;

end generate g2;


g4: for k in 1 to (check - 1) generate
	cmul:	auk_rs_gfmul
		generic map	(m => m, irrpol => irrpol)
		port map	(a => point, b => alphareg_q(k)(m downto 1),  c => mul(k)(m downto 1));

	reg_d(k)(m downto 1) <= reg_q(k+1)(m downto 1) xor mul(k)(m downto 1);

end generate g4;

cmuln:	auk_rs_gfmul
	generic map	(m=>m, irrpol=>irrpol)
	port map	(a => point, b => alphareg_q(check)(m downto 1), c => reg_d(check)(m downto 1));

end generate ifg_var;


end architecture rtl;
