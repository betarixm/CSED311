`include "opcodes.v"
`include "mux.v"

`define OFFSET `WORD_SIZE'b1

module pc_calculator(pc, bcond, branch, jump, sign_extend, target_offset, write_pc_reg, next_pc, real_next_pc);
    input [`WORD_SIZE-1:0] pc;
    input branch_cond, branch, jump;
    input [`WORD_SIZE-1:0] sign_extended;
    input [`ADDR_SIZE-1:0] target_offset;
    input [`WORD_SIZE-1:0] write_pc_reg;
    output [`WORD_SIZE-1:0] next_pc, real_next_pc;

    wire [`WORD_SIZE-1:0] jump_target_address;
    wire [`WORD_SIZE-1:0] branch_address;


    assign jump_target_address = {pc[`WORD_SIZE-1:`ADDR_SIZE],target_offset};

    
    adder AdderNextPC(.adder_input_0(pc),
                        .adder_input_1(`OFFSET),
                        .adder_output(next_pc));

    adder AdderBranch(.adder_input0(pc),
                        .adder_input1(sign_extended),
                        .adder_output(branch_address));


    mux_3_1 MuxPC(.mux_input_0(next_pc),
                    .mux_input_1(branch_address+`WORD_SIZE'b1),
                    .selector_1(branch && bcond),
                    .mux_input_2(jump_target_address),
                    .selector_2(jump),
                    .mux_output(real_next_pc));


endmodule