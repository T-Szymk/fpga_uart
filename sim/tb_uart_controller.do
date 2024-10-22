onerror {resume}
quietly WaveActivateNextPane {} 0

log -r /*

add wave -noupdate -group tb /tb_uart_controller/tb_clk
add wave -noupdate -group tb /tb_uart_controller/tb_rst
add wave -noupdate -group tb /tb_uart_controller/baud_sel_s
add wave -noupdate -group tb /tb_uart_controller/tx_en_s
add wave -noupdate -group tb /tb_uart_controller/tx_start_s
add wave -noupdate -group tb /tb_uart_controller/tx_conf_s
add wave -noupdate -group tb /tb_uart_controller/tx_data_s
add wave -noupdate -group tb /tb_uart_controller/tx_fifo_en_s
add wave -noupdate -group tb /tb_uart_controller/rx_en_s
add wave -noupdate -group tb /tb_uart_controller/uart_rx_s
add wave -noupdate -group tb /tb_uart_controller/rx_conf_s
add wave -noupdate -group tb /tb_uart_controller/rx_fifo_en_s
add wave -noupdate -group tb /tb_uart_controller/tx_done_s
add wave -noupdate -group tb /tb_uart_controller/tx_busy_s
add wave -noupdate -group tb /tb_uart_controller/uart_tx_s
add wave -noupdate -group tb /tb_uart_controller/tx_fifo_pop_s
add wave -noupdate -group tb /tb_uart_controller/rx_done_s
add wave -noupdate -group tb /tb_uart_controller/rx_parity_err_s
add wave -noupdate -group tb /tb_uart_controller/rx_stop_err_s
add wave -noupdate -group tb /tb_uart_controller/rx_busy_s
add wave -noupdate -group tb /tb_uart_controller/rx_data_s
add wave -noupdate -group tb /tb_uart_controller/rx_fifo_push_s
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/clk_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rst_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/baud_sel_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_en_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_start_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_conf_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_data_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_fifo_en_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_en_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/uart_rx_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_conf_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_fifo_en_i
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_done_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_busy_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/uart_tx_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/tx_fifo_pop_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_done_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_parity_err_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_stop_err_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_busy_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_data_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/rx_fifo_push_o
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/baud_en_s
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/uart_rx_sync0_r
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/uart_rx_sync1_r
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/uart_rx_sync2_r
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/clk_i
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/rst_i
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/baud_sel_i
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/baud_en_o
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/baud_en_r
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/select_update_s
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/baud_sel_r
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/sample_count_max_s
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/sample_count_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/clk_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/rst_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/baud_en_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_en_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_start_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_conf_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_data_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_fifo_en_i
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_done_o
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_busy_o
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/uart_tx_o
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_fifo_pop_o
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/sample_count_done_s
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/parity_bit_s
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/uart_tx_s
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/load_tx_conf_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/parity_en_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/busy_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_done_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_fifo_pop_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/c_state_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/n_state_s
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/data_counter_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/stop_counter_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/sample_counter_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/tx_data_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/data_counter_max_r
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/stop_counter_max_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/clk_i
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rst_i
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/baud_en_i
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_en_i
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/uart_rx_i
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_conf_i
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_done_o
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_busy_o
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_parity_err_o
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_stop_err_o
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_data_o
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/final_sample_s
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/last_data_sample_s
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/last_stop_sample_s
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/uart_rx_s
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/load_rx_conf_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/start_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/stop_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/parity_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/parity_en_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/busy_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_done_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/parity_error_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/stop_error_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/c_state_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/n_state_s
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/data_counter_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/stop_counter_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/sample_counter_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/rx_data_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/data_counter_max_r
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/stop_counter_max_r

run -all

configure wave -signalnamewidth 1
wave zoom full
