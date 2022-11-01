all: run

Includes= \
-Isrc \
-Itestbench \
-Imemfiles \
-Ibsc-vector-accelerator/src/include \
-Ibsc-vector-accelerator/src/modules/vector_lane/functional_unit/fpu-encrypted/src/include

Srcs= \
src/top.sv \
src/interfaces.sv \
src/automata.sv \
src/definitions.sv \
bsc-vector-accelerator/src/package/fpuv_pkg.sv \
bsc-vector-accelerator/src/package/target_pkg.sv \
bsc-vector-accelerator/src/package/EPI_pkg.sv \
bsc-vector-accelerator/src/package/fpuv_div_sqrt_pkg.sv \
bsc-vector-accelerator/src/package/fpuv_wrapper_pkg.sv \
bsc-vector-accelerator/src/modules/top/rtl/vpu_core.sv \
bsc-vector-accelerator/src/modules/commit_unit/rtl/* \
bsc-vector-accelerator/src/modules/common_lib/rtl/* \
bsc-vector-accelerator/src/modules/front_end/rtl/* \
bsc-vector-accelerator/src/modules/issue/rtl/* \
bsc-vector-accelerator/src/modules/memory_units/rtl/* \
bsc-vector-accelerator/src/modules/pmu/rtl/* \
bsc-vector-accelerator/src/modules/reorder_buffer/rtl/* \
bsc-vector-accelerator/src/modules/ring/rtl/* \
bsc-vector-accelerator/src/modules/sram_wrappers/*.sv \
bsc-vector-accelerator/src/modules/sram_wrappers/rtl/* \
bsc-vector-accelerator/src/modules/vector_control_unit/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/buffers/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/element_tracker/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/functional_unit/alu/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/functional_unit/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/mask_register_file/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/ready_bits/rtl/* \
bsc-vector-accelerator/src/modules/vector_lane/vector_register_file/rtl/* \


#bsc-vector-accelerator/src/modules/vector_lane/functional_unit/fpu-encrypted/src/pkg/fpuv_pkg.sv \
bsc-vector-accelerator/src/modules/vector_lane/functional_unit/fpu-encrypted/src/pkg/fpuv_wrapper_pkg.sv \
bsc-vector-accelerator/src/modules/vector_lane/functional_unit/fpu-encrypted/src/rtl/* \



build_sv:
	verilator -cc $(Includes) $(Srcs) --unroll-count 70000 --unroll-stmts 70000 -Wno-fatal --top-module top --exe testbench/sim_main.cpp --autoflush
build_cpp: build_sv
	make -j -C obj_dir/ -f Vtop.mk OP_FAST="-Os"
run: build_cpp
	obj_dir/Vtop	
onlyrun: 
	obj_dir/Vtop	

