#include <unistd.h>
#include <memory>

#include "Vtb_tx_module.h"
#include "verilated.h"

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

int main(int argc, char** argv) {

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  
  const std::unique_ptr<Vtb_tx_module> top{new Vtb_tx_module};

  while ( !Verilated::gotFinish() ) { 
    if(main_time != -1) {
      top->eval();    
    }
    main_time = top->nextTimeSlot();
  }

  top->final();

  Verilated::threadContextp()->coveragep()->write("coverage.dat");

  return 0;
}
