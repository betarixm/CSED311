`include "opcodes.v" 	   

module instruction_memory (data, address_in, address_out, sig_fetch, instruction, clk);
    input [`WORD_SIZE-1:0] data;
    input [`WORD_SIZE-1:0] address_in;
    output [`WORD_SIZE-1:0] address_out;
    output reg sig_fetch;
    output reg [`WORD_SIZE-1:0] instruction;

    input clk;

    assign address_out = address_in;
    assign instruction = (data != 'bz) ? data : instruction;

    initial begin
        sig_fetch <= 0;
    end

    always @(posedge clk) begin
        sig_fetch <= 1;
    end

    always @(negedge clk) begin
        sig_fetch <= 0;
    end

endmodule