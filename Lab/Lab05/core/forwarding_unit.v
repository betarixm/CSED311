`include "opcodes.v"

// for reg_write_dest
`define RD_W      2'b00
`define RT_W      2'b01
`define TWO_W     2'b10

// for forwarding
`define None      2'b00
`define WB        2'b01
`define MEM       2'b10


module forwarding_unit (EXMEM_RegWrite, EXMEM_RegWriteDest, EXMEM_RD, EXMEM_RT, MEMWB_RegWrite, MEMWB_RegWriteDest, MEMWB_RD, MEMWB_RT, IDEX_RS, IDEX_RT, forward_a, forward_b)
    input EXMEM_RegWrite, EXMEM_RegWriteDest;
    input [`REG_SIZE-1:0] EXMEM_RD, EXMEM_RT;
    input MEMWB_RegWrite, MEMWB_RegWriteDest;
    input [`REG_SIZE-1:0] MEMWB_RD, EXMEM_RT;
    input [`REG_SIZE-1:0] IDEX_RS, IDEX_RT;

    output [2-1] forward_a, forward_b;


    always @(*) begin
        if (EXMEM_RegWrite) begin
            if (EXMEM_RegWriteDest == `RD_W) begin
                if (IDEX_RS == MEMWB_RD) forward_a = `MEM;
                else forward_a = `None;
                if (IDEX_RT == MEMWB_RD) forward_b = `MEM;
                else forward_b = `None;
            end
            else if (EXMEM_RegWriteDest == `RT_W) begin
                if (IDEX_RS == MEMWB_RT) forward_a = `MEM;
                else forward_a = `None;
                if (IDEX_RT == MEMWB_RT) forward_b = `MEM;
                else forward_b = `None;
            end
            else if (EXMEM_RegWriteDest == `TWO_W) begin
                if (IDEX_RS == `TWO_W) forward_a = `MEM;
                else forward_a = `None;
                if (IDEX_RT == `TWO_W) forward_b = `MEM;
                else forward_b = `None;
            end
        end

        if (MEMWB_RegWrite) begin
            if (MEMWB_RegWriteDest == `RD_W) begin
                if (IDEX_RS == MEMWB_RD) forward_a = `WB;
                else forward_a = `None;
                if (IDEX_RT == MEMWB_RD) forward_b = `WB;
                else forward_b = `None;
            end
            else if (MEMWB_RegWriteDest == `RT_W) begin
                if (IDEX_RS == MEMWB_RT) forward_a = `WB;
                else forward_a = `None;
                if (IDEX_RT == MEMWB_RT) forward_b = `WB;
                else forward_b = `None;
            end
            else if (MEMWB_RegWriteDest == `TWO_W) begin
                if (IDEX_RS == `TWO_W) forward_a = `WB;
                else forward_a = `None;
                if (IDEX_RT == `TWO_W) forward_b = `WB;
                else forward_b = `None;
            end
        end
    end

endmodule