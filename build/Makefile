
VERILATOR      = verilator
VERILATOR_ARGS = --cc --exe --build --timing --trace -Wall -Wno-UNUSEDSIGNAL -j 0
SIM_MAIN_CPP  ?= ../sim/tb_tx_module_sim_main.cpp
SV_TB         ?= ../tb/tb_tx_module.sv
V_RTL         ?= ../rtl/tx_module.v

OUT_DIR       ?= obj_dir
TOP           ?= Vtb_tx_module
WAVEFORM      ?= waveform

.PHONY: verilate
verilate:
	$(VERILATOR) $(VERILATOR_ARGS) $(SIM_MAIN_CPP) $(SV_TB) $(V_RTL)

.PHONY: run
run : verilate
	./$(OUT_DIR)/$(TOP)

.PHONY: wave
wave : run
	gtkwave $(WAVEFORM).vcd

clean:
	rm -rf $(WAVEFORM).vcd
	rm -rf $(OUT_DIR)