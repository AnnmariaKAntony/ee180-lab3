###############################################################################
# File         : xori.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'xori' instruction.
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
# Test 1: basic xori
#   0x12345678 ^ 0x00FF = 0x12345687
###############################################################################
    lui     $t0, 0x1234
    ori     $t0, $t0, 0x5678       # rs
    xori    $t1, $t0, 0x00FF       # actual

    lui     $t2, 0x1234
    ori     $t2, $t2, 0x5687       # expected
    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 2: imm = 0 => identity
###############################################################################
    lui     $t0, 0xDEAD
    ori     $t0, $t0, 0xBEEF
    xori    $t1, $t0, 0x0000

    lui     $t2, 0xDEAD
    ori     $t2, $t2, 0xBEEF
    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 3: imm = 0xFFFF must be ZERO-extended (0x0000FFFF)
#   rs = 0x12340000
#   result = 0x1234FFFF
###############################################################################
    lui     $t0, 0x1234
    ori     $t0, $t0, 0x0000
    xori    $t1, $t0, 0xFFFF

    lui     $t2, 0x1234
    ori     $t2, $t2, 0xFFFF
    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 4: rs = 0 => result equals imm (zero-extended)
#   0 ^ 0x8001 = 0x00008001
###############################################################################
    addu    $t0, $0, $0
    xori    $t1, $t0, 0x8001

    lui     $t2, 0x0000
    ori     $t2, $t2, 0x8001
    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 5: rs with high bits set to confirm zero-extension
#   rs = 0xFFFF0000
#   imm = 0xFFFF (=> 0x0000FFFF)
#   result = 0xFFFFFFFF
###############################################################################
    lui     $t0, 0xFFFF
    ori     $t0, $t0, 0x0000
    xori    $t1, $t0, 0xFFFF

    lui     $t2, 0xFFFF
    ori     $t2, $t2, 0xFFFF
    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 6: hazard - rs produced immediately before xori
#   rs = 0x00001234 then xori imm=0x00F0 => 0x000012C4
###############################################################################
    ori     $t0, $0, 0x1200
    addiu   $t0, $t0, 0x0034       # rs = 0x1234 (dependency)
    xori    $t1, $t0, 0x00F0

    ori     $t2, $0, 0x12C4
    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 7: write to $zero ignored
###############################################################################
    lui     $t0, 0x0000
    ori     $t0, $t0, 0x00FF
    xori    $zero, $t0, 0x00FF     # would produce 0, but $zero stays 0
    addu    $t1, $zero, $zero
    addu    $t2, $zero, $zero
    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Finish
###############################################################################
    sw      $s2, 4($s0)         # test result
    sw      $s1, 0($s0)         # done

$done:
    j       $done
    nop

    .end    boot