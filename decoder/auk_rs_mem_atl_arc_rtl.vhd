-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_rs_mem_atl_arc_rtl.vhd,v $
-- $Source: /disk2/cvs/data/Projects/RS/Units/Dec_atlantic/auk_rs_mem_atl_arc_rtl.vhd,v $
--
-- $Revision: 1.39 $
-- $Date: 2005/10/03 09:02:18 $
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


Architecture rtl of auk_rs_mem_atl is

Constant gf_n_max : NATURAL := 2**m-1;
Constant log2m   : NATURAL := log2_ceil_table(m+1);
constant two_pow_m		: NATURAL := 2**m;
constant dev_family : STRING := "Cyclone III";

Subtype vector_m is Std_Logic_Vector(m downto 1);
Subtype vector_w is Std_Logic_Vector(wide downto 1);
type matrix_m is array(NATURAL RANGE <>) of vector_m;
type matrix_w is array(NATURAL RANGE <>) of vector_w;

signal dataone_q, datatwo_q, datathr_q, datafor_q :  Std_Logic_Vector(m downto 1);
signal err_value_swap:  Std_Logic_Vector(m downto 1);
signal data_2_correct : Std_Logic_Vector(m downto 1);
signal rsoutff_q, rsout_shunt : Std_Logic_Vector(m downto 1);
Signal pipe_wr_ptr : matrix_m(2 downto 1);
Signal pipe_nc_ptr : matrix_w(2 downto 1); 
signal writeadd, wr_errvec_add, rd_errvec_add : Std_Logic_Vector(m downto 1);
signal seed_cnt, readadd, writeadd_shunt : std_logic_vector(m downto 1);
signal seed_count_wr, seed_count_rd : std_logic_vector(m downto 1);
signal onein, twoin, thrin, forin : Std_Logic;
signal oneout, twoout, throut, forout : Std_Logic;

Signal numroots : Std_Logic_Vector(wide downto 1);
signal err_bit_accum_q, err_bit_accum_d, err_bit_out_q : Std_Logic_Vector(bitwide downto 1);
Signal err_bit0_accum_d, err_bit0_accum_q : std_logic_vector(bitwide downto 1); 
Signal err_bit1_accum_d, err_bit1_accum_q : std_logic_vector(bitwide downto 1);
signal err_add_bit, err_add_bit0_d, err_add_bit1_d : Std_Logic_Vector(log2m downto 1);
signal err_add_bit0_q, err_add_bit1_q : Std_Logic_Vector(log2m downto 1);
Signal err_val_bit0, err_val_bit1 : std_logic_vector(m downto 1);
signal dav_source_align : Std_Logic_Vector(2 downto 1);

	Type machine_states  is (S0, S1, S2, S3, S4);
	Type machine_states2 is (S1, S2, S3, S4);
	Type bi_status_states is (idle, busy);
	Type status_states is (idle, busy, booked);
	Type counter_states is (S0, idle, busy, booked);
	Type switch_states  is (S0, waiting, wait_4_wr, wait_4_rd);
	Type switch_states2 is (S0, waiting, wait_4_wr, wait_4_rd, wait_4_eop);
	type load_status_states is (unloaded, loaded);
	Type ena_ctrl_states is (disable_val_nonactive, disable_val_active, able);
	type syn_bms_chn_synch_states is (S0, allow_ena, bms_block, chn_block, bms_chn_block, fifo_block);
	Type atl_buffer_fsm is (S0, out_idle, out_active, out_hold);
	

signal wr_state, next_wr_state : machine_States2;
signal rd_state, next_rd_state : machine_States;
signal chn_status, next_chn_status : status_states;
signal bms_status, next_bms_status : status_states;
signal atl_buffer_state, atl_buffer_next_state : atl_buffer_fsm;
signal readadd_ctrl, next_readadd_ctrl : counter_states; 
signal wr_errvec_ctrl, next_wr_errvec_ctrl : bi_status_states;
Signal wr_rd_altern_ctrl, next_wr_rd_altern_ctrl : switch_states2;
Signal wr_rd_synch_ctrl_bis,  next_wr_rd_synch_ctrl_bis : switch_states;
Signal ena_ctrl_state, next_ena_ctrl_state : ena_ctrl_states;
signal syn_bms_chn_synch_ctrl, next_syn_bms_chn_synch_ctrl : syn_bms_chn_synch_states;
Signal load_status, next_load_status : load_status_states; 
signal out_wr_fsm, out_rd_fsm : Std_Logic_Vector(4 downto 1);

signal numerrhold_q : matrix_w(3 downto 1);
signal decfail_1q, decfail_2q, bypass_int, load_syn_extend : Std_Logic;
signal dav_source_int, pull_numerr_fifo, pull_nc_ptr_fifo : Std_Logic;
Signal wr1, wr2, wr3, wr4, load_syn_int, load_syn_gen : std_logic;
Signal nc_ptr_ctrl, toggle_cnt_del : std_logic_vector(3 downto 1);
signal wr_ptr_ctrl : std_logic_vector(3 downto 0);
signal numerr_ctrl : std_logic_vector(2 downto 0);
signal dav_source_del : std_logic_vector(2 downto 1);

Signal wr_errvec_altern, rd_errvec_altern : std_logic;
Signal chn_end_point,	seed_cnt_eq_zero, rd_ge_block_size : std_logic;
signal sop_source_gen, eop_source_gen : Std_Logic;
signal eop_source_pipe, sop_source_pipe : std_logic_vector(4 downto 1);
Signal eop_gen_pipe_ena_2 : std_logic_vector(2 downto 1); 
Signal data_val_pipe : Std_Logic; 
signal align1, align2, align3 : std_logic_vector(m downto 1);
signal align1_err, align2_err, align3_err : std_logic_vector(m downto 1);
Signal rserrff_q, rserr_shunt, dat_source_int_d : std_logic_vector(m downto 1);
Signal align_fifo_ctrl : std_logic_vector(3 downto 1);
signal data_val_shunt, val_source_q : Std_Logic;
signal sop_source_shunt, eop_source_shunt : Std_Logic;
signal allow_val_assert, ena_syn_int : std_logic; 
Signal dav_source_gen, sink_eop_c, ena_syn_int_q : std_logic;
Signal load_wr_seed_cnt, rd_end_point, load_rd_seed_cnt : std_logic;
Signal wr_rd_end_point, load_wr_seed_cnt_d, load_wr_seed_cnt_q : std_logic;
Signal enable, pull_ptr_fifo, wr_err_val : std_logic;
Signal go_wr_errvec, load_chn_int : std_logic;
Signal decfail_gen, sink_ena_master_int : std_logic;
Signal decfail_gen_shunt : std_logic; 
Signal ena_1, ena_2, sink_eop_q_extend, sink_eop_q_int : std_logic;


function fourbits_2_3count(fourbits: std_logic_vector(3 downto 0)) return std_logic_vector is
	variable result : std_logic_vector(3 downto 1);

begin
	case fourbits(3 downto 0) is
	when "0000" => Result := "000";
	when "0001" => Result := "001";
	when "0010" => Result := "001";
	when "0011" => Result := "010";
	when "0100" => Result := "001";
	when "0101" => Result := "010";
	when "0110" => Result := "010";
	when "0111" => Result := "011";
	when "1000" => Result := "001";
	when "1001" => Result := "010";
	when "1010" => Result := "010";
	when "1011" => Result := "011";
	when "1100" => Result := "010";
	when "1101" => Result := "011";
	when "1110" => Result := "011";
	when "1111" => Result := "100";
	when others =>  Result := "000";
	end case;			
	return result;			 
end fourbits_2_3count;


begin

ena_bms <= enable;
ena_chn <= enable; 

-- if_var2: if Varcheck="true" generate
-- 
-- syn_bms_chn_synch_FSM: process(syn_bms_chn_synch_ctrl, bms_status, sink_eop,
								-- bms_done, sink_eop_c, chn_status, wr_rd_end_point, enable, wr_ptr_ctrl(1))
-- begin
	-- case syn_bms_chn_synch_ctrl is
	-- when S0 =>
		-- sink_ena_master_int <= '0';
		-- next_syn_bms_chn_synch_ctrl <= allow_ena;
	-- when allow_ena =>
		-- sink_ena_master_int <= '1';
		-- if (bms_status=idle or bms_done='1') and sink_eop='1' and (chn_status=booked or chn_status=busy) and sink_eop_c='0' and wr_rd_end_point='0' then
			-- next_syn_bms_chn_synch_ctrl <= chn_block;
		-- elsif bms_status=busy and sink_eop='1' and bms_done='0' and sink_eop_c='0' and (chn_status=idle or wr_rd_end_point='1') then
			-- next_syn_bms_chn_synch_ctrl <= bms_block;
		-- elsif bms_status=busy and bms_done='0' and sink_eop='1' and (chn_status=booked or chn_status=busy) and sink_eop_c='0' and wr_rd_end_point='0' then
			-- next_syn_bms_chn_synch_ctrl <= bms_chn_block;
		-- else
			-- next_syn_bms_chn_synch_ctrl <= allow_ena;
		-- end if;
	-- when bms_block => 
		-- sink_ena_master_int <= '0';
		-- if bms_done='1' and enable='1' and wr_ptr_ctrl(1)='0' then
			-- next_syn_bms_chn_synch_ctrl <= allow_ena;
		-- elsif bms_done='1' and enable='1' and wr_ptr_ctrl(1)='1' then
			-- next_syn_bms_chn_synch_ctrl <= fifo_block;
		-- else
			-- next_syn_bms_chn_synch_ctrl <= bms_block;
		-- end if;
	-- when fifo_block =>
		-- sink_ena_master_int <= '0';
		-- if wr_ptr_ctrl(1)='0' then
			-- next_syn_bms_chn_synch_ctrl <= allow_ena;
		-- else
			-- next_syn_bms_chn_synch_ctrl <= fifo_block;
		-- end if;
	-- when chn_block =>
		-- sink_ena_master_int <= '0';
		-- if wr_rd_end_point='1' and enable='1' then
			-- next_syn_bms_chn_synch_ctrl <= allow_ena;
		-- else
			-- next_syn_bms_chn_synch_ctrl <= chn_block;
		-- end if;
	-- when bms_chn_block => 
		-- sink_ena_master_int <= '0';
		-- if bms_done='1' and wr_rd_end_point='1' and enable='1' then
			-- next_syn_bms_chn_synch_ctrl <= allow_ena;
		-- elsif bms_done='0' and wr_rd_end_point='1' then
			-- next_syn_bms_chn_synch_ctrl <= bms_block;
		-- elsif bms_done='1' and wr_rd_end_point='0' then
			-- next_syn_bms_chn_synch_ctrl <= chn_block;
		-- else
			-- next_syn_bms_chn_synch_ctrl <= bms_chn_block;
		-- end if;
	-- -- coverage off
	-- when others => 
		-- sink_ena_master_int <= '0';
		-- next_syn_bms_chn_synch_ctrl <= S0;
	-- -- coverage on
	-- end case;
