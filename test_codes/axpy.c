//This is used to let the verilator testbench know when to finish
#define STDOUT 0xd0580000
#define END() asm volatile("1:;\n li x3, %0 \n addi x5, x0, 0xff \n sb x5, 0(x3)  \n beq x0, x0, 1b \n" : : "i"(STDOUT) : "x3", "x5");

//Declare where local variables are stored (stack pointer)
#define STACK 1024
#define N 8
int main(){
	asm volatile("li sp, %0\n" : : "i"(STACK)); 
	long A[N], B[N], C[N];
	volatile long alpha = 3; //volatile so the mul does not get optimized into sll
     ini:
	for(int i=0; i<N; ++i){
		A[i] = 10;
		B[i] = i;
	}
    loop:
	for(int i=0; i<N; ++i)	C[i] = A[i] + B[i]*alpha;
	volatile long xx = C[0]; //So the loop does not get optimized
	END()
}



