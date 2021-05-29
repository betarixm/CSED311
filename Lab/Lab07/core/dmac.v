`include "env.v"

module DMA_controller(clk, reset_n, addr, data, br, bg, c__dmac_req, addr_offset, m2_ack, write_q2, intrpt, intrpt_resolved);
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

    output reg [`WORD_SIZE-1:0] addr_offset;
    input m2_ack;

    inout write_q2;

    output reg [1:0] intrpt;
    input intrpt_resolved;

    reg [`WORD_SIZE-1:0] target_addr;
    reg [`WORD_SIZE-1:0] target_length;

    reg r__br;
    reg c__write;

    assign addr = (bg) ? (target_addr + addr_offset) : `WORD_SIZE'bz;
    assign data = `QWORD_SIZE'bz;
    assign br = r__br;
    assign write_q2 = (bg) ? c__write : 1'bz;

    initial begin
        r__br = 0;
        addr_offset = 0;
        c__write = 0;
    end

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
            r__br <= 1;
        end
        
        if (bg && br) begin
            $display("[DMA EXECUTING](DMAC) ADDR: %d", target_addr + addr_offset);
        end
        
        if (bg && addr_offset < target_length) begin
            if(addr_offset == 0) begin
                c__write <= 1;
            end
            
            if (m2_ack) begin
                if (addr_offset == target_length - 4) begin
                    r__br <= 0;
                    c__write <= 0;
                    intrpt <= `INST_DMA_END;
                    addr_offset <= 0;
                end else begin
                    c__write <= 1;
                    addr_offset <= addr_offset + 4;
                end
            end
        end

        if (intrpt_resolved) begin
            intrpt <= 0;
        end
    end

endmodule