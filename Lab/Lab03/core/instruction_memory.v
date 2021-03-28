`include "opcodes.v" 	   

module instruction_memory (data, input_ready, mem_read, mem_write, address_in, address_out, sig_fetch, instruction, clk, reset_n);
    inout [`WORD_SIZE-1:0] data;
    input input_ready;
    input mem_read;
    input mem_write;
    input [`WORD_SIZE-1:0] address_in;
    output [`WORD_SIZE-1:0] address_out;
    output reg sig_fetch;
    output reg [`WORD_SIZE-1:0] instruction;

    input clk;  
    input reset_n;

    assign address_out = address_in;
    assign instruction = data;

    initial begin
        sig_fetch <= 1;
    end

    always @(reset_n) begin
        sig_fetch <= 1;
    end

	always @(*) begin
		if (input_ready) begin
			sig_fetch = 0;
		end
    end

    always @(posedge clk) begin
        if (!mem_read && !mem_write) begin
            sig_fetch <= 1;
        end
    end

endmodule