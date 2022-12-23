Remember to update the BSC submodule with `git submodule update --init --recursive` after cloning this project!

Before running our module, you need to make some changes to the VPU:

- Disable the vector floating point unit by edditing the file `bsc-vector-accelerator/src/include/config_control.svh` and changing line 78 from `\`define HAS_FPU` to `\`define EXCLUDE_FPU`  
- Also change line 85 so BSC_RTL_SRAMS is uncommented. 
- Also change line 77-80 of file `bsc-vector-accelerator/src/modules/vector_control_unit/rtl/vcu_lane_assignment.sv` from  
```
76  /* vector increment comparator */
77  assign vlen_comp_incr  = vec_incr[~vsew_i];
78
```
to: 
```
77  /* vector increment comparator */
78  logic [VSEW_WIDTH-1:0] negated_vsew;
79  assign negated_vsew = ~vsew_i;
80  assign vlen_comp_incr = vec_incr[negated_vsew];
```

Also, the explanation of all the testcodes and its sources is present in our report.

To compile and simulate our module without the CPU, go in the `ovi` folder and run one of the following commands:
`make arith`  
`make memarith`  
Both will generate a sim.vcd waveform that you can then analyze with gtkwave using the configuration file found in `ovi/waveform_good.gtkw`.  
The FakeCPU+OVI+VPU takes about 2 minutes to compile.


You can also test the SWERV+OVI+VPU. You need to go in the root folder (not the `ovi` folder) and run one of the following commands:
`make arith`  
`make loadstore`  
`make setvl`  
`make vecaxpy`  
All will generate a sim.vcd waveform that you can then analyze with gtkwave using the configuration file found in `gtk.gtkw`.  

Keep in mind compiling the full project takes from 10 to 20 minutes.
