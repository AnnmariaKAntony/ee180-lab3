###############################################################################
# File         : jal.S
# Project      : EE180 Lab 3: MIPS
###############################################################################

    .section .boot, "x"
    .balign 4
    .set    noreorder
    .global boot
    .ent    boot

boot:
    lui     $s0, 0x8002
    ori     $s1, $zero, 1
    ori     $s2, $zero, 1

    ###########################################################################
    # Test 1: leaf call + delay slots
    #
    # t7 accumulates:
    #   jal delay slot:        +1
    #   func1 body:            +2
    #   jr delay slot:         +4
    #   after return:          +8
    # Expected: 15
    ###########################################################################
    ori     $t7, $zero, 0

    jal     func1
    addiu   $t7, $t7, 1            # jal delay slot: +1

after_func1:
    addiu   $t7, $t7, 8            # after return: +8

    ori     $t2, $zero, 15
    xor     $t3, $t7, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 2: nested call with $ra saved in register instead of memory
    #
    # t6 accumulates:
    #   jal func2 delay slot:          +1
    #   jal func3 delay slot (func2):  +2
    #   func3 body:                    +16
    #   func3 jr delay slot:           +32
    #   after func3 return (func2):    +4
    #   func2 jr delay slot:           +8
    #   after func2 return (main):     +64
    # Expected: 127
    ###########################################################################
    ori     $t6, $zero, 0

    jal     func2
    addiu   $t6, $t6, 1            # jal delay slot: +1

after_func2:
    addiu   $t6, $t6, 64           # after return: +64

    ori     $t2, $zero, 127
    xor     $t3, $t6, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 3: check $ra value is exactly after_call address
    #
    # After jal func4, $ra should equal after_func4
    # xor of $ra and after_func4 address should be 0
    ###########################################################################
    jal     func4
    nop

after_func4:
    # $ra should == after_func4
    lui     $t0, %hi(after_func4)
    ori     $t0, $t0, %lo(after_func4)

    # mask top 4 bits of both
    sll     $t1, $ra, 4
    srl     $t1, $t1, 4
    sll     $t2, $t0, 4
    srl     $t2, $t2, 4

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Report
    ###########################################################################
    sw      $s2, 4($s0)
    sw      $s1, 0($s0)

$done:
    j       $done
    nop

###############################################################################
# func1: leaf
###############################################################################
func1:
    addiu   $t7, $t7, 2            # +2
    jr      $ra
    addiu   $t7, $t7, 4            # jr delay slot: +4

###############################################################################
# func2: non-leaf, saves $ra in $s4 (saved register, no memory needed)
###############################################################################
func2:
    ori     $s4, $ra, 0            # save $ra to $s4

    jal     func3
    addiu   $t6, $t6, 2            # jal delay slot: +2

    addiu   $t6, $t6, 4            # after func3 returns: +4

    jr      $s4                    # return using saved $ra
    addiu   $t6, $t6, 8            # jr delay slot: +8

###############################################################################
# func3: leaf called by func2
###############################################################################
func3:
    addiu   $t6, $t6, 16           # +16
    jr      $ra
    addiu   $t6, $t6, 32           # jr delay slot: +32

###############################################################################
# func4: leaf, just returns immediately
###############################################################################
func4:
    jr      $ra
    nop

    .end    boot