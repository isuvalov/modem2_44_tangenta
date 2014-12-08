-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- Description	:  testbench is for regresion testing on the standard
--                 atlantic RS encoder.
--
-- Copyright 2004 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all; -- to be removed 
Use Std.TextIO.All;


Architecture bench of bench_rs_enc_atl is

Constant time_lapse_max : TIME := 1 ms;
Constant gf_m : NATURAL := 2**m-1;

type NATURAL_ARRAY is array(NATURAL RANGE <>) of NATURAL;
SubType codeword is NATURAL_ARRAY(gf_m downto 0);

Type four_codewords is ARRAY(0 to 3) of codeword;

Subtype data_vector is Std_Logic_Vector(m downto 1);
type data_vector_2D is array(NATURAL RANGE <>) of data_vector;

signal keep_clk_running : BOOLEAN := TRUE;
signal expecting_sop : BOOLEAN := TRUE;
signal data_cw_pipe : four_codewords;
signal size_cw_pipe, check_cw_pipe : NATURAL_ARRAY(0 to 3);
signal pos_ptr_data_sig : NATURAL; 
signal fail_encoding : Std_Logic;
signal reset_int, clk_int : Std_Logic := '1';
Signal val_source_q, data_val_shunt : Std_Logic;
Signal file_2_source : std_logic_vector (m downto 1);
Signal encoder_2_bench_q : std_logic_vector(m downto 1);


Type atl_buffer_fsm is (S0, out_idle, out_active, out_hold);

signal atl_buffer_state, atl_buffer_next_state : atl_buffer_fsm;

Signal time_lapse : TIME;

--Signal ben_2_enc_data_pipe : data_vector_2D(3 downto 1);
signal sop_source_pipe, eop_source_pipe : Std_Logic_Vector(4 downto 1);

Signal bench_2_encoder_shunt : Std_Logic_Vector(m downto 1);
signal sop_source_gen, eop_source_gen : Std_Logic;
Signal sop_source_shunt, eop_source_shunt : Std_Logic;
Signal allow_val_assert, allow_ena_assert : Std_Logic;
signal data_available : BOOLEAN := TRUE;
signal ena_sink_q, data_val_pipe : Std_Logic;
Signal sink_val_q, sink_sop_q, sink_eop_q : Std_Logic;
signal sink_eop_counter, source_eop_counter : NATURAL := 0;
Signal dav_source_int, ena_data_sourcing : Std_Logic;
signal out_fsm_buf : Std_Logic_Vector(3 downto 1);
signal numcheck_file : std_logic_vector(wide downto 1);

Signal source_dav_disconnected : std_logic; -- internal for reference

file FSUM_OUT: TEXT open WRITE_MODE is "summary_output.txt";


begin

clk <= clk_int;
reset <= reset_int;

Osc: process
begin

while keep_clk_running loop
	clk_int <= '1';
	wait for clock_period/2;  -- half de clock period
	clk_int <= '0';
	wait for clock_period/2;
end loop; 	
wait;

end process Osc;
	

stim_atlantic: process

	--Constant str8: String(1 to 50) := "Parameters: check m irrpol genstart rootspace seed";

	FILE F: TEXT open READ_MODE is INPUT_FILE;
	FILE FBLK: TEXT open READ_MODE is BLOCKS_FILE;
	variable L, L_numcheck, L_bypass, L_size_of_block : Line;
	variable seed1, seed2: positive := 1;
	variable x: REAL;
	variable good_read, last_symbol : BOOLEAN;
	variable cursor, pos_ptr_data, number_of_blocks : NATURAL;
	variable file_2_source_var : Std_Logic_Vector(m downto 1);
	variable block_size, numcheck_var, symbol_in_block : natural;
	variable symbol_val, wr_ptr_var : natural;
	--block_index
	variable delivered_val, source_eop_cnt_var : natural;
	variable data_cw_hold : NATURAL_ARRAY(gf_m downto 0);

begin

READLINE(FBLK, L_bypass);
READ(L_bypass, number_of_blocks, good_read);
READLINE(FBLK, L_bypass);
READLINE(FBLK, L_numcheck);
READLINE(FBLK, L_size_of_block);

last_symbol := FALSE;
source_eop_cnt_var := 0;
reset_int <= '1';
dav_source_int <= '0';
file_2_source <= (others => '0');
data_cw_pipe <= (others => (others => 0));
size_cw_pipe <= (others => 0);
check_cw_pipe <= (others => 0);
pos_ptr_data := 0;
pos_ptr_data_sig <= 0;
numcheck_file <= (others => '0');

