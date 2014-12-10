onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group tb /tb/clkq
add wave -noupdate -group tb /tb/clk125
add wave -noupdate -group tb /tb/clk125_B
add wave -noupdate -group tb /tb/clk125_div2
add wave -noupdate -group tb /tb/clk125_div4
add wave -noupdate -group tb /tb/reset
add wave -noupdate -group tb /tb/cnt_rd
add wave -noupdate -group tb /tb/cnt_wr
add wave -noupdate -group tb /tb/Txd12
add wave -noupdate -group tb /tb/Rxd12
add wave -noupdate -group tb /tb/Txd21
add wave -noupdate -group tb /tb/Rxd21
add wave -noupdate -group tb /tb/data_fromfile12
add wave -noupdate -group tb /tb/ce_fromfile12
add wave -noupdate -group tb /tb/tx_coded_data12
add wave -noupdate -group tb /tb/cccnt
add wave -noupdate -group tb /tb/dataout_end12_1w
add wave -noupdate -group tb /tb/dataout_end12
add wave -noupdate -group tb /tb/ceout_end12_1w
add wave -noupdate -group tb /tb/ceout_end12
add wave -noupdate -group tb /tb/Tx_er_end12
add wave -noupdate -group tb /tb/time_cnt
add wave -noupdate -group tb /tb/makerr
add wave -noupdate -group tb /tb/rd89
add wave -noupdate -group tb /tb/empty89
add wave -noupdate -group tb /tb/state_value
add wave -noupdate -group tb /tb/ce89
add wave -noupdate -group tb /tb/ce89_w1
add wave -noupdate -group tb /tb/ce98
add wave -noupdate -group tb /tb/ce98_w1
add wave -noupdate -group tb /tb/empty98
add wave -noupdate -group tb /tb/data89
add wave -noupdate -group tb /tb/data98
add wave -noupdate -group tb /tb/DataOutB_2
add wave -noupdate -group tb /tb/DataOutB
add wave -noupdate -group tb /tb/data8
add wave -noupdate -group tb /tb/useRS
add wave -noupdate -group tb /tb/data_spi
add wave -noupdate -group tb /tb/spi_clk
add wave -noupdate -group tb /tb/read_irq
add wave -noupdate -group tb /tb/spi_data
add wave -noupdate -group tb /tb/spi_ce
add wave -noupdate -group tb /tb/cnt
add wave -noupdate -group tb /tb/spi_cnt
add wave -noupdate -group tb /tb/spi_circle
add wave -noupdate -group tb /tb/flow_ctrl_req12
add wave -noupdate -group tb /tb/flow_ctrl_ok12
add wave -noupdate -group tb /tb/reset_W
add wave -noupdate -group tb /tb/last_data
add wave -noupdate -group tb /tb/flow_ctrl_answer12
add wave -noupdate -group tb /tb/RF_1_2
add wave -noupdate -group tb /tb/clkq_SW
add wave -noupdate -group tb /tb/test_stm
add wave -noupdate -group tb /tb/f_number
add wave -noupdate -group tb /tb/f_data
add wave -noupdate -group tb /tb/p_test_err
add wave -noupdate -group tb /tb/fifo_going_full_12b
add wave -noupdate -group tb /tb/fifo_going_full_12
add wave -noupdate -group tb /tb/receive_full_12
add wave -noupdate -group tb /tb/flow_ctrl_req_a12
add wave -noupdate -group tb /tb/flow_ctrl_ok_a12
add wave -noupdate -group tb /tb/pause_mode12
add wave -noupdate -group tb /tb/flow_ctrl_ok_a12b
add wave -noupdate -group tb /tb/flow_a_get12
add wave -noupdate -group tb /tb/tangenta_12get
add wave -noupdate -group tb /tb/SyncFindLED
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/clk125
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/clkq
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/rs_reset_i
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/clkq_more_than_clk125
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/need_to_clkq_big
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_er
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_en
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Txd
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Crs
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Col
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/tp
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/write_irq
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/spi_clk
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/spi_ce
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/spi_data
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/o_tangenta
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fifo_going_full
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/receive_full
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req_a
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok_a
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/pause_mode_o
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_a_get
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dv_in
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_answer
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/useRS
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/frames_reg01
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/ErrRS_reg02
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/failRS_reg03
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/SyncFindLED
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/bad_channelLED
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_correct
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/sync_for_test
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/ce_in
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/USE_XORstd
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/shift
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fout_timed2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fout_timed
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fout_timea
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fout_timeb
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fout_cnt_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fout_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fout_timed2_val
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/ce_in_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/ce_in_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/SyncFind
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in_shift_w4
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in_shift_w3
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in_shift_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in_shift_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in_shift_descr_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in_shift_descr
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_in_shift
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_n
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data9
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data9_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data9_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/DecodData_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/DecodData
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_mac_wa
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_mac_wr
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_mac_data
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_mac_BE
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_mac_eop
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_mac_sop
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Tx_mac_wa_n
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/sGtx_clk
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_with_sync_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_with_sync_n
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_with_sync
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/err
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/decfail
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Bdata9_shift_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Bdata9_3
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Bdata9_shift
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Bdata9
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Bdata9_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Bdata9_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/have_to_start_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/have_to_start2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/have_to_start2_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/e_full
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/e_empty
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_not
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/have_to_start
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data9_ce2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data9_ce
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/new_ce9
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/frame_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dout_cnt_forstart
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_n_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_w3
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_w4
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_w5
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frm_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/num_err_sym
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_ErrRS_reg02
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_failRS_reg03
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_with_sync_by125
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/source_sop_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/source_sop
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/source_eop_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/source_eop
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/d_to_design
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_rs_p1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_rs
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/scr_ce
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/scr_ce_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/scr_ce_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/new_start_p1_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/new_start
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/new_start_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_rs_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_rs_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/cnt_for_ce
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/cnt_for_ce2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_with_sync_add
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/rs_reset_i_byclkq
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_by_fifofull
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_by_fifofull_byclkq
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_by_decfail
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/decfail2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/can_remove
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/decfail_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/decfail_scale
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/useRS_w1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/useRS_w2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/decfail_scale_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fifo_monitor
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_by_RSmode
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/rs_reset_i_byclkq2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/start_frame_p1_test
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/descriptor_ce
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/descriptor
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req_reg
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok_reg
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req_byclk125
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok_byclk125
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req_byclk125_s
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok_byclk125_s
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req_byclk125_m
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok_byclk125_m
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/empty_space
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/empty_space_start
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dv_delayed
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dv_mux
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/pause_mode
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/pause_mode_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/delayed_data
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data_mux
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_mux_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/first_start
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/have_datainfifo
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_descr
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fiford
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fiford_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fifo_cnt_d
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fifo_cnt_out
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fifo_cnt_in
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fifo_cnt_in_byclkq
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/fifo_cnt_in_byclkq2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/data9_8_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/Bdata9_shift_8_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/have_to_start_state
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/stm_reader
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/stm_reader_havereg
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/stm_reader_reg
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/clkq_more_than_clk125_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/empty_space_start_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/empty_space_start_2w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/empty_space_start_3w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/someflowneed
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/go_flow1
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/go_flow2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_fifo_going_full_state
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_flow_ctrl_req_a
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_flow_ctrl_ok_a
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/tx_cnt_timeout
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dv_in_timeout
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dv_in_timeout_event_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dv_in_timeout_event
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/dv_in_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/addpause_w_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/test_val
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/test_val_reg
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/test_val_err
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/test_pre_val
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/qtest_val
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/qtest_val_reg
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/qtest_val_err
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/qtest_pre_val
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/test_in_pause_mode
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_req2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_receive_full
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_receive_full_1w
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/flow_ctrl_ok2
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/add_flow_ok
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/add_flow_ok_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_flow_ok
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_flow_pause
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/reset_with_sync_with_full
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/s_fifo_going_full
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/timecnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/pause_mode_cnt
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/pause_mode_cnt_more
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/cntflow
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/ok_made
add wave -noupdate -expand -group mac_tx /tb/mac_frame_tx_inst/stop_made
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3372077638 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 222
configure wave -valuecolwidth 100
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
configure wave -timelineunits ps
update
WaveRestoreZoom {1757565730 ps} {10433812330 ps}
