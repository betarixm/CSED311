`include "opcodes.v" 	   

module instruction_memory (read_address, inputReady, data, readM, address_out, instruction, clk);
    input [`WORD_SIZE-1:0] read_address;
    input inputReady;
    inout [`WORD_SIZE-1:0] data;
    output readM;
    output [`WORD_SIZE-1:0] address_out;
    output [`WORD_SIZE-1:0] instruction;

    input clk;

    reg fetch_instruction;
    reg [`WORD_SIZE-1:0] _instruction;

    initial begin
        fetch_instruction <= 1;
    end

    assign readM = fetch_instruction == 1 ? 1 : readM;
    assign data = fetch_instruction == 1 && inputReady == 1 ? `WORD_SIZE'bz : data;
    assign instruction = _instruction;
    assign address_out = read_address;

    always @(posedge clk) begin
        
    end

    always @(*) begin
        if (fetch_instruction == 1) begin
            if (inputReady == 1) begin
                fetch_instruction = 0;
                _instruction = data;
            end
        end
    end

endmodule