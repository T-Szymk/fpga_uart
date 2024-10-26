onerror {resume}
quietly WaveActivateNextPane {} 0

log -r /*

add wave -noupdate -group tb /tb_uart_controller/*
add wave -noupdate -expand -group dut /tb_uart_controller/i_dut/*
add wave -noupdate -expand -group dut -group baud_gen /tb_uart_controller/i_dut/i_baud_generator/8
add wave -noupdate -expand -group dut -group tx_module /tb_uart_controller/i_dut/i_tx_module/*
add wave -noupdate -expand -group dut -group rx_module /tb_uart_controller/i_dut/i_rx_module/*

run -all

configure wave -signalnamewidth 1
wave zoom full
