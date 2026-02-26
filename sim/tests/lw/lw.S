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
    ori     $s1, $zero, 1          # done value
    ori     $s2, $zero, 1          # overall_ok = 1

    # Known-good save slot for $ra, far from any code
    lui     $s3, 0x0000
    ori     $s3, $s3, 0x7000       # $s3 = 0x00007000

    # pre-clear the save slot so we don't read stale data
    sw      $zero, 0($s3)
    nop
    nop
    nop

    ###########################################################################
    # Test 1: leaf call + delay slots
    # Expected t7 = 1 + 2 + 4 + 8 = 15
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
    # Test 2: non-leaf call + delay slots + $ra save/restore
    # Expected t6 = 1 + 2 + 16 + 32 + 4 + 8 + 64 = 127
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
# func2: non-leaf, saves/restores $ra to 0x00007000
###############################################################################
func2:
    sw      $ra, 0($s3)
    nop
    nop
    nop
    lw      $ra, 0($s3)            # verify save slot is readable
    nop
    nop
    nop

    jal     func3
    addiu   $t6, $t6, 2            # jal delay slot: +2

    addiu   $t6, $t6, 4            # after func3 returns: +4

    lw      $ra, 0($s3)            # restore saved $ra
    nop
    nop
    nop

    jr      $ra
    addiu   $t6, $t6, 8            # jr delay slot: +8

###############################################################################
# func3: leaf called by func2
###############################################################################
func3:
    addiu   $t6, $t6, 16           # +16
    jr      $ra
    addiu   $t6, $t6, 32           # jr delay slot: +32

    .end    boot