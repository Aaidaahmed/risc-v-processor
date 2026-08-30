`timescale 1ns/1ps

module cpu_tb;
reg clk;
reg rst;

cpu DUT(
    .clk(clk),
    .rst(rst)
);

initial 
begin
    clk = 0;
end
always #5 clk = ~clk;

initial 
begin
    rst = 1'b1;
    #10;
    rst = 1'b0;
end

initial
begin
    /*DUT.IM.internal_memory[0] = 32'h00500093; // addi x1, x0, 5
    DUT.IM.internal_memory[1] = 32'h00A00113; // addi x2, x0, 10
    DUT.IM.internal_memory[2] = 32'h002081B3; // add  x3, x1, x2
    DUT.IM.internal_memory[3] = 32'h00302023; // sw   x3, 0(x0)
    DUT.IM.internal_memory[4] = 32'h00002203; // lw   x4, 0(x0)
    DUT.IM.internal_memory[5] = 32'h0220828B; // mac x5,x1,x2
    DUT.IM.internal_memory[0] = 32'h123452B7; // lui x5,0x12345
    DUT.IM.internal_memory[0] = 32'h008000EF; // jal x1,+8
    DUT.IM.internal_memory[1] = 32'h06300113; // addi x2,x0,99 (should be skipped)
    DUT.IM.internal_memory[2] = 32'h00700193; // addi x3,x0,7
    DUT.IM.internal_memory[0] = 32'h12345297; // auipc x5,0x12345*/
    
    DUT.IM.internal_memory[0] = 32'h10000337; // lui x6,0x10000
    DUT.IM.internal_memory[1] = 32'h02A00293; // addi x5,x0,42
    DUT.IM.internal_memory[2] = 32'h00532023; // sw x5,0(x6)

end

initial
begin
    
        /*$monitor("Time=%0t PC=%h Instr=%h x1=%0d x2=%0d x3=%0d x4=%0d x5=%0d",
        $time,
        DUT.PC.pc_out,
        DUT.instruction,
        DUT.RF.registers[1],
        DUT.RF.registers[2],
        DUT.RF.registers[3],
        DUT.RF.registers[4],
        DUT.RF.registers[5]
);*/
$monitor(
"PC=%h Instr=%h ALU_ADDR=%h x6=%h x5=%0d",
    DUT.PC.pc_out,
    DUT.instruction,
    DUT.alu_result,
    DUT.RF.registers[6],
    DUT.RF.registers[5]
);
end
initial
begin 
    $dumpfile("waves/cpu.vcd");
    $dumpvars(0,cpu_tb);
    #100;

    $display("\n===== PERFORMANCE COUNTERS =====");

    $display("Cycles       : %0d", DUT.cycle_counter);
    $display("Instructions : %0d", DUT.inst_counter);
    $display("Loads        : %0d", DUT.load_counter);
    $display("Stores       : %0d", DUT.store_counter);
    $display("Branches     : %0d", DUT.branch_counter);
    $display("MAC          : %0d", DUT.mac_counter);

    $finish;
end
endmodule