onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /tb/use_ipgen_inst/clk
add wave -noupdate -radix hexadecimal /tb/use_ipgen_inst/rd
add wave -noupdate -radix hexadecimal /tb/use_ipgen_inst/dv
add wave -noupdate -radix hexadecimal /tb/use_ipgen_inst/dataout
add wave -noupdate -radix hexadecimal /tb/use_ipgen_inst/reset_1w
add wave -noupdate -radix hexadecimal /tb/use_ipgen_test_inst/clk
add wave -noupdate -radix hexadecimal /tb/use_ipgen_test_inst/wr
add wave -noupdate -radix hexadecimal /tb/use_ipgen_test_inst/dv
add wave -noupdate -radix hexadecimal /tb/use_ipgen_test_inst/datain
add wave -noupdate -radix hexadecimal /tb/use_ipgen_test_inst/error
add wave -noupdate -radix hexadecimal /tb/use_ipgen_test_inst/reset_1w
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {182012 ps} 0}
configure wave -namecolwidth 294
configure wave -valuecolwidth 129
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {340502 ps}
