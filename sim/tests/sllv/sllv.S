###############################################################################
# File         : sllv.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'sllv' instruction.
#
# Notes:
#
###############################################################################

    .section .boot, "x"
    .balign 4
    .set    noreorder
    .global boot
    .ent    boot

boot:
    lui     $s0, 0x8002         # status/test reg base
    ori     $s1, $0, 1          # done
    ori     $s2, $0, 1          # overall_ok = 1

###############################################################################
# Helper pattern:
#   xor diff = actual ^ expected
#   sltiu eq = (diff < 1)   => 1 if equal else 0
#   overall_ok &= eq
###############################################################################

###############################################################################
# Test 1: shift by 0
#   rt = 0x12345678, rs = 0  => rd = 0x12345678
###############################################################################
    lui     $t0, 0x1234
    ori     $t0, $t0, 0x5678       # rt
    addu    $t1, $0, $0            # rs = 0

    sllv    $t2, $t0, $t1          # actual

    lui     $t3, 0x1234
    ori     $t3, $t3, 0x5678       # expected
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 2: shift by 1
#   rt = 1, rs = 1 => rd = 2
###############################################################################
    ori     $t0, $0, 1
    ori     $t1, $0, 1
    sllv    $t2, $t0, $t1

    ori     $t3, $0, 2
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 3: shift by 31
#   rt = 1, rs = 31 => rd = 0x80000000
###############################################################################
    ori     $t0, $0, 1
    ori     $t1, $0, 31
    sllv    $t2, $t0, $t1

    lui     $t3, 0x8000
    ori     $t3, $t3, 0x0000
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 4: mask shift amount (rs[4:0])
#   rs = 32 => 0, so rt<<0
###############################################################################
    lui     $t0, 0x00FF
    ori     $t0, $t0, 0x00FF       # rt = 0x00FF00FF
    ori     $t1, $0, 32            # rs = 32 => masked to 0
    sllv    $t2, $t0, $t1

    lui     $t3, 0x00FF
    ori     $t3, $t3, 0x00FF       # expected unchanged
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 5: mask shift amount (rs=33 => 1)
#   rt = 0x1, rs = 33 => 0x2
###############################################################################
    ori     $t0, $0, 1
    ori     $t1, $0, 33            # masked to 1
    sllv    $t2, $t0, $t1

    ori     $t3, $0, 2
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 6: shifting a value with top bit set
#   rt = 0x80000001, rs = 1 => 0x00000002 (top bit shifts out)
###############################################################################
    lui     $t0, 0x8000
    ori     $t0, $t0, 0x0001
    ori     $t1, $0, 1
    sllv    $t2, $t0, $t1

    ori     $t3, $0, 2
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 7: hazard - shift amount produced immediately before sllv
#   rs computed as (40 - 8) = 32 => masked to 0
###############################################################################
    lui     $t0, 0x1357
    ori     $t0, $t0, 0x9BDF       # rt
    ori     $t1, $0, 40
    addiu   $t1, $t1, -8           # rs=32 => masked to 0 (dependency)
    sllv    $t2, $t0, $t1

    lui     $t3, 0x1357
    ori     $t3, $t3, 0x9BDF       # expected unchanged
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 8: hazard - rt produced immediately before sllv
#   rt computed then shifted
#   rt = 0x00000003, rs = 4 => 0x00000030
###############################################################################
    ori     $t0, $0, 1
    addiu   $t0, $t0, 2            # rt = 3 (dependency)
    ori     $t1, $0, 4
    sllv    $t2, $t0, $t1

    ori     $t3, $0, 0x0030
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Test 9: write to $zero ignored
###############################################################################
    ori     $t0, $0, 1
    ori     $t1, $0, 8
    sllv    $zero, $t0, $t1        # would be 0x100, but $zero stays 0
    addu    $t2, $zero, $zero
    addu    $t3, $zero, $zero
    xor     $t4, $t2, $t3
    sltiu   $t4, $t4, 1
    and     $s2, $s2, $t4

###############################################################################
# Finish
###############################################################################
    sw      $s2, 4($s0)         # test result
    sw      $s1, 0($s0)         # done

$done:
    j       $done
    nop

    .end    boot