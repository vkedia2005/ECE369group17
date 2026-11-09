.data
DATA:   .word 1, 2, 3, 4, 5, 6, 7

.text
.globl main

    # Load values
main:
    la   $a0, DATA  # use for qtspim only
	#addi $a0, $zero, 0 # use for MIPS helper
    addi $t0, $zero, 8  # 0x8
    addi $t1, $zero, 9  # 0x9
    addi $t2, $zero, 10  # 0xA
    addi $t3, $zero, 11  # 0xB
    addi $t4, $zero, 12  # 0xC
    addi $t5, $zero, 13  # 0xD
    addi $t6, $zero, 15  # 0xF	


 # case 1: rs for sub->addi
    sub $t0, $t1, $zero    # t0 = 9 - 0 = 9 0x9
    addi $t5, $t0, 14        # t5 = 9 + 14 = 23 0x17

    nop                
    nop                 
    nop                 
    nop                 
    nop 

    # case 2: rt,rs for lw->andi->sub
    lw $t3, 4($a0)           # t3 = Mem[1] = 2 0x2
    and $t4, $t1, $t2     # t4 = 9 AND 8 = 8 0x8
    sub $t0, $t3, $t4        # t0 = 2 - 8 = -6 0xFFFA

    nop                
    nop                 
    nop                 
    nop                 
    nop   
	
    #case 3: lw->sw
    lw $t3, 16($a0)             # t3 = Mem[4] = 5	
    sw $t3, 16($a0)            # Mem[4] = t3 = 5	
    lw $t3, 16($a0)             # t3 = Mem[4] = 5	
    nop                 
    nop                 
    nop                 
    nop                 
    nop                

    # case 4: rt,rs for lw->andi->sub
    add $t3, $t3 $t0          # t3 = 5 + -6 = -1  0xFFFF
    andi $t4, $t6, 8          # t4 = 15 AND 8 = 8
    sub $t0, $t3, $t5         # t0 = -1 - 23 = -24  0xFFE8
	
    nop                
    nop                 
    nop                 
    nop                 
    nop 