###############################################################################
# File         : jal.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'jal' instruction.
#
# Notes:
#   - Avoids beq/bne/etc. Uses jal/jr/j only for control flow.
#
###############################################################################

    .section .boot, "x"
    .balign 4
    .set    noreorder
    .global boot
    .ent    boot

boot:
    # Base address of status/test registers:
    #   0x80020000: status ("done")
    #   0x80020004: test result (1=pass, 0=fail)
    lui     $s0, 0x8002
    ori     $s1, $zero, 1          # done value
    ori     $s2, $zero, 1          # overall_ok = 1

    # Put stack somewhere safe in kernel segment for our save/restore test
    ori     $sp, $zero, 0x3F00     # $sp = 0x3F00 (local storage)

    ###########################################################################
    # Helper convention (no macros):
    #   diff = actual xor expected
    #   neq  = (diff != 0) using sltu
    #   ok   = 1 - neq
    #   overall_ok &= ok
    ###########################################################################

    ###########################################################################
    # Test 1: leaf call + delay slots
    #
    # Marker t7 accumulates:
    #   jal delay slot (in caller):            +1
    #   func1 body before jr:                  +2
    #   jr delay slot (in func1, on return):   +4
    #   after return (in caller):              +8
    #
    # Expected: 1 + 2 + 4 + 8 = 15
    ###########################################################################
    ori     $t7, $zero, 0

    jal     func1
    addiu   $t7, $t7, 1            # jal delay slot MUST execute

after_func1:
    addiu   $t7, $t7, 8

    ori     $t2, $zero, 15         # expected
    xor     $t3, $t7, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 2: non-leaf function (nested jal) with $ra save/restore
    #
    # Marker t6 accumulates:
    #   jal func2 delay slot (in caller):      +1
    #   jal func3 delay slot (in func2):       +2
    #   func3 body before jr:                  +16
    #   jr delay slot (in func3):              +32
    #   after return from func3 (in func2):    +4
    #   jr delay slot (in func2):              +8
    #   after return to caller (in main):      +64
    #
    # Expected: 1+2+16+32+4+8+64 = 127
    ###########################################################################
    ori     $t6, $zero, 0

    jal     func2
    addiu   $t6, $t6, 1            # jal delay slot MUST execute

after_func2:
    addiu   $t6, $t6, 64

    ori     $t2, $zero, 127        # expected
    xor     $t3, $t6, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Report result and finish
    ###########################################################################
    sw      $s2, 4($s0)            # test result (1=pass, 0=fail)
    sw      $s1, 0($s0)            # done

$done:
    j       $done
    nop

###############################################################################
# func1: leaf function
###############################################################################
func1:
    addiu   $t7, $t7, 2
    jr      $ra
    addiu   $t7, $t7, 4            # jr delay slot MUST execute

###############################################################################
# func2: non-leaf function; saves/restores $ra; calls func3
###############################################################################
func2:
    addiu   $sp, $sp, -16
    sw      $ra, 0($sp)

    jal     func3
    addiu   $t6, $t6, 2            # jal delay slot MUST execute

    addiu   $t6, $t6, 4

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 16

    jr      $ra
    addiu   $t6, $t6, 8            # jr delay slot MUST execute

###############################################################################
# func3: leaf function called by func2
###############################################################################
func3:
    addiu   $t6, $t6, 16
    jr      $ra
    addiu   $t6, $t6, 32           # jr delay slot MUST execute

    .end    boot