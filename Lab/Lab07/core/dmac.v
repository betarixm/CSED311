`include "env.v"

module DMA_controller(clk, reset_n, addr, data, br, bg, c__dmac_req);
    input clk;
    input reset_n;

    // Bus
    inout [`WORD_SIZE-1:0] addr;
    inout [`QWORD_SIZE-1:0] data;
    
    // Bus op.
    output br; // Bus Req
    input bg; // Bus Grn

    // From CPU
    input c__dmac_req;

    reg [`WORD_SIZE-1:0] target_addr;
    reg [`WORD_SIZE-1:0] target_length;

    assign addr = `WORD_SIZE'bz;
    assign data = `QWORD_SIZE'bz;

    always @(*) begin
	    // TODO: implement your combinational logic
    end

    always @(posedge clk) begin
        if (c__dmac_req) begin
            $display("[DMA START](DMAC) REQ: %d", c__dmac_req);
            $display("[DMA START](DMAC) ADR: %d", addr);
            $display("[DMA START](DMAC) LEN: %d", data[`WORD_SIZE-1:0]);
            target_addr <= addr;
            target_length <= data[`WORD_SIZE-1:0];
        end
    end

endmodule