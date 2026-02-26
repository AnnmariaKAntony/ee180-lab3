###############################################################################
# File         : ll.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'll' (load linked) instruction.
#
# Notes:
#   - Doesn't really focus on testing sc behaviors yet
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

    # Scratch RAM base for test data (pick a safe RAM region)
    lui     $s3, 0x0000
    ori     $s3, $s3, 0x3000       # $s3 = 0x00003000

    ###########################################################################
    # Helper convention (no macros):
    #   diff = actual xor expected
    #   neq  = (diff != 0) using sltu
    #   ok   = 1 - neq
    #   overall_ok &= ok
    ###########################################################################

    ###########################################################################
    # Initialize memory words we will ll from
    #   [s3+0]  = 0x11223344
    #   [s3+4]  = 0xDEADBEEF
    #   [s3+8]  = 0x80000001
    #   [s3+12] = 0x00000000
    ###########################################################################
    lui     $t0, 0x1122
    ori     $t0, $t0, 0x3344
    sw      $t0, 0($s3)

    lui     $t0, 0xDEAD
    ori     $t0, $t0, 0xBEEF
    sw      $t0, 4($s3)

    lui     $t0, 0x8000
    ori     $t0, $t0, 0x0001
    sw      $t0, 8($s3)

    sw      $zero, 12($s3)

    ###########################################################################
    # Test 1: basic ll loads correct value (offset 0)
    ###########################################################################
    ll      $t1, 0($s3)            # actual in t1

    lui     $t2, 0x1122
    ori     $t2, $t2, 0x3344       # expected in t2

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 2: base+offset addressing (offset 4)
    ###########################################################################
    ll      $t1, 4($s3)

    lui     $t2, 0xDEAD
    ori     $t2, $t2, 0xBEEF

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 3: sign-bit set pattern (0x80000001) at offset 8
    ###########################################################################
    ll      $t1, 8($s3)

    lui     $t2, 0x8000
    ori     $t2, $t2, 0x0001

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 4: zero pattern at offset 12
    ###########################################################################
    ll      $t1, 12($s3)
    addu    $t2, $zero, $zero      # expected = 0

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 5: dependency / hazard-style use of ll result immediately
    #   Load 0x11223344 then add 1 -> 0x11223345
    ###########################################################################
    ll      $t1, 0($s3)
    addiu   $t1, $t1, 1            # use immediately after ll

    lui     $t2, 0x1122
    ori     $t2, $t2, 0x3345       # expected = 0x11223345

    xor     $t3, $t1, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 6: consecutive ll's to different addresses
    #   t6 = ll [s3+4] (DEADBEEF)
    #   t7 = ll [s3+0] (11223344)
    ###########################################################################
    ll      $t6, 4($s3)
    ll      $t7, 0($s3)

    lui     $t2, 0xDEAD
    ori     $t2, $t2, 0xBEEF
    xor     $t3, $t6, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    lui     $t2, 0x1122
    ori     $t2, $t2, 0x3344
    xor     $t3, $t7, $t2
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