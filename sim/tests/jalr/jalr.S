###############################################################################
# File         : jalr.S
# Project      : EE180 Lab 3: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Comprehensive test for the 'jalr' instruction.
#
# Notes:
#   - Avoids conditional branches. Uses jalr/jr/j only for control flow.
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
    ori     $s1, $zero, 1          # done value
    ori     $s2, $zero, 1          # overall_ok = 1

    # stack for save/restore tests
    lui     $sp, 0x8003
    ori     $sp, $sp, 0xF000       # $sp = 0x8003F000

    ###########################################################################
    # Helper convention (no macros):
    #   diff = actual xor expected
    #   neq  = (diff != 0) using sltu
    #   ok   = 1 - neq
    #   overall_ok &= ok
    ###########################################################################

    ###########################################################################
    # Test 1: jalr (default link to $ra) + delay slots
    #
    # Marker t7 accumulates:
    #   jalr delay slot (in caller):           +1
    #   funcA body before jr:                  +2
    #   jr delay slot (in funcA):              +4
    #   after return in caller:                +8
    #
    # Expected: 1 + 2 + 4 + 8 = 15
    ###########################################################################
    ori     $t7, $zero, 0

    la      $t0, funcA             # rs = &funcA
    jalr    $t0                     # link -> $ra
    addiu   $t7, $t7, 1            # jalr delay slot MUST execute

after_funcA:
    addiu   $t7, $t7, 8

    ori     $t2, $zero, 15
    xor     $t3, $t7, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 2: jalr rd, rs (explicit link reg) + verify $ra NOT clobbered
    #
    # We set $ra to a known sentinel before jalr. If jalr uses rd correctly,
    # $ra should remain sentinel.
    #
    # Marker t6 accumulates:
    #   jalr delay slot (in caller):           +1
    #   funcB body before jr $t9:              +2
    #   jr delay slot (in funcB):              +4
    #   after return in caller:                +8
    #
    # Expected marker: 15
    # And $ra expected sentinel: 0x12345678
    ###########################################################################
    ori     $t6, $zero, 0

    lui     $ra, 0x1234
    ori     $ra, $ra, 0x5678        # sentinel in $ra

    la      $t0, funcB              # rs = &funcB
    jalr    $t9, $t0                # link -> $t9 (NOT $ra)
    addiu   $t6, $t6, 1             # jalr delay slot

after_funcB:
    addiu   $t6, $t6, 8

    # Check marker == 15
    ori     $t2, $zero, 15
    xor     $t3, $t6, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    # Check $ra unchanged == 0x12345678
    lui     $t1, 0x1234
    ori     $t1, $t1, 0x5678
    xor     $t3, $ra, $t1
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Test 3: Nested jalr through function pointer, with link save/restore
    #
    # Caller uses jalr default ($ra). funcC is non-leaf, calls funcD via jalr.
    # funcC must save/restore $ra around inner call.
    #
    # Marker t8 accumulates:
    #   outer jalr delay slot (caller):        +1
    #   funcC inner jalr delay slot:           +2
    #   funcD body before jr:                  +16
    #   funcD jr delay slot:                   +32
    #   after return from funcD (in funcC):    +4
    #   funcC jr delay slot:                   +8
    #   after return to caller:                +64
    #
    # Expected: 1+2+16+32+4+8+64 = 127
    ###########################################################################
    ori     $t8, $zero, 0

    la      $t0, funcC
    jalr    $t0
    addiu   $t8, $t8, 1             # outer jalr delay slot

after_funcC:
    addiu   $t8, $t8, 64

    ori     $t2, $zero, 127
    xor     $t3, $t8, $t2
    sltu    $t4, $zero, $t3
    ori     $t5, $zero, 1
    subu    $t5, $t5, $t4
    and     $s2, $s2, $t5

    ###########################################################################
    # Report result and finish
    ###########################################################################
    sw      $s2, 4($s0)              # test result (1=pass, 0=fail)
    sw      $s1, 0($s0)              # done

$done:
    j       $done
    nop

###############################################################################
# funcA: leaf, returns via jr $ra
###############################################################################
funcA:
    addiu   $t7, $t7, 2
    jr      $ra
    addiu   $t7, $t7, 4              # jr delay slot

###############################################################################
# funcB: leaf, returns via jr $t9 (explicit link register)
###############################################################################
funcB:
    addiu   $t6, $t6, 2
    jr      $t9
    addiu   $t6, $t6, 4              # jr delay slot

###############################################################################
# funcC: non-leaf, calls funcD via jalr (default link to $ra)
# Must save/restore $ra around the inner jalr
###############################################################################
funcC:
    addiu   $sp, $sp, -16
    sw      $ra, 0($sp)

    la      $t0, funcD
    jalr    $t0
    addiu   $t8, $t8, 2              # inner jalr delay slot

    addiu   $t8, $t8, 4

    lw      $ra, 0($sp)
    addiu   $sp, $sp, 16

    jr      $ra
    addiu   $t8, $t8, 8              # jr delay slot

###############################################################################
# funcD: leaf, returns via jr $ra
###############################################################################
funcD:
    addiu   $t8, $t8, 16
    jr      $ra
    addiu   $t8, $t8, 32             # jr delay slot

    .end    boot