sop_source_gen <= '0';
eop_source_gen <= '0';
--symbol_in_block := 1;
wait for Clock_Period;
reset_int <= '0' after Clock_Offset;

--main: while (not ENDFILE(F)) and keep_clk_running loop
main: for block_index in 0 to number_of_blocks-1 loop 
	READLINE(F, L);
	--if symbol_in_block=1 then
	READ(L_numcheck, numcheck_var, good_read);
	if not good_read then
		exit;
	else
		assert (numcheck_var <= check)
			report "Variable Check value is greater than parameter Check"
			severity ERROR;
		numcheck_file <= CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => numcheck_var, SIZE => wide), SIZE => wide) after Clock_Offset;
		--check_cw_pipe(pos_ptr_data) <= numcheck_var; -- to be removed
	end if;
	READ(L_size_of_block, block_size, good_read);
	if not good_read then
		-- last symbol being read
--			ASSERT FALSE
--				REPORT "Not good reading of block size" severity Note;
		exit;
	else
		wr_ptr_var := block_size - numcheck_var;
		size_cw_pipe(pos_ptr_data) <= block_size;
	end if;
	-- I have to read the whole codeword here and load into an array
	cursor := 0;
	data_cw_hold := (others => 0);
	for I in block_size downto 1 loop
		READ(L, symbol_val, good_read);
		cursor := cursor + 1;
		data_cw_hold(I) := symbol_val; 
		if cursor=20 and (not ENDFILE(F))then
			READLINE(F, L);
			cursor := 0;
		end if;
	end loop;
	data_cw_pipe(pos_ptr_data) <= data_cw_hold;
	--end if;
	--nested_1: while (cursor < 20) and keep_clk_running loop
	--if ena_data_sourcing='0' then
		--wait until ena_data_sourcing='1';
		--wait for Clock_Period;
	--end if;
	nested_1: for symbol_in_block in block_size downto numcheck_var+1 loop
		if ena_data_sourcing='0' then
			wait until ena_data_sourcing='1';
			wait for Clock_Period;
		end if;
		if symbol_in_block = block_size and symbol_in_block > numcheck_var+1 then
			sop_source_gen <= '1' after Clock_Offset;
			eop_source_gen <= '0' after Clock_Offset;
		elsif symbol_in_block < block_size and symbol_in_block = numcheck_var+1 then
			sop_source_gen <= '0' after Clock_Offset;
			eop_source_gen <= '1' after Clock_Offset;
			if test_for="dav_sink3" then
				dav_source_int <= '0' after Clock_Offset;
				wait for source_eop_cnt_var*Clock_Period;
				dav_source_int <= '1' after Clock_Offset;
			end if;
		-- this case is for codewords where N= check+1 
		elsif symbol_in_block = block_size and symbol_in_block = numcheck_var+1 then
			sop_source_gen <= '1' after Clock_Offset;
			eop_source_gen <= '1' after Clock_Offset;
		else
			sop_source_gen <= '0' after Clock_Offset;
			eop_source_gen <= '0' after Clock_Offset;
		end if;
		delivered_val := data_cw_hold(symbol_in_block);
		file_2_source_var(m downto 1):= 
				CONV_STD_LOGIC_VECTOR(ARG => CONV_UNSIGNED(ARG => delivered_val, SIZE => m), SIZE => m);
		uniform (seed1, seed2, x);
		x := x - 0.3;
		if (test_for="dav_sink1" or test_for="both_sides11" or test_for="both_sides12") and (x < 0.0) then
			uniform (seed1, seed2, x);
			if 2.0 * x >= 1.0 then 
				dav_source_int <= '0' after Clock_Offset;
				wait for natural(5.0 * x)*Clock_Period;
			end if;
			dav_source_int <= '1' after Clock_Offset;
		elsif (test_for="dav_sink2" or test_for="both_sides21" or test_for="both_sides22") then
			dav_source_int <= '0' after Clock_Offset;
			wait for Clock_Period;
			dav_source_int <= '1' after Clock_Offset;
		else
			dav_source_int <= '1' after Clock_Offset;
		end if;
		file_2_source(m downto 1) <= file_2_source_var(m downto 1) after Clock_Offset;
		file_2_source_var := (others => '0');
		if ena_data_sourcing='0' then
			wait until ena_data_sourcing='1';
			wait for Clock_Period;
		else
			wait for Clock_Period;
		end if;
		
	end loop nested_1;
	source_eop_counter <= source_eop_counter + 1;
	source_eop_cnt_var := source_eop_cnt_var + 1;
	pos_ptr_data := (pos_ptr_data + 1) mod 4; 
	pos_ptr_data_sig <= pos_ptr_data;
	
