module instruction_memory(
input [31:0]address,
output [31:0]instruction);

reg [31:0]internal_memory[0:255];//Instruction Index = Byte Address / 4=====>>shift by 2 = divide by 4

assign instruction = internal_memory[address[31:2]];

endmodule