-- end process syn_bms_chn_synch_FSM;
-- 
-- end generate if_var2;


--if_non_var2: if Varcheck="false" generate

syn_bms_chn_synch_FSM: process(syn_bms_chn_synch_ctrl, bms_status, sink_eop,
								bms_done, sink_eop_c, chn_status, wr_rd_end_point, enable, wr_ptr_ctrl(1))
begin
	case syn_bms_chn_synch_ctrl is
	when S0 =>
		sink_ena_master_int <= '0';
		next_syn_bms_chn_synch_ctrl <= allow_ena;
	when allow_ena =>
		sink_ena_master_int <= '1';
		--if (bms_status=idle or bms_done='1') and sink_eop='1' and (chn_status=booked or chn_status=busy) and sink_eop_c='0' and wr_rd_end_point='0' then
			--next_syn_bms_chn_synch_ctrl <= chn_block;
		if (bms_status=idle or bms_done='1') and sink_eop='1' and chn_status=booked and sink_eop_c='0' and wr_rd_end_point='0' then
		-- didn't work
		--if chn_status=booked then
			next_syn_bms_chn_synch_ctrl <= chn_block;
		elsif bms_status=busy and sink_eop='1' and bms_done='0' and sink_eop_c='0' and (chn_status=idle or wr_rd_end_point='1') then
			next_syn_bms_chn_synch_ctrl <= bms_block;
		elsif bms_status=busy and bms_done='0' and sink_eop='1' and (chn_status=booked or chn_status=busy) and sink_eop_c='0' and wr_rd_end_point='0' then
			next_syn_bms_chn_synch_ctrl <= bms_chn_block;
		elsif bms_status=busy and bms_done='1' and sink_eop='1' and (chn_status=booked or chn_status=busy) and sink_eop_c='0' and wr_rd_end_point='0' then
			next_syn_bms_chn_synch_ctrl <= chn_block;
		else
			next_syn_bms_chn_synch_ctrl <= allow_ena;
		end if;
	when bms_block => 
		sink_ena_master_int <= '0';
		if bms_done='1' and enable='1' and wr_ptr_ctrl(1)='0' then
			next_syn_bms_chn_synch_ctrl <= allow_ena;
		elsif bms_done='1' and enable='1' and wr_ptr_ctrl(1)='1' then
			next_syn_bms_chn_synch_ctrl <= fifo_block;
		else
			next_syn_bms_chn_synch_ctrl <= bms_block;
		end if;
	when fifo_block =>
		sink_ena_master_int <= '0';
		if wr_ptr_ctrl(1)='0' then
			next_syn_bms_chn_synch_ctrl <= allow_ena;
		else
			next_syn_bms_chn_synch_ctrl <= fifo_block;
		end if;
	when chn_block =>
		sink_ena_master_int <= '0';
		if wr_rd_end_point='1' and enable='1' then
		-- didn't work
		--if chn_status/=booked and enable='1' then
			next_syn_bms_chn_synch_ctrl <= allow_ena;
		else
			next_syn_bms_chn_synch_ctrl <= chn_block;
		end if;
	when bms_chn_block => 
		sink_ena_master_int <= '0';
		if bms_done='1' and wr_rd_end_point='1' and enable='1' then
			next_syn_bms_chn_synch_ctrl <= allow_ena;
		elsif bms_done='0' and wr_rd_end_point='1' then
			next_syn_bms_chn_synch_ctrl <= bms_block;
		elsif bms_done='1' and wr_rd_end_point='0' then
			next_syn_bms_chn_synch_ctrl <= chn_block;
		else
			next_syn_bms_chn_synch_ctrl <= bms_chn_block;
		end if;
	-- coverage off
	when others => 
		sink_ena_master_int <= '0';
		next_syn_bms_chn_synch_ctrl <= S0;
	-- coverage on
	end case;
end process syn_bms_chn_synch_FSM;

--end generate if_non_var2;


clk_atl: Process (clk, reset)
	begin
	if reset='1' then
		-- sink_eop_c for signal conditioning
		sink_eop_c <= '0';
		load_wr_seed_cnt_q <= '0';
	elsif Rising_edge(clk) then
		sink_eop_c <= sink_eop;
		if enable='1' then
			load_wr_seed_cnt_q <= load_wr_seed_cnt_d;
		end if;
	end if;
		
end process clk_atl;

sink_ena_master <= sink_ena_master_int;
ena_syn <= ena_syn_int;

-- end Atlantic stuff

FSM_ena_ctrl: process(ena_ctrl_state,	sink_val, sink_ena_master_int)

begin
	case ena_ctrl_state is
	when disable_val_nonactive =>
		ena_syn_int <= '0';
		if sink_ena_master_int = '1' then
			next_ena_ctrl_state <= able;
		else
			next_ena_ctrl_state <= disable_val_nonactive;
		end if;
	when able => 
		ena_syn_int <= sink_val and sink_ena_master_int;
		if sink_ena_master_int='0' and sink_val='0' then
			next_ena_ctrl_state <= disable_val_nonactive;
		elsif sink_ena_master_int='0' and sink_val='1' then
			next_ena_ctrl_state <= disable_val_active;
		else
			next_ena_ctrl_state <= able;
		end if;
	when disable_val_active =>
		ena_syn_int <= sink_ena_master_int;
		if sink_ena_master_int = '1' then
			next_ena_ctrl_state <= able;
		else
			next_ena_ctrl_state <= disable_val_active;
		end if;
-- coverage off
	when others => next_ena_ctrl_state <= disable_val_nonactive;  
-- coverage on
	end case;
	
end process FSM_ena_ctrl;

-- new controller, keeping status of RAMs
FSM_wr: process(wr_state,	sink_eop_q )

	begin
		case wr_state is
		when S1 => 
			out_wr_fsm <= "0001";
			if sink_eop_q = '1' then
				next_wr_state <= S2;
			else
				next_wr_state <= S1;
			end if;
		when S2 => 
			out_wr_fsm <= "0010";
			if sink_eop_q = '1' then
				next_wr_state <= S3;
			else
				next_wr_state <= S2;
			end if;
		when S3 => 
			out_wr_fsm <= "0100";
			if sink_eop_q = '1' then
				next_wr_state <= S4;
			else
				next_wr_state <= S3;
			end if;
  	 when S4 => 
		 	out_wr_fsm <= "1000";
		 	if sink_eop_q = '1' then
				next_wr_state <= S1;
			else
			 next_wr_state <= S4;
			end if;
		
	-- coverage off
		when others =>
			out_wr_fsm <= "0000";
			next_wr_state <= S1;  
	-- coverage on
		end case;
		
	end process FSM_wr;


wr1 <= onein and ena_syn_int_q; 
wr2 <= twoin and ena_syn_int_q; 
wr3 <= thrin and ena_syn_int_q; 
wr4 <= forin and ena_syn_int_q; 

onein <= out_wr_fsm(1); 
twoin <= out_wr_fsm(2); 
thrin <= out_wr_fsm(3); 
forin <= out_wr_fsm(4);


FSM_rd: process(rd_state,	sop_source_pipe(1), eop_gen_pipe_ena_2(2))  

	begin
		case rd_state is
		when S0 => 
			out_rd_fsm <= "0000";
			if sop_source_pipe(1)='1' then
				next_rd_state <= S1;
			else
				next_rd_state <= S0;
			end if;
	  when S1 => 
			out_rd_fsm <= "0001";
			if eop_gen_pipe_ena_2(2)='1' then
				next_rd_state <= S2;
			else
				next_rd_state <= S1;
			end if;
		when S2 => 
			out_rd_fsm <= "0010";
			if eop_gen_pipe_ena_2(2)='1' then
				next_rd_state <= S3;
			else
				next_rd_state <= S2;
			end if;
		when S3 => 
			out_rd_fsm <= "0100";
			if eop_gen_pipe_ena_2(2)='1' then
				next_rd_state <= S4;
			else
				next_rd_state <= S3;
			end if;
  	when S4 => 
			out_rd_fsm <= "1000";
			if eop_gen_pipe_ena_2(2)='1' then
				next_rd_state <= S1;
			else
				next_rd_state <= S4;
			end if;
	-- coverage off
		when others =>
			out_rd_fsm <= "0000";
			next_rd_state <= S0;  
	-- coverage on
		end case;
		
end process FSM_rd;

oneout <= out_rd_fsm(1);
twoout <= out_rd_fsm(2);
throut <= out_rd_fsm(3);
forout <= out_rd_fsm(4);


--  FSM to control sink_ena_master
-- if sink_eop asserted AND bms_status=busy and bms_done=0
-- then disable sink_ena_master

FSM_bms: process(bms_status, bms_done, sink_eop_q_int, load_syn_int)

	begin
		case bms_status is
		when idle => 
			if load_syn_int = '1' then
				next_bms_status <= busy;
			else
				next_bms_status <= idle;
			end if;
		when busy => 
			if bms_done='0' and sink_eop_q_int='1' then
				next_bms_status <= booked;
			elsif bms_done = '1' and sink_eop_q_int='0' and load_syn_int='0' then
				next_bms_status <= idle;
			else
				next_bms_status <= busy;
			end if;
		when booked => 
			if bms_done = '1' then
				next_bms_status <= busy;
			else
				next_bms_status <= booked;
			end if;
  	 		
	-- coverage off
		when others => next_bms_status <= idle;  
		end case;
	-- coverage on
