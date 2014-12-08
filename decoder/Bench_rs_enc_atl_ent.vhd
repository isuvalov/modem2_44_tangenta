-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- Description	:  testbench is for regresion testing on the standard
--                 atlantic RS decoder.
--
-- Copyright 2004 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


Entity bench_rs_enc_atl is
	Generic (	check : NATURAL := 6;
		m : NATURAL := 4;
		irrpol : NATURAL := 19; 
		genstart : NATURAL := 0;
		rootspace : NATURAL := 1;
		Varcheck : STRING := "false";
		wide : NATURAL := 3;
		--channel_bypass : BOOLEAN := FALSE;
		seed : NATURAL;
		clock_period : TIME := 30 ns;
		clock_offset : TIME := 2 ns;
		INPUT_FILE   : STRING := "rs_encoded_data.txt";
		BLOCKS_FILE  : STRING := "block_period_stim.txt";
		OUTPUT_FILE  : STRING := "rs_enc_core_data.txt";
		test_for     : STRING := "BER"  -- BER or dav_sink or ena_source or both_sides
		);
	Port (
		reset  : out Std_Logic;
		clk : out Std_Logic;
		sink_ena				: out Std_Logic; 
		sink_val        : in  Std_Logic; 
		sink_sop        : in  Std_Logic; 
		sink_eop        : in  Std_Logic;
		encoder_2_bench : in Std_Logic_Vector(m downto 1);
		
		Bench_2_encoder: out		std_logic_vector (m downto 1);
		numcheck	 : out    Std_Logic_Vector(wide downto 1);
		
		--source_dav_slave : out Std_Logic; 
		source_ena : in Std_Logic; 
		source_val : out Std_Logic; 
		source_sop : out Std_Logic; 
		source_eop : out Std_Logic);
end entity bench_rs_enc_atl;	



