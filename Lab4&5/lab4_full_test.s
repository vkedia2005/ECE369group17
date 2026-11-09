# ECE369A Lab 4 - full Table 1 test program (all 30 instructions)
# 5 nops after every instruction (no hazard detection).
# Comments give each instruction's PC and the WriteData expected in WB
# (0 = no register written). Values are signed decimal.
# Taken branches skip an 'addi $t9, $zero, 99': seeing 99 means a branch failed.
# Labels sit on the same line as an instruction (MipsHelper requirement).
# Check: 'ori $t8, $zero, 40000' should encode as 34189c40.

.data
dummy:  .word 0

.text
main:   addi $t0, $zero, 10       # PC=0    expect 10      t0 = 10
        nop
        nop
        nop
        nop
        nop
        addi $t1, $zero, -3       # PC=24   expect -3      t1 = -3
        nop
        nop
        nop
        nop
        nop
        add  $t2, $t0, $t1        # PC=48   expect 7       10 + -3
        nop
        nop
        nop
        nop
        nop
        sub  $t3, $t0, $t1        # PC=72   expect 13      10 - -3
        nop
        nop
        nop
        nop
        nop
        mul  $t4, $t0, $t1        # PC=96   expect -30     10 * -3
        nop
        nop
        nop
        nop
        nop
        addi $s0, $zero, 12       # PC=120  expect 12      s0 = 12 (1100)
        nop
        nop
        nop
        nop
        nop
        addi $s1, $zero, 10       # PC=144  expect 10      s1 = 10 (1010)
        nop
        nop
        nop
        nop
        nop
        and  $t5, $s0, $s1        # PC=168  expect 8       1100 & 1010 = 1000
        nop
        nop
        nop
        nop
        nop
        or   $t6, $s0, $s1        # PC=192  expect 14      1100 | 1010 = 1110
        nop
        nop
        nop
        nop
        nop
        xor  $t7, $s0, $s1        # PC=216  expect 6       1100 ^ 1010 = 0110
        nop
        nop
        nop
        nop
        nop
        nor  $t8, $s0, $s1        # PC=240  expect -15     ~1110
        nop
        nop
        nop
        nop
        nop
        andi $t5, $s0, 6          # PC=264  expect 4       1100 & 0110
        nop
        nop
        nop
        nop
        nop
        ori  $t6, $s0, 3          # PC=288  expect 15      1100 | 0011
        nop
        nop
        nop
        nop
        nop
        xori $t7, $s0, 5          # PC=312  expect 9       1100 ^ 0101
        nop
        nop
        nop
        nop
        nop
        ori  $t8, $zero, 40000    # PC=336  expect 40000   zero-extend test (sign-extend would give -25536)
        nop
        nop
        nop
        nop
        nop
        sll  $s2, $s0, 2          # PC=360  expect 48      12 << 2
        nop
        nop
        nop
        nop
        nop
        srl  $s3, $s0, 2          # PC=384  expect 3       12 >> 2
        nop
        nop
        nop
        nop
        nop
        slt  $s4, $t1, $t0        # PC=408  expect 1       -3 < 10 (signed)
        nop
        nop
        nop
        nop
        nop
        slt  $s5, $t0, $t1        # PC=432  expect 0       10 < -3 is false
        nop
        nop
        nop
        nop
        nop
        slti $s6, $t1, 0          # PC=456  expect 1       -3 < 0
        nop
        nop
        nop
        nop
        nop
        slti $s7, $t0, 5          # PC=480  expect 0       10 < 5 is false
        nop
        nop
        nop
        nop
        nop
        sw   $t1, 0($zero)        # PC=504  expect 0       mem[0] = -3
        nop
        nop
        nop
        nop
        nop
        lw   $a0, 0($zero)        # PC=528  expect -3      load word back
        nop
        nop
        nop
        nop
        nop
        addi $a1, $zero, 200      # PC=552  expect 200     a1 = 200 = 0xC8
        nop
        nop
        nop
        nop
        nop
        sb   $a1, 4($zero)        # PC=576  expect 0       byte 4 = 0xC8
        nop
        nop
        nop
        nop
        nop
        lb   $a2, 4($zero)        # PC=600  expect -56     0xC8 sign-extended
        nop
        nop
        nop
        nop
        nop
        addi $v1, $zero, 17       # PC=624  expect 17      v1 = 17 = 0x11
        nop
        nop
        nop
        nop
        nop
        sb   $v1, 5($zero)        # PC=648  expect 0       byte 5 = 0x11
        nop
        nop
        nop
        nop
        nop
        lw   $v1, 4($zero)        # PC=672  expect 4552    word = 0x000011C8: sb kept byte 4
        nop
        nop
        nop
        nop
        nop
        addi $a3, $zero, -2000    # PC=696  expect -2000   a3 = 0xFFFFF830
        nop
        nop
        nop
        nop
        nop
        sh   $a3, 8($zero)        # PC=720  expect 0       half at 8 = 0xF830
        nop
        nop
        nop
        nop
        nop
        lh   $v0, 8($zero)        # PC=744  expect -2000   0xF830 sign-extended
        nop
        nop
        nop
        nop
        nop
        sh   $t0, 10($zero)       # PC=768  expect 0       upper half at 10 = 0x000A
        nop
        nop
        nop
        nop
        nop
        lw   $v0, 8($zero)        # PC=792  expect 718896  word = 0x000AF830
        nop
        nop
        nop
        nop
        nop
        beq  $t0, $t0, tk1        # PC=816  expect 0       beq equal: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=840  expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk1:    beq  $t0, $t1, nt2        # PC=864  expect 0       beq not equal: NOT taken
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 1        # PC=888  expect 1       runs because branch not taken
        nop
        nop
        nop
        nop
        nop
