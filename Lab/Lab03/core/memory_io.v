`include "opcodes.v"

module memory_io (
    data,
    sig_fetch,
    sig_read,
    sig_write,
    data_write,
    input_ready,
    address_in,
    address_out,
    read_m,
    write_m,
    data_out
);
    inout [`WORD_SIZE-1:0] data;
    input sig_fetch;
    input sig_read;
    input sig_write;
    input [`WORD_SIZE-1:0] data_write;
    input input_ready;
    input [`WORD_SIZE-1:0] address_in;
    output [`WORD_SIZE-1:0] address_out;
    output read_m;
    output write_m;
    output [`WORD_SIZE-1:0] data_out;
    
endmodule