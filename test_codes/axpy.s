	.file	"axpy.c"
	.option nopic
	.attribute arch, "rv32i2p0_m2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	li sp, 1024
	addi	sp,sp,-128
	sw	s0,124(sp)
	addi	s0,sp,128
 #APP
# 9 "axpy.c" 1

# 0 "" 2
 #NO_APP
	li	a5,3
	sw	a5,-124(s0)
.L2:
	sw	zero,-20(s0)
	j	.L3
.L4:
	lw	a5,-20(s0)
	slli	a5,a5,2
	addi	a4,s0,-16
	add	a5,a4,a5
	li	a4,10
	sw	a4,-40(a5)
	lw	a5,-20(s0)
	slli	a5,a5,2
	addi	a4,s0,-16
	add	a5,a4,a5
	lw	a4,-20(s0)
	sw	a4,-72(a5)
	lw	a5,-20(s0)
	addi	a5,a5,1
	sw	a5,-20(s0)
.L3:
	lw	a4,-20(s0)
	li	a5,7
	ble	a4,a5,.L4
	nop
.L5:
	sw	zero,-24(s0)
	j	.L6
.L7:
	lw	a5,-24(s0)
	slli	a5,a5,2
	addi	a4,s0,-16
	add	a5,a4,a5
	lw	a4,-40(a5)
	lw	a5,-24(s0)
	slli	a5,a5,2
	addi	a3,s0,-16
	add	a5,a3,a5
	lw	a3,-72(a5)
	lw	a5,-124(s0)
	mul	a5,a3,a5
	add	a4,a4,a5
	lw	a5,-24(s0)
	slli	a5,a5,2
	addi	a3,s0,-16
	add	a5,a3,a5
	sw	a4,-104(a5)
	lw	a5,-24(s0)
	addi	a5,a5,1
	sw	a5,-24(s0)
.L6:
	lw	a4,-24(s0)
	li	a5,7
	ble	a4,a5,.L7
	lw	a5,-120(s0)
	sw	a5,-128(s0)
 #APP
# 20 "axpy.c" 1
	1:;
 li x3, -799539200 
 addi x5, x0, 0xff 
 sb x5, 0(x3)  
 beq x0, x0, 1b 

# 0 "" 2
 #NO_APP
	li	a5,0
	mv	a0,a5
	lw	s0,124(sp)
	addi	sp,sp,128
	jr	ra
	.size	main, .-main
	.ident	"GCC: (GNU) 10.2.0"
