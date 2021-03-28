`include "opcodes.v"

module mux (mux_input_1, mux_input_2, selector, mux_output);
	input [`WORD_SIZE-1:0] mux_input_1;
	input [`WORD_SIZE-1:0] mux_input_2;
	input selector;
	output [`WORD_SIZE-1:0] mux_output;

    assign mux_output = selector == 0 ? mux_input_1 : mux_input_2;

endmodule