end loop main;

-- In this new version of the bench, the file is going to be read and then when finish reading
-- the running time is going to extend to allow all the decoding bits to come out.
-- if I add after Clock_Offset then I get an extra spurious cycle of dav, ena and val.
-- I have to review this for parallel too. For hybrid it has to go down in sync with 
-- source_ena
if ena_data_sourcing/='1' and keep_clk_running then
	wait until ena_data_sourcing='1';
	wait until rising_edge(clk_int);
	dav_source_int <= '0' after Clock_Offset;
else
	--wait for Clock_Period;
	dav_source_int <= '0' after Clock_Offset;
end if;
if ena_data_sourcing/='1' and keep_clk_running then
	wait until ena_data_sourcing='1';
else
	wait for Clock_Period;
end if;

if keep_clk_running then
	if sink_eop_counter < source_eop_counter then
		wait until sink_eop_q='1';
	end if;
	wait for 2*Clock_Period;
end if;
data_available <= FALSE;
wait;

end process stim_atlantic;


monitor: Process

	Constant str9: String(1 to 29) := "Encoding Failure on Sequence ";
	variable rd_ptr_var, cw_ptr_var: natural;
	variable l : line;
	variable fail_encoding_var : std_logic;
	
	--FILE F: TEXT open WRITE_MODE is "rs_encoded_core_data.txt";

begin
	rd_ptr_var := 0;
	cw_ptr_var := 0;
	expecting_sop <= TRUE;
	fail_encoding <= '0';
	wait until sink_val_q'event;
	reading: while keep_clk_running loop
		--sink_val_q, sink_sop_q, sink_eop_q
		if expecting_sop and fail_encoding='1' then
			fail_encoding <= '0';
		end if;
		if expecting_sop and sink_val_q='1' and sink_sop_q='0' then
			ASSERT FALSE
				REPORT "Error: Sink_sop not asserted when expected" severity Warning;
		elsif expecting_sop and sink_val_q='1' and sink_sop_q='1' then
			expecting_sop <= FALSE after Clock_Offset;
			rd_ptr_var := size_cw_pipe(cw_ptr_var);
			if data_cw_pipe(cw_ptr_var)(rd_ptr_var)=natural(conv_integer(arg => unsigned(encoder_2_bench_q))) and fail_encoding='0' then
				fail_encoding <= '0';
			else
				fail_encoding <= '1';
			end if;
			
			-- commenting out to avoid error ; to review later
			rd_ptr_var := rd_ptr_var-1;
		
		elsif sink_val_q='1' and sink_eop_q='1' then
			expecting_sop <= TRUE after Clock_Offset;
			if data_cw_pipe(cw_ptr_var)(rd_ptr_var)=natural(conv_integer(arg => unsigned(encoder_2_bench_q))) and fail_encoding='0' then
				fail_encoding <= '0';
				fail_encoding_var := '0';
			else
				fail_encoding <= '1';
				fail_encoding_var := '1';
			end if;
			if rd_ptr_var/=1 then
				ASSERT FALSE
					REPORT "Error: Sink_eop asserted NOT when expected" severity Warning;
			end if;
			rd_ptr_var := rd_ptr_var-1;
			if fail_encoding='1' or fail_encoding_var='1' then
  			write(l, str9);
  			write(l, sink_eop_counter);
  			Writeline(FSUM_OUT, l);
				fail_encoding_var := '0';
  		end if;
			cw_ptr_var := (cw_ptr_var + 1) mod 4;
		elsif not expecting_sop and sink_sop_q='1' and sink_val_q='1' then
			ASSERT FALSE
					REPORT "Error: Sink_sop asserted NOT when expected" severity Warning;
		elsif sink_val_q='1' and sink_eop_q='0' and rd_ptr_var=1 then
		-- I have to review this ... error being flagged and it doesn't apply
			ASSERT FALSE
					REPORT "Error: Sink_eop NOT asserted when expected" severity Warning;
		elsif sink_val_q='1' then
			if data_cw_pipe(cw_ptr_var)(rd_ptr_var)=natural(conv_integer(arg => unsigned(encoder_2_bench_q))) and fail_encoding='0' then
				fail_encoding <= '0';
			else
				fail_encoding <= '1';
			end if;
			rd_ptr_var := rd_ptr_var-1;
		end if;
		wait until rising_edge(clk_int) or not keep_clk_running;
		
	end loop;

	FILE_CLOSE(FSUM_OUT);
	wait;
	
end process monitor;


end_block_stim: Process 

