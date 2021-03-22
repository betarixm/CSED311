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

	control_unit MainControl(Instruction, ALUSrc, ALUOp, RegWrite, MemRead, MemtoReg, MemWrite, PCtoReg, Jump, Branch);
	register_file Registers(ReadData1, ReadData2, Instruction[11:10], Instruction[9:8], Instruction[7:6], WriteData, RegWrite, clk);

endmodule							  																		  