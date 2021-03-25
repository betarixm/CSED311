`include "opcodes.v"
`include "adder.v"
`include "mux.v"


module pc_calculator (pc, branch_cond, branch, jump, sign_extended, target_offset, write_pc_reg, next_pc, real_next_pc);
	input [`WORD_SIZE-1:0] pc;
    input branch_cond;
    input branch;
    input jump;
    input [`WORD_SIZE-1:0] sign_extended;
    input [`ADDR_SIZE-1:0] target_offset;
    input [`WORD_SIZE-1:0] write_pc_reg;
	output [`WORD_SIZE-1:0] next_pc;
	output [`WORD_SIZE-1:0] real_next_pc;

    wire [`WORD_SIZE-1:0] before_mux_jump;
    wire [`WORD_SIZE-1:0] jump_target_address;
    wire [`WORD_SIZE-1:0] branch_address;

    reg [`WORD_SIZE-1:0] offset = 1;

    assign jump_target_address = {pc[`WORD_SIZE-1:`ADDR_SIZE],target_offset};

	adder AdderNextPC(.adder_input1(pc),
					.adder_input2(offset),
					.adder_output(next_pc));

    adder AdderBranch(.adder_input1(pc),
                    .adder_input2(sign_extended),
                    .adder_output(branch_address));

    mux MuxBranch(.mux_input_1(next_pc),
                .mux_input_2(branch_address),
                .selector(branch && branch_cond),
                .mux_output(before_mux_jump));

    mux MuxJump(.mux_input_1(jump_target_address),
                .mux_input_2(before_mux_jump),
                .selector(jump),
                .mux_output(real_next_pc));

endmodule