end process FSM_bms;


FSM_chn: process(chn_status,	bms_done, wr_rd_end_point) 

	begin
		case chn_status is
		when idle => 
			load_chn_int <= bms_done;
			if bms_done = '1' then
				next_chn_status <= busy;
			else
				next_chn_status <= idle;
			end if;
		when busy => 
			load_chn_int <= wr_rd_end_point and bms_done;
			if wr_rd_end_point = '1' and bms_done='0' then
				next_chn_status <= idle;
			elsif wr_rd_end_point = '1' and bms_done='1' then
				next_chn_status <= busy;
			elsif wr_rd_end_point = '0' and bms_done='1' then
				next_chn_status <= booked;
			else
				next_chn_status <= busy;
			end if;
		when booked =>
			load_chn_int <= wr_rd_end_point;
			if wr_rd_end_point = '1' then
				next_chn_status <= busy;
			else
				next_chn_status <= booked;
			end if;
	-- coverage off
		when others => 
			next_chn_status <= idle;  
			load_chn_int <= '0';
	-- coverage on	
		end case;
		
end process FSM_chn;


load_seed_counters_proc: process(wr_errvec_ctrl, readadd_ctrl, seed_cnt_eq_zero, go_wr_errvec,
               rd_ge_block_size, wr_rd_altern_ctrl, bms_status, load_syn_int, sink_eop_q_int, load_status, wr_ptr_ctrl(3))
begin
	if ((wr_errvec_ctrl=busy and seed_cnt_eq_zero='1') or
		 (wr_errvec_ctrl=idle and go_wr_errvec='1')) and readadd_ctrl=S0 and wr_ptr_ctrl(3)='0' then
		load_wr_seed_cnt <= '1';
		load_wr_seed_cnt_d <= '0';
	elsif wr_rd_altern_ctrl=waiting and load_status=unloaded and wr_ptr_ctrl(3)='0' then
		load_wr_seed_cnt <= go_wr_errvec or rd_ge_block_size;
		load_wr_seed_cnt_d <= '0';
	--elsif wr_rd_altern_ctrl=waiting and wr_errvec_ctrl=idle and load_status=unloaded and wr_ptr_ctrl(3)='0' then
	--	load_wr_seed_cnt <= rd_ge_block_size;
	--	load_wr_seed_cnt_d <= '0';
  --  I don't need to wait for rd_ge_block_size=1 for this!! 
	elsif wr_rd_altern_ctrl=waiting and wr_errvec_ctrl=idle and load_status=unloaded and wr_ptr_ctrl(3)='1' and sink_eop_q_int='1' then 
		load_wr_seed_cnt <= '0';
		load_wr_seed_cnt_d <= '1';
	elsif wr_rd_altern_ctrl=waiting and wr_ptr_ctrl(3)='0' then
		load_wr_seed_cnt <= rd_ge_block_size and seed_cnt_eq_zero;
		load_wr_seed_cnt_d <= '0';
	-- so it can happend that readadd finishes before seed_cnt
	-- another condition to assert load_wr_seed_cnt here is that bms_status be busy
	-- this if branch here is creating trouble in the current test case
	elsif wr_rd_altern_ctrl=wait_4_eop and ((wr_errvec_ctrl=idle and load_status=unloaded) or (wr_errvec_ctrl=busy and seed_cnt_eq_zero='1')) then
		load_wr_seed_cnt <= '0';
		load_wr_seed_cnt_d <= sink_eop_q_int;
	elsif wr_rd_altern_ctrl=wait_4_wr and wr_ptr_ctrl(3)='0' then --and (bms_status=busy or bms_status=booked) then
		load_wr_seed_cnt <= seed_cnt_eq_zero;
		load_wr_seed_cnt_d <= '0';
	-- I have to check with coverage is this iftree is ever executed
	elsif wr_rd_altern_ctrl=wait_4_wr and bms_status=idle then
		load_wr_seed_cnt <= seed_cnt_eq_zero and go_wr_errvec;
		load_wr_seed_cnt_d <= sink_eop_q_int and seed_cnt_eq_zero;
	elsif wr_rd_altern_ctrl=wait_4_wr then
		load_wr_seed_cnt <= seed_cnt_eq_zero and go_wr_errvec;
		load_wr_seed_cnt_d <= '0';
	elsif wr_rd_altern_ctrl=wait_4_rd and wr_ptr_ctrl(3)='0' then
		load_wr_seed_cnt <= rd_ge_block_size;
		load_wr_seed_cnt_d <= '0';
	elsif wr_rd_altern_ctrl=wait_4_rd and sink_eop_q_int='1' and load_status=unloaded and rd_ge_block_size='1' then
		load_wr_seed_cnt <= '0';
		load_wr_seed_cnt_d <= '1';
	else
		load_wr_seed_cnt <= '0';
		load_wr_seed_cnt_d <= '0';
	end if;
	
	-- load_rd_seed_cnt downt here
	if ((wr_errvec_ctrl=busy and seed_cnt_eq_zero='1') or
		 (wr_errvec_ctrl=idle and go_wr_errvec='1')) and readadd_ctrl=S0 then
		load_rd_seed_cnt <= '1';
	elsif wr_rd_altern_ctrl=waiting then
		load_rd_seed_cnt <= rd_ge_block_size and seed_cnt_eq_zero;
	-- so it can happend that readadd finishes before seed_cnt in variable
	elsif wr_rd_altern_ctrl=wait_4_eop then
		load_rd_seed_cnt <= sink_eop_q_int or seed_cnt_eq_zero;
	elsif wr_rd_altern_ctrl=wait_4_wr then
		load_rd_seed_cnt <= seed_cnt_eq_zero;
	elsif wr_rd_altern_ctrl=wait_4_rd then
		load_rd_seed_cnt <= rd_ge_block_size;
	else
		load_rd_seed_cnt <= '0';
	end if;
end process load_seed_counters_proc;

FSM_wradd: process(wr_errvec_ctrl,	seed_cnt_eq_zero, go_wr_errvec) 

begin
	case wr_errvec_ctrl is
	-- when S0 => 
		-- wr_err_val <= '0';
		-- if go_wr_errvec='1' then
			-- next_wr_errvec_ctrl <= busy;
		-- else
			-- next_wr_errvec_ctrl <= S0;
		-- end if;
	when busy => 
		wr_err_val <= '1';
	  if seed_cnt_eq_zero='1' and go_wr_errvec='0' then
			next_wr_errvec_ctrl <= idle;
		--elsif seed_cnt_eq_zero='0' and go_wr_errvec='1' then
		--	next_wr_errvec_ctrl <= booked;
		else
			next_wr_errvec_ctrl <= busy;
		end if;
	-- when booked => 
		-- wr_err_val <= '1';
		-- if seed_cnt_eq_zero='1' then
			-- next_wr_errvec_ctrl <= busy;
		-- else
			-- next_wr_errvec_ctrl <= booked;
		-- end if;
	when idle => 
		wr_err_val <= '0';
		if go_wr_errvec='1' then
			next_wr_errvec_ctrl <= busy;
		else
			next_wr_errvec_ctrl <= idle;
		end if;
	-- coverage off
	when others => 
		wr_err_val <= '0';
		next_wr_errvec_ctrl <= idle; --S0;
-- coverage on  
	end case;

end process FSM_wradd;


FSM_rdadd: process(readadd_ctrl, wr_errvec_ctrl, seed_cnt_eq_zero, rd_ge_block_size )

