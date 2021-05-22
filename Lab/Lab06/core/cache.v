`include "env.v" 
`include "opcodes.v" 

module cache(c__read_m, c__write_m, addr, i__data, o__data, c__valid, m__read_m, m__write_m, m__addr, m__data_out, m__is_stall);
    wire c__read_m, c__write_m;
    wire [`WORD_SIZE-1:0] addr;
    wire [`WORD_SIZE-1:0] i__data;
    wire [`WORD_SIZE-1:0] o__data'
    wire c__valid;
    wire m__read_m, m__write_m;
    wire [`WORD_SIZE-1:0] m__addr;
    wire [`WORD_SIZE-1:0] m__data_out;
    wire [`WORD_SIZE-1:0] m__is_stall;

    
endmodule