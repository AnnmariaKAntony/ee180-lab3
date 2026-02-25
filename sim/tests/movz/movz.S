###############################################################################
# File         : movz.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'movz' instruction.
#
# Notes:
#   - Avoids conditional branches
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
    # Test 1: rt == 0 => move happens
    #   rd starts as 0xAAAAAAAA, rs = 0x11223344, rt = 0
    #   expected rd = 0x11223344
    ###########################################################################
    lui     $t0, 0xAAAA
    ori     $t0, $t0, 0xAAAA       # rd initial
    lui     $t1, 0x1122
    ori     $t1, $t1, 0x3344       # rs
    addu    $t2, $zero, $zero      # rt = 0

    movz    $t0, $t1, $t2          # should move

    # expected in t3 = 0x11223344
    lui     $t3, 0x1122
    ori     $t3, $t3, 0x3344

    xor     $t4, $t0, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 2: rt != 0 => no move (rd unchanged)
    #   rd starts as 0xAAAAAAAA, rs = 0x11223344, rt = 1
    #   expected rd = 0xAAAAAAAA
    ###########################################################################
    lui     $t0, 0xAAAA
    ori     $t0, $t0, 0xAAAA       # rd initial
    lui     $t1, 0x1122
    ori     $t1, $t1, 0x3344       # rs
    ori     $t2, $zero, 1          # rt = 1

    movz    $t0, $t1, $t2          # should NOT move

    lui     $t3, 0xAAAA
    ori     $t3, $t3, 0xAAAA       # expected

    xor     $t4, $t0, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 3: rd == rs case (self move / should still obey condition)
    #   If rt == 0, rd=rs (no effective change), but must not break.
    ###########################################################################
    lui     $t0, 0x0BAD
    ori     $t0, $t0, 0xF00D       # rd == rs == 0x0BADF00D
    addu    $t2, $zero, $zero      # rt = 0

    movz    $t0, $t0, $t2          # rd==rs, move condition true

    lui     $t3, 0x0BAD
    ori     $t3, $t3, 0xF00D       # expected unchanged value

    xor     $t4, $t0, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 4: rd == $zero (writes ignored even if condition true)
    #   rs = 0x12345678, rt = 0, movz $zero, rs, rt
    #   expected $zero still 0
    ###########################################################################
    lui     $t1, 0x1234
    ori     $t1, $t1, 0x5678
    addu    $t2, $zero, $zero      # rt = 0

    movz    $zero, $t1, $t2        # attempt write to $zero

    addu    $t0, $zero, $zero      # read back $zero
    addu    $t3, $zero, $zero      # expected = 0

    xor     $t4, $t0, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 5: hazard - rt produced immediately before movz (rt becomes 0)
    #   rt = (5 - 5) = 0, so movz should move
    ###########################################################################
    lui     $t0, 0xAAAA
    ori     $t0, $t0, 0x5555       # rd initial
    lui     $t1, 0xCAFE
    ori     $t1, $t1, 0xBABE       # rs

    ori     $t2, $zero, 5
    addiu   $t2, $t2, -5           # rt = 0 (dependency!)

    movz    $t0, $t1, $t2          # should move

    lui     $t3, 0xCAFE
    ori     $t3, $t3, 0xBABE       # expected

    xor     $t4, $t0, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 6: hazard - rt produced immediately before movz (rt becomes nonzero)
    #   rt = (5 - 4) = 1, so movz should NOT move (rd unchanged)
    ###########################################################################
    lui     $t0, 0x1357
    ori     $t0, $t0, 0x9BDF       # rd initial
    lui     $t1, 0x2468
    ori     $t1, $t1, 0xACE0       # rs

    ori     $t2, $zero, 5
    addiu   $t2, $t2, -4           # rt = 1 (dependency!)

    movz    $t0, $t1, $t2          # should NOT move

    lui     $t3, 0x1357
    ori     $t3, $t3, 0x9BDF       # expected unchanged

    xor     $t4, $t0, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 7: hazard - rs produced immediately before movz (rs dependency)
    #   rt = 0, rs computed right before movz, so rd should take new rs
    ###########################################################################
    lui     $t0, 0x9999
    ori     $t0, $t0, 0x0000       # rd initial

    lui     $t1, 0x1111
    ori     $t1, $t1, 0x1111
    addiu   $t1, $t1, 1            # rs becomes 0x11111112 (dependency!)

    addu    $t2, $zero, $zero      # rt = 0
    movz    $t0, $t1, $t2          # should move the newly-produced rs

    lui     $t3, 0x1111
    ori     $t3, $t3, 0x1112       # expected 0x11111112

    xor     $t4, $t0, $t3
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