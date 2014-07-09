# copyright 2002 Chris Kelly ckdake@ckdake.com

main:
	
.data
str1:	 .asciiz "What are these?\n"
brk:	 .asciiz "\n"
start:   .byte 0
	
.text
		la $s1, start    
		li $s2, 0       
		li $s3, 0      
		la $s4, start  
		li $s5, 2
		li $s6, 1
		addi $s7, $s4, 998 

init:	sb $s6, ($s4)		
		addi $s4, $s4, 1
		slt $t2, $s4, $s7  
		beqz $t2, endi	  
		j init
endi:

		la $s4, start	
		li $s5, 2

trav:	slti $t2, $s5, 1000	
		beqz $t2, p1
		
outer:	lb $t2, ($s4)	
		beqz $t2, endo		
		add $t4, $s4, $s5
		add $t5, $s5, $s5
		
inner:	slti $t2, $t5, 1000 	
		beqz $t2, endo
		sb $zero, ($t4)	
		add $t4, $t4, $s5	
		add $t5, $t5, $s5
		j inner		
		
endo:  
		addi $s5, $s5, 1
		addi $s4, $s4, 1
		j trav



p1:		la $a0, str1
		li $v0, 4
		syscall

		la $s4, start		
		li $s5, 2 	
		
		
pnums:  lb $t0, ($s4)  	
		slti $t2, $t0, 1
		beq $t2, $s6, restp
		
		la $a0, ($s5)
		li $v0, 1
		syscall	
		la $a0, brk
		li $v0, 4
		syscall	
		
restp:	addi $s4, $s4, 1  	
		addi $s5, $s5, 1	
		slt $t2, $s4, $s7  
		beqz $t2, endp	  
		j pnums
endp:
