`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "env.v"
`include "util.v"
`include "alu.v"
`include "register_file.v"
`include "control_unit.v"
`include "memory.v"
`include "branch_calculator.v"
`include "branch_predictor.v"
`include "hazard.v"
`include "forwarding_unit.v"


module cpu(clk, reset_n, read_m1, address1, data1, read_m2, write_m2, address2, data2, num_inst, output_port, is_halted);

    input clk;
    input reset_n;

    output read_m1;
    output [`WORD_SIZE-1:0] address1;
    output read_m2;
    output write_m2;
    output [`WORD_SIZE-1:0] address2;

    input [`WORD_SIZE-1:0] data1;
    inout [`WORD_SIZE-1:0] data2;

    output [`WORD_SIZE-1:0] num_inst;
    output [`WORD_SIZE-1:0] output_port;
    output is_halted;

    ///////////////////////////////////////////////////

    //# Wires
    //## Control
    wire c__alu_src;
    wire c__mem_read;
    wire c__mem_write;
    wire c__mem_to_reg;
    wire c__reg_write;
    wire [1:0] c__reg_write_dest;
    wire c__halt;
    wire c__wwd;
    wire c__pc_to_reg;
    wire c__new_inst;
    wire c__hdu_is_stall;
    wire c__bp_select;
    wire c__is_bj;

    // alu
    wire [2-1:0] c__forward_a;
    wire [2-1:0] c__forward_b;

    //## WB/MEM
    wire [`WORD_SIZE-1:0] w__addr__pc;
    wire [`WORD_SIZE-1:0] w__pc__mux;
    wire [`WORD_SIZE-1:0] w__aout__mux;
    wire [`WORD_SIZE-1:0] w__mux__memory;
    wire [`WORD_SIZE-1:0] w__data;

    //## MEM/IF
    wire [`WORD_SIZE-1:0] w__memory__inst;
    wire [`WORD_SIZE-1:0] w__memory__r_memory_register;

    //## IF/ID
    wire [`WORD_SIZE-1:0] w__inst;

    //## ID/EX
    wire [`WORD_SIZE-1:0] w__next_pc;
    wire [`WORD_SIZE-1:0] w__imm_ext;
    wire [`WORD_SIZE-1:0] w__read_data_1;
    wire [`WORD_SIZE-1:0] w__read_data_2;
    wire [`REG_SIZE-1:0] w__write_reg;
    wire [`WORD_SIZE-1:0] w__mux__write_data;
    wire [`WORD_SIZE-1:0] w__alu_a;
    wire [`WORD_SIZE-1:0] w__alu_b;
    wire [`WORD_SIZE-1:0] w__alu_src_a_reg;
    wire [`WORD_SIZE-1:0] w__alu_src_b_reg;
    wire [`WORD_SIZE-1:0] w__mux_alu_src_b;
    wire [3-1:0] w__func_code;
    wire [2-1:0] w__branch_type;
    wire w__bcond;
    wire w__branch_address;

    //## EX/MEM
    wire w__overflow_flag;
    wire [`WORD_SIZE-1:0] w__mux__pc;
    wire [`WORD_SIZE-1:0] w__alu_out;

    //## MEM/WB
    wire [`WORD_SIZE-1:0] w__write_data;

    //# Registers
    reg [`WORD_SIZE-1:0] r__pc;
    reg [`WORD_SIZE-1:0] r__memory_register;
    reg [`WORD_SIZE-1:0] r__read_data_1;
    reg [`WORD_SIZE-1:0] r__read_data_2;
    reg [`WORD_SIZE-1:0] r__num_inst;

    /////////////////////////////////
    //    PIPELINE REGISTERS       //

    // from IF/ID
    reg [`WORD_SIZE-1:0] r__if_id__inst;
    reg [`WORD_SIZE-1:0] r__if_id__pc, r__id_ex__pc;
    reg [`WORD_SIZE-1:0] r__if_id__next_pc, r__id_ex__next_pc, r__ex_mem__next_pc, r__mem_wb__next_pc;
    
    // from ID/EX
    reg [`WORD_SIZE-1:0] r__id_ex__read_data_1, r__ex_mem__read_data_1, r__mem_wb__read_data_1; // for wwd
    reg [`WORD_SIZE-1:0] r__id_ex__read_data_2;
    reg [`WORD_SIZE-1:0] r__id_ex__mux_alu_src_b, r__ex_mem__mux_alu_src_b;
    reg [`WORD_SIZE-1:0] r__id_ex__imm_ext;
    reg [`WORD_SIZE-1:0] r__id_ex__opcode;
    reg [`WORD_SIZE-1:0] r__id_ex__funct;
    reg [3-1:0] r__id_ex__func_code;
    reg [`REG_SIZE-1:0] r__id_ex__rd, r__ex_mem__rd, r__mem_wb__rd;
    reg [`REG_SIZE-1:0] r__id_ex__rt, r__ex_mem__rt, r__mem_wb__rt;
    reg [`REG_SIZE-1:0] r__id_ex__rs;
    reg rc__id_ex__halt, rc__ex_mem__halt, rc__mem_wb__halt;
    reg rc__id_ex__wwd, rc__ex_mem__wwd, rc__mem_wb__wwd;
    reg rc__id_ex__alu_src;
    reg rc__id_ex__mem_read, rc__ex_mem__mem_read;
    reg rc__id_ex__mem_write, rc__ex_mem__mem_write;
    reg rc__id_ex__reg_write, rc__ex_mem__reg_write, rc__mem_wb__reg_write;
    reg rc__id_ex__mem_to_reg, rc__ex_mem__mem_to_reg, rc__mem_wb__mem_to_reg;
    reg rc__id_ex__pc_to_reg, rc__ex_mem__pc_to_reg, rc__mem_wb__pc_to_reg;
    reg [1:0] rc__id_ex__reg_write_dest, rc__ex_mem__reg_write_dest, rc__mem_wb__reg_write_dest;

    // from EX/MEM
    reg [`WORD_SIZE-1:0] r__ex_mem__alu_out, r__mem_wb__alu_out;
    
    // form MEM/WB
    reg [`WORD_SIZE-1:0] r__mem_wb__memory_read_data;
    
    //    PIPELINE REGISTERS END   //
    /////////////////////////////////

    assign is_halted = rc__mem_wb__halt;
    assign output_port = rc__mem_wb__wwd ? r__mem_wb__read_data_1 : `WORD_SIZE'b0;

    assign num_inst = r__num_inst;

    initial begin
        r__pc <= 0;
        r__num_inst <= 0;
    end
    
    always @(*) begin
        if (reset_n) begin
            r__pc <= 0;
            r__num_inst <= 0;
        end
    end


    ////////// IF ///////////

    /// Memory ///
    /// Instruction memory is concatenated to Data memory
    /// See bottom, MEM stage.


    ////////// ID ///////////

    mux4_1_reg mux__write_reg(
        .sel(rc__mem_wb__reg_write_dest),
        .i1(r__mem_wb__rd), 
        .i2(r__mem_wb__rt), 
        .i3(`REG_SIZE'd2),
        .i4(`REG_SIZE'd0),
        .o(w__write_reg)
    );

    mux2_1 mux__reg_data(
        .sel(rc__mem_wb__pc_to_reg),
        .i1(w__write_data),
        .i2(r__mem_wb__next_pc),
        .o(w__mux__write_data)
    );

    register_file Registers(
        .read1(r__if_id__inst[`RS]),
        .read2(r__if_id__inst[`RT]),
        .dest(w__write_reg),
        .write_data(w__mux__write_data),
        .reg_write(rc__mem_wb__reg_write),
        .clk(clk),
        .reset_n(reset_n),
        .read_out1(w__read_data_1),
        .read_out2(w__read_data_2)
    );

    control_unit Control(
        .opcode(r__if_id__inst[`OPCODE]),
        .funct(r__if_id__inst[`FUNC]),
        .clk(clk),
        .reset_n(reset_n),
        .alu_src(c__alu_src),
        .mem_read(c__mem_read),
        .mem_to_reg(c__mem_to_reg),
        .mem_write(c__mem_write),
        .pc_to_reg(c__pc_to_reg),
        .halt(c__halt),
        .wwd(c__wwd),
        .reg_write(c__reg_write),
        .reg_write_dest(c__reg_write_dest),
        .func_code(w__func_code),
        .branch_type(w__branch_type),
        .is_bj(c__is_bj)
    );

    sign_extender Imm_extend(
        .immediate(r__if_id__inst[`IMMD_SIZE-1:0]),
        .sign_extended(w__imm_ext)
    );

    hazard_detect Hazard_Detect(
        .IFID_IR(r__if_id__inst),
        .IDEX_rd(r__id_ex__rd),
        .IDEX_M_mem_read(rc__id_ex__mem_read),
        .is_stall(c__hdu_is_stall)
    );

    branch_calculator Branch_Calculator(
        .A(w__read_data_1),
        .B(w__read_data_2),
        .PC(r__if_id__pc),
        .imm(w__imm_ext),
        .branch_type(w__branch_type),
        .next_pc(w__branch_address),
        .bcond(w__bcond)
    );

    branch_predictor Branch_Predictor(
        .clk(clk),
        .reset_n(reset_n),
        .is_flush(c__hdu_is_stall),
        .is_BJ_type(c__is_bj),
        .caculated_pc(w__branch_address),
        .current_PC(r__if_id__pc),
        .next_PC(w__next_pc)
    );


    // ID/EX flush mux is implemented in sequential logic


    ////////////// EX ////////////////

    forwarding_unit Forwarding_Unit(
        .EXMEM_RegWrite(rc__ex_mem__reg_write),
        .EXMEM_RegWriteDest(rc__ex_mem__regwrite_dest),
        .EXMEM_RD(r__ex_mem__rd),
        .EXMEM_RT(r__ex_mem__rt),
        .MEMWB_RegWrite(rc__mem_wb__reg_write),
        .MEMWB_RegWriteDest(rc__mem_wb__reg_write_dest),
        .MEMWB_RD(r__mem_wb__rd),
        .MEMWB_RT(r__mem_wb__rt),
        .IDEX_RS(r__id_ex__rs),
        .IDEX_RT(r__id_ex__rt),
        .forward_a(c__forward_a),
        .forward_b(c__forward_b)
    );


    mux4_1 mux__alu_forward_a(
        .sel(c__forward_a),
        .i1(w__alu_a),           // no forwarding
        .i2(w__write_data),      // forwarding from WB
        .i3(r__ex_mem__alu_out), // forwarding from MEM
        .i4(`WORD_SIZE'b0),
        .o(w__alu_src_a_reg)
    );

    mux4_1 mux__alu_forward_b(
        .sel(c__forward_b),
        .i1(w__read_data_2),     // no forwarding
        .i2(w__write_data),      // forwarding from WB
        .i3(r__ex_mem__alu_out), // forwarding from MEM
        .i4(`WORD_SIZE'b0),
        .o(w__alu_src_b_reg)
    );

    mux2_1 mux__alu_b(
        .sel(rc__id_ex__alu_src),
        .i1(w__alu_src_b_reg),
        .i2(w__imm_ext),
        .o(w__mux_alu_src_b)
    );

    alu ALU(
        .A(w__alu_src_a_reg), 
        .B(w__mux_alu_src_b), 
        .func_code(r__id_ex__func_code),
        .alu_out(w__alu_out),
        .overflow_flag(w__overflow_flag)
    );


    ////////////// MEM ////////////////

    Memory memory(
        .clk(clk),
        .reset_n(reset_n),
        .read_m1(~is_flush),
        .address1(r__pc),
        .data1(w__inst),
        .read_m2(rc__ex_mem__mem_read),
        .write_m2(rc__ex_mem__mem_write),
        .address2(r__ex_mem__alu_out),
        .data2(w__data)
    );

    assign w__data = (rc__ex_mem__mem_write) ? r__read_data_2 : `WORD_SIZE'bz;


    /////////////// WB ////////////////
    mux2_1 mux__alu_out__reg_memory(
        .sel(rc__mem_wb__mem_to_reg),
        .i1(r__mem_wb__alu_out),
        .i2(r__mem_wb__memory_read_data),
        .o(w__write_data)
    );	



    always @(posedge clk) begin
        // update Pipeline Registers
        // - MEM/WB
        r__mem_wb__memory_read_data <= w__data;
        r__mem_wb__alu_out <= r__ex_mem__alu_out;
        r__mem_wb__rd <= r__ex_mem__rd;
        r__mem_wb__rt <= r__ex_mem__rt;
        r__mem_wb__read_data_1 <= r__ex_mem__read_data_1;
        r__mem_wb__next_pc <= r__ex_mem__next_pc;
        rc__mem_wb__reg_write <= rc__ex_mem__reg_write;
        rc__mem_wb__reg_write_dest <= rc__ex_mem__reg_write_dest;
        // - EX/MEM
        r__ex_mem__alu_out <= w__alu_out;
        r__ex_mem__rd <= r__id_ex__rd;
        r__ex_mem__rt <= r__id_ex__rt;
        r__ex_mem__read_data_1 <= r__id_ex__read_data_1;
        r__ex_mem__mux_alu_src_b <= r__id_ex__mux_alu_src_b;
        r__ex_mem__next_pc <= r__id_ex__next_pc;
        rc__ex_mem__mem_read <= rc__id_ex__mem_read;
        rc__ex_mem__mem_write <= rc__id_ex__mem_write;
        rc__ex_mem__mem_to_reg <= rc__id_ex__mem_to_reg;
        rc__ex_mem__pc_to_reg <= rc__id_ex__pc_to_reg;
        rc__ex_mem__reg_write <= rc__id_ex__reg_write;
        rc__ex_mem__reg_write_dest <= rc__id_ex__reg_write_dest;
        // - ID/EX
        r__id_ex__read_data_1 <= w__read_data_1;
        r__id_ex__read_data_2 <= w__read_data_2;
        r__id_ex__mux_alu_src_b <= w__mux_alu_src_b;
        r__id_ex__imm_ext <= w__imm_ext;
        r__id_ex__func_code <= w__func_code;
        r__id_ex__rd <= r__if_id__inst[`RD];
        r__id_ex__rt <= r__if_id__inst[`RT];
        r__id_ex__rs <= r__if_id__inst[`RS];
        r__id_ex__pc <= r__if_id__pc;
        r__id_ex__next_pc <= r__if_id__next_pc;
        rc__id_ex__alu_src <= c__alu_src;
        rc__id_ex__mem_read <= c__mem_read;
        if (c__hdu_is_stall)
            rc__id_ex__mem_write <= 1'b0;
        else
            rc__id_ex__mem_write <= c__mem_write;
        rc__id_ex__mem_to_reg <= c__mem_to_reg; 
        rc__id_ex__pc_to_reg <= c__pc_to_reg;
        if (c__hdu_is_stall)
            rc__id_ex__reg_write <= 1'b0;
        else
            rc__id_ex__reg_write <= c__reg_write;
        rc__id_ex__reg_write_dest <= c__reg_write_dest;
        // - IF/ID
        if (!c__hdu_is_stall) begin
            r__if_id__inst <= w__inst;
            r__if_id__pc <= r__pc;
            r__if_id__next_pc <= w__next_pc;
        end

        // Update PC
        if(!c__hdu_is_stall) begin
            r__pc <= w__next_pc;
        end
    end


endmodule