begin

	while keep_clk_running loop
	  wait until Falling_edge(sink_eop_q);
		sink_eop_counter <= sink_eop_counter + 1;
	  wait for Clock_Period;
  end loop; 	
  wait;
end process end_block_stim;


monitor_toggling_activity: Process(clk_int, reset_int,  
																	 sink_val_q, sink_sop_q, sink_eop_q, data_available)
begin
	if reset_int='1' then
		time_lapse <= 0 ns;
	elsif sink_val_q'event or 
				sink_sop_q'event or sink_eop_q'event or data_available'event then
		time_lapse <= 0 ns;
	elsif rising_edge(clk_int) then
		time_lapse <= time_lapse + Clock_Period;
	end if;
end process monitor_toggling_activity;


clk_running_ctrl: Process(reset_int, source_eop_counter, 
												sink_eop_counter, data_available, time_lapse)
begin
	if reset_int='1' then
		keep_clk_running <= TRUE;
	elsif (source_eop_counter = sink_eop_counter) and not data_available then
		keep_clk_running <= FALSE after 3*clock_Period;
	elsif (time_lapse > time_lapse_max) then
		ASSERT FALSE
				REPORT "Reached time_lapse_max without activity, probable hang up" severity Error;
		keep_clk_running <= FALSE;
	end if;
end process clk_running_ctrl;


-- START ATLANTIC SOURCE CONTROL LOGIC 

clk_FSM_atl: Process (clk_int, reset_int)
	begin
		if reset_int='1' then
			atl_buffer_state <= out_idle;
		elsif Rising_edge(clk_int) then
			atl_buffer_state <= atl_buffer_next_state;
		end if;
		
end process clk_FSM_atl;


FSM_out : process(atl_buffer_state, dav_source_int, source_ena)

	variable atl_buffer_next_state_var : atl_buffer_fsm;

begin

  atl_buffer_next_state_var := atl_buffer_state;
  case atl_buffer_state is
	
	when S0 =>
		allow_val_assert <= '0';
		ena_data_sourcing <= '0';
		atl_buffer_next_state_var := out_idle;
	when out_idle =>
		allow_val_assert <= dav_source_int;
		ena_data_sourcing <= '1';
		if dav_source_int='1' and source_ena='1' then
			atl_buffer_next_state_var := out_active;
		elsif dav_source_int='1' and source_ena='0' then
			atl_buffer_next_state_var := out_hold;
		end if;
	when out_hold =>
		allow_val_assert <= '1';
		ena_data_sourcing <= '0';
		if dav_source_int='1' and source_ena='1' then 
			atl_buffer_next_state_var := out_active;
		elsif dav_source_int='0' and source_ena='1' then 
			atl_buffer_next_state_var := out_idle;
		end if;
	when out_active =>
		allow_val_assert <= dav_source_int;
		ena_data_sourcing <= '1';
		if source_ena='0' then --and dav_source_int='1' then
      atl_buffer_next_state_var := out_hold;
    --elsif source_ena='1' and dav_source_int='0' then
		elsif dav_source_int='0' then
      atl_buffer_next_state_var := out_idle;
    end if;
	-- coverage off
	when others => 
		allow_val_assert <= '0';
		ena_data_sourcing <= '0';
		atl_buffer_next_state_var := out_idle;
	-- coverage on
	end case;
	atl_buffer_next_state <= atl_buffer_next_state_var;
	
end process FSM_out;


-- latching atlantic ports for slave source to be connected to master sink
clk_atl_sink: Process (clk_int, reset_int)
	begin
		if reset_int='1' then
			ena_sink_q	 <= '0';
			val_source_q <= '0';
		elsif Rising_edge(clk_int) then
			ena_sink_q <= source_ena;
			val_source_q <= source_ena and allow_val_assert after Clock_Offset;
		end if;
end process clk_atl_sink;


clk_atl_data_sink: Process (clk_int, reset_int)

