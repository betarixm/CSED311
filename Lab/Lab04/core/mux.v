`include "opcodes.v"

module mux_2_1 (mux_input_0, mux_input_1, selector_1, mux_output);
	input [`WORD_SIZE-1:0] mux_input_0;
	input [`WORD_SIZE-1:0] mux_input_1;
	input selector_1;
	output [`WORD_SIZE-1:0] mux_output;

    assign mux_output = selector_1 == 1 ? mux_input_1 : mux_input_0;

endmodule


module mux_3_1 (mux_input_0, mux_input_1, mux_input_2, selector_1, selector_2, mux_output);
	input [`WORD_SIZE-1:0] mux_input_0;
	input [`WORD_SIZE-1:0] mux_input_1;
	input [`WORD_SIZE-1:0] mux_input_2;
	input selector_1;
	input selector_2;
	output [`WORD_SIZE-1:0] mux_output;

    assign mux_output = selector_2 == 1 ? mux_input_2 : (selector_1 == 1 ? mux_input_1 : mux_input_0);

endmodule


module mux_4_1 (mux_input_0, mux_input_1, mux_input_2, mux_input_3, selector_1, selector_2, selector_3, mux_output);
	input [`WORD_SIZE-1:0] mux_input_0;
	input [`WORD_SIZE-1:0] mux_input_1;
	input [`WORD_SIZE-1:0] mux_input_2;
	input [`WORD_SIZE-1:0] mux_input_3;
	input selector_1;
	input selector_2;
	input selector_3;
	output [`WORD_SIZE-1:0] mux_output;

    assign mux_output = selector_3 == 1 ? mux_input_3 : (selector_2 == 1 ? mux_input_2 : (selector_1 == 1 ? mux_input_1 : mux_input_0));

endmodule