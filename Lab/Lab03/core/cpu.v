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
																																					  
endmodule							  																		  