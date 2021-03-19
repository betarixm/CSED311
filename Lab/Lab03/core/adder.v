`include "opcodes.v"

`define	NumBits	16

module adder (adder_input1, adder_input2, adder_output);
    input [NumBits-1:0] adder_input1;
    input [NumBits-1:0] adder_input2;
    output [NumBits-1:0] adder_output;

    assign adder_output = adder_input1 + adder_input2;

endmodule