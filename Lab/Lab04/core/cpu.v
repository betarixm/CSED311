`include "env.v"
`include "util.v"
`include "memory.v"
`include "extender.v"
`include "alu_control_unit.v"
`include "alu.v"
`include "control_unit.v"
`include "memory.v"
`include "opcodes.v"
`include "register_file.v"

`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

module cpu(clk, reset_n, read_m, write_m, address, data, num_inst, output_port, is_halted);
	input clk;
	input reset_n;
	
	output read_m;
	output write_m;
	output [`WORD_SIZE-1:0] address;

	inout [`WORD_SIZE-1:0] data;

	output [`WORD_SIZE-1:0] num_inst;		// number of instruction executed (for testing purpose)
	output [`WORD_SIZE-1:0] output_port;	// this will be used for a "WWD" instruction
	output is_halted;

	// TODO : implement multi-cycle CPU
    
	//# Wires
	//## Control
	wire c__pc_write_not_cond;
	wire c__pc_write;
	wire c__i_or_d;
	wire c__mem_read;
	wire c__mem_write;
	wire c__mem_to_reg;
	wire c__ir_write;
	wire c__pc_source;
	wire [1:0] c__alu_op;
	wire [1:0] c__alu_src_a;
	wire [1:0] c__alu_src_b;
	wire c__reg_write;
	wire [1:0] c__reg_write_dest;
	wire c__wwd;
	wire c__pc_to_write;
	wire c__new_inst;
	wire c__pvs_write_en;

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
	wire [`WORD_SIZE-1:0] w__inst_ext;

	//## ID/EX
	wire [`WORD_SIZE-1:0] w__immext__mux;
	wire [`WORD_SIZE-1:0] w__read_data_1;
	wire [`WORD_SIZE-1:0] w__read_data_2;
	wire [`REG_SIZE-1:0] w__write_reg;
	wire [`WORD_SIZE-1:0] w__alu_a;
	wire [`WORD_SIZE-1:0] w__alu_b;

	//## EX/MEM
	wire w__bcond;
	wire w__overflow_flag;
	wire [`WORD_SIZE-1:0] w__mux__pc;
	wire [`WORD_SIZE-1:0] w__alu_result;

	//## MEM/WB
	wire [`WORD_SIZE-1:0] w__mux__write_data;
    wire [4-1:0] w__alu__func_code;
    wire [2-1:0] w__alu__branch_type;

	//# Registers
	reg [`WORD_SIZE-1:0] r__pc;
	reg [`WORD_SIZE-1:0] r__memory_register;
	reg [`WORD_SIZE-1:0] r__read_data_1;
	reg [`WORD_SIZE-1:0] r__read_data_2;
	reg [`WORD_SIZE-1:0] r__alu_out;
	reg [`WORD_SIZE-1:0] r__inst;
	reg [`WORD_SIZE-1:0] r__num_inst;

	reg [`WORD_SIZE-1:0] r__const_0;
	reg [`WORD_SIZE-1:0] r__const_1;

	//# Initial
	// TODOTODOTODOTODOTODOTODOTODOTODOTODO
	// assign w__data = c__pvs_write_en ? r__read_data_2 : w__data;
	
	assign output_port = c__wwd ? r__read_data_1 : 0;
	assign num_inst = r__num_inst;

	initial begin
		r__const_0 <= 0;
		r__const_1 <= 1;

		r__pc <= 0;
	end
	//# Modules
	//## MEM
	mux2_1 mux__pc__alu_out(
		.sel(c__i_or_d),
		.i1(r__pc),
		.i2(r__alu_out),
		.o(w__mux__memory));

	memory Memory(
		.clk(clk),
		.reset_n(reset_n),
		.read_m(c__mem_read),
		.write_m(c__mem_write),
		.address(w__mux__memory),
		.data(w__data)
	);

	//## IF
	mux2_1 mux__alu_result__alu_out(
		.sel(c__pc_source),
		.i1(w__alu_result),
		.i2(r__alu_out),
		.o(w__mux__pc)
	);


	mux4_1_reg mux__write_reg(
		.sel(c__reg_write_dest),
		.i1(r__inst[`RD]),
		.i2(r__inst[`RT]),
		.i3(`REG_SIZE'd2),
		.i4(`REG_SIZE'd0),
		.o(w__write_reg)
	);

	//## ID
	register_file Registers(
		.read1(r__inst[`RS]),
		.read2(r__inst[`RT]),
		.write_reg(w__write_reg),
		.write_data(w__mux__write_data),
		.reg_write(c__reg_write),
		.pvs_write_en(c__pvs_write_en),
		.clk(clk),
		.read_out1(w__read_data_1),
		.read_out2(w__read_data_2)
	);

	control_unit Control(
		.opcode(r__inst[`OPCODE]),
		.func_code(r__inst[`FUNC]),
		.clk(clk),
		.reset_n(reset_n),
		.pc_write_cond(),
		.pc_write(c__pc_write),
		.i_or_d(c__i_or_d),
		.mem_read(c__mem_read),
		.mem_to_reg(c__mem_to_reg),
		.mem_write(c__mem_write),
		.ir_write(c__ir_write),
		.pc_to_reg(c__pc_to_write),
		.pc_src(c__pc_source),
		.halt(is_halted),
		.wwd(c__wwd),
		.new_inst(c__new_inst),
		.reg_write(c__reg_write),
		.reg_write_dest(c__reg_write_dest),
		.alu_src_A(c__alu_src_a),
		.alu_src_B(c__alu_src_b),
		.alu_op(c__alu_op),
		.pvs_write_en(c__pvs_write_en),
		.bcond(w__bcond)
	);

	sign_extender Imm_extend(
		.immediate(r__inst[`IMMD_SIZE-1:0]),
		.sign_extended(w__immext__mux)
	);

	//## EX
	mux2_1 mux__alu_a(
		.sel(c__alu_src_a[0]),
		.i1(r__pc),
		.i2(r__read_data_1),
		.o(w__alu_a)
	);

	mux4_1 mux__alu_b(
		.sel(c__alu_src_b),
		.i1(r__read_data_2),
		.i2(r__const_1),
		.i3(w__immext__mux),
		.i4(r__const_0),
		.o(w__alu_b)
	);

	alu_control_unit ALU_control(
		.funct(r__inst[`FUNC]),
		.opcode(r__inst[`OPCODE]),
		.ALUOp(c__alu_op), 
		.clk(clk), 
		.funcCode(w__alu__func_code),
		.branchType(w__alu__branch_type)
	);

	alu ALU(
		.A(w__alu_a), 
		.B(w__alu_b), 
		.func_code(w__alu__func_code), 
		.branch_type(w__alu__branch_type), 
		.C(w__alu_result), 
		.overflow_flag(w__overflow_flag), 
		.bcond(w__bcond));

	//## WB
	mux2_1 mux__alu_out__reg_memory(
		.sel(c__mem_to_reg),
		.i1(r__alu_out),
		.i2(r__memory_register),
		.o(w__mux__write_data)
	);
	
	always @(posedge clk) begin
		if (!reset_n) begin
			r__num_inst <= 1;
			r__pc <= 0;
		end
		// PC
		if(c__pc_write || (w__bcond && c__pc_write_not_cond)) begin
			r__num_inst <= r__num_inst + 1;
			r__pc <= w__mux__pc;
		end

		// Memory
		if(c__mem_read) begin
			if(c__i_or_d) begin
				r__memory_register <= w__data;
			end else begin
				r__inst <= w__data;
			end
		end

		// Register Latch
		r__read_data_1 <= w__read_data_1;
		r__read_data_2 <= w__read_data_2;

		// ALU Latch
		r__alu_out <= w__alu_result;
	end
endmodule
