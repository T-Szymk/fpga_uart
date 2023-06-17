#include <unistd.h>

#include "Vtb_tx_module.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {

  Vtb_tx_module* top = new Vtb_tx_module;
  VerilatedVcdC* m_trace = new VerilatedVcdC;

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);  

  top->trace(m_trace, 5);
  m_trace->open("waveform.vcd");

  while ( !Verilated::gotFinish() ) { 
    top->eval();    
    main_time = top->nextTimeSlot();
    if(!(main_time % 1000)) 
      m_trace->dump(main_time);
  }
  top->final();
  m_trace->close();

  delete top; 
  delete m_trace;

  return 0;
}