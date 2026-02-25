###############################################################################
# File         : addi.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'addi' instruction.
#
# Notes:
#   - Avoids conditional branches so can still run without branching implemented yet
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

    # done value
    ori     $s1, $zero, 1

    # overall_ok = 1
    ori     $s2, $zero, 1

    ###########################################################################
    # Helper convention (no macros):
    #   Given actual in Rx and expected in Ry:
    #     diff = Rx xor Ry
    #     neq  = (diff != 0) using sltu
    #     ok   = 1 - neq
    #     overall_ok &= ok
    ###########################################################################

    ###########################################################################
    # Test 1: small positive immediate
    #   t0 = 5
    #   actual:   t1 = t0 + 7  => 12
    #   expected: t2 = 12
    ###########################################################################
    ori     $t0, $zero, 5
    addi    $t1, $t0, 7
    ori     $t2, $zero, 12

    xor     $t3, $t1, $t2          # diff
    sltu    $t4, $zero, $t3        # neq = 1 if diff != 0
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4          # ok = 1 - neq
    and     $s2, $s2, $t5          # overall_ok &= ok

    ###########################################################################
    # Test 2: negative immediate
    #   t0 = 5
    #   actual:   t1 = t0 + (-3) => 2
    #   expected: t2 = 2
    ###########################################################################
    ori     $t0, $zero, 5
    addi    $t1, $t0, -3
    ori     $t2, $zero, 2

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 3: sign-extension edge (imm = 0x8000 = -32768)
    #   t0 = 1
    #   actual:   t1 = 1 + (-32768) = -32767 = 0xFFFF8001
    ###########################################################################
    ori     $t0, $zero, 1
    addi    $t1, $t0, 0x8000       # -32768

    lui     $t2, 0xFFFF
    ori     $t2, $t2, 0x8001       # 0xFFFF8001

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 4: max positive imm (imm = 0x7FFF = +32767)
    #   t0 = -1 (0xFFFFFFFF)
    #   actual:   t1 = -1 + 32767 = 32766 = 0x00007FFE
    ###########################################################################
    addiu   $t0, $zero, -1         # 0xFFFFFFFF
    addi    $t1, $t0, 0x7FFF

    ori     $t2, $zero, 0x7FFE

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 5: larger values, no overflow (0x7FFFFFF0 + 0x000F = 0x7FFFFFFF)
    ###########################################################################
    lui     $t0, 0x7FFF
    ori     $t0, $t0, 0xFFF0       # 0x7FFFFFF0
    addi    $t1, $t0, 0x000F       # +15

    lui     $t2, 0x7FFF
    ori     $t2, $t2, 0xFFFF       # 0x7FFFFFFF

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 6: rs = $zero
    #   actual: t1 = 0 + 123 = 123
    ###########################################################################
    addi    $t1, $zero, 123
    ori     $t2, $zero, 123

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 7: rt = $zero should remain zero (writes to $zero are ignored)
    ###########################################################################
    ori     $t0, $zero, 77
    addi    $zero, $t0, 5          # attempt to write $zero
    addu    $t1, $zero, $zero      # read back $zero into t1
    ori     $t2, $zero, 0

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 8: dependency / back-to-back addi (hazard-style behavior)
    #   t0 = 10
    #   t0 = t0 + 1  => 11
    #   t1 = t0 + 2  => 13
    ###########################################################################
    ori     $t0, $zero, 10
    addi    $t0, $t0, 1
    addi    $t1, $t0, 2

    ori     $t2, $zero, 13

    xor     $t3, $t1, $t2
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

    .end    boot