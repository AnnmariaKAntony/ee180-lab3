###############################################################################
# File         : sw.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'sw' (store word) instruction.
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

    # Choose a writable RAM address (lb.S uses 0x00003210 successfully)
    # We'll use a nearby aligned region.
    lui     $s3, 0x0000
    ori     $s3, $s3, 0x4200    # base = 0x00004200

###############################################################################
# Helper pattern:
#   xor diff = actual ^ expected
#   sltiu eq = (diff < 1)   => 1 if equal else 0
#   overall_ok &= eq
###############################################################################

###############################################################################
# Test 1: basic sw at offset 0
###############################################################################
    lui     $t0, 0x1122
    ori     $t0, $t0, 0x3344       # rt = 0x11223344
    sw      $t0, 0($s3)

    lw      $t1, 0($s3)            # actual
    lui     $t2, 0x1122
    ori     $t2, $t2, 0x3344       # expected

    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 2: sw with base+offset addressing (offset 4)
###############################################################################
    lui     $t0, 0xDE0F
    ori     $t0, $t0, 0xBEEF       # rt = 0xDE0FBEEF
    sw      $t0, 4($s3)

    lw      $t1, 4($s3)
    lui     $t2, 0xDE0F
    ori     $t2, $t2, 0xBEEF

    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 3: overwrite existing value at offset 4
###############################################################################
    lui     $t0, 0xA5A5
    ori     $t0, $t0, 0x5A5A       # new rt
    sw      $t0, 4($s3)

    lw      $t1, 4($s3)
    lui     $t2, 0xA5A5
    ori     $t2, $t2, 0x5A5A

    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 4: store pattern with sign bit set (0x80000001) at offset 8
###############################################################################
    lui     $t0, 0x8000
    ori     $t0, $t0, 0x0001
    sw      $t0, 8($s3)

    lw      $t1, 8($s3)
    lui     $t2, 0x8000
    ori     $t2, $t2, 0x0001

    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 5: hazard - rt produced immediately before sw
#   rt = (0x1000 + 0x234) = 0x1234
###############################################################################
    ori     $t0, $0, 0x1000
    addiu   $t0, $t0, 0x0234       # rt = 0x1234 (dependency)
    sw      $t0, 12($s3)

    lw      $t1, 12($s3)
    ori     $t2, $0, 0x1234

    xor     $t3, $t1, $t2
    sltiu   $t3, $t3, 1
    and     $s2, $s2, $t3

###############################################################################
# Test 6: hazard - base register produced immediately before sw
#   base = s3 + 16, store 0xCAFEBABE there
###############################################################################
    addu    $t7, $s3, $zero        # t7 = base copy
    addiu   $t7, $t7, 16           # t7 = s3+16 (dependency)

    lui     $t0, 0xCAFE
    ori     $t0, $t0, 0xBABE
    sw      $t0, 0($t7)

    lw      $t1, 16($s3)           # read back from original base + 16
    lui     $t2, 0xCAFE
    ori     $t2, $t2, 0xBABE

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