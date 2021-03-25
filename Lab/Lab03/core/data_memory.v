`include "opcodes.v"

module data_memory (address, write_data, ackOutput, inputReady, data, read_data, readM, writeM, address_out, mem_write, mem_read, clk);
    input [`WORD_SIZE-1:0] address;
    input [`WORD_SIZE-1:0] write_data;
    input ackOutput;
    input inputReady;
    inout [`WORD_SIZE-1:0] data;
    output readM;
    output writeM;
    output [`WORD_SIZE-1:0] address_out;
    output [`WORD_SIZE-1:0] read_data;
    
    input mem_write;
    input mem_read;

    input clk;

    reg reading_data;
    reg writing_data;
    reg [`WORD_SIZE-1:0] _read_data;

    initial begin
        reading_data <= 0;
        writing_data <= 0;
    end

    assign readM = reading_data == 1 ? 1 : readM;
    assign writeM = writing_data == 1 ? 1 : writeM;
    assign data = (reading_data == 1 && inputReady == 1) ? `WORD_SIZE'bz : (
                    (writing_data == 1 && ackOutput == 1) ? write_data : data
                );
    assign address_out = address;
    assign read_data = _read_data;

    always @(negedge clk) begin
        if (mem_read) begin
            reading_data <= 1;
        end
        if (mem_write) begin
            writing_data <= 1;
        end
    end

    always @(*) begin
        if (reading_data && inputReady == 1) begin
            reading_data = 0;
            _read_data = data;
        end
        if (writing_data == 1 && ackOutput == 1) begin
            writing_data = 0;
        end
    end 

endmodule