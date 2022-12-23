all: arithvec

%:
	rm -f program.hex
	export RV_ROOT=`pwd`; VM_PARALLEL_BUILDS=1 CUSTOM_HEX=1 make -f tools/Makefile verilator TEST=$@ TEST_DIR=testbench/hex debug=1 

#stall:
#	rm -f program.hex
#	export RV_ROOT=`pwd`; CUSTOM_HEX=1 make -f tools/Makefile verilator TEST=stall TEST_DIR=testbench/hex debug=1
#arithvec:
#	rm -f program.hex
#	export RV_ROOT=`pwd`; CUSTOM_HEX=1 make -f tools/Makefile verilator TEST=arithvec TEST_DIR=testbench/hex debug=1
#loadstore:
#	rm -f program.hex
#	export RV_ROOT=`pwd`; CUSTOM_HEX=1 make -f tools/Makefile verilator TEST=loadstore TEST_DIR=testbench/hex debug=1
#axpy:
#	rm -f program.hex
#	export RV_ROOT=`pwd`; make -f tools/Makefile verilator TEST=axpy debug=1

clean:
	export RV_ROOT=`pwd`; make -f tools/Makefile clean
