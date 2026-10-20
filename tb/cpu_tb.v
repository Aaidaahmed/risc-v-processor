
`timescale 1ns/1ps

module cpu_tb;

reg clk;
reg rst;

cpu DUT (
    .clk(clk),
    .rst(rst)
);

initial begin
    clk = 0;
end

always #5 clk = ~clk;

initial begin
    rst = 1'b1;
    #10;
    rst = 1'b0;
end

// =====================================================
// INSTRUCTION AND DATA MEMORY INITIALIZATION
// =====================================================
initial begin

    // Initial data word:
    // Address 0 = AB, 1 = 34, 2 = F2, 3 = 80
    DUT.DM.internal_memory[0] = 32'h80F234AB;

    // Separate locations for store tests
    DUT.DM.internal_memory[2] = 32'h00000000; // Address 8
    DUT.DM.internal_memory[3] = 32'h00000000; // Address 12

    // x1 = 0
    DUT.IM.internal_memory[0] = 32'h00000093; // ADDI x1,x0,0

    // ---------------- LOAD TESTS ----------------

    DUT.IM.internal_memory[1] = 32'h00308103; // LB  x2,3(x1)
    DUT.IM.internal_memory[2] = 32'h0030C183; // LBU x3,3(x1)
    DUT.IM.internal_memory[3] = 32'h00209203; // LH  x4,2(x1)
    DUT.IM.internal_memory[4] = 32'h0020D283; // LHU x5,2(x1)
    DUT.IM.internal_memory[5] = 32'h0000A303; // LW  x6,0(x1)

    // ---------------- STORE TESTS ----------------

    DUT.IM.internal_memory[6] = 32'h00200423; // SB x2,8(x0)
    DUT.IM.internal_memory[7] = 32'h00401523; // SH x4,10(x0)
    DUT.IM.internal_memory[8] = 32'h00602623; // SW x6,12(x0)

end

// =====================================================
// MONITOR
// =====================================================
initial begin
    $monitor(
        "PC=%h Instr=%h ALU_ADDR=%h x6=%h x5=%0d",
        DUT.PC.pc_out,
        DUT.instruction,
        DUT.alu_result,
        DUT.RF.registers[6],
        DUT.RF.registers[5]
    );
end

// =====================================================
// SIMULATION AND ASSERTIONS
// =====================================================
initial begin

    $dumpfile("waves/cpu.vcd");
    $dumpvars(0, cpu_tb);

    #140;

    $display("\n===== PERFORMANCE COUNTERS =====");
    $display("Cycles       : %0d", DUT.cycle_counter);
    $display("Instructions : %0d", DUT.inst_counter);
    $display("Loads        : %0d", DUT.load_counter);
    $display("Stores       : %0d", DUT.store_counter);
    $display("Branches     : %0d", DUT.branch_counter);
    $display("MAC          : %0d", DUT.mac_counter);

    // ---------------- LOAD RESULTS ----------------

    $display("\n===== LOAD TEST RESULTS =====");

    if (DUT.RF.registers[2] !== 32'hFFFFFF80)
        $display("FAIL: LB");
    else
        $display("PASS: LB");

    if (DUT.RF.registers[3] !== 32'h00000080)
        $display("FAIL: LBU");
    else
        $display("PASS: LBU");

    if (DUT.RF.registers[4] !== 32'hFFFF80F2)
        $display("FAIL: LH");
    else
        $display("PASS: LH");

    if (DUT.RF.registers[5] !== 32'h000080F2)
        $display("FAIL: LHU");
    else
        $display("PASS: LHU");

    if (DUT.RF.registers[6] !== 32'h80F234AB)
        $display("FAIL: LW");
    else
        $display("PASS: LW");

    // ---------------- STORE RESULTS ----------------

    $display("\n===== STORE TEST RESULTS =====");

    // SB at address 8 writes byte 0x80.
    // SH at address 10 then writes bytes F2,80.
    // Both operations affect memory word 2.
    if (DUT.DM.internal_memory[2] !== 32'h80F20080)
        $display("FAIL: SB/SH or byte preservation");
    else
        $display("PASS: SB and SH");

    // SW at address 12 writes a full 32-bit word.
    if (DUT.DM.internal_memory[3] !== 32'h80F234AB)
        $display("FAIL: SW");
    else
        $display("PASS: SW");

    $display("Memory word 2 after SB/SH = %08h",
         DUT.DM.internal_memory[2]);

    $finish;
end

endmodule
