###############################################################################
# File         : bgtz.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'bgtz' instruction.
#
# Notes:
#   - Tests if branch taken when rs > 0, not taken when rs <= 0, and delay-slot
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
    #   diff = actual xor expected
    #   neq  = (diff != 0) using sltu
    #   ok   = 1 - neq
    #   overall_ok &= ok
    ###########################################################################

    ###########################################################################
    # Test 1: rs > 0  => branch TAKEN
    # Also checks delay slot executes.
    #
    # We compute a "marker" t7 that depends on which path executes:
    #   delay slot:        t7 += 1   (always)
    #   if taken target:   t7 += 2
    #   if not taken path: t7 += 4
    #
    # Expected when taken: t7 = 0 + 1 + 2 = 3
    ###########################################################################
    ori     $t0, $zero, 1          # rs = +1
    ori     $t7, $zero, 0          # marker = 0

    bgtz    $t0, T1_taken
    addiu   $t7, $t7, 1            # delay slot: always executes

    # not-taken path (should NOT execute for this test)
    addiu   $t7, $t7, 4
    j       T1_after
    nop

T1_taken:
    addiu   $t7, $t7, 2

T1_after:
    ori     $t2, $zero, 3          # expected = 3
    xor     $t3, $t7, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 2: rs == 0 => branch NOT taken
    # Delay slot still executes.
    #
    # Expected when not taken: t7 = 0 + 1 + 4 = 5
    ###########################################################################
    ori     $t0, $zero, 0          # rs = 0
    ori     $t7, $zero, 0

    bgtz    $t0, T2_taken
    addiu   $t7, $t7, 1            # delay slot

    # not-taken path (should execute)
    addiu   $t7, $t7, 4
    j       T2_after
    nop

T2_taken:
    addiu   $t7, $t7, 2

T2_after:
    ori     $t2, $zero, 5          # expected = 5
    xor     $t3, $t7, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 3: rs < 0  => branch NOT taken
    # Use rs = -1 (0xFFFFFFFF)
    #
    # Expected when not taken: t7 = 0 + 1 + 4 = 5
    ###########################################################################
    addiu   $t0, $zero, -1         # rs = -1
    ori     $t7, $zero, 0

    bgtz    $t0, T3_taken
    addiu   $t7, $t7, 1            # delay slot

    addiu   $t7, $t7, 4            # not-taken path
    j       T3_after
    nop

T3_taken:
    addiu   $t7, $t7, 2

T3_after:
    ori     $t2, $zero, 5
    xor     $t3, $t7, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 4: rs = 0x7FFFFFFF (largest positive) => TAKEN
    # Also sanity-check that bgtz doesn't modify rs.
    #
    # Marker expected when taken: 3
    # rs expected unchanged: 0x7FFFFFFF
    ###########################################################################
    lui     $t0, 0x7FFF
    ori     $t0, $t0, 0xFFFF       # rs = 0x7FFFFFFF
    addu    $t6, $t0, $zero        # save copy in t6

    ori     $t7, $zero, 0
    bgtz    $t0, T4_taken
    addiu   $t7, $t7, 1            # delay slot

    addiu   $t7, $t7, 4
    j       T4_after
    nop

T4_taken:
    addiu   $t7, $t7, 2

T4_after:
    # Check marker == 3
    ori     $t2, $zero, 3
    xor     $t3, $t7, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    # Check rs unchanged: t0 == t6
    xor     $t3, $t0, $t6
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