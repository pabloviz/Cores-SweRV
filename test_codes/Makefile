#RISCV=../riscv-gnu-toolchain/build64/bin
#CC=$(RISCV)/riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O1
#DUMP=$(RISCV)/riscv32-unknown-elf-objdump
#CC=$(RISCV)/riscv64-unknown-elf-gcc -march=rv64im -O0 #-mabi=lp64 -O0
CC=riscv32-unknown-elf-gcc -march=rv32im -mabi=ilp32 -O0
all:axpy 

% : %.c
	$(CC) $< -S -o $@.s 
	$(CC) $< -o $@.x

clean:
	rm -f *.s
