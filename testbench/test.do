quit -sim

vlib work
vmap work work

vcom -novopt -work work ../rx_tx_mod/lan_frames_pack.vhd 
vlog -novopt -sv -work work ip_gen/use_ipgen.v
vlog -novopt -sv -work work ip_gen/use_ipgen2.v

vcom -novopt -work work ../rx_tx_mod/frame_fifo.vhd
vcom -novopt -work work ../rx_tx_mod/fifo256x2.vhd
vcom -novopt -work work ../rx_tx_mod/mem9x1024.vhd 

vcom -novopt -work work ../rx_tx_mod/from_hdlc.vhd 
vcom -novopt -work work ../rx_tx_mod/to_hdlc.vhd

vcom -novopt -work work ../rx_tx_mod/RScoder.vhd 
vcom -novopt -work work ../rx_tx_mod/RScoder_ver2.vhd 

vcom -novopt -work work ../rx_tx_mod/Bench_rs_dec_atl_ent.vhd
vcom -novopt -work work ../rx_tx_mod/Bench_rs_dec_atl_arc_ben.vhd
vcom -novopt -work work ../rx_tx_mod/Bench_rs_enc_atl_ent.vhd
vcom -novopt -work work ../rx_tx_mod/Bench_rs_enc_atl_arc_ben.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_fun_pkg.vhd

vcom -novopt -work work ../rx_tx_mod/auk_rs_bms_atl_ent.vhd

vcom -novopt -work work ../rx_tx_mod/auk_rs_bms_atl_arc_ful_era_rtl.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_bms_atl_arc_ful_rtl.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_bms_atl_arc_hal_era_rtl.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_bms_atl_arc_hal_rtl.vhd

vcom -novopt -work work ../rx_tx_mod/auk_rs_chn_atl_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_chn_atl_arc_rtl.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_dec_top_atl_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_dec_top_atl_arc_rtl.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_enc_top_atl_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_enc_top_atl_arc_rtl.vhd

vcom -novopt -work work ../rx_tx_mod/auk_rs_gfmul_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_gfmul_arc_rtl.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_gfmul_cnt_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_gfmul_cnt_arc_rtl.vhd

vcom -novopt -work work ../rx_tx_mod/auk_rs_mem_atl_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_mem_atl_arc_rtl.vhd

vcom -novopt -work work ../rx_tx_mod/auk_rs_gfdiv_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_gfdiv_arc_rtl.vhd

vcom -novopt -work work ../rx_tx_mod/auk_rs_syn_atl_ent.vhd
vcom -novopt -work work ../rx_tx_mod/auk_rs_syn_atl_arc_rtl.vhd
vcom -novopt -work work ../rx_tx_mod/rs_decoder.vhd

vcom -novopt -work work ../rx_tx_mod/stob_scale.vhd 


#############################
vcom -novopt -work work xorframe.vhd
vcom -novopt -work work show_frame_error.vhd 
vcom -novopt -work work FromTextFile.vhd
vcom -novopt -work work test_mac_fileplayer.vhd
vcom -novopt -work work ToTextFile.vhd 

vcom -novopt -work work ../rx_tx_mod/find_synchro.vhd
vcom -novopt -work work ../rx_tx_mod/flowbyte_shifter.vhd
vcom -novopt -work work ../rx_tx_mod/shift_finder.vhd

vcom -novopt -work work ../rx_tx_mod/simple_mac_rx.vhd 
vcom -novopt -work work ../rx_tx_mod/simple_mac_tx.vhd 

vcom -novopt -work work ../rx_tx_mod/self_descrambler.vhd 
vcom -novopt -work work ../rx_tx_mod/self_scrambler.vhd 

vcom -novopt -work work ../rx_tx_mod/ce2wr_filter.vhd 
vcom -novopt -work work ../rx_tx_mod/read_frames4fifo.vhd

vcom -novopt -work work ../rx_tx_mod/block2ip_frame.vhd 
vcom -novopt -work work ../rx_tx_mod/frame_filter.vhd 

#vcom -novopt -work work ../rx_tx_mod/find_bytes.vhd 

vcom -novopt -work work ../rx_tx_mod/changer_freq_rx.vhd
vcom -novopt -work work ../rx_tx_mod/changer_freq_tx.vhd 

#vcom -novopt -work work ../rx_tx_mod/insert_frames.vhd 

vcom -novopt -work work ../rx_tx_mod/mac_frame_rx_ver2.vhd
vcom -novopt -work work ../rx_tx_mod/mac_frame_tx_ver2.vhd

vcom -novopt -work work phy_emu.vhd 

vcom ../rx_tx_mod/trafic_buf.vhd 
vcom ../rx_tx_mod/tangenta_manager_master.vhd
vcom ../rx_tx_mod/tangenta_manager_slave.vhd 

vcom -novopt -work work tb_whole_quadro_div2.vhd 





vsim -novopt -t ps work.tb -pli ip_gen/ipgen_pli.dll -pli ip_gen/ipgen_pli2.dll
do wave.do

# test

