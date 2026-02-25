###############################################################################
# File         : sc.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'sc' (store conditional) instruction.
#   sc rt, imm(rs)
#     if reservation for (rs+imm) is valid:
#        Mem[rs+imm] = rt_old
#        rt = 1
#     else:
#        Mem unchanged
#        rt = 0
#
# Notes:
#   - Uses lw to verify memory contents
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
    lui     $t0, 0x0000
    ori     $t0, $t0, 0x4000    # base = 0x00004000

###############################################################################
# Helper pattern:
#   xor diff = actual ^ expected
#   sltiu eq = (diff < 1)   => 1 if equal else 0
#   overall_ok &= eq
###############################################################################

###############################################################################
# Test 1: ll; sc to same address => should SUCCEED
#   mem[0] starts 0x11111111
#   attempt store 0x22222222
#   expect:
#     rt after sc == 1
#     mem[0] == 0x22222222
###############################################################################
    lui     $t1, 0x1111
    ori     $t1, $t1, 0x1111
    sw      $t1, 0($t0)

    ll      $t3, 0($t0)         # establish reservation

    lui     $t2, 0x2222
    ori     $t2, $t2, 0x2222    # rt_old = 0x22222222
    sc      $t2, 0($t0)         # t2 becomes 1 on success, 0 on failure

    # Check t2 == 1
    ori     $t4, $0, 1
    xor     $t5, $t2, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

    # Check mem == 0x22222222
    lw      $t6, 0($t0)
    lui     $t4, 0x2222
    ori     $t4, $t4, 0x2222
    xor     $t5, $t6, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

###############################################################################
# Test 2: sc without prior ll => should FAIL
#   mem[0] starts 0x33333333
#   attempt store 0x44444444
#   expect:
#     rt after sc == 0
#     mem[0] unchanged == 0x33333333
###############################################################################
    lui     $t1, 0x3333
    ori     $t1, $t1, 0x3333
    sw      $t1, 0($t0)

    lui     $t2, 0x4444
    ori     $t2, $t2, 0x4444
    sc      $t2, 0($t0)         # should set t2 = 0 and not store

    # Check t2 == 0
    addu    $t4, $0, $0
    xor     $t5, $t2, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

    # Check mem still == 0x33333333
    lw      $t6, 0($t0)
    lui     $t4, 0x3333
    ori     $t4, $t4, 0x3333
    xor     $t5, $t6, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

###############################################################################
# Test 3: ll then intervening store to SAME address breaks reservation => sc FAIL
#   mem[0] starts 0x55555555
#   ll; then sw 0x66666666 to same address; then sc attempt 0x77777777
#   expect:
#     rt after sc == 0
#     mem[0] == 0x66666666 (from the sw)
###############################################################################
    lui     $t1, 0x5555
    ori     $t1, $t1, 0x5555
    sw      $t1, 0($t0)

    ll      $t3, 0($t0)         # reservation on mem[0]

    lui     $t7, 0x6666
    ori     $t7, $t7, 0x6666
    sw      $t7, 0($t0)         # break reservation (same address)

    lui     $t2, 0x7777
    ori     $t2, $t2, 0x7777
    sc      $t2, 0($t0)         # should fail: t2=0, no store

    # Check t2 == 0
    addu    $t4, $0, $0
    xor     $t5, $t2, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

    # Check mem == 0x66666666
    lw      $t6, 0($t0)
    lui     $t4, 0x6666
    ori     $t4, $t4, 0x6666
    xor     $t5, $t6, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

###############################################################################
# Test 4: ll to addr0 then ll to addr4 moves reservation => sc to addr0 FAIL
#   addr0 = 0x88888888
#   addr4 = 0x99999999
#   ll addr0; ll addr4; sc attempt to addr0 with 0xAAAAAAAA
#   expect:
#     rt after sc == 0
#     addr0 unchanged == 0x88888888
###############################################################################
    lui     $t1, 0x8888
    ori     $t1, $t1, 0x8888
    sw      $t1, 0($t0)

    lui     $t1, 0x9999
    ori     $t1, $t1, 0x9999
    sw      $t1, 4($t0)

    ll      $t3, 0($t0)         # reservation on addr0
    ll      $t3, 4($t0)         # reservation moves to addr4

    lui     $t2, 0xAAAA
    ori     $t2, $t2, 0xAAAA
    sc      $t2, 0($t0)         # should fail: wrong reservation address

    # Check t2 == 0
    addu    $t4, $0, $0
    xor     $t5, $t2, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

    # Check addr0 still == 0x88888888
    lw      $t6, 0($t0)
    lui     $t4, 0x8888
    ori     $t4, $t4, 0x8888
    xor     $t5, $t6, $t4
    sltiu   $t5, $t5, 1
    and     $s2, $s2, $t5

###############################################################################
# Finish
###############################################################################
    sw      $s2, 4($s0)         # test result
    sw      $s1, 0($s0)         # done

$done:
    j       $done
    nop

    .end    boot