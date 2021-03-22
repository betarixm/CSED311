`include "opcodes.v"

module mux (mux_input_1, mux_input_2, selector, mux_output);
	input [`NumBits-1:0] mux_input_1;
	input [`NumBits-1:0] mux_input_2;
	input selector;
	output reg [`NumBits-1:0] mux_output;

    always @(*) begin
        case (selector)
            1'd0: mux_output = mux_input_1;
            1'd1: mux_output = mux_input_2;
        endcase
    end

endmodule