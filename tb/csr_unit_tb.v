
`timescale 1ns/1ps

module csr_unit_tb;

    reg clk = 0;
    reg rst = 1;
    reg instruction_valid = 0;
    reg mem_read = 0;
    reg mem_write = 0;
    reg branch_taken = 0;
    reg mac_executed = 0;

    wire [31:0] cycle_counter;
    wire [31:0] inst_counter;
    wire [31:0] load_counter;
    wire [31:0] store_counter;
    wire [31:0] branch_counter;
    wire [31:0] mac_counter;

    csr_unit DUT (
        .clk(clk),
        .rst(rst),
        .instruction_valid(instruction_valid),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch_taken(branch_taken),
        .mac_executed(mac_executed),
        .cycle_counter(cycle_counter),
        .inst_counter(inst_counter),
        .load_counter(load_counter),
        .store_counter(store_counter),
        .branch_counter(branch_counter),
        .mac_counter(mac_counter)
    );

    always #5 clk = ~clk;

    initial begin
        // Reset all counters
        @(negedge clk);
        rst = 1;
        @(negedge clk);
        rst = 0;

        // One ordinary valid instruction
        instruction_valid = 1;
        @(negedge clk);
        if (inst_counter !== 1)
            $fatal(1, "FAIL: instruction counter");
        $display("PASS: instruction counter");

        // Two consecutive taken branches
        branch_taken = 1;
        @(negedge clk);
        @(negedge clk);
        branch_taken = 0;

        if (branch_counter !== 2)
            $fatal(1, "FAIL: branch counter expected 2, got %0d",
                   branch_counter);
        $display("PASS: branch counter increments repeatedly");

        // One load, one store, one MAC
        mem_read = 1;
        mem_write = 1;
        mac_executed = 1;
        @(negedge clk);

        mem_read = 0;
        mem_write = 0;
        mac_executed = 0;

        if (load_counter !== 1)
            $fatal(1, "FAIL: load counter");
        if (store_counter !== 1)
            $fatal(1, "FAIL: store counter");
        if (mac_counter !== 1)
            $fatal(1, "FAIL: MAC counter");

        $display("PASS: load, store, and MAC counters");
        $display("Cycles counted: %0d", cycle_counter);
        $display("All CSR counter tests passed.");
        $finish;
    end

endmodule
