`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size
`define QWORD_SIZE 64

`include "env.v"
`include "util.v"
`include "alu.v"
`include "register_file.v"
`include "control_unit.v"
`include "branch_calculator.v"
`include "branch_predictor.v"
`include "hazard.v"
`include "forwarding_unit.v"
`include "cache.v"
`include "memory_io.v"


module cpu(clk, reset_n, read_m1, address1, qdata1, read_m2, write_m2, write_q2, address2, qdata2, num_inst, output_port, is_halted, m1_ready, m1_ack, m2_ready, m2_ack, m2_br, m2_bg, dmac_intrpt_inst, ext_intrpt_inst, dmac_req, dmac_intrpt_resolved, ext_intrpt_resolved);

    input clk;
    input reset_n;

    output read_m1;
    inout [`WORD_SIZE-1:0] address1;
    output read_m2;
    output write_m2;
    inout write_q2;
    inout [`WORD_SIZE-1:0] address2;

    inout [`QWORD_SIZE-1:0] qdata1;
    inout [`QWORD_SIZE-1:0] qdata2;

    output [`WORD_SIZE-1:0] num_inst;
    output [`WORD_SIZE-1:0] output_port;
    output is_halted;

    input m1_ready, m1_ack;
    input m2_ready, m2_ack;
    input m2_br;
    output reg m2_bg;

    input [1:0] dmac_intrpt_inst;
    input [1:0] ext_intrpt_inst;

    output dmac_req;

    output reg dmac_intrpt_resolved;
    output reg ext_intrpt_resolved;

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
    wire c__hdu_is_stall;
    wire c__is_branch;
    wire c__is_jump;
    wire [2-1:0] c__forward_bc_a;
    wire [2-1:0] c__forward_bc_b;

    //## Cache
    wire w__i_cache__read_m;
    wire [`WORD_SIZE-1:0] w__i_cache__addr;
    wire [`QWORD_SIZE-1:0] w__i_cache__data;

    wire w__d_cache__read_m, w__d_cache__write_m;
    wire [`WORD_SIZE-1:0] w__d_cache__addr;
    wire [`QWORD_SIZE-1:0] w__d_cache__data;

    // alu
    wire [2-1:0] c__forward_a;
    wire [2-1:0] c__forward_b;

    wire [`WORD_SIZE-1:0] w__wwd_src;
    //## WB/MEM
    wire [`WORD_SIZE-1:0] w__data;

    //## MEM/IF

    //## IF/ID
    wire w__ready_inst, w__ack_inst;
    wire w__i_cache_ready;
    wire [`WORD_SIZE-1:0] w__inst;
    wire [`WORD_SIZE-1:0] w__bc_forward_a, w__bc_forward_b;

    //## ID/EX
    wire [`WORD_SIZE-1:0] w__pred_pc;
    wire [`WORD_SIZE-1:0] w__imm_ext;
    wire [`WORD_SIZE-1:0] w__read_data_1;
    wire [`WORD_SIZE-1:0] w__read_data_2;
    wire [`REG_SIZE-1:0] w__write_reg;
    wire [`WORD_SIZE-1:0] w__mux__write_data;
    wire [`WORD_SIZE-1:0] w__alu_src_a_reg;
    wire [`WORD_SIZE-1:0] w__alu_src_b_reg;
    wire [3-1:0] w__func_code;
    wire [2-1:0] w__branch_type;
    wire [2-1:0] w__jump_type;
    wire w__bcond;
    wire [`WORD_SIZE-1:0] w__branch_address;
    wire [`WORD_SIZE-1:0] w__jump_address;

    //## EX/MEM
    wire w__overflow_flag;
    wire [`WORD_SIZE-1:0] w__mux__pc;
    wire [`WORD_SIZE-1:0] w__mux_alu_src_b;
    wire [`WORD_SIZE-1:0] w__alu_out;

    //## MEM/WB
    wire w__ready_data, w__ack_data;
    wire w__d_cache_ready;
    wire [`WORD_SIZE-1:0] w__write_data;

    //# Registers
    reg first;
    reg r__fetch;
    reg r__is_flush;
    reg [`WORD_SIZE-1:0] r__pc;
    reg [`WORD_SIZE-1:0] r__memory_register;
    reg [`WORD_SIZE-1:0] r__read_data_1;
    reg [`WORD_SIZE-1:0] r__read_data_2;
    reg r__new_inst;
    reg [`WORD_SIZE-1:0] r__num_inst;

    /////////////////////////////////
    //    PIPELINE REGISTERS       //

    // from IF/ID
    reg [`WORD_SIZE-1:0] r__if_id__inst;
    reg [`WORD_SIZE-1:0] r__if_id__pc, r__id_ex__pc;
    reg [`WORD_SIZE-1:0] r__if_id__pred_pc, r__id_ex__next_pc, r__ex_mem__next_pc, r__mem_wb__next_pc;
    reg rc__if_id__valid, rc__id_ex__valid, rc__ex_mem__valid, rc__mem_wb__valid;
    
    // from ID/EX
    reg [`WORD_SIZE-1:0] r__ex_mem__wwd_value, r__mem_wb__wwd_value;
    reg [`WORD_SIZE-1:0] r__id_ex__read_data_1, r__ex_mem__read_data_1, r__mem_wb__read_data_1; // for wwd
    reg [`WORD_SIZE-1:0] r__id_ex__read_data_2, r__ex_mem__read_data_2; // for store
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
    reg rc__id_ex__mem_read, rc__ex_mem__mem_read, rc__mem_wb__mem_read;
    reg rc__id_ex__mem_write, rc__ex_mem__mem_write;
    reg rc__id_ex__reg_write, rc__ex_mem__reg_write, rc__mem_wb__reg_write;
    reg rc__id_ex__mem_to_reg, rc__ex_mem__mem_to_reg, rc__mem_wb__mem_to_reg;
    reg rc__id_ex__pc_to_reg, rc__ex_mem__pc_to_reg, rc__mem_wb__pc_to_reg;
    reg [1:0] rc__id_ex__reg_write_dest, rc__ex_mem__reg_write_dest, rc__mem_wb__reg_write_dest;
    reg rc__id_ex__hdu_is_stall, rc__ex_mem__hdu_is_stall, rc__mem_wb__hdu_is_stall;

    // from EX/MEM
    reg [`WORD_SIZE-1:0] r__ex_mem__alu_out, r__mem_wb__alu_out;
    reg [`WORD_SIZE-1:0] r__ex_mem__mux_alu_src_b;
    
    // form MEM/WB
    reg [`WORD_SIZE-1:0] r__mem_wb__memory_read_data;
    
    //    PIPELINE REGISTERS END   //
    /////////////////////////////////

    wire w__imm__write_q2;
    
    // Interrupt begin
    reg is_intrpt;
    reg [1:0] intrpt_inst;  
    // Interrupt end

    // DMAC begin
    reg dmac_req;
    // assign dmac_req = (is_intrpt && intrpt_inst == `INST_DMA_BEGIN) ? 1 : 0;
    reg [`WORD_SIZE-1:0] dmac_addr;
    reg [`QWORD_SIZE-1:0] dmac_length;
    // DMAC end

    // Bus begin
    reg is_granted;

    assign address1 = `WORD_SIZE'bz;
    assign qdata1 = `QWORD_SIZE'bz;

    assign address2 = (dmac_req) ? (dmac_addr) : (
        (is_granted & (write_m2 | write_q2)) ? w__d_cache__addr : `WORD_SIZE'bz
    );
    assign qdata2 = (dmac_req) ? (dmac_length) : (
        (is_granted & (write_m2 | write_q2)) ? w__d_cache__data : `QWORD_SIZE'bz
    );

    assign write_q2 = (is_granted) ? (w__imm__write_q2) : (1'bz);
    // Bus end

    assign is_halted = rc__mem_wb__halt;

    mux4_1 mux__wwd_forward(
        .sel(c__forward_a),
        .i1(r__id_ex__read_data_1),     // no forwarding
        .i2(w__write_data),      // forwarding from WB
        .i3(r__ex_mem__alu_out), // forwarding from MEM
        .i4(`WORD_SIZE'b0),
        .o(w__wwd_src)
    );

    assign output_port = (rc__mem_wb__wwd && rc__mem_wb__valid) ? (
        rc__mem_wb__hdu_is_stall ? 
            r__ex_mem__wwd_value : r__mem_wb__wwd_value
        ) : output_port;

    assign num_inst = r__num_inst;

    initial begin
        is_granted = 1;
        is_intrpt = 0;
        dmac_intrpt_resolved = 0;
        ext_intrpt_resolved = 0;
        m2_bg = 0;
        r__fetch = 1;
        r__is_flush = 0;
        r__pc = 0;
        r__memory_register = 0;
        r__read_data_1 = 0;
        r__read_data_2 = 0;
        r__num_inst = 0;
        r__if_id__inst = `NOP;
        r__if_id__pc = 0;
        r__id_ex__pc = 0;
        r__if_id__pred_pc = 0;
        r__id_ex__next_pc = 0;
        r__ex_mem__next_pc = 0;
        r__mem_wb__next_pc = 0;
        r__ex_mem__wwd_value = 0;
        r__mem_wb__wwd_value = 0;
        r__id_ex__read_data_1 = 0;
        r__ex_mem__read_data_1 = 0;
        r__mem_wb__read_data_1 = 0;
        r__id_ex__read_data_2 = 0;
        r__ex_mem__read_data_2 = 0;
        r__ex_mem__mux_alu_src_b = 0;
        r__id_ex__imm_ext = 0;
        r__id_ex__opcode = 0;
        r__id_ex__funct = 0;
        r__id_ex__func_code = 0;
        r__id_ex__rd = 0;
        r__ex_mem__rd = 0;
        r__mem_wb__rd = 0;
        r__id_ex__rt = 0;
        r__ex_mem__rt = 0;
        r__mem_wb__rt = 0;
        r__id_ex__rs = 0;
        rc__id_ex__halt = 0; 
        rc__ex_mem__halt = 0; 
        rc__mem_wb__halt = 0;
        rc__id_ex__wwd = 0; 
        rc__ex_mem__wwd = 0; 
        rc__mem_wb__wwd = 0;
        rc__id_ex__alu_src = 0;
        rc__id_ex__mem_read = 0; 
        rc__ex_mem__mem_read = 0; 
        rc__mem_wb__mem_read = 0;
        rc__id_ex__mem_write = 0; 
        rc__ex_mem__mem_write = 0;
        rc__id_ex__reg_write = 0; 
        rc__ex_mem__reg_write = 0; 
        rc__mem_wb__reg_write = 0;
        rc__id_ex__mem_to_reg = 0; 
        rc__ex_mem__mem_to_reg = 0; 
        rc__mem_wb__mem_to_reg = 0;
        rc__id_ex__pc_to_reg = 0; 
        rc__ex_mem__pc_to_reg = 0; 
        rc__mem_wb__pc_to_reg = 0;
        rc__id_ex__reg_write_dest = 0;
        rc__ex_mem__reg_write_dest = 0;
        rc__mem_wb__reg_write_dest = 0;
        r__ex_mem__alu_out = 0;
        r__mem_wb__alu_out = 0;
        r__mem_wb__memory_read_data = 0;
        rc__if_id__valid = 0;
        rc__id_ex__valid = 0;
        rc__ex_mem__valid = 0;
        rc__id_ex__hdu_is_stall = 0;
        rc__ex_mem__hdu_is_stall = 0;
        rc__mem_wb__hdu_is_stall = 0;
        first = 1;
    end
    
    always @(*) begin
        if (reset_n) begin
            r__fetch = 1;
            r__is_flush = 0;
            r__pc = 0;
            r__memory_register = 0;
            r__read_data_1 = 0;
            r__read_data_2 = 0;
            r__num_inst = 0;
            r__if_id__inst = `NOP;
            r__if_id__pc = 0;
            r__id_ex__pc = 0;
            r__if_id__pred_pc = 0;
            r__id_ex__next_pc = 0;
            r__ex_mem__next_pc = 0;
            r__mem_wb__next_pc = 0;
            r__ex_mem__wwd_value = 0;
            r__mem_wb__wwd_value = 0;
            r__id_ex__read_data_1 = 0;
            r__ex_mem__read_data_1 = 0;
            r__mem_wb__read_data_1 = 0;
            r__id_ex__read_data_2 = 0;
            r__ex_mem__read_data_2 = 0;
            r__ex_mem__mux_alu_src_b = 0;
            r__id_ex__imm_ext = 0;
            r__id_ex__opcode = 0;
            r__id_ex__funct = 0;
            r__id_ex__func_code = 0;
            r__id_ex__rd = 0;
            r__ex_mem__rd = 0;
            r__mem_wb__rd = 0;
            r__id_ex__rt = 0;
            r__ex_mem__rt = 0;
            r__mem_wb__rt = 0;
            r__id_ex__rs = 0;
            rc__id_ex__halt = 0; 
            rc__ex_mem__halt = 0; 
            rc__mem_wb__halt = 0;
            rc__id_ex__wwd = 0; 
            rc__ex_mem__wwd = 0; 
            rc__mem_wb__wwd = 0;
            rc__id_ex__alu_src = 0;
            rc__id_ex__mem_read = 0; 
            rc__ex_mem__mem_read = 0; 
            rc__mem_wb__mem_read = 0;
            rc__id_ex__mem_write = 0; 
            rc__ex_mem__mem_write = 0;
            rc__id_ex__reg_write = 0; 
            rc__ex_mem__reg_write = 0; 
            rc__mem_wb__reg_write = 0;
            rc__id_ex__mem_to_reg = 0; 
            rc__ex_mem__mem_to_reg = 0; 
            rc__mem_wb__mem_to_reg = 0;
            rc__id_ex__pc_to_reg = 0; 
            rc__ex_mem__pc_to_reg = 0; 
            rc__mem_wb__pc_to_reg = 0;
            rc__id_ex__reg_write_dest = 0;
            rc__ex_mem__reg_write_dest = 0;
            rc__mem_wb__reg_write_dest = 0;
            r__ex_mem__alu_out = 0;
            r__mem_wb__alu_out = 0;
            r__mem_wb__memory_read_data = 0;
            rc__if_id__valid = 0;
            rc__id_ex__valid = 0;
            rc__ex_mem__valid = 0;
            rc__id_ex__hdu_is_stall = 0;
            rc__ex_mem__hdu_is_stall = 0;
            rc__mem_wb__hdu_is_stall = 0;
            first = 1;
        end
    end

    ////////// IF ///////////

    /// Memory ///
    /// Instruction memory is concatenated to Data memory
    /// See bottom, MEM stage.

    branch_predictor Branch_Predictor(
        .clk(clk),
        .reset_n(reset_n),
        .is_flush(c__hdu_is_stall),
        .opcode(w__inst[`OPCODE]),
        .calculated_pc(w__branch_address),
        .current_pc(r__pc),
        .is_branch(c__is_branch),
        .is_jump(c__is_jump),
        .next_pc(w__pred_pc)
    );


    ////////// ID ///////////

    wire w__i_cache__hit;

    cache i_cache(
        .c__read_m(r__fetch),
        .c__write_m(),
        .addr(r__pc),
        .i__data(),
        .o__data(w__inst),
        .c__ready(w__i_cache_ready),
        .m__read_m(w__i_cache__read_m),
        .m__write_m(),
        .m__addr(w__i_cache__addr),
        .m__size(),
        .m__data(w__i_cache__data),
        .m__ready(w__ready_inst),
        .m__ack(w__ack_inst),
        .is_hit(w__i_cache__hit),
        .clk(clk),
        .reset_n(reset_n)
    );

    forwarding_unit Forwarding_BC_Unit(
        .EXMEM_RegWrite(rc__id_ex__reg_write),
        .EXMEM_RegWriteDest(rc__id_ex__reg_write_dest),
        .EXMEM_RD(r__id_ex__rd),
        .EXMEM_RT(r__id_ex__rt),
        .MEMWB_RegWrite(rc__ex_mem__reg_write),
        .MEMWB_RegWriteDest(rc__ex_mem__reg_write_dest),
        .MEMWB_RD(r__ex_mem__rd),
        .MEMWB_RT(r__ex_mem__rt),
        .IDEX_RS(r__if_id__inst[`RS]),
        .IDEX_RT(r__if_id__inst[`RT]),
        .forward_a(c__forward_bc_a),
        .forward_b(c__forward_bc_b)
    );

    mux4_1 mux__bc_forward_a(
        .sel(c__forward_bc_a),
        .i1(w__read_data_1),          // no forwarding
        .i2(r__ex_mem__alu_out),      // forwarding from MEM
        .i3(w__alu_out),              // forwarding from EX
        .i4(`WORD_SIZE'b0),
        .o(w__bc_forward_a)
    );

    mux4_1 mux__bc_forward_b(
        .sel(c__forward_bc_b),
        .i1(w__read_data_2),          // no forwarding
        .i2(r__ex_mem__alu_out),      // forwarding from MEM
        .i3(w__alu_out),              // forwarding from EX
        .i4(`WORD_SIZE'b0),
        .o(w__bc_forward_b)
    );

    sign_extender Imm_Extend(
        .immediate(r__if_id__inst[`IMMD_SIZE-1:0]),
        .sign_extended(w__imm_ext)
    );

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
        .jump_type(w__jump_type),
        .is_branch(c__is_branch),
        .is_jump(c__is_jump)
    );

    hazard_detect Hazard_Detect(
        .IFID_IR(r__if_id__inst),
        .IFID_M_valid(rc__if_id__valid),
        .IDEX_rd(r__id_ex__rd),
        .IDEX_M_valid(rc__id_ex__valid),
        .IDEX_M_reg_write(rc__id_ex__reg_write),
        .IDEX_M_mem_read(rc__id_ex__mem_read),
        .is_stall(c__hdu_is_stall)
    );

    branch_calculator Branch_Calculator(
        .A(w__bc_forward_a),
        .B(w__bc_forward_b),
        .PC(r__if_id__pc),
        .imm(r__if_id__inst[`IMMD_SIZE-1:0]),
        .is_branch(c__is_branch),
        .is_jump(c__is_jump),
        .branch_type(w__branch_type),
        .jump_type(w__jump_type),
        .next_pc(w__branch_address),
        .bcond(w__bcond)
    );

    // ID/EX flush mux is implemented in sequential logic


    ////////////// EX ////////////////

    forwarding_unit Forwarding_Unit(
        .EXMEM_RegWrite(rc__ex_mem__reg_write),
        .EXMEM_RegWriteDest(rc__ex_mem__reg_write_dest),
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
        .i1(rc__id_ex__pc_to_reg ? r__id_ex__next_pc : r__id_ex__read_data_1),     // no forwarding
        .i2(rc__mem_wb__pc_to_reg? r__mem_wb__next_pc : w__write_data),      // forwarding from WB
        .i3(rc__ex_mem__pc_to_reg ? r__ex_mem__next_pc : r__ex_mem__alu_out), // forwarding from MEM
        .i4(`WORD_SIZE'b0),
        .o(w__alu_src_a_reg)
    );

    mux4_1 mux__alu_forward_b(
        .sel(c__forward_b),
        .i1(rc__id_ex__pc_to_reg ? r__id_ex__next_pc : r__id_ex__read_data_2),     // no forwarding
        .i2(rc__mem_wb__pc_to_reg? r__mem_wb__next_pc : w__write_data),      // forwarding from WB
        .i3(rc__ex_mem__pc_to_reg ? r__ex_mem__next_pc : r__ex_mem__alu_out), // forwarding from MEM
        .i4(`WORD_SIZE'b0),
        .o(w__alu_src_b_reg)
    );

    mux2_1 mux__alu_b(
        .sel(rc__id_ex__alu_src),
        .i1(w__alu_src_b_reg),
        .i2(r__id_ex__imm_ext),
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

    wire [`WORD_SIZE-1:0] size_m2;
    /// Memory ///
    memory_io Memory (
        .clk(clk),
        .reset_n(reset_n),
        .is_granted(is_granted),
        .qdata1(qdata1),
        .qdata2(qdata2),
        .m1_ready(m1_ready),
        .m1_ack(m1_ack),
        .m2_ready(m2_ready),
        .m2_ack(m2_ack),
        .read_inst(w__i_cache__read_m),
        .read_data(w__d_cache__read_m),
        .write_data(w__d_cache__write_m),
        .addr_inst(w__i_cache__addr),
        .addr_data(w__d_cache__addr),
        .read_m1(read_m1),
        .read_m2(read_m2),
        .write_m2(write_m2),
        .write_q2(w__imm__write_q2),
        .size_m2(size_m2),
        .address1(address1),
        .address2(address2),
        .res_inst(w__i_cache__data),
        .res_data(w__d_cache__data),
        .ready_inst(w__ready_inst),
        .ack_inst(w__ack_inst),
        .ready_data(w__ready_data),
        .ack_data(w__ack_data),
        .dmac_req(dmac_req)
    );
    
    
    wire w__d_cache__hit;

    cache d_cache(
        .c__read_m(rc__ex_mem__valid & rc__ex_mem__mem_read),
        .c__write_m(rc__ex_mem__valid & rc__ex_mem__mem_write),
        .addr(r__ex_mem__alu_out),
        .i__data(r__ex_mem__read_data_2),
        .o__data(w__data),
        .c__ready(w__d_cache_ready),
        .m__read_m(w__d_cache__read_m),
        .m__write_m(w__d_cache__write_m),
        .m__addr(w__d_cache__addr),
        .m__size(size_m2),
        .m__data(w__d_cache__data),
        .m__ready(w__ready_data),
        .m__ack(w__ack_data),
        .is_hit(w__d_cache__hit),
        .clk(clk),
        .reset_n(reset_n)
    );


    /////////////// WB ////////////////
    mux2_1 mux__alu_out__reg_memory(
        .sel(rc__mem_wb__mem_to_reg),
        .i1(r__mem_wb__alu_out),
        .i2(r__mem_wb__memory_read_data),
        .o(w__write_data)
    );	

    reg haz;

    always @(posedge clk) begin
        // Arbiter begin
            if(m2_br == 1 && !m2_ack) begin
                is_granted <= 0;
                m2_bg <= 1;
            end else if(m2_br == 0) begin
                is_granted <= 1;
                m2_bg <= 0;
            end

        // Arbiter end

        if(is_intrpt) begin
            if (intrpt_inst == `INST_DMA_BEGIN) begin
                dmac_req <= 1;
                dmac_addr <= `WORD_SIZE'h00d0;
                dmac_length <= `QWORD_SIZE'h000c;
                ext_intrpt_resolved <= 1;
            end else if (intrpt_inst == `INST_DMA_END) begin
                dmac_intrpt_resolved <= 1;
            end
        end else begin
            dmac_req <= 0;
            dmac_intrpt_resolved <= 0;
            ext_intrpt_resolved <= 0;
            haz <= c__hdu_is_stall;
            // update Pipeline Registers
            // - MEM/WB
            r__mem_wb__wwd_value <= r__ex_mem__wwd_value;
            r__mem_wb__alu_out <= r__ex_mem__alu_out;
            r__mem_wb__rd <= r__ex_mem__rd;
            r__mem_wb__rt <= r__ex_mem__rt;
            r__mem_wb__read_data_1 <= r__ex_mem__read_data_1;
            r__mem_wb__next_pc <= r__ex_mem__next_pc;
            r__mem_wb__memory_read_data = w__data;
            rc__mem_wb__wwd <= rc__ex_mem__wwd;
            rc__mem_wb__halt <= rc__ex_mem__halt;
            rc__mem_wb__mem_read <= rc__ex_mem__mem_read;
            rc__mem_wb__mem_to_reg <= rc__ex_mem__mem_to_reg;
            rc__mem_wb__pc_to_reg <= rc__ex_mem__pc_to_reg;
            rc__mem_wb__reg_write <= rc__ex_mem__reg_write;
            rc__mem_wb__reg_write_dest <= rc__ex_mem__reg_write_dest;
            rc__mem_wb__valid <= rc__ex_mem__valid;
            rc__mem_wb__hdu_is_stall <= rc__ex_mem__hdu_is_stall;

            if (w__d_cache_ready == 0 && ~w__d_cache__hit) begin
                rc__mem_wb__reg_write <= 1'b0;
                rc__mem_wb__valid <= 1'b0;
            end else begin
                // - EX/MEM
                if (rc__ex_mem__valid == 1'b1) begin
                    r__num_inst <= r__num_inst + 1;
                end
                r__ex_mem__wwd_value <= w__wwd_src;
                r__ex_mem__alu_out <= w__alu_out;
                r__ex_mem__rd <= r__id_ex__rd;
                r__ex_mem__rt <= r__id_ex__rt;
                r__ex_mem__mux_alu_src_b <= w__mux_alu_src_b;
                r__ex_mem__read_data_1 <= r__id_ex__read_data_1;
                r__ex_mem__read_data_2 <= r__id_ex__read_data_2;
                r__ex_mem__next_pc <= r__id_ex__next_pc;
                rc__ex_mem__wwd <= rc__id_ex__wwd;
                rc__ex_mem__halt <= rc__id_ex__halt;
                rc__ex_mem__mem_read <= rc__id_ex__mem_read;
                rc__ex_mem__mem_write <= rc__id_ex__mem_write;
                rc__ex_mem__mem_to_reg <= rc__id_ex__mem_to_reg;
                rc__ex_mem__pc_to_reg <= rc__id_ex__pc_to_reg;
                rc__ex_mem__reg_write <= rc__id_ex__reg_write;
                rc__ex_mem__reg_write_dest <= rc__id_ex__reg_write_dest;
                rc__ex_mem__valid <= rc__id_ex__valid;
                rc__ex_mem__hdu_is_stall <= rc__id_ex__hdu_is_stall;
                // - ID/EX
                r__id_ex__read_data_1 <= w__read_data_1;
                r__id_ex__read_data_2 <= w__read_data_2;
                r__id_ex__imm_ext <= w__imm_ext;
                r__id_ex__func_code <= w__func_code;
                r__id_ex__rd <= r__if_id__inst[`RD];
                r__id_ex__rt <= r__if_id__inst[`RT];
                r__id_ex__rs <= r__if_id__inst[`RS];
                r__id_ex__pc <= r__if_id__pc;
                r__id_ex__next_pc <= r__if_id__pred_pc;
                rc__id_ex__wwd <= c__wwd;
                rc__id_ex__halt <= c__halt;
                rc__id_ex__alu_src <= c__alu_src;
                rc__id_ex__mem_read <= c__mem_read;
                rc__id_ex__valid <= rc__if_id__valid;
                rc__id_ex__hdu_is_stall <= c__hdu_is_stall;
                if (c__hdu_is_stall) begin
                    rc__id_ex__mem_write <= 1'b0;
                end else begin
                    rc__id_ex__mem_write <= c__mem_write;
                end
                rc__id_ex__mem_to_reg <= c__mem_to_reg; 
                rc__id_ex__pc_to_reg <= c__pc_to_reg;
                if (c__hdu_is_stall)
                    rc__id_ex__reg_write <= 1'b0;
                else
                    rc__id_ex__reg_write <= c__reg_write;
                rc__id_ex__reg_write_dest <= c__reg_write_dest;


                if (w__ready_inst == 0 || first) begin    // memory instruction port not ready, waiting for fetch
                    first <= 0;
                    rc__if_id__valid <= 1'b0;
                    r__if_id__inst <= `NOP;
                end
                else begin
                    if (r__is_flush) begin     // fetch done, but we'll flush that
                        r__is_flush <= 1'b0;
                        rc__if_id__valid <= 1'b0;
                        r__if_id__inst <= `NOP;
                    end else begin
                        if ((w__ack_inst || w__i_cache__hit) && !c__hdu_is_stall) begin
                            rc__if_id__valid <= 1'b1;
                            r__if_id__inst <= w__inst;
                            r__if_id__pc <= r__pc;
                            r__if_id__pred_pc <= w__pred_pc;
                            
                            // Update PC
                            r__pc <= w__pred_pc;
                        end
                        else begin
                            if (!((c__is_jump && r__pc != w__branch_address) || (c__is_branch && r__if_id__pred_pc != w__branch_address)))
                                rc__id_ex__valid <= 1'b0;
                        end
                    end

                end  // end not i cache ready

                // Update PC for jump and branch, Update flush
                if (!c__hdu_is_stall) begin
                    if ((c__is_jump && r__pc != w__branch_address) || (c__is_branch && r__if_id__pred_pc != w__branch_address)) begin
                        r__pc <= w__branch_address;
                        r__is_flush <= 1'b1;
                    end
                end

            end  // end not data cache ready
        end
    end // end always posedge clk

    always @(*) begin
        // Interrupt begin
        if(dmac_intrpt_inst == `INST_DMA_BEGIN || ext_intrpt_inst == `INST_DMA_BEGIN) begin
            is_intrpt = 1;
            intrpt_inst = `INST_DMA_BEGIN;
        end else if(dmac_intrpt_inst == `INST_DMA_END || ext_intrpt_inst == `INST_DMA_END) begin
            is_intrpt = 1;
            intrpt_inst = `INST_DMA_END;
        end else begin
            is_intrpt = 0;
            intrpt_inst = 0;
        end
        // Interrupt end

        if (r__if_id__inst !== `NOP && !haz) begin
            if (r__is_flush) begin
                rc__if_id__valid = 1'b0;
                r__if_id__inst = `NOP;
            end
            else begin
                r__if_id__inst = w__inst;
            end
        end
        if (w__data !== `WORD_SIZE'bX && w__data !== `WORD_SIZE'bZ)
            r__mem_wb__memory_read_data = w__data;
    end

endmodule