begin
	if (readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1' then
		eop_source_gen <= '1';
	else
		eop_source_gen <= '0';
	end if;
	case readadd_ctrl is
	when S0 => 
		if wr_errvec_ctrl=busy and seed_cnt_eq_zero='1' then
			next_readadd_ctrl <= busy;
		else
			next_readadd_ctrl <= S0;
		end if;
	when busy => 
		if wr_errvec_ctrl=busy and seed_cnt_eq_zero='1' and rd_ge_block_size='0' then
			next_readadd_ctrl <= booked;
		elsif (wr_errvec_ctrl=idle or seed_cnt_eq_zero='0') and rd_ge_block_size='1' then
			next_readadd_ctrl <= idle;
		else
			next_readadd_ctrl <= busy;
		end if;
	when booked => 
		if rd_ge_block_size='1' then
			next_readadd_ctrl <= busy;
		else
			next_readadd_ctrl <= booked;
		end if;
	when idle => 
		if wr_errvec_ctrl=busy and seed_cnt_eq_zero='1' then
			next_readadd_ctrl <= busy;
		else
			next_readadd_ctrl <= idle;
		end if;
-- coverage off
	when others => next_readadd_ctrl <= S0; 
-- coverage on
	end case;
end process FSM_rdadd;

FSM_wr_rd_switch: process(wr_rd_altern_ctrl, wr_errvec_ctrl, readadd_ctrl, seed_cnt_eq_zero, rd_ge_block_size, 
                          sink_eop_q_int, wr_ptr_ctrl, load_status) 

begin
	case wr_rd_altern_ctrl is
	when S0 => 
		if wr_errvec_ctrl=busy and seed_cnt_eq_zero='1' then
			next_wr_rd_altern_ctrl <= waiting;
		else
			next_wr_rd_altern_ctrl <= S0;
		end if;
	when waiting => 
	  -- if both counters finish at the same time there is toggling
		if (wr_errvec_ctrl=busy and seed_cnt_eq_zero='1') and 
		   ((readadd_ctrl/=busy and readadd_ctrl/=booked) or rd_ge_block_size='0') then
				next_wr_rd_altern_ctrl <= wait_4_rd;
		--elsif ((wr_errvec_ctrl=idle and (wr_ptr_ctrl(3)='0' or (wr_ptr_ctrl(3)='1' and sink_eop_q_int='1'))) or 
		--        (wr_errvec_ctrl=busy and seed_cnt_eq_zero='0')) and 
		elsif ((wr_errvec_ctrl=idle and load_status=loaded) or (wr_errvec_ctrl=busy and seed_cnt_eq_zero='0')) and 
		      ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1')  then
			next_wr_rd_altern_ctrl <= wait_4_wr;
		-- I think the second or has to go, it will only go to wait_4_eop if wr_errvec_ctrl is idle.
		--elsif ((wr_errvec_ctrl=idle and wr_ptr_ctrl(3)='1' and sink_eop_q_int='0') or
		--        (wr_errvec_ctrl=busy and seed_cnt_eq_zero='0')) and
		--      ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1') then
		elsif wr_errvec_ctrl=idle and --wr_ptr_ctrl(3)='1' and sink_eop_q_int='0') and
					load_status=unloaded and 
		      ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1') then
			next_wr_rd_altern_ctrl <= wait_4_eop;
		else
			next_wr_rd_altern_ctrl <= waiting;
		end if;
	when wait_4_rd =>
	-- However I am looking at the code and I think I have to remove dependencies upon wr_ptr_ctrl in wr_rd_altern !
		--if ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1') and wr_ptr_ctrl(3)='0' then
		if ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1') then --and load_status=loaded then --wr_ptr_ctrl(3)='0' then
			next_wr_rd_altern_ctrl <= waiting;
		--elsif ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1') and load_status=unloaded then --wr_ptr_ctrl(3)='1' then
		--	next_wr_rd_altern_ctrl <= wait_4_eop;
		else
			next_wr_rd_altern_ctrl <= wait_4_rd;
		end if;
	when wait_4_wr => 
		if (wr_errvec_ctrl=busy and seed_cnt_eq_zero='1') then
			next_wr_rd_altern_ctrl <= waiting;
		else
			next_wr_rd_altern_ctrl <= wait_4_wr;
		end if;
	when wait_4_eop =>
		if sink_eop_q_int='1' or wr_ptr_ctrl(3)='0' or load_status=loaded then
		--if load_status=loaded then
			next_wr_rd_altern_ctrl <= wait_4_wr;
		else
			next_wr_rd_altern_ctrl <= wait_4_eop;
		end if;
	-- coverage off
	when others => next_wr_rd_altern_ctrl <= S0;  
-- coverage on
	end case;

end process FSM_wr_rd_switch;


FSM_wr_rd_synch: process(wr_rd_synch_ctrl_bis, wr_errvec_ctrl, readadd_ctrl, chn_end_point, rd_end_point) 

begin
	case wr_rd_synch_ctrl_bis is
	when S0 => 
		wr_rd_end_point <= chn_end_point;
		if wr_errvec_ctrl=busy and chn_end_point='1' then
			next_wr_rd_synch_ctrl_bis <= waiting;
		else
			next_wr_rd_synch_ctrl_bis <= S0;
		end if;
	when waiting => 
	  wr_rd_end_point <= chn_end_point and rd_end_point;
		if (wr_errvec_ctrl=busy and chn_end_point='1') and 
		   ((readadd_ctrl/=busy and readadd_ctrl/=booked) or rd_end_point='0') then
			next_wr_rd_synch_ctrl_bis <= wait_4_rd;
		elsif (wr_errvec_ctrl=idle or chn_end_point='0') and 
		      ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_end_point='1') then
			next_wr_rd_synch_ctrl_bis <= wait_4_wr;
		else
			next_wr_rd_synch_ctrl_bis <= waiting;
		end if;
	when wait_4_rd => 
		wr_rd_end_point <= rd_end_point;
		if ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_end_point='1') then
			next_wr_rd_synch_ctrl_bis <= waiting;
		else
			next_wr_rd_synch_ctrl_bis <= wait_4_rd;
		end if;
	when wait_4_wr => 
		wr_rd_end_point <= chn_end_point;
		if (wr_errvec_ctrl=busy and chn_end_point='1') then
			next_wr_rd_synch_ctrl_bis <= waiting;
		else
			next_wr_rd_synch_ctrl_bis <= wait_4_wr;
		end if;
	-- coverage off
	when others =>
		wr_rd_end_point <= '0';
		next_wr_rd_synch_ctrl_bis <= S0;  
-- coverage on
	end case;

end process FSM_wr_rd_synch;

FSM_load_status: process(load_status, seed_cnt_eq_zero, load_wr_seed_cnt, load_wr_seed_cnt_q) 

begin
	case load_status is
	when unloaded => 
		if load_wr_seed_cnt='1' or load_wr_seed_cnt_q='1' then
			next_load_status <= loaded;
		else
			next_load_status <= unloaded;
		end if;
	when loaded => 
	-- no it is not loaded right here if the wr_ptr_fifo doesn't have the value yet!!
		if seed_cnt_eq_zero='1' and load_wr_seed_cnt='0' and load_wr_seed_cnt_q='0' then
			next_load_status <= unloaded;
		else
			next_load_status <= loaded;
		end if;
	-- coverage off
	when others =>
		next_load_status <= unloaded;  
-- coverage on
	end case;

end process FSM_load_status;


clk_FSM_status: Process (clk, reset)
	 begin
		 if Rising_edge(clk) then
		 if reset='1' then
			 bms_status <= idle;
			 chn_status <= idle;
			 readadd_ctrl <= S0; 
			 wr_errvec_ctrl <= idle; --S0;
			 wr_rd_altern_ctrl <= S0;
			 wr_rd_synch_ctrl_bis <= S0;
			 wr_state <= S1;
			 rd_state <= S0;
			 ena_ctrl_state <= disable_val_nonactive;
			 syn_bms_chn_synch_ctrl <= S0;
			 load_status <= unloaded;
		 else  --# reset
			 if enable='1' then
				 readadd_ctrl <= next_readadd_ctrl;
				 --rd_state <= next_rd_state;
				 wr_rd_altern_ctrl <= next_wr_rd_altern_ctrl;
				 chn_status <= next_chn_status;
				 wr_rd_synch_ctrl_bis <= next_wr_rd_synch_ctrl_bis;
				 wr_errvec_ctrl <= next_wr_errvec_ctrl;
				 --syn_bms_chn_synch_ctrl <= next_syn_bms_chn_synch_ctrl;
				 bms_status <= next_bms_status;
				 --wr_state <= next_wr_state;
				 load_status <= next_load_status;
			 end if;
				 --wr_rd_synch_ctrl_bis <= next_wr_rd_synch_ctrl_bis;
				 ena_ctrl_state <= next_ena_ctrl_state;
				 --load_status <= next_load_status;
			 --bms_status <= next_bms_status;
			 --chn_status <= next_chn_status;
			 wr_state <= next_wr_state;
			 rd_state <= next_rd_state;
			 syn_bms_chn_synch_ctrl <= next_syn_bms_chn_synch_ctrl;
		end if; --# reset
		 end if;
end process clk_FSM_status;

--------------------
-- end FSMs
--------------------

-- for atlantic writeadd increases with sink_val_q
-- it should only increase with that sink_Val is valid
-- filter out unvalid sink_val
-- for zeroing? I guess a controller + sink_sop_q
-- with sink_eop the value has to be stored for later processing
cnt_a : Process (clk, reset)
begin
	if reset='1' then
		writeadd <= (others => '0');
		writeadd_shunt <= (others => '0');
		ena_syn_int_q <= '0';
	elsif Rising_edge(clk) then
		ena_syn_int_q <= ena_syn_int;
		if sink_eop_q='1' then
			writeadd_shunt <= writeadd;
		end if;
		-- [Alex Diaz-Manero 04/20/2005]  After receiving notification of a disciplinary hearing for the 25th
		--this is now the source of the last vsim_error enable vs syn entity working out of enable scope (and rightly so)
		-- I need to let writeadd run even though enable=0 , however I cannot loose it's value should that happen
		-- as it has to be loaded into pipe_wr_prt. Explore shunt buffer solution.
		if sink_eop_q='1' then
			writeadd <= (others => '0');
		-- when I stop internally this has to stop as well!!
		--elsif sink_val_q='1' then
		--elsif ena_syn_int_q='1' and sink_eop_q_int='0' then
		elsif ena_syn_int_q='1' and sink_eop_q='0' then
			writeadd <= unsigned(writeadd) + natural(1); 
		end if;		
	end if;
end process cnt_a;

ena_syn_q <= ena_syn_int_q;

go_wr_errvec <= toggle_cnt_del(3);
pull_ptr_fifo <= load_wr_seed_cnt or load_wr_seed_cnt_q;

cnt_seed : Process (clk, reset)
begin
	if reset='1' then
		seed_cnt <= (others => '0');
		readadd <= (others => '0');
		seed_count_wr <= (others => '0');
		seed_count_rd <= (others => '0');
	elsif Rising_edge(clk) then
		if (load_wr_seed_cnt='1' or load_wr_seed_cnt_q='1') and enable='1' then
			seed_count_wr <= pipe_wr_ptr(2);
		end if;
		-- I have to review this ...
		-- yeap, this the source of a nasty fault, seed_count_rd gets overwritten before it should
		-- the controllers of wr_errvec_ctrl and readadd_ctrl need to coordinate this 
		-- and load seed_count_rd and seed_count_wr both at the same time and WHEN they
		-- are ready to do so!!
		if load_rd_seed_cnt='1' and enable='1' then
			seed_count_rd <= seed_count_wr;
		end if;
		if (load_wr_seed_cnt='1' or load_wr_seed_cnt_q='1') and enable='1' then
			seed_cnt <= pipe_wr_ptr(2);
		elsif wr_errvec_ctrl=busy and enable='1' then
			seed_cnt <= unsigned(seed_cnt) - natural(1); 
		end if;
		-- some work here to be done
		if rd_ge_block_size='1' and enable='1' then
			readadd <= (others => '0');
		elsif (readadd_ctrl=busy or readadd_ctrl=booked) and enable='1' then
			readadd <= unsigned(readadd) + natural(1);
		end if;
	end if;
