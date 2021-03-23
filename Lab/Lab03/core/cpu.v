`include "opcodes.v"
`include "alu.v" 	
`include "adder.v"
`include "sign_extender.v"
`include "register_file.v"
`include "mux.v"   

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output readM;									
	output writeM;								
	output [`WORD_SIZE-1:0] address;	
	inout [`WORD_SIZE-1:0] data;		
	input ackOutput;								
	input inputReady;								
	input reset_n;									
	input clk;			

	reg [`WORD_SIZE-1:0] PC;
	wire [`WORD_SIZE-1:0] NextPC;

	wire Instruction[15:0];

    wire ALUSrc;
    wire [3-1:0] ALUOp;
    wire RegWrite;
    wire MemRead;
    wire MemtoReg;
    wire MemWrite;
    wire PCtoReg;
    wire Jump;
    wire Branch;
	
	wire [`WORD_SIZE-1:0] ReadData1;
	wire [`WORD_SIZE-1:0] ReadData2;

	wire [`WORD_SIZE-1:0] WriteData;
	wire [`WORD_SIZE-1:0] WriteDataValue;

	wire [`WORD_SIZE-1:0] WireSignExtendOut;
	wire [`WORD_SIZE-1:0] WireMuxALUOut;

	wire [`WORD_SIZE-1:0] WireALUOut;

	wire [`WORD_SIZE-1:0] ReadDataMemory;

	adder AdderNextPC(.adder_input1(PC),
					.adder_input2(1),
					.adder_output(NextPC));

	control_unit MainControl(.instr(Instruction), 
							.alu_src(ALUSrc), 
							.alu_op(ALUOp), 
							.reg_write(RegWrite), 
							.mem_read(MemRead), 
							.mem_to_reg(MemtoReg), 
							.mem_write(MemWrite), 
							.PCtoReg(PCtoReg), 
							.jp(Jump), 
							.branch(Branch));

	mux MuxWriteData(.mux_input_1(WriteDataValue),
					.mux_input_2(NextPC),
					.selector(PCtoReg),
					.mux_output(WriteData));

	register_file Registers(.read_out1(ReadData1), 
							.read_out2(ReadData2), 
							.read1(Instruction[11:10]), 
							.read2(Instruction[9:8]), 
							.write_reg(Instruction[7:6]), 
							.write_data(WriteData), 
							.reg_write(RegWrite), 
							.clk(clk));


	sign_extender SignExtend(.immediate(Instruction[`IMMD_SIZE-1:0]), 
							.sign_extended(WireSignExtendOut));

	mux MuxALU(.mux_input_1(ReadData2), 
				.mux_input_2(WireSignExtendOut), 
				.selector(ALUSrc), 
				.mux_output(WireMuxALUOut));

	alu ALU(.alu_input_1(ReadData1), 
			.alu_input_2(WireMuxALUOut), 
			.func_code(ALUOp), 
			.alu_output(WireALUOut));

	data_memory DataMemory(.address(WireALUOut),
						.write_data(ReadData2),
						.ackOutput(ackOutput),
						.inputReady(inputReady),
						.data(data),
						.readM(readM),
						.writeM(writeM),
						.address_out(address),
						.read_data(ReadDataMemory),
						.mem_write(MemWrite),
						.mem_read(MemRead));

	mux MuxWriteDataValue(.mux_input_1(WireALUOut),
						.mux_input_2(ReadDataMemory),
						.selector(MemtoReg),
						.mux_output(WriteDataValue));

endmodule							  																		  