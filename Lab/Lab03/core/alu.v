`include "opcodes.v"

module alu (alu_input_1, alu_input_2, func_code, alu_output, sub_output);
	input [`WORD_SIZE-1:0] alu_input_1;
	input [`WORD_SIZE-1:0] alu_input_2;
	input [2:0] func_code;
	output reg [`WORD_SIZE-1:0] alu_output;
	output reg [`WORD_SIZE-1:0] sub_output;

	always @(*) begin
		case (func_code)
			`FUNC_ADD: alu_output = alu_input_1 + alu_input_2;
			`FUNC_SUB: alu_output = alu_input_1 - alu_input_2;
			`FUNC_AND: alu_output = alu_input_1 & alu_input_2;
			`FUNC_ORR: alu_output = alu_input_1 | alu_input_2;
			`FUNC_NOT: alu_output = ~alu_input_1;
			`FUNC_TCP: alu_output = ~alu_input_1 + 1;
			`FUNC_SHL: alu_output = $signed(alu_input_1) <<< 1;
			`FUNC_SHR: alu_output = $signed(alu_input_1) >>> 1;
		endcase
		sub_output = alu_input_1 - alu_input_2;
	end

endmodule
