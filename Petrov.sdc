derive_clock_uncertainty

set_time_format -unit ns -decimal_places 3

create_clock 				-name Clk_50MHz    	-period  50MHz    [get_ports {Clk_50MHz}]
create_clock 				-name rx_clk         -period  25MHz    [get_ports {RxClk}]
create_clock 				-name tx_clk         -period  25MHz    [get_ports {TxClk}]

derive_pll_clocks -create_base_clocks

#create_generated_clock \
#	-name rxc_div_2 \
#	-divide_by 2	 \
#	-source [get_pins {inst7|altpll_component|pll1|inclk[0]}] \ [get_pins {inst7|altpll_component|pll1|clk[1]}]

set_false_path -from [get_clocks {Clk_50MHz}] -to [get_clocks {any clocks}]
set_false_path -from [get_clocks {any clocks}] -to [get_clocks {Clk_50MHz}]
#set_false_path -from [get_clocks {inst4|altpll_component|auto_generated|pll1|inclk[0]}] -to [all_clocks]
#set_false_path -from [all_clocks] -to [get_clocks {inst4|altpll_component|auto_generated|pll1|clk[0]}]