end process cnt_seed;

rd_errvec_altern <= not wr_errvec_altern; 

process (reset, clk)
	begin
	if reset='1' then 
		wr_errvec_altern <= '0';
		dav_source_del <= (others => '0');
		dav_source_gen <= '0';
		sop_source_gen <= '0';
		dav_source_align <= (others => '0');
	elsif rising_edge(clk) then
	if enable='1' then
	-- when seed_cnt reaches zero + chn other than idle ?
	-- this needs major work here
		case wr_rd_altern_ctrl is
		when S0 => 
			if wr_errvec_ctrl=busy and seed_cnt_eq_zero='1' then
			-- toggle wr_errvec_altern
				wr_errvec_altern <= not wr_errvec_altern;
				sop_source_gen <= '1';
			else
				sop_source_gen <= '0';
			end if;
		when waiting => 
			-- if both counters finish at the same time there is toggling
			if (wr_errvec_ctrl=busy and seed_cnt_eq_zero='1') and 
			   ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1') then
				wr_errvec_altern <= not wr_errvec_altern;
				sop_source_gen <= '1';
			else
				sop_source_gen <= '0';
			end if;
		when wait_4_rd => 
			if ((readadd_ctrl=busy or readadd_ctrl=booked) and rd_ge_block_size='1') then
				wr_errvec_altern <= not wr_errvec_altern;
				sop_source_gen <= '1';
			else
				sop_source_gen <= '0';
			end if;
		when wait_4_wr => 
			if (wr_errvec_ctrl=busy and seed_cnt_eq_zero='1') then
				wr_errvec_altern <= not wr_errvec_altern;
				sop_source_gen <= '1';
			else
				sop_source_gen <= '0';
			end if;
		when wait_4_eop => 
			if (wr_errvec_ctrl=busy and seed_cnt_eq_zero='1') then
				wr_errvec_altern <= not wr_errvec_altern;
				sop_source_gen <= '1';
			else
				sop_source_gen <= '0';
			end if;
		-- coverage off
		when others => 
				wr_errvec_altern <= '0';
				sop_source_gen <= '0';
		end case;
		end if;
		
		if enable='1' then
			dav_source_del(1) <= dav_source_gen;
			dav_source_del(2) <= dav_source_del(1);
		end if;
		-- botched for quick implementation
		-- well this "botch" is already failing!! do correct
		-- dav goes high for 1 clock cycle and then gets deasserted because of idle _ctrl
		-- it should remain high!
		if readadd_ctrl=busy and enable='1' then
			dav_source_gen <= '1';
		elsif (readadd_ctrl=idle or readadd_ctrl=S0) and enable='1' then
			dav_source_gen <= '0';
		end if;
		-- I am going to introduce a new dav indicator that follows the following rule:
		-- de-asserted 2 clock cycles after readadd_ctrl changes from busy to idle. No enable is taken into consideration
		-- assert 2 clock cycles after readadd_ctrl changes from idle to busy. This time taking enable into consideration.
		-- only count clock cycles if enable is asserted
		if readadd_ctrl=idle then
			dav_source_align(1) <= '0';
		elsif readadd_ctrl=busy and enable='1' then
			dav_source_align(1) <= '1';
		end if;
		if dav_source_align(1)='0' then
			dav_source_align(2) <= '0';
		elsif dav_source_align(1)='1' and enable='1' then
			dav_source_align(2) <= '1';
		end if;
	end if;
end process;

dav_source_int <= dav_source_del(2);

latch_signals_worst_path: Process (clk, reset)
begin
if reset='1' then
	rd_end_point <= '0';
	chn_end_point <= '0';
	seed_cnt_eq_zero <= '0';
	pull_numerr_fifo <= '0';
	rd_ge_block_size <= '0';
elsif Rising_edge(clk) then
	if enable='1' then
	-- I guess doing this will increase the minimum CW size +1 (6)
		if (unsigned(seed_count_rd) - natural(4)) = unsigned(readadd) then
			rd_end_point <= '1';
		else
			rd_end_point <= '0';
		end if;
		if (unsigned(seed_cnt) = natural(4)) then
			chn_end_point <= '1';
		else
			chn_end_point <= '0';
		end if;
		if unsigned(seed_cnt) = natural(1) then
			seed_cnt_eq_zero <= '1';
			if wr_errvec_ctrl=busy then
				pull_numerr_fifo <= '1';
			else
				pull_numerr_fifo <= '0';
			end if;
		else
			seed_cnt_eq_zero <= '0';
			pull_numerr_fifo <= '0';
		end if;
		if (unsigned(readadd)+natural(1)) = unsigned(seed_count_rd) then
			rd_ge_block_size <= '1';
		else
			rd_ge_block_size <= '0';
		end if;
	end if;
end if;
end process latch_signals_worst_path;

add_transform: process(seed_cnt, seed_count_wr, seed_count_rd, wr_errvec_altern, rd_errvec_altern,
												wr_errvec_ctrl, toggle_cnt_del, readadd)
	Constant full_count : std_logic_vector(m downto 1) := (others => '1');
	variable offset_point_wr, offset_point_rd : std_logic_vector(m downto 1);
begin
  offset_point_wr := unsigned(full_count) - unsigned(seed_count_wr);
	offset_point_rd := unsigned(full_count) - unsigned(seed_count_rd);
	if wr_errvec_altern='0' then
		wr_errvec_add <= unsigned(seed_count_wr) - unsigned(seed_cnt);
	else
		wr_errvec_add <= unsigned(seed_cnt) + unsigned(offset_point_wr);
	end if;
	-- it should be based in readadd instead of seed_cnt
	if rd_errvec_altern='0' then
		rd_errvec_add <= unsigned(seed_count_rd) - unsigned(readadd);
	else
		rd_errvec_add <= unsigned(readadd) + unsigned(offset_point_rd);
	end if;

end process add_transform;

-- this pipe for write has to be controlled by ctrl 
-- and every stage has to go to next when appropriate
-- think that perhaps 1 block going through 
-- this arrangements of of blocks coming for this information to go through
-- rather NOT use memory for this information.
-- sink_eop_q_int = push_ptr_fifo

pipe_ptr : Process (clk, reset)
begin
if reset='1' then
	pipe_wr_ptr <= (others => (others => '0'));
	wr_ptr_ctrl(3 downto 0) <= "1000";
elsif Rising_edge(clk) then
  -- chance it may miss a sink_eop during enable=0?
	-- YES, I need an "extender" for sink_eop_q_int
	-- no, better "reduce" pull_ptr_fifo and remove the enable
	if sink_eop_q_int='1' and pull_ptr_fifo='0' and enable='1' then 
		wr_ptr_ctrl(2 downto 0) <= wr_ptr_ctrl(3 downto 1);
		wr_ptr_ctrl(3) <= '0';
	elsif sink_eop_q_int='0' and pull_ptr_fifo='1' and wr_ptr_ctrl(3)='0' and enable='1' then
		wr_ptr_ctrl(3 downto 1) <= wr_ptr_ctrl(2 downto 0);
		wr_ptr_ctrl(0) <= '0';
		-- what if sink_eop_q_int and pull_ptr collide? wr_ptr_ctrl stays the same.
	end if;
	
	if ((sink_eop_q_int='1' and (wr_ptr_ctrl(2)='1' or wr_ptr_ctrl(3)='1') and pull_ptr_fifo='0' and enable='1') or 
	   (sink_eop_q_int='1' and wr_ptr_ctrl(1)='1' and pull_ptr_fifo='1' and enable='1'))  then 
		pipe_wr_ptr(1) <= (writeadd and (m downto 1 => not sink_eop_q_extend)) or (writeadd_shunt and (m downto 1 => sink_eop_q_extend));
	elsif pull_ptr_fifo='1' and enable='1' then
		pipe_wr_ptr(1) <= writeadd_shunt;
	end if;
	if ((sink_eop_q_int='1' and wr_ptr_ctrl(3)='1' and pull_ptr_fifo='0' and enable='1') or
	   (sink_eop_q_int='1' and wr_ptr_ctrl(2)='1' and pull_ptr_fifo='1' and enable='1')) then
		pipe_wr_ptr(2) <= (writeadd and (m downto 1 => not sink_eop_q_extend)) or (writeadd_shunt and (m downto 1 => sink_eop_q_extend));
	elsif pull_ptr_fifo='1' and enable='1' then
		pipe_wr_ptr(2) <= pipe_wr_ptr(1);
	end if;
end if;
end process pipe_ptr;

if_var: if Varcheck="true" generate

pipe_ptr_nc : Process (clk, reset)
begin
if reset='1' then
	pipe_nc_ptr <= (others => (others => '0'));
	nc_ptr_ctrl(3 downto 1) <= "100";
