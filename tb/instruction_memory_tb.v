`timescale 1ns/1ps

module instruction_memory_tb;
wire [31:0]instruction;

reg [31:0]address;

instruction_memory DUT(
    .instruction(instruction),
    .address(address)
);

initial 
begin
    DUT.internal_memory[0] = 32'hFEEDBEAD;
    DUT.internal_memory[1] = 32'hBADDEED1;
    DUT.internal_memory[2] = 32'hFADEDEDA;
    DUT.internal_memory[3] = 32'hDEADBEEF;
end
//Byte Address = Memory Index × 4

initial
begin
    $monitor("Time=%0t Address=%0d Instruction=%h",
              $time, address, instruction);
end

initial 
begin
    $dumpfile("waves/instruction_memory.vcd");
    $dumpvars(0,instruction_memory_tb);

    address = 0;
    #10;
    address = 4;
    #10;
    address = 8;
    #10;
    address = 12;
    #10;
    $finish;
end

endmodule