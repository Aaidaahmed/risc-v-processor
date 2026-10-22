
`timescale 1ns/1ps

module gpio_demo_tb;

    reg clk;
    reg rst;
    integer errors;
    integer i;

    cpu DUT (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        errors = 0;

        $dumpfile("waves/gpio_demo.vcd");
        $dumpvars(0, gpio_demo_tb);

        repeat (2) @(negedge clk);

        // Initialize instruction memory with NOPs.
        for (i = 0; i < 256; i = i + 1)
            DUT.IM.internal_memory[i] = 32'h00000013;

        // Initialize data memory.
        DUT.DM.internal_memory[0] = 32'd42;

        // x1 = GPIO address 0x10000000
        DUT.IM.internal_memory[0] = 32'h100000B7;

        // GPIO outputs: 1, 3, 7, 0
        DUT.IM.internal_memory[1] = 32'h00100113; // ADDI x2,x0,1
        DUT.IM.internal_memory[2] = 32'h0020A023; // SW x2,0(x1)
        DUT.IM.internal_memory[3] = 32'h00300113; // ADDI x2,x0,3
        DUT.IM.internal_memory[4] = 32'h0020A023; // SW x2,0(x1)
        DUT.IM.internal_memory[5] = 32'h00700113; // ADDI x2,x0,7
        DUT.IM.internal_memory[6] = 32'h0020A023; // SW x2,0(x1)
        DUT.IM.internal_memory[7] = 32'h00000113; // ADDI x2,x0,0
        DUT.IM.internal_memory[8] = 32'h0020A023; // SW x2,0(x1)

        // Load 42 from data memory into x3.
        DUT.IM.internal_memory[9]  = 32'h00002183; // LW x3,0(x0)

        // Taken branch: x3 == x4 (x4 is initialized to zero? No).
        DUT.IM.internal_memory[10] = 32'h00000213; // ADDI x4,x0,0
        // x3 is 42, so this BEQ is not taken.
        // BNE x3,x4,+8 is taken and skips the NOP at index 13.
        DUT.IM.internal_memory[11] = 32'h00419463; // BNE x3,x4,+8
        DUT.IM.internal_memory[12] = 32'h00000013; // NOP (skipped)
        DUT.IM.internal_memory[13] = 32'h00300193; // ADDI x3,x0,3


        // Initialize MAC operands and accumulator.
        DUT.IM.internal_memory[14] = 32'h00200213; // ADDI x4,x0,2
        DUT.IM.internal_memory[15] = 32'h00300293; // ADDI x5,x0,3
        DUT.IM.internal_memory[16] = 32'h00400313; // ADDI x6,x0,4

        // MAC x6,x4,x5: x6 = 4 + (2*3) = 10
        DUT.IM.internal_memory[17] = {
            7'b0000001, 5'd5, 5'd4,
            3'b000, 5'd6, 7'b0001011
        };


        // Reset the CPU, then execute the program.
        @(posedge clk);
        @(negedge clk);
        rst = 0;

        $display("\n===== CPU + GPIO DEMONSTRATION =====");

        repeat (24) @(negedge clk);

        // GPIO output check
        if (DUT.gpio_out !== 32'd0) begin
            $display("FAIL: GPIO output expected 0, got %0d",
                     DUT.gpio_out);
            errors = errors + 1;
        end else begin
            $display("PASS: GPIO output sequence completed");
        end

        // Load check
        if (DUT.RF.registers[3] !== 32'd3) begin
            $display("FAIL: expected x3 = 3, got %0d",
                     DUT.RF.registers[3]);
            errors = errors + 1;
        end else begin
            $display("PASS: load and subsequent instruction execution");
        end
                // Verify MAC arithmetic result.
        if (DUT.RF.registers[6] !== 32'd10) begin
            $display("FAIL: expected x6 = 10, got %0d",
                     DUT.RF.registers[6]);
            errors = errors + 1;
        end else begin
            $display("PASS: MAC result x6 = 10");
        end
        // Counter checks
        if (DUT.load_counter !== 32'd1) begin
            $display("FAIL: load counter = %0d", DUT.load_counter);
            errors = errors + 1;
        end else begin
            $display("PASS: load counter");
        end

        if (DUT.store_counter !== 32'd4) begin
            $display("FAIL: store counter = %0d", DUT.store_counter);
            errors = errors + 1;
        end else begin
            $display("PASS: store counter");
        end

        if (DUT.branch_counter !== 32'd1) begin
            $display("FAIL: branch counter = %0d", DUT.branch_counter);
            errors = errors + 1;
        end else begin
            $display("PASS: branch counter");
        end

        if (DUT.mac_counter !== 32'd1) begin
            $display("FAIL: MAC counter = %0d", DUT.mac_counter);
            errors = errors + 1;
        end else begin
            $display("PASS: MAC counter");
        end

        $display("\n===== PERFORMANCE COUNTERS =====");
        $display("Cycles       : %0d", DUT.cycle_counter);
        $display("Instructions : %0d", DUT.inst_counter);
        $display("Loads        : %0d", DUT.load_counter);
        $display("Stores       : %0d", DUT.store_counter);
        $display("Branches     : %0d", DUT.branch_counter);
        $display("MAC          : %0d", DUT.mac_counter);

        if (errors == 0)
            $display("\nCPU + GPIO DEMO PASSED");
        else
            $display("\nCPU + GPIO DEMO FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
