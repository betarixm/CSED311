`include "opcodes.v"

module data_memory (read_data, write_data, mem_read, mem_write, input_ready, ack_output, address_in, address_out, sig_read, sig_write, read_data_out, write_data_out, clk, reset_n);
    input [`WORD_SIZE-1:0] read_data;
    input [`WORD_SIZE-1:0] write_data;
    input mem_read;
    input mem_write;
    input input_ready;
    input ack_output;
    input [`WORD_SIZE-1:0] address_in;
    output [`WORD_SIZE-1:0] address_out;
    output reg sig_read;
    output reg sig_write;
    output reg [`WORD_SIZE-1:0] read_data_out;
    output reg [`WORD_SIZE-1:0] write_data_out;

    input clk;
    input reset_n;

    assign address_out = address_in;
    assign read_data_out = read_data;
    assign write_data_out = write_data;

    initial begin
        sig_read <= 0;
        sig_write <= 0;
    end
    
    always @(reset_n) begin
        sig_read <= 0;
        sig_write <= 0;
    end


	always @(*) begin
		if (input_ready) begin
			sig_read = 0;
		end
        
		if (ack_output) begin
			sig_write = 0;
		end
    end

    always @(posedge clk) begin
        if (mem_read) begin
            sig_read <= 1;
        end
    end

    always @(negedge clk) begin
        if (mem_write) begin
            sig_write <= 1;
        end
    end

endmodule