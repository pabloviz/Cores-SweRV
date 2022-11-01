

To compile and simulate the module, run `make`. It will simulate 50 cycles of the CPUautomata-ovi-VPUautomata interaction

Remember to update the BSC submodule with `git submodule update --init --recursive`

Also, disable the vector floating point unit by edditing the file `bsc-vector-accelerator/src/include/config_control.svh` and changing line 78 from `\`define HAS_FPU` to `\`define EXCLUDE_FPU`


TODO: implement VPUautomata
