onerror {resume}
quietly WaveActivateNextPane {} 0

log -r /*

add wave -group tb               /tb_uart_top/*
add wave -group dut              /tb_uart_top/i_dut/*
add wave -group reg_ctrl         /tb_uart_top/i_dut/i_uart_register_controller/*
add wave -group registers        /tb_uart_top/i_dut/i_uart_register_controller/i_uart_registers/*
add wave -group uart_status_reg  /tb_uart_top/i_dut/i_uart_register_controller/i_uart_registers/i_uart_status_reg/*
add wave -group uart_control_reg /tb_uart_top/i_dut/i_uart_register_controller/i_uart_registers/i_uart_control_reg/*
add wave -group tx_data_reg      /tb_uart_top/i_dut/i_uart_register_controller/i_uart_registers/i_tx_data_reg/*
add wave -group rx_data_reg      /tb_uart_top/i_dut/i_uart_register_controller/i_uart_registers/i_rx_data_reg/*
add wave -group uart_ctrl        /tb_uart_top/i_dut/i_uart_controller/*
add wave -group baud_generator   /tb_uart_top/i_dut/i_uart_controller/i_baud_generator/*
add wave -group tx_module        /tb_uart_top/i_dut/i_uart_controller/i_tx_module/*
add wave -group rx_module        /tb_uart_top/i_dut/i_uart_controller/i_rx_module/*
run -all

configure wave -signalnamewidth 1
wave zoom full
