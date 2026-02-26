//=============================================================================
// EE180 Lab 3
//
// Instruction fetch module. Maintains PC and updates it. Reads from the
// instruction ROM.
//=============================================================================

// for jal need to respect the delay slot (instruction after jal needs to execute, THEN got to next instruction?)

module instruction_fetch (
    input clk,
    input rst,
    input en,
    input jump_branch,
    input jump_target,
    input jump_reg,
    input [31:0] jr_pc,
    input [31:0] pc_id,
    input [25:0] instr_id,  // Lower 26 bits of the instruction

    output [31:0] pc
);

    wire [31:0] pc_id_p4 = pc_id + 32'd4;
    wire [31:0] j_addr = {pc_id_p4[31:28], instr_id[25:0], 2'b00};

    // branch target = PC + 4 + sign extended offset (16 bits) << 2
    wire [31:0] branch_target = pc_id_p4 + {{14{instr_id[15]}}, instr_id[15:0], 2'b0}; 

    // for any jump, need to save to respect delay
    wire jump_delay = jump_reg | jump_branch | jump_target;
    wire [31:0] jump_addr = jump_reg ? jr_pc :
                            jump_branch ? branch_target :
                            j_addr;
    
    wire need_to_jump;
    wire [31:0] jump_delay_target;

    dffare #(1) need_to_jump_reg (.clk(clk), .r(rst), .en(en), .d(jump_delay), .q(need_to_jump));

    // new register that saves the jump so we can do delay then come back and do the jump
    wire store_jump = en & jump_delay;
    dffare #(32) delayed_jump_target (.clk(clk), .r(rst), .en(store_jump), .d(jump_addr), .q(jump_delay_target));

    // if doing have a jump that needs to execute (after delay), do jump, else do pc + 4 (delay)
    wire [31:0] pc_next = need_to_jump ? jump_delay_target : (pc + 32'd4);

    dffare #(32) pc_reg (.clk(clk), .r(rst), .en(en), .d(pc_next), .q(pc));


    //wire store_delay = en & jump_delay;
    
    //dffare #(32) delayed_jump_target (.clk(clk), .r(rst), .en(store_delay), .d(delay_target), .q(jump_delay_target));

endmodule
