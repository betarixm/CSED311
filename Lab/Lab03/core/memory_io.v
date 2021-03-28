`include "opcodes.v"

module memory_io (
    data,
    sig_fetch,
    sig_read,
    sig_write,
    data_write,
    input_ready,
    address_fetch_in,
    address_data_in,
    address_out,
    read_m,
    write_m,
    data_out,
    clk
);
    inout [`WORD_SIZE-1:0] data;
    input sig_fetch;
    input sig_read;
    input sig_write;
    input [`WORD_SIZE-1:0] data_write;
    input input_ready;
    input [`WORD_SIZE-1:0] address_fetch_in;
    input [`WORD_SIZE-1:0] address_data_in;
    output reg [`WORD_SIZE-1:0] address_out;
    output reg read_m;
    output reg write_m;
    output reg [`WORD_SIZE-1:0] data_out;

    input clk;

    reg is_write;
    
    assign data = (is_write) ? (data_write) : (`WORD_SIZE'bz);

    always @(*) begin
        if(sig_fetch) begin
            is_write <= 0;
            read_m <= 1;
            write_m <= 0;
            address_out = address_fetch_in;
        end

        if(sig_read) begin
            is_write <= 0;
            read_m <= 1;
            write_m <= 0;
            address_out = address_data_in;
        end

        if(sig_write) begin
            is_write <= 1;
            read_m <= 0;
            write_m <= 1;
            address_out = address_data_in;
        end

        if(!is_write) begin 
            data_out <= data;
        end
    end

endmodule