variable bench_2_encoder_d : Std_Logic_Vector(m downto 1);
variable sop_source_d, eop_source_d, data_val_d : Std_Logic;

	begin
		if reset_int='1' then
			bench_2_encoder_shunt <= (others => '0');
			sop_source_pipe <= (others => '0');
			eop_source_pipe <= (others => '0');
			sop_source_shunt <= '0';
			eop_source_shunt <= '0';
			--ben_2_enc_data_pipe <= (others => (others => '0'));
			bench_2_encoder <= (others => '0');
			data_val_pipe <= '0';
			data_val_shunt <= '0';
		elsif Rising_edge(clk_int) then
			if ena_data_sourcing='1' then
				bench_2_encoder_d := file_2_source; --ben_2_enc_data_pipe(2);
				data_val_d := dav_source_int; 
				sop_source_d := sop_source_gen; --sop_source_pipe(3);
				eop_source_d := eop_source_gen; --eop_source_pipe(3);
			else
				bench_2_encoder_d := bench_2_encoder_shunt;
				data_val_d := data_val_shunt;
				sop_source_d := sop_source_shunt;
				eop_source_d := eop_source_shunt;
			end if;
			if ena_data_sourcing='1' then
				--ben_2_enc_data_pipe(1) <= file_2_source; 
				--sop_source_pipe(2) <= sop_source_gen;
				--eop_source_pipe(2) <= eop_source_gen;
				--ben_2_enc_data_pipe(2) <= ben_2_enc_data_pipe(1); 
				--sop_source_pipe(2) <= sop_source_pipe(1);
				bench_2_encoder_shunt <= file_2_source; --ben_2_enc_data_pipe(2);
				data_val_shunt <= dav_source_int; 
				sop_source_shunt <= sop_source_gen; --sop_source_pipe(3);
				eop_source_shunt <= eop_source_gen; --eop_source_pipe(3);
			end if;
			if source_ena='1' then
				bench_2_encoder <= bench_2_encoder_d after Clock_Offset;
				data_val_pipe <= data_val_d;
				sop_source_pipe(4) <= sop_source_d  after Clock_Offset;
				eop_source_pipe(4) <= eop_source_d  after Clock_Offset;
			end if;
		end if;
end process clk_atl_data_sink;

source_val <= val_source_q and data_val_pipe;
source_sop <= sop_source_pipe(4);
source_eop <= eop_source_pipe(4);

-- END ATLANTIC SOURCE CONTROL LOGIC

clk_atl_source: Process (clk_int, reset_int)
	begin
		if reset_int='1' then
			sink_ena	 <= '0';
			sink_val_q <= '0';
			sink_sop_q <= '0';
			sink_eop_q <= '0';
			encoder_2_bench_q <= (others => '0');
			numcheck <= (others => '0');
		elsif Rising_edge(clk_int) then
			sink_ena   <= allow_ena_assert after Clock_Offset;
			sink_val_q <= sink_val;
			sink_sop_q <= sink_sop;
			sink_eop_q <= sink_eop and sink_val;
			encoder_2_bench_q <= encoder_2_bench;
			numcheck <= numcheck_file after Clock_Offset;
		end if;
end process clk_atl_source;


ena_source_process: process
  variable seed1, seed2: positive := 1;
	variable x: real;
begin
	--if test_for="ena_source1" then
	if (test_for="ena_source1" or test_for="both_sides11" or test_for="both_sides21") then
    allow_ena_assert <= '1';
    looping: while keep_clk_running loop
		-- I have to remvove dav
	    if sink_val_q/='1' then
	    	wait until Rising_edge(sink_val_q);
			end if;
	    uniform (seed1, seed2, x);
			if x < 0.2 then
			  allow_ena_assert <= '0';
				wait for Clock_Period;
				allow_ena_assert <= '1';
				wait for Clock_Period;
				allow_ena_assert <= '0';
--				wait for 2*Clock_Period;
				wait for Clock_Period;
				allow_ena_assert <= '1';
--				wait for 3*Clock_Period;
				wait for Clock_Period;
				allow_ena_assert <= '0';
				wait for Clock_Period;
				allow_ena_assert <= '1';
			elsif (0.2 <= x) and (x < 0.5) then
				allow_ena_assert <= '0';
				wait for Clock_Period;
				allow_ena_assert <= '1';
				wait for Clock_Period;
				allow_ena_assert <= '0';
				wait for 2*Clock_Period;
				allow_ena_assert <= '1';
				wait for 3*Clock_Period;
				allow_ena_assert <= '0';
				wait for Clock_Period;
				allow_ena_assert <= '1';
		  elsif (0.5 <= x) and  (x < 0.9) then
		  	allow_ena_assert <= '1';
			else
			-- long time without sinking capability
			  allow_ena_assert <= '0';
				uniform (seed1, seed2, x);
				wait for natural(10.0 * x)*Clock_Period;
				allow_ena_assert <= '1';
			end if;
		end loop looping;
	elsif (test_for="ena_source2" or test_for="both_sides12" or test_for="both_sides22") then
		allow_ena_assert <= '1';
    looping2: while keep_clk_running loop
			wait for Clock_Period;
			allow_ena_assert <= '0';
			wait for Clock_Period;
			allow_ena_assert <= '1';
		end loop looping2;
	else
	  allow_ena_assert <= '1';
	end if;
	wait;
end process ena_source_process;

end architecture bench;	

