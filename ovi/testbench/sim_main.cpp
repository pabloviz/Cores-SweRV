#include <iostream>
#include "Vtop.h"
#include "Vtop_top.h"
#include "Vtop_automata.h"
#include "Vtop_ovi.h"
#include "Vtop_core_issue_bus.h"
#include "Vtop_core_completed_bus.h"
#include "verilated.h"
int main(int argc, char **argv, char **env){
	Verilated::commandArgs(argc,argv);
	Vtop * top = new Vtop;
	while (!Verilated::gotFinish()){
		if (top->CLK){
			std::cout << "Cycle counter: " <<  top->top->debug_counter;
			std::cout << " core_Automata_state: " << (int)top->top->core_automata->curr_state;
			std::cout << " core_Issue_valid: " << (int)top->top->core_issue->valid;
			std::cout << " core_Completed_valid: " << (int)top->top->core_completed->valid;
			std::cout << " core_halt: " << (int)top->top->core_halt;
			std::cout << " OVI_Automata_state: " << (int)top->top->ovi_module->curr_state;
			std::cout << " OVI_credits: " << (int)top->top->ovi_module->issue_credits;
			std::cout << std::endl;
		}
		top->CLK ^= 1;
		top->eval();
	}
	delete top;
	exit(0);
}
