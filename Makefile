all: arithvec
stall:
	rm -f program.hex
	export RV_ROOT=`pwd`; CUSTOM_HEX=1 make -f tools/Makefile verilator TEST=stall TEST_DIR=testbench/hex debug=1
arithvec:
	rm -f program.hex
	export RV_ROOT=`pwd`; CUSTOM_HEX=1 make -f tools/Makefile verilator TEST=arithvec TEST_DIR=testbench/hex debug=1

clean:
	make -f tools/Makefile clean
