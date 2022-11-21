#include <iostream>
#include "Vtop.h"
#include "Vtop_top.h"
#include "Vtop_automata.h"
#include "Vtop_ovi.h"
#include "Vtop_core_issue_bus.h"
#include "Vtop_core_completed_bus.h"

#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;

double sc_time_stamp () {
 return 0;
}

int main(int argc, char **argv, char **env){
	Verilated::commandArgs(argc,argv);
	Vtop * top = new Vtop;

	//For tracing
  	Verilated::traceEverOn(true);
	VerilatedVcdC* trace = new VerilatedVcdC;
	top->trace(trace, 5);
	trace->open ("sim.vcd");


	//while (!Verilated::gotFinish()){
	while (main_time != 1500){
		if (top->CLK){
			std::cout << "Cycle counter: " <<  main_time/2;
			std::cout << "\tAut_state: " << (int)top->top->core_automata->curr_state;
			std::cout << "\tcore_iss_vld: " << (int)top->top->core_issue->valid;
			std::cout << "\tcore_Instr: " << std::hex << top->top->core_issue->instr;
			std::cout << "\tcore_Cmpl_vld: " << std::dec << (int)top->top->core_completed->valid;
			std::cout << "\tcore_Cmpl_data: " << std::dec << (int)top->top->core_completed->data;
			std::cout << "\tcore_halt: " << (int)top->top->core_halt;
			std::cout << "\tOVI_state: " << (int)top->top->ovi_module->curr_state;
			std::cout << "\tOVI_crdts: " << (int)top->top->ovi_module->issue_credits;
			std::cout << std::endl;
		}
      		main_time++;
      		trace->dump (main_time);
		top->CLK ^= 1;
		top->RESET = (main_time > 5);
		top->eval();
	}
	printf("main time: %ld\n", main_time);
  	trace->close();
	delete top;
	exit(0);
}
