`include "opcodes.v" 	   

module instruction_memory (data, input_ready, address_in, address_out, sig_fetch, instruction, clk, reset_n);
    inout [`WORD_SIZE-1:0] data;
    input input_ready;
    input [`WORD_SIZE-1:0] address_in;
    output [`WORD_SIZE-1:0] address_out;
    output reg sig_fetch;
    output reg [`WORD_SIZE-1:0] instruction;

    input clk;  
    input reset_n;

    assign address_out = address_in;

    initial begin
        sig_fetch <= 1;
    end

    always @(reset_n) begin
        sig_fetch <= 1;
    end

    integer wait_bit;

	always @(*) begin
		if (sig_fetch && input_ready) begin
            wait_bit = 1;
            sig_fetch = 0;
		end

        if (wait_bit && !input_ready) begin
            wait_bit = 0;
            instruction = data;
        end
    end

    always @(posedge clk) begin
        sig_fetch <= 1;
    end

endmodule