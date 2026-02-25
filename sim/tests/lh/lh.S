###############################################################################
# File         : lh.S
# Project      : EE180 Lab 2: MIPS
#
# Standards/Formatting:
#   MIPS gas, soft tab, 80 column
#
# Description:
#   Test the functionality of the 'lh' instruction.
#
###############################################################################


    .section .boot, "x"
    .balign 4
    .set    noreorder
    .global boot
    .ent    boot
boot:
    lui     $s0, 0x8002         # Load the base address of the status/test registers
    ori     $s1, $0, 1          # Prepare the 'done' status
    lui     $t0, 0              # Load some valid address 0x00003210 to register $t0
    ori     $t0, $t0, 0x3210
    lui     $t1, 0xde0f
    ori     $t1, $t1, 0xbeef    # $t1 = 0xde0fbeef
    sw      $t1, 0($t0)         # 0($t0) = 0xde0fbeef
    lh      $s2, 0($t0)         # $s2 = 0xffffde0f
    lh      $s4, 2($t0)         # $s4 = 0xffffbeef
    lui     $t2, 0xffff			
    ori     $t2, $t2, 0xde0f    # $t2 = 0xffffde0f
    lui     $t4, 0xffff			
    ori     $t4, $t4, 0xbeef	# $t4 = 0xffffbeef
    subu    $v1, $t2, $s2		# v1 = 0
    ori     $v1, $v1, 1         # v1 = 1
    subu    $v0, $t4, $s4		# v0 = 0
    ori     $v0, $v0, 1         # v0 = 1
    and     $v0, $v0, $v1		# v0 = 1
    sw      $v0, 4($s0)         # Set the test result
    sw      $s1, 0($s0)         # Set 'done'

$done:
    j       $done
    nop

    .end boot