elsif Rising_edge(clk) then
-- [Alex Diaz-Manero 20/04/2005  17:50  second issue being tackled after 
-- being handled an invitation for a Disciplinary hearing.
-- the issue here is the loading of pipe_nc_ptr with sink_eop
-- how do I manage this?
	if sink_eop_q_int='1' and pull_nc_ptr_fifo='0' and enable='1' then 
		nc_ptr_ctrl(2 downto 1) <= nc_ptr_ctrl(3 downto 2);
		nc_ptr_ctrl(3) <= '0';
	elsif sink_eop_q_int='0' and pull_nc_ptr_fifo='1' and nc_ptr_ctrl(3)='0' and enable='1' then
		nc_ptr_ctrl(3 downto 2) <= nc_ptr_ctrl(2 downto 1);
		nc_ptr_ctrl(1) <= '0';
	end if;
	if (sink_eop_q='1' and nc_ptr_ctrl(2)='1' and pull_nc_ptr_fifo='0') or 
	   (sink_eop_q='1' and nc_ptr_ctrl(1)='1' and pull_nc_ptr_fifo='1') then
		pipe_nc_ptr(1) <= numcheck;
	end if;
	if (sink_eop_q='1' and nc_ptr_ctrl(3)='1' and pull_nc_ptr_fifo='0') or
	   (sink_eop_q='1' and nc_ptr_ctrl(2)='1' and pull_nc_ptr_fifo='1') then
		pipe_nc_ptr(2) <= numcheck;
	elsif pull_nc_ptr_fifo='1' and enable='1' and sink_eop_q_extend='0' then
		pipe_nc_ptr(2) <= pipe_nc_ptr(1);
	end if;
end if;
end process pipe_ptr_nc;

pull_nc_ptr_fifo <= bms_done;
numcheck_bms <= pipe_nc_ptr(2);

end generate if_var;
	

	RAM_DP_1: altsyncram 
   GENERIC map (
      operation_mode => "DUAL_PORT", width_a => m, widthad_a => m, numwords_a => 2**m,
      outdata_reg_a => "UNUSED", 
      outdata_aclr_a => "UNUSED",  
			width_byteena_a => 1, address_reg_b => "CLOCK0",
			width_b => m, widthad_b => m, numwords_b => 2**m,
			rdcontrol_reg_b => "CLOCK0",
			outdata_reg_b => "CLOCK0", outdata_aclr_b => "UNUSED", rdcontrol_aclr_b => "UNUSED",
			indata_reg_b => "UNUSED", wrcontrol_wraddress_reg_b => "UNUSED",
			indata_aclr_b => "UNUSED", wrcontrol_aclr_b => "UNUSED", 
      READ_DURING_WRITE_MODE_MIXED_PORTS => "DONT_CARE", RAM_BLOCK_TYPE => "AUTO",
      INTENDED_DEVICE_FAMILY => DEV_FAMILY, LPM_HINT => "UNUSED")
			
   PORT map (
      wren_a => wr1, data_a => rsin, address_a => writeadd,
			address_b => readadd, clock0 => clk,
			rden_b => enable,
      q_b => dataone_q );

	RAM_DP_2: altsyncram 
   GENERIC map (
      operation_mode => "DUAL_PORT", width_a => m, widthad_a => m, numwords_a => 2**m,
      outdata_reg_a => "UNUSED", --address_aclr_a => "CLEAR0",
      outdata_aclr_a => "UNUSED", --indata_aclr_a => "CLEAR0", wrcontrol_aclr_a => "CLEAR0", 
			width_byteena_a => 1, address_reg_b => "CLOCK0",
			width_b => m, widthad_b => m, numwords_b => 2**m,
			rdcontrol_reg_b => "CLOCK0",
			outdata_reg_b => "CLOCK0", outdata_aclr_b => "UNUSED", rdcontrol_aclr_b => "UNUSED",
			indata_reg_b => "UNUSED", wrcontrol_wraddress_reg_b => "UNUSED",
			indata_aclr_b => "UNUSED", wrcontrol_aclr_b => "UNUSED", --address_aclr_b => "CLEAR0",
      READ_DURING_WRITE_MODE_MIXED_PORTS => "DONT_CARE", RAM_BLOCK_TYPE => "AUTO",
      INTENDED_DEVICE_FAMILY => DEV_FAMILY, LPM_HINT => "UNUSED")
   PORT map (
      wren_a => wr2, data_a => rsin, address_a => writeadd,
			address_b => readadd, clock0 => clk,
			rden_b => enable,
      q_b => datatwo_q );

	RAM_DP_3: altsyncram 
   GENERIC map (
      operation_mode => "DUAL_PORT", width_a => m, widthad_a => m, numwords_a => 2**m,
      outdata_reg_a => "UNUSED", --address_aclr_a => "CLEAR0",
      outdata_aclr_a => "UNUSED", --indata_aclr_a => "CLEAR0", wrcontrol_aclr_a => "CLEAR0", 
			width_byteena_a => 1, address_reg_b => "CLOCK0",
			width_b => m, widthad_b => m, numwords_b => 2**m,
			rdcontrol_reg_b => "CLOCK0",
			outdata_reg_b => "CLOCK0", outdata_aclr_b => "UNUSED", rdcontrol_aclr_b => "UNUSED",
			indata_reg_b => "UNUSED", wrcontrol_wraddress_reg_b => "UNUSED",
			indata_aclr_b => "UNUSED", wrcontrol_aclr_b => "UNUSED", --address_aclr_b => "CLEAR0",
      READ_DURING_WRITE_MODE_MIXED_PORTS => "DONT_CARE", RAM_BLOCK_TYPE => "AUTO",
      INTENDED_DEVICE_FAMILY => DEV_FAMILY, LPM_HINT => "UNUSED")
   PORT map (
      wren_a => wr3, data_a => rsin, address_a => writeadd,
			address_b => readadd, clock0 => clk,
			rden_b => enable,
      --clocken0 => enable, --aclr0 => reset, 
      q_b => datathr_q );

RAM_DP_4: altsyncram 
   GENERIC map (
      operation_mode => "DUAL_PORT", width_a => m, widthad_a => m, numwords_a => 2**m,
      outdata_reg_a => "UNUSED", --address_aclr_a => "CLEAR0",
      outdata_aclr_a => "UNUSED", --indata_aclr_a => "CLEAR0", wrcontrol_aclr_a => "CLEAR0", 
			width_byteena_a => 1, address_reg_b => "CLOCK0",
			width_b => m, widthad_b => m, numwords_b => 2**m,
			rdcontrol_reg_b => "CLOCK0",
			outdata_reg_b => "CLOCK0", outdata_aclr_b => "UNUSED", rdcontrol_aclr_b => "UNUSED",
			indata_reg_b => "UNUSED", wrcontrol_wraddress_reg_b => "UNUSED",
			indata_aclr_b => "UNUSED", wrcontrol_aclr_b => "UNUSED", --address_aclr_b => "CLEAR0",
      READ_DURING_WRITE_MODE_MIXED_PORTS => "DONT_CARE", RAM_BLOCK_TYPE => "AUTO",
      INTENDED_DEVICE_FAMILY => DEV_FAMILY, LPM_HINT => "UNUSED")
   PORT map (
      wren_a => wr4, data_a => rsin, address_a => writeadd,
			address_b => readadd, clock0 => clk,
			rden_b => enable,
      --clocken0 => enable, --aclr0 => reset, 
      q_b => datafor_q );
			
			
data_2_correct <= (dataone_q and (m downto 1 => oneout)) or (datatwo_q and (m downto 1 => twoout)) or
		  	 			    (datathr_q and (m downto 1 => throut)) or (datafor_q and (m downto 1 => forout));

	RAM_DP_err_value: altsyncram 
   GENERIC map (
      OPERATION_MODE => "DUAL_PORT", WIDTH_A => m, WIDTHAD_A => m, NUMWORDS_A => 2**m,
      OUTDATA_REG_A => "UNUSED", --ADDRESS_ACLR_A => "CLEAR0",
      OUTDATA_ACLR_A => "UNUSED", --INDATA_ACLR_A => "CLEAR0", WRCONTROL_ACLR_A => "CLEAR0", 
			WIDTH_BYTEENA_A => 1, ADDRESS_REG_B => "CLOCK0",
			WIDTH_B => m, WIDTHAD_B => m, NUMWORDS_B => 2**m,
			rdcontrol_reg_b => "CLOCK0",
			OUTDATA_REG_B => "CLOCK0", OUTDATA_ACLR_B => "UNUSED", RDCONTROL_ACLR_B => "UNUSED",
			INDATA_REG_B => "UNUSED", WRCONTROL_WRADDRESS_REG_B => "UNUSED",
			INDATA_ACLR_B => "UNUSED", WRCONTROL_ACLR_B => "UNUSED", --ADDRESS_ACLR_B => "CLEAR0",
      READ_DURING_WRITE_MODE_MIXED_PORTS => "DONT_CARE", RAM_BLOCK_TYPE => "AUTO",
      INTENDED_DEVICE_FAMILY => DEV_FAMILY, LPM_HINT => "UNUSED")

   PORT map (
      wren_a => wr_err_val, data_a => errvec, address_a => wr_errvec_add,
			address_b => rd_errvec_add, clock0 => clk,
			rden_b => enable, 
      --clocken0 => enable, --aclr0 => reset, 
      q_b => err_value_swap );


--For transferring syndromes syn -> bms need signal load_syn which 
--which will be tightly controlled. It will be sink_eop_q_int when the 
--syn finishes and bms is ready to received otherwise it will be delayed. 
--I think that ena in bms won’t be needed as FSM with exert control.

-- right now simple implementation 
-- but this load_chn signal ought to be controlled by FSM
chn_load: process (reset, clk)
	begin
	if reset='1' then 
		toggle_cnt_del <= (others => '0');
		load_syn_extend <= '0';
		sink_eop_q_extend <= '0';
	elsif rising_edge(clk) then
	-- I get stuck if enable this pipe
		if enable='1' then
			toggle_cnt_del(1) <= load_chn_int;
			toggle_cnt_del(3 downto 2) <= toggle_cnt_del(2 downto 1);
		end if;
		if enable='0' and load_syn_gen='1' then
			load_syn_extend <= '1';
		elsif enable='1' then
			load_syn_extend <= '0';
		end if;
		if enable='0' and sink_eop_q='1' then
			sink_eop_q_extend <= '1';
		elsif enable='1' then
			sink_eop_q_extend <= '0';
		end if;
	end if;
end process chn_load;


load_chn <= load_chn_int;
load_syn <= load_syn_gen and not load_syn_extend; 
bms_clear <= load_syn_int;
load_syn_int <= load_syn_gen or load_syn_extend;
sink_eop_q_int <= sink_eop_q or sink_eop_q_extend;

-- load_syn still needs some work. In the case sink_eop comes along and 
-- bms is still busy.
-- sink_ena_master_int
syn_load: process(sink_eop_q_int, bms_status, bms_done, syn_bms_chn_synch_ctrl,	wr_rd_end_point) 
begin 
  -- in here if chn_status= booked and load_syn happens before load_chn the
	-- polynomials of bms get lost!! 
	-- an FSM is needed here to synch load_chn when chn_status=booked with load_syn when bms_status=idle.
	if (bms_status=idle or (bms_status=busy and bms_done='1')) and sink_eop_q_int='1' and syn_bms_chn_synch_ctrl=allow_ena then
		load_syn_gen <= '1';
	-- bms_status jumps to busy with sink_eop ... 
	elsif syn_bms_chn_synch_ctrl=chn_block then
		load_syn_gen <= wr_rd_end_point;
	elsif syn_bms_chn_synch_ctrl=bms_block then --or syn_bms_chn_synch_ctrl=allow_ena then
	-- 30-01-2005  I am getting a situation where I am loading bms before loading chn!!
	-- still here I am getting load_syn in front of load_chn here.
		load_syn_gen <= bms_done; --'1';
	elsif syn_bms_chn_synch_ctrl=bms_chn_block then
		load_syn_gen <= bms_done and wr_rd_end_point;
	else
		load_syn_gen <= '0';
	end if;
end process syn_load;


----------------------------
ifg_full_bit_count: if err_bit_connect="full_count" generate

err_count: process(errvec, wr_err_val)
	variable count: natural;
begin
	count := 0;
	if wr_err_val='1' then
		for i in 1 to m loop
			if errvec(i) = '1' then
				count := count + 1;
			end if;
		end loop;
	else
		count := 0;
	end if;
  err_add_bit <= 
	CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => count, SIZE => log2m), SIZE => log2m);
end process err_count;

err_bit_accum_d <= unsigned(err_bit_accum_q) + unsigned(err_add_bit);

err_bit_accum : Process (clk, reset)
begin
if reset = '1' then
	err_bit_accum_q <= (others => '0');
	err_bit_out_q <= (others => '0');
	num_err_bit <= (others => '0');
elsif Rising_edge(clk) then
	if enable='1' then
		if seed_cnt_eq_zero='0' then
			err_bit_accum_q <= err_bit_accum_d;
		else
		  err_bit_accum_q <= (others => '0');
		end if;
		if seed_cnt_eq_zero='1' then
			err_bit_out_q <= err_bit_accum_d;
		end if;
	end if;
	if enable='1' and sop_source_pipe(3)='1' and decfail_1q='0' then
		num_err_bit <= err_bit_out_q;
	elsif enable='1' and sop_source_pipe(3)='1' and decfail_1q='1' then
		num_err_bit <= (others => '0');
	end if;
end if;
end process err_bit_accum;

num_err_bit0 <= (others => '0');
num_err_bit1 <= (others => '0');

end generate ifg_full_bit_count;


ifg_split_bit_count: if err_bit_connect="split_count" generate

	-- BIG PROBLEM HERE Ineed the data_2_correct in reverse to compute
	-- the split bit error count. And I don'thave this readily available
	-- in v4 of the core!!
	--err_val_bit0 <= err_value_swap and data_2_correct;
	--err_val_bit1 <= err_value_swap and not data_2_correct;
	--err_val_bit0 <= align1_err and align1 and (m downto 1 => dav_source_del(2));
	--err_val_bit1 <= align1_err and not align1 and (m downto 1 => dav_source_del(2));
	err_val_bit0 <= err_value_swap and dat_source_int_d and (m downto 1 => dav_source_align(2) and not decfail_1q);
	err_val_bit1 <= err_value_swap and not dat_source_int_d and (m downto 1 => dav_source_align(2) and not decfail_1q);
	
ifgmnot8: if m/=8 generate
err_count_split: process(err_val_bit0, err_val_bit1) --, decfail_1q)
	variable count0, count1: natural;
begin
	count0 := 0;
	count1 := 0;
	--if decfail_1q='0' then
		for i in 1 to m loop
			if err_val_bit0(i) = '1' then
				count0 := count0 + 1;
			end if;
			if err_val_bit1(i) = '1' then
				count1 := count1 + 1;
			end if;
		end loop;
	--else
		--count0 := 0;
		--count1 := 0;
	--end if;
  err_add_bit0_d <= 
	CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => count0, SIZE => log2m), SIZE => log2m);
	err_add_bit1_d <= 
	CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => count1, SIZE => log2m), SIZE => log2m);
end process err_count_split;
end generate ifgmnot8;

ifgm8: if m=8 generate
err_count_split: process(err_val_bit0, err_val_bit1)
  variable tmp : std_logic_vector(3 downto 0); 
	variable count0_msb, count0_lsb: std_logic_vector(3 downto 1);
	variable count1_msb, count1_lsb: std_logic_vector(3 downto 1);
begin
	count0_msb := fourbits_2_3count(err_val_bit0(8 downto 5));
	count0_lsb := fourbits_2_3count(err_val_bit0(4 downto 1));
	count1_msb := fourbits_2_3count(err_val_bit1(8 downto 5));
	count1_lsb := fourbits_2_3count(err_val_bit1(4 downto 1));
  err_add_bit0_d <= unsigned('0'&count0_msb) + unsigned('0'&count0_lsb);
	err_add_bit1_d <= unsigned('0'&count1_msb) + unsigned('0'&count1_lsb);
end process err_count_split;
end generate ifgm8;


--err_bit0_accum_d <= unsigned(err_bit0_accum_q) + unsigned(err_add_bit0_d);
--err_bit1_accum_d <= unsigned(err_bit1_accum_q) + unsigned(err_add_bit1_);
err_bit0_accum_d <= unsigned(err_bit0_accum_q) + unsigned(err_add_bit0_q);
err_bit1_accum_d <= unsigned(err_bit1_accum_q) + unsigned(err_add_bit1_q);

err_bit_accum_dual : Process (clk, reset)
begin
if reset = '1' then
	err_add_bit0_q <= (others => '0');
	err_add_bit1_q <= (others => '0');
	err_bit0_accum_q <= (others => '0');
	err_bit1_accum_q <= (others => '0');
	num_err_bit0 <= (others => '0');
	num_err_bit1 <= (others => '0');
elsif Rising_edge(clk) then
	--if enable='1' then
	if ena_2='1' then
		err_add_bit0_q <= err_add_bit0_d; 
		err_add_bit1_q <= err_add_bit1_d;
		if eop_source_pipe(4)='0' then
			err_bit0_accum_q <= err_bit0_accum_d;
			err_bit1_accum_q <= err_bit1_accum_d;
		else
		  --err_bit0_accum_q(log2m downto 1) <= err_add_bit0_d;
			--err_bit1_accum_q(log2m downto 1) <= err_add_bit1_d;
			err_bit0_accum_q(log2m downto 1) <= err_add_bit0_q;
			err_bit1_accum_q(log2m downto 1) <= err_add_bit1_q;
			err_bit0_accum_q(bitwide downto log2m+1) <= (others => '0');
			err_bit1_accum_q(bitwide downto log2m+1) <= (others => '0');
		end if;
	end if;
	if enable='1' and eop_source_pipe(4)='1' then
		num_err_bit0 <= err_bit0_accum_q; 
		num_err_bit1 <= err_bit1_accum_q; 
	end if;
end if;
end process err_bit_accum_dual;

num_err_bit <= (others => '0');

end generate ifg_split_bit_count;

-- pull_numerr_fifo controlled by end of chn
-- it is seed_cnt_eq_zero and wr_errvec_ctrl=busy or booked
-- numerr_ctrl(0)=1 means full
pipe_numerr : Process (clk, reset)
begin
if reset='1' then
	numerrhold_q <= (others => (others => '0'));
	numerr_ctrl(2 downto 0) <= "100";
elsif Rising_edge(clk) then
-- I think the control has to change and have 1 extra bit for full status
	if bms_done='1' and pull_numerr_fifo='0' and enable='1' then 
		numerr_ctrl(1 downto 0) <= numerr_ctrl(2 downto 1);
		numerr_ctrl(2) <= '0';
	elsif bms_done='0' and pull_numerr_fifo='1' and numerr_ctrl(2)='0' and enable='1' then
		numerr_ctrl(2 downto 1) <= numerr_ctrl(1 downto 0);
		numerr_ctrl(0) <= '0';
		-- what if bms_done and pull_numerr_fifo collide?
		-- first write then pull. NO override the numerr_ctrl by 1
	end if;
	if bms_done='1' and numerr_ctrl(1)='1' and pull_numerr_fifo='0' and enable='1' then
		numerrhold_q(1) <= numerr_bms;
	elsif bms_done='1' and numerr_ctrl(1)='1' and pull_numerr_fifo='1' and enable='1' then
		numerrhold_q(2) <= numerr_bms;
	end if;
	if bms_done='1' and numerr_ctrl(2)='1' and pull_numerr_fifo='0' and enable='1' then
		numerrhold_q(2) <= numerr_bms;
		-- I have to consider collision here
	elsif pull_numerr_fifo='1' and bms_done='0' and enable='1' then
		numerrhold_q(2) <= numerrhold_q(1);
	end if;
	if pull_numerr_fifo='1' and enable='1' then
		numerrhold_q(3) <= numerrhold_q(2);
	end if;
end if;
end process pipe_numerr;

-- calculate decoding failure (totalhold_q[] <> numerrhold_q[])
-- if decfail, don't correct, i.e. bypass data
bypass_int <= bypass or decfail_1q;
decfail <= decfail_2q;

clocking_decfail : Process (clk, reset)
begin
if reset='1' then
	decfail_1q <= '0';
	decfail_2q <= '0';
	num_err_sym <= (others => '0');
elsif Rising_edge(clk) then
	if eop_gen_pipe_ena_2(2)='1' or sop_source_pipe(1)='1' then
		decfail_1q <= decfail_gen;
	end if;
	if enable='1' and sop_source_pipe(3)='1' then
		decfail_2q <= decfail_1q;
	end if;
	if enable='1' and sop_source_pipe(3)='1' then
		num_err_sym <= numerrhold_q(3);
	end if;
end if;
end process clocking_decfail;


