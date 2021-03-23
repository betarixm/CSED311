`include "opcodes.v"

module adder (adder_input1, adder_input2, adder_output);
    input [`WORD_SIZE-1:0] adder_input1;
    input [`WORD_SIZE-1:0] adder_input2;
    output [`WORD_SIZE-1:0] adder_output;

    assign adder_output = adder_input1 + adder_input2;

endmodule