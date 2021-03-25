`include "opcodes.v" 	   

module instruction_memory (read_address, readM, instruction, clk);
    input read_address;
    output readM;
    output [`WORD_SIZE-1:0] instruction;

    input clk;

    wire fetch_instruction;


    always @(posedge clk) begin
        readM <= 1;
        fetch_instruction <= 1;    
    end

    always @(*) begin
        if (fetch_instruction == 1 && inputReady == 1) begin
            fetch_instruction = 0;
            instruction = data;
        end
    end

endmodule