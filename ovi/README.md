

To compile and simulate the module, run `make`. It will simulate 800 cycles of the CPUautomata<-->ovi<-->VPU interaction  

Remember to update the BSC submodule with `git submodule update --init --recursive`  

Also, disable the vector floating point unit by edditing the file `bsc-vector-accelerator/src/include/config_control.svh` and changing line 78 from `\`define HAS_FPU` to `\`define EXCLUDE_FPU`  

Also change line 85 so BSC_RTL_SRAMS is uncommented. 

Also change line 77-80 of file `bsc-vector-accelerator/src/modules/vector_control_unit/rtl/vcu_lane_assignment.sv` from  
```
76  /* vector increment comparator */
77  assign vlen_comp_incr  = vec_incr[~vsew_i];
78
```

```
77  /* vector increment comparator */
78  logic [VSEW_WIDTH-1:0] negated_vsew;
79  assign negated_vsew = ~vsew_i;
80  assign vlen_comp_incr = vec_incr[negated_vsew];
```

Maybe this will need changes too: `src/modules/vector_lane/buffers/rtl/wb_buffer.sv`

TODO: implement VPUautomata
