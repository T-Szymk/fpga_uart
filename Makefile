################################################################################
# Title: Makefile for FPGA UART project
# Author(s): Tom Szymkowiak
################################################################################

ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

START_TIME=`date +%F_%H:%M`

ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
VERILATOR_COVERAGE = verilator_coverage
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
VERILATOR_COVERAGE = $(VERILATOR_ROOT)/bin/verilator_coverage
endif

CURR_DIR        ?= $(PWD)
BUILD_DIR       ?= $(CURR_DIR)/build
VERIL_BUILD_DIR ?= $(BUILD_DIR)/verilator
RTL_DIR         ?= $(CURR_DIR)/rtl
TB_DIR          ?= $(CURR_DIR)/tb
SIM_DIR         ?= $(CURR_DIR)/sim

TOP_MODULE  ?= tb_uart_top

DO_FILE ?= run.do

RTL_FILES ?= \
  $(RTL_DIR)/baud_generator.v \
  $(RTL_DIR)/rx_module.v \
  $(RTL_DIR)/tx_module.v \
  $(RTL_DIR)/uart_controller.v \
	$(RTL_DIR)/bram.v \
	$(RTL_DIR)/register.v \
	$(RTL_DIR)/uart_registers.v \
  $(RTL_DIR)/fifo.v

TB_FILES  ?= \
	$(TB_DIR)/tb_uart_pkg.sv \
  $(TB_DIR)/tb_tx_module.sv \
  $(TB_DIR)/tb_uart_controller.sv

VERILATOR_TB ?= \
	$(SIM_DIR)/$(TOP_MODULE)_sim_main.cpp

VERIL_WARNS ?= -Wall

VERIL_DEFINES ?=

VERIL_SUPPRESS ?=

VERIL_FLAGS ?= \
  --top-module $(TOP_MODULE) \
	-sv \
	--timing \
	-Mdir $(VERIL_BUILD_DIR)

LIBS = \
	-L $(BUILD_DIR)/fpga_uart_rtl_lib \
	-L $(BUILD_DIR)/fpga_uart_tb_lib

VOPT_OPTS ?= \
	"+acc=npr"

# VERILATOR FLOW

show-config:
	$(VERILATOR) -V


.PHONY: vlint
vlint: clean_verilator init
	$(VERILATOR) \
	--lint-only \
	$(VERIL_FLAGS) \
	$(VERIL_WARNS) \
	$(VERIL_DEFINES) \
	$(VERIL_SUPPRESS) \
	$(RTL_FILES) \
	$(TB_FILES) \
	$(VERILATOR_TB)


.PHONY: verilint
verilint: clean_verilator init
	$(VERILATOR) \
	--lint-only \
	--coverage \
	--trace-fst \
	-O3 \
	$(VERIL_FLAGS) \
	$(VERIL_WARNS) \
	$(VERIL_DEFINES) \
	$(VERIL_SUPPRESS) \
	$(RTL_FILES) \
	$(TB_FILES) \
	$(VERILATOR_TB) \
	--build -j `nproc`

.PHONY: verilate
verilate: clean_verilator init
	$(VERILATOR) \
	-cc --exe \
	--coverage \
	--trace-fst \
	-O3 \
	$(VERIL_FLAGS) \
	$(VERIL_WARNS) \
	$(VERIL_SUPPRESS) \
	$(RTL_FILES) \
	$(TB_FILES) \
	$(VERILATOR_TB) \
	--build -j `nproc`


init:
	@echo "-- CREATING BUILD DIR ----------" 
	@mkdir -p $(BUILD_DIR)

# QUESTA FLOW

.PHONY: lib
lib: clean init
	vlib $(BUILD_DIR)/fpga_uart_rtl_lib
	vlib $(BUILD_DIR)/fpga_uart_tb_lib

.PHONY: compile
compile: lib
	vlog -work $(BUILD_DIR)/fpga_uart_rtl_lib -incr -f $(RTL_DIR)/rtl_files.list
	vlog -sv -work $(BUILD_DIR)/fpga_uart_tb_lib -incr -f $(TB_DIR)/tb_files.list

.PHONY: sim
sim: compile
	cd $(BUILD_DIR) && \
	vsim -work fpga_uart_tb_lib -L fpga_uart_rtl_lib -voptargs="+acc" -wlf $(TOP_MODULE)_waves.wlf $(TOP_MODULE) -onfinish stop -do $(SIM_DIR)/$(DO_FILE)

.PHONY: simc
simc: compile
	cd $(BUILD_DIR) && \
	vsim -work fpga_uart_tb_lib -L fpga_uart_rtl_lib -c $(TOP_MODULE) -do "run -all;"


.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)

.PHONY: clean_verilator
clean_verilator:
	@rm -rf $(VERIL_BUILD_DIR)