nt2:    bne  $t0, $t1, tk3        # PC=912  expect 0       bne not equal: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=936  expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk3:    bne  $t0, $t0, nt4        # PC=960  expect 0       bne equal: NOT taken
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 2        # PC=984  expect 2       runs because branch not taken
        nop
        nop
        nop
        nop
        nop
nt4:    bgez $t0, tk5             # PC=1008 expect 0       bgez 10: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=1032 expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk5:    bgez $zero, tk6           # PC=1056 expect 0       bgez 0: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=1080 expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk6:    bgez $t1, nt7             # PC=1104 expect 0       bgez -3: NOT taken
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 3        # PC=1128 expect 3       runs because branch not taken
        nop
        nop
        nop
        nop
        nop
nt7:    bgtz $t0, tk8             # PC=1152 expect 0       bgtz 10: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=1176 expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk8:    bgtz $zero, nt9           # PC=1200 expect 0       bgtz 0: NOT taken
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 4        # PC=1224 expect 4       runs because branch not taken
        nop
        nop
        nop
        nop
        nop
nt9:    blez $t1, tk10            # PC=1248 expect 0       blez -3: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=1272 expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk10:   blez $zero, tk11          # PC=1296 expect 0       blez 0: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=1320 expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk11:   blez $t0, nt12            # PC=1344 expect 0       blez 10: NOT taken
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 5        # PC=1368 expect 5       runs because branch not taken
        nop
        nop
        nop
        nop
        nop
nt12:   bltz $t1, tk13            # PC=1392 expect 0       bltz -3: TAKEN
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 99       # PC=1416 expect skip    SKIPPED (99 here = branch not taken)
        nop
        nop
        nop
        nop
        nop
tk13:   bltz $zero, nt14          # PC=1440 expect 0       bltz 0: NOT taken
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 6        # PC=1464 expect 6       runs because branch not taken
        nop
        nop
        nop
        nop
        nop
nt14:   jal  func                 # PC=1488 expect 1492    jal: $ra = PC+4
        nop
        nop
        nop
        nop
        nop
        addi $t9, $zero, 77       # PC=1512 expect 77      runs after jr returns
        nop
        nop
        nop
        nop
        nop
        j    main                 # PC=1536 expect 0       loop back to start
        nop
        nop
        nop
        nop
        nop
func:   addi $t9, $zero, 55       # PC=1560 expect 55      func: runs only via jal
        nop
        nop
        nop
        nop
        nop
        jr   $ra                  # PC=1584 expect 0       return
        nop
        nop
        nop
        nop
        nop
