`include "util.v"
`include "memory.v"

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
	wire c__alu_op;
	wire c__alu_src_a;
	wire c__alu_src_b;
	wire c__reg_write;

	//## WB/MEM
	wire [`WORD_SIZE-1:0] w__addr__pc;
	wire [`WORD_SIZE-1:0] w__pc__mux;
	wire [`WORD_SIZE-1:0] w__aout__mux;
	wire [`WORD_SIZE-1:0] w__mux__memory;

	//## MEM/IF
	wire [`WORD_SIZE-1:0] w__memory__inst;
	wire [`WORD_SIZE-1:0] w__memory__r_memory_register;

	//## IF/ID
	wire [`WORD_SIZE-1:0] w__inst_ext;
	wire [`]

	//## ID/EX
	wire [`WORD_SIZE-1:0] w__read_data_1;
	wire [`WORD_SIZE-1:0] w__read_data_2;

	//## EX/MEM

	//## MEM/WB
	wire [`WORD_SIZE-1:0] w__mux__write_data;


	//# Registers
	reg [`WORD_SIZE-1:0] pc;
	reg [`WORD_SIZE-1:0] r__memory_register;
	reg [`WORD_SIZE-1:0] r__read_data_1;
	reg [`WORD_SIZE-1:0] r__read_data_2;
	reg [`WORD_SIZE-1:0] r__alu_out;
	reg [`WORD_SIZE-1:0] r__inst;

	//# Modules

	//## MEM
	mux2_1 mux__pc__alu_out(
		.sel(c__i_or_d),
		.i1(w__pc__mux),
		.i2(w__aout__mux)
		.o(w__mux__memory));

	// TODO: HOW??
	memory Memory(
		.clk(clk),
		.reset_n(reset_n),
		.read_m(c__mem_read),
		.write_m(c__mem_write),
		.address(w__mux__memory),
		.data()
	);

	//## IF

	//## ID
	register_file Registers(
		.read1(r__inst[19:15]),
		.read2(r__inst[24:20]),
		.write_reg(r__inst[11:7]),
		.write_data(w__mux__write_data),
		.reg_write(c__reg_write),
		.reset_n(reset_n),
		.pvs_write_en(pvs_write_en),
		.clk(clk),
		.read_out1(w__read_data_1),
		.read_out2(w__read_data_2)
	);

	control_unit Control(
		.opcode(),
		.func_code(),
		.clk(clk),
		.reset_n(reset_n),
		.pc_write_cond(),
		.pc_write(c__pc_write),
		.i_or_d(c__i_or_d),
		.mem_read(c__mem_read),
		.mem_to_reg(c__mem_to_reg),
		.mem_write(c__mem_write),
		.ir_write(c__ir_write),
		.pc_to_reg(),
		.pc_src(c__pc_source),
		.halt(),
		.wwd(),
		.new_inst(),
		.reg_write(),
		.alu_src_A(),
		.alu_src_B(),
		.alu_op()
	);

	// TODO: imm extend


	//## EX
	alu_control_unit ALU_control(
		.funct(),
		.opcode(),
		.ALUOp(), 
		.clk(), 
		.funcCode(),
		.branchType()
	);

	alu ALU(
		.A(), 
		.B(), 
		.func_code(), 
		.branch_type(), 
		.C(), 
		.overflow_flag(), 
		.bcond());
	

endmodule
