###############################################################################
# File         : or.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'or' instruction.
#
###############################################################################

    .section .boot, "x"
    .balign 4
    .set    noreorder
    .global boot
    .ent    boot

boot:
    # Status/result registers
    lui     $s0, 0x8002
    ori     $s1, $zero, 1          # done value
    ori     $s2, $zero, 1          # overall_ok = 1

    ###########################################################################
    # Helper convention (no macros):
    #   diff = actual xor expected
    #   neq  = (diff != 0) using sltu
    #   ok   = 1 - neq
    #   overall_ok &= ok
    ###########################################################################

    ###########################################################################
    # Test 1: alternating patterns -> all ones
    #   0xAAAAAAAA | 0x55555555 = 0xFFFFFFFF
    ###########################################################################
    lui     $t0, 0xAAAA
    ori     $t0, $t0, 0xAAAA       # rs
    lui     $t1, 0x5555
    ori     $t1, $t1, 0x5555       # rt

    or      $t2, $t0, $t1          # actual

    lui     $t3, 0xFFFF
    ori     $t3, $t3, 0xFFFF       # expected = 0xFFFFFFFF

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 2: OR with zero (identity)
    #   x | 0 = x
    ###########################################################################
    lui     $t0, 0x1234
    ori     $t0, $t0, 0x5678       # x
    or      $t2, $t0, $zero

    lui     $t3, 0x1234
    ori     $t3, $t3, 0x5678       # expected = x

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 3: OR with all ones (absorption)
    #   x | 0xFFFFFFFF = 0xFFFFFFFF
    ###########################################################################
    lui     $t1, 0xFFFF
    ori     $t1, $t1, 0xFFFF       # all ones
    or      $t2, $t0, $t1          # x | all_ones

    lui     $t3, 0xFFFF
    ori     $t3, $t3, 0xFFFF       # expected = all ones

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 4: OR where result equals rs (rt is subset bits)
    #   rs = 0xF0F0F0F0, rt = 0x0000000F => result 0xF0F0F0FF
    ###########################################################################
    lui     $t0, 0xF0F0
    ori     $t0, $t0, 0xF0F0       # 0xF0F0F0F0
    ori     $t1, $zero, 0x000F     # 0x0000000F

    or      $t2, $t0, $t1

    lui     $t3, 0xF0F0
    ori     $t3, $t3, 0xF0FF       # expected 0xF0F0F0FF

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 5: mixed pattern
    #   rs = 0x00FF00FF
    #   rt = 0x0F0F0F0F
    #   result = 0x0FFF0FFF
    ###########################################################################
    lui     $t0, 0x00FF
    ori     $t0, $t0, 0x00FF       # 0x00FF00FF
    lui     $t1, 0x0F0F
    ori     $t1, $t1, 0x0F0F       # 0x0F0F0F0F

    or      $t2, $t0, $t1

    lui     $t3, 0x0FFF
    ori     $t3, $t3, 0x0FFF       # expected 0x0FFF0FFF

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 6: dependency/hazard - use OR result immediately
    #   t2 = 0x00000000 | 0x00000001 = 1
    #   then sll t2, t2, 4 => 0x10
    ###########################################################################
    addu    $t0, $zero, $zero
    ori     $t1, $zero, 1
    or      $t2, $t0, $t1
    sll     $t2, $t2, 4

    ori     $t3, $zero, 0x0010     # expected 0x10

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 7: write to $zero should be ignored
    #   Attempt: or $zero, all_ones, 0 => would be all_ones, but $zero stays 0
    ###########################################################################
    lui     $t0, 0xFFFF
    ori     $t0, $t0, 0xFFFF       # all ones
    or      $zero, $t0, $zero

    addu    $t2, $zero, $zero      # read back $zero
    addu    $t3, $zero, $zero      # expected 0

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Report result and finish
    ###########################################################################
    sw      $s2, 4($s0)            # test result (1=pass, 0=fail)
    sw      $s1, 0($s0)            # done

$done:
    j       $done
    nop

    .end    boot