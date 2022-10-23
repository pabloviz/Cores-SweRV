all: run

build_sv:
	verilator -cc -Isrc -Itestbench src/top.sv src/interfaces.sv src/automata.sv src/definitions.sv --top-module top --exe testbench/sim_main.cpp --autoflush
build_cpp: build_sv
	make -j -C obj_dir/ -f Vtop.mk OP_FAST="-Os"
run: build_cpp
	obj_dir/Vtop	

