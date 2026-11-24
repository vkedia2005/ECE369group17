#  Fall 2026
#  Team Members:    Vasu Kedia, Noah Kramer, Luke Mccullough
#  % Effort    :    Vasu Kedia 33.3%, Noah Kramer 33.3%, Luke Mccullough 33.3%
#
# ECE369A, Lab 8 (competition) - working test case until the 64x64 data is released
#
# Single test: Lab 7 test 5 (32x32 frame, 4x4 window).
#   Expected result: $v0 (row) = 5, $v1 (col) = 16, minimum SAD ($t7) = 0
#
# Data layout (data memory starts at address 0):
#   asize5  : word 0    (byte 0)
#   frame5  : word 4    (byte 16)
#   window5 : word 1028 (byte 4112)
#
# vbsme is the same as Lab 7. The best SAD is kept in $t7 (team agreement:
# the testbench and display read $t7), row/col in $v0/$v1.
# The program ends in 'exit: j exit' (competition requirement).
#
########################################################################################################################
### data
########################################################################################################################
.data
asize5: .word    32, 32, 4, 4    #i, j, k, l
frame5: .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
         .word    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
window5:   .word    10, 10, 10, 10, 
            .word    10, 10, 10, 10, 
            .word    10, 10, 10, 10, 
            .word    10, 10, 10, 10

########################################################################################################################
### main
########################################################################################################################
.text
main:       addi    $sp, $zero, 32764       # $sp = last word of the 8192-word data memory
            addi    $sp, $sp, -4            # make space on stack
            sw      $ra, 0($sp)             # save return address
            addi    $a0, $zero, 0           # $a0 = &asize5
            addi    $a1, $zero, 16          # $a1 = &frame5
            addi    $a2, $zero, 4112        # $a2 = &window5
            jal     vbsme                   # result in $v0 (row), $v1 (col), SAD in $t7
            lw      $ra, 0($sp)             # restore return address
            addi    $sp, $sp, 4             # restore stack pointer
exit:       j       exit                    # infinite loop: end of program

#####################################################################
### vbsme
#####################################################################
# Circular (spiral) search: outer layer clockwise (right, down, left, up),
# then shrink the boundary by one on every side and repeat.
#   $a0 = &asize, $a1 = &frame[0][0], $a2 = &window[0][0]
#   $v0 = row, $v1 = col of the block with the minimum SAD
#
# Registers:
#   $s1 = j (frame cols)   $s2 = k (window rows)   $s3 = l (window cols)
#   $t5 = top  $t6 = bottom  $s6 = left  $s0 = right   (current layer)
#   $s4 = r    $s5 = c                                  (current position)
#   $t7 = best SAD so far, $s7 = saved return address to main
vbsme:      addi    $v0, $zero, 0           # best row = 0
            addi    $v1, $zero, 0           # best col = 0
            add     $s7, $ra, $zero         # save main's return address (jal checkPos overwrites $ra)
            lw      $s0, 0($a0)             # i = frame rows
            lw      $s1, 4($a0)             # j = frame cols
            lw      $s2, 8($a0)             # k = window rows
            lw      $s3, 12($a0)            # l = window cols
            sub     $t6, $s0, $s2           # bottom = i - k
            sub     $s0, $s1, $s3           # right  = j - l
            addi    $t5, $zero, 0           # top  = 0
            addi    $s6, $zero, 0           # left = 0
            addi    $t7, $zero, -1          # $t7 = 0xFFFFFFFF
            srl     $t7, $t7, 1             # $t7 = 0x7FFFFFFF (largest positive int)

layer:      slt     $t3, $t6, $t5           # bottom < top ?
            bne     $t3, $zero, doneAll     #   yes -> every position visited
            slt     $t3, $s0, $s6           # right < left ?
            bne     $t3, $zero, doneAll     #   yes -> every position visited
            add     $s4, $t5, $zero         # r = top
            add     $s5, $s6, $zero         # c = left

goRight:    jal     checkPos
            addi    $s5, $s5, 1             # c++
            slt     $t3, $s0, $s5           # right < c ?
            beq     $t3, $zero, goRight     #   no -> keep going right
            add     $s5, $s0, $zero         # c = right
            addi    $s4, $t5, 1             # r = top + 1

goDown:     slt     $t3, $t6, $s4           # bottom < r ?
            bne     $t3, $zero, doneDown    #   yes -> leg finished
            jal     checkPos
            addi    $s4, $s4, 1             # r++
            j       goDown

doneDown:   slt     $t3, $t5, $t6           # top < bottom ?
            beq     $t3, $zero, doneLeft    #   no -> layer is one row tall
            add     $s4, $t6, $zero         # r = bottom
            addi    $s5, $s0, -1            # c = right - 1

goLeft:     slt     $t3, $s5, $s6           # c < left ?
            bne     $t3, $zero, doneLeft    #   yes -> leg finished
            jal     checkPos
            addi    $s5, $s5, -1            # c--
            j       goLeft

doneLeft:   slt     $t3, $s6, $s0           # left < right ?
            beq     $t3, $zero, shrink      #   no -> layer is one col wide
            add     $s5, $s6, $zero         # c = left
            addi    $s4, $t6, -1            # r = bottom - 1

goUp:       slt     $t3, $t5, $s4           # top < r ?
            beq     $t3, $zero, shrink      #   no -> reached the top
            jal     checkPos
            addi    $s4, $s4, -1            # r--
            j       goUp

shrink:     addi    $t5, $t5, 1             # top++
            addi    $t6, $t6, -1            # bottom--
            addi    $s6, $s6, 1             # left++
            addi    $s0, $s0, -1            # right--
            j       layer

doneAll:    jr      $s7                     # back to main ($v0/$v1 already hold the best)

# SAD of the window placed at (r, c) = ($s4, $s5); updates best if smaller
checkPos:   addi    $t0, $zero, 0           # sum = 0
            addi    $t1, $zero, 0           # a = 0 (window row)
sadRow:     addi    $t2, $zero, 0           # b = 0 (window col)
sadCol:     add     $t3, $s4, $t1           # r + a
            mul     $t3, $t3, $s1           # (r + a) * j
            add     $t4, $s5, $t2           # c + b
            add     $t3, $t3, $t4           # frame index = (r+a)*j + (c+b)
            sll     $t3, $t3, 2             # x4 -> byte offset
            add     $t3, $t3, $a1           # + frame base
            lw      $t3, 0($t3)             # f = frame value
            mul     $t4, $t1, $s3           # a * l
            add     $t4, $t4, $t2           # window index = a*l + b
            sll     $t4, $t4, 2             # x4 -> byte offset
            add     $t4, $t4, $a2           # + window base
            lw      $t4, 0($t4)             # w = window value
            sub     $t3, $t3, $t4           # d = f - w
            bgez    $t3, sadPos             # d >= 0 ? skip negation
            sub     $t3, $zero, $t3         # d = -d
sadPos:     add     $t0, $t0, $t3           # sum += |f - w|
            addi    $t2, $t2, 1             # b++
            slt     $t3, $t2, $s3           # b < l ?
            bne     $t3, $zero, sadCol      #   yes -> next window col
            addi    $t1, $t1, 1             # a++
            slt     $t3, $t1, $s2           # a < k ?
            bne     $t3, $zero, sadRow      #   yes -> next window row
            slt     $t3, $t0, $t7           # sum < best ?
            beq     $t3, $zero, notBetter
            add     $t7, $t0, $zero         # best SAD = sum
            add     $v0, $s4, $zero         # best row = r   (display updates here)
            add     $v1, $s5, $zero         # best col = c
notBetter:  jr      $ra                     # back to the leg that called it