counter_b : Process (clk, reset)
BEGIN
	if reset='1' then
		numroots <= (others => '0');
	elsif Rising_edge(clk) then
		if toggle_cnt_del(1)='1' and polyzero='1' then
			numroots <= (others => '0');
		elsif toggle_cnt_del(1)='1' and polyzero='0' then
			numroots(1) <= '1';
			numroots(wide downto 2) <= (others => '0');
		elsif polyzero='0' and (chn_status=busy or chn_status=booked) and enable='1' then
			numroots <= unsigned(numroots) + natural(1);
		end if;
	end if;
END PROCESS counter_b;

decfail_gen_proc: process(reset, clk)
begin
	if reset='1' then
		decfail_gen <= '0';
		decfail_gen_shunt <= '0';
	elsif Rising_edge(clk) then
		if chn_end_point='1' and (chn_status=busy or chn_status=booked) and enable='1' and ena_1='1' then
			if polyzero='0' then
				if (unsigned(numroots)+natural(1)) = unsigned(numerrhold_q(2)) then
					decfail_gen <= '0';
				else
					decfail_gen <= '1';
				end if;
			else
				if unsigned(numroots) = unsigned(numerrhold_q(2)) then
					decfail_gen <= '0';
				else
					decfail_gen <= '1';
				end if;
			end if;
		elsif chn_end_point='1' and (chn_status=busy or chn_status=booked) and enable='1' and ena_1='0' then
			decfail_gen <= decfail_gen_shunt;
		end if;
		if chn_end_point='1' and (chn_status=busy or chn_status=booked) and enable='0' then
			if polyzero='0' then
				if (unsigned(numroots)+natural(1)) = unsigned(numerrhold_q(2)) then
					decfail_gen_shunt <= '0';
				else
					decfail_gen_shunt <= '1';
				end if;
			else
				if unsigned(numroots) = unsigned(numerrhold_q(2)) then
					decfail_gen_shunt <= '0';
				else
					decfail_gen_shunt <= '1';
				end if;
			end if;
		end if;
	end if;
end process decfail_gen_proc; 

-------------------
--  Atlantic I + Atlantic II 0.4 spec

clk_FSM_atl: Process (clk, reset)
	begin
		if reset='1' then
			atl_buffer_state <= S0;
		elsif Rising_edge(clk) then
			atl_buffer_state <= atl_buffer_next_state;
		end if;
		
end process clk_FSM_atl;

-- Atlantic I + Atlantic II 0.4 spec
-------------------

FSM_out : process(atl_buffer_state, dav_source_int, source_ena)

	variable atl_buffer_next_state_var : atl_buffer_fsm;

begin

  atl_buffer_next_state_var := atl_buffer_state;
  case atl_buffer_state is
	
	when S0 =>
		atl_buffer_next_state_var := out_idle;
	when out_idle =>
		if dav_source_int='1' and source_ena='1' then
			atl_buffer_next_state_var := out_active;
		elsif dav_source_int='1' and source_ena='0' then
			atl_buffer_next_state_var := out_hold;
		end if;
	when out_hold =>
		if dav_source_int='1' and source_ena='1' then 
			atl_buffer_next_state_var := out_active;
		elsif dav_source_int='0' and source_ena='1' then 
			atl_buffer_next_state_var := out_idle;
		end if;
	when out_active =>
		if source_ena='0' then 
      atl_buffer_next_state_var := out_hold;
		elsif dav_source_int='0' then
      atl_buffer_next_state_var := out_idle;
    end if;
	
	-- coverage off
	when others => atl_buffer_next_state_var := out_idle;
	-- coverage on
	end case;
	atl_buffer_next_state <= atl_buffer_next_state_var;
	
end process FSM_out;


outputs_FSM_atl: process(atl_buffer_state, dav_source_int) 

	begin
		case atl_buffer_state is
		
		when S0 =>
			allow_val_assert <= '0';
			enable <= '0';
		when out_idle =>
			allow_val_assert <= dav_source_int;
			enable <= '1';
		when out_active =>
			allow_val_assert <= dav_source_int;
			enable <= '1';
		when out_hold =>
			allow_val_assert <= '1';
			enable <= '0';
		-- coverage off
		when others => 
			allow_val_assert <= '0';
			enable <= '0';
		-- coverage on
		end case;
		
end process outputs_FSM_atl;

-- dat_source_int_d is data_corrected or delivered
dat_source_int_d <= ((data_2_correct xor err_value_swap) and (m downto 1 => not bypass_int)) or
						        (data_2_correct and (m downto 1 => bypass_int));

ifg_rserr: if rserr_connect="true" generate
	last_pipe_rserr_reg : Process (clk, reset)
		variable rserrff_d : std_logic_vector(m downto 1);
	begin
		if reset = '1' then
			rserrff_q <= (others => '0');
			rserr_shunt <= (others => '0');
		elsif Rising_edge(clk) then
			if enable='1' then
				rserrff_d := align1_err; 
			else
				rserrff_d := rserr_shunt; 
			end if;
			if enable='1' then
				rserr_shunt <= align1_err; 
			end if;
			if source_ena='1' then
				rserrff_q <= rserrff_d;
			end if;
		end if;
	end process last_pipe_rserr_reg;
	
	rserr <= rserrff_q;
end generate ifg_rserr;
 
last_pipe_reg : Process (clk, reset)

	variable sop_source_d, eop_source_d : Std_Logic;
	variable rsoutff_d : std_logic_vector(m downto 1);
	variable data_val_d : Std_Logic;
  
begin
if reset = '1' then
	rsoutff_q <= (others => '0');
	rsout_shunt <= (others => '0');
	data_val_shunt <= '0';
	val_source_q <= '0';
  eop_source_shunt <= '0';
	sop_source_shunt <= '0';
  eop_source_shunt <= '0';
	data_val_pipe <= '0';
	eop_source_pipe <= (others => '0');
	sop_source_pipe <= (others => '0');
	eop_gen_pipe_ena_2 <= (others => '0');
	-- fifo for dat_source_int_d alignment with enable
	align_fifo_ctrl <= "001";
	ena_1 <= '0';
	ena_2 <= '0';
	align1 <= (others => '0');
	align2 <= (others => '0');
	align3 <= (others => '0');
	align1_err <= (others => '0');
	align2_err <= (others => '0');
	align3_err <= (others => '0');
elsif Rising_edge(clk) then
--  trying to align data out of ram with enable
  ena_1 <= enable;
	ena_2 <= ena_1;
	
	if enable='1' and dav_source_align(2)='1' and align_fifo_ctrl(1)='1' then 
		align1 <= dat_source_int_d;
		align1_err <= err_value_swap;
	elsif enable='1' and align_fifo_ctrl(1)='0' then
		align1 <= align2;
		align1_err <= align2_err;
	end if;
	if (enable='0' and dav_source_align(2)='1' and align_fifo_ctrl(1)='1') or
	   (enable='1' and dav_source_align(2)='1' and align_fifo_ctrl(2)='1') then 
		align2 <= dat_source_int_d;
		align2_err <= err_value_swap;
	elsif enable='1' and align_fifo_ctrl(2)='0' then
		align2 <= align3;
		align2_err <= align3_err;
	end if;
	if (enable='0' and dav_source_align(2)='1' and align_fifo_ctrl(2)='1') or
	   (enable='1' and dav_source_align(2)='1' and align_fifo_ctrl(3)='1') then 
		align3 <= dat_source_int_d;
		align3_err <= err_value_swap;
	end if;
	-- I think that more than enable I have to align as well dav!
	if enable='0' and dav_source_align(2)='1' and align_fifo_ctrl(1)='1' then
		align_fifo_ctrl <= "010";
	elsif enable='0' and dav_source_align(2)='1' and align_fifo_ctrl(2)='1' and ena_1='0' then
		align_fifo_ctrl <= "100";
	elsif enable='1' and align_fifo_ctrl(3)='1' then
		align_fifo_ctrl <= "010";
	elsif enable='1' and align_fifo_ctrl(2)='1' and (ena_2='0' or dav_source_align(2)='0') then
		align_fifo_ctrl <= "001";
	end if;

-- end fifo for dat_source_int_d alignment with enable 
  if enable='1' then
		rsoutff_d := align1;
		data_val_d := dav_source_int; 
		eop_source_d := eop_source_pipe(3);
		sop_source_d := sop_source_pipe(3);
	else
		data_val_d := data_val_shunt;
		rsoutff_d := rsout_shunt;
		eop_source_d := eop_source_shunt;
		sop_source_d := sop_source_shunt;
	end if;
	-- this is under question still
	-- alternative : 2 clock cycles after condition rd_eq_block_size =1 AND enable=1
	if enable='1' and rd_ge_block_size='1' then
		eop_gen_pipe_ena_2(1) <= '1';
	elsif eop_gen_pipe_ena_2(1)='1' then
		eop_gen_pipe_ena_2(1) <= '0';
	end if;
	if eop_gen_pipe_ena_2(1)='1' then
		eop_gen_pipe_ena_2(2) <= '1';
	elsif eop_gen_pipe_ena_2(2)='1' then
	  eop_gen_pipe_ena_2(2) <= '0';
	end if;
	
  if enable='1' then
		data_val_shunt <= dav_source_int; 
		sop_source_pipe(1) <= sop_source_gen; 
		eop_source_pipe(1) <= eop_source_gen; 
		sop_source_pipe(2) <= sop_source_pipe(1);
		eop_source_pipe(2) <= eop_source_pipe(1);
		sop_source_pipe(3) <= sop_source_pipe(2);
		eop_source_pipe(3) <= eop_source_pipe(2);
		rsout_shunt <= align1;
		eop_source_shunt <= eop_source_pipe(3);
		sop_source_shunt <= sop_source_pipe(3);
  end if;
	if source_ena='1' then
		rsoutff_q <= rsoutff_d;
		data_val_pipe <= data_val_d;
		eop_source_pipe(4) <= eop_source_d;
		sop_source_pipe(4) <= sop_source_d;
	end if;

  val_source_q <= source_ena and allow_val_assert;
end if;
end process last_pipe_reg;

rsout <= rsoutff_q;
source_val <= val_source_q and data_val_pipe;
source_eop <= eop_source_pipe(4); 
source_sop <= sop_source_pipe(4);

end architecture rtl;
