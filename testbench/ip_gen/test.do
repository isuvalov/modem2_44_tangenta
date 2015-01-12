quit -sim

vlib work
vmap work work

vlog -novopt -sv -work work use_ipgen.v
vlog -novopt -sv -work work use_ipgen_test.v 


vcom -novopt -work work tb.vhd 


vsim -novopt -t ps work.tb -pli ipgen_pli.dll -pli ipgen_test_pli.dll 
do wave.do


