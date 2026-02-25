###############################################################################
# File         : nor.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'nor' instruction.
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
    # Test 1: nor with complementary alternating patterns
    #   rs = 0xAAAAAAAA
    #   rt = 0x55555555
    #   rs|rt = 0xFFFFFFFF => ~(...) = 0x00000000
    ###########################################################################
    lui     $t0, 0xAAAA
    ori     $t0, $t0, 0xAAAA       # rs
    lui     $t1, 0x5555
    ori     $t1, $t1, 0x5555       # rt

    nor     $t2, $t0, $t1          # actual

    addu    $t3, $zero, $zero      # expected = 0

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 2: nor with zeros
    #   nor x, 0, 0 = 0xFFFFFFFF
    ###########################################################################
    nor     $t2, $zero, $zero

    lui     $t3, 0xFFFF
    ori     $t3, $t3, 0xFFFF       # expected = 0xFFFFFFFF

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 3: nor x, x, 0 = ~x
    #   x = 0x12345678 => ~x = 0xEDCBA987
    ###########################################################################
    lui     $t0, 0x1234
    ori     $t0, $t0, 0x5678       # x
    nor     $t2, $t0, $zero

    lui     $t3, 0xEDCB
    ori     $t3, $t3, 0xA987       # expected

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 4: nor x, x, x = ~x
    #   x = 0x80000001 => ~x = 0x7FFFFFFE
    ###########################################################################
    lui     $t0, 0x8000
    ori     $t0, $t0, 0x0001       # x
    nor     $t2, $t0, $t0

    lui     $t3, 0x7FFF
    ori     $t3, $t3, 0xFFFE       # expected

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 5: random-ish mixed pattern check
    #   rs = 0x0F0F00FF
    #   rt = 0x00FF0F0F
    #   rs|rt = 0x0FFF0FFF => ~ = 0xF000F000
    ###########################################################################
    lui     $t0, 0x0F0F
    ori     $t0, $t0, 0x00FF
    lui     $t1, 0x00FF
    ori     $t1, $t1, 0x0F0F

    nor     $t2, $t0, $t1

    lui     $t3, 0xF000
    ori     $t3, $t3, 0xF000

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 6: dependency/hazard - use nor result immediately
    #   t2 = nor(0,0)=0xFFFFFFFF; then addiu t2, t2, 1 => 0x00000000
    ###########################################################################
    nor     $t2, $zero, $zero
    addiu   $t2, $t2, 1

    addu    $t3, $zero, $zero      # expected = 0

    xor     $t4, $t2, $t3
    sltu    $t5, $zero, $t4
    ori     $t6, $zero, 1
    subu    $t6, $t6, $t5
    and     $s2, $s2, $t6

    ###########################################################################
    # Test 7: write to $zero should be ignored
    #   Try to do nor $zero, 0, 0 (would be 0xFFFFFFFF), but $zero must stay 0.
    ###########################################################################
    nor     $zero, $zero, $zero
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