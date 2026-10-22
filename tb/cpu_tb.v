
/*`timescale 1ns/1ps

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
*/

////////////////////////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module cpu_tb;

    reg clk = 0;
    reg rst = 1;

    integer tests_passed = 0;
    integer tests_failed = 0;
    integer i;

    cpu DUT (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    localparam [31:0] NOP = 32'h00000013;

    // Encode an R-type instruction.
    function [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    // Encode an I-type ALU instruction.
    function [31:0] enc_i;
        input [11:0] imm;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction


    // Encode a B-type branch instruction.
    function [31:0] enc_b;
        input [12:0] imm;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        begin
            enc_b = {
                imm[12],
                imm[10:5],
                rs2,
                rs1,
                funct3,
                imm[4:1],
                imm[11],
                7'b1100011
            };
        end
    endfunction


    // Encode a J-type instruction (JAL).
    function [31:0] enc_j;
        input [20:0] imm;
        input [4:0] rd;
        begin
            enc_j = {
                imm[20],
                imm[10:1],
                imm[11],
                imm[19:12],
                rd,
                7'b1101111
            };
        end
    endfunction


    // Check a register's value.
    task check_reg;
        input [4:0] reg_num;
        input [31:0] expected;
        input [8*40-1:0] test_name;
        begin
            if (DUT.RF.registers[reg_num] === expected) begin
                $display("PASS: %0s", test_name);
                tests_passed = tests_passed + 1;
            end
            else begin
                $display("FAIL: %0s expected=%08h actual=%08h",
                         test_name, expected,
                         DUT.RF.registers[reg_num]);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    // Check a data-memory word.
    task check_mem;
        input integer word_index;
        input [31:0] expected;
        input [8*40-1:0] test_name;
        begin
            if (DUT.DM.internal_memory[word_index] === expected) begin
                $display("PASS: %0s", test_name);
                tests_passed = tests_passed + 1;
            end
            else begin
                $display("FAIL: %0s expected=%08h actual=%08h",
                         test_name, expected,
                         DUT.DM.internal_memory[word_index]);
                tests_failed = tests_failed + 1;
            end
        end
    endtask


    // Check the current program counter.
    task check_pc;
        input [31:0] expected;
        input [8*40-1:0] test_name;
        begin
            if (DUT.pc_out === expected) begin
                $display("PASS: %0s", test_name);
                tests_passed = tests_passed + 1;
            end
            else begin
                $display("FAIL: %0s expected=%08h actual=%08h",
                         test_name, expected, DUT.pc_out);
                tests_failed = tests_failed + 1;
            end
        end
    endtask


    // Reset the CPU, execute one instruction at address zero,
    // and return after the instruction's rising clock edge.

task execute_one;
    input [31:0] instruction;
    integer j;
    begin
        // Assert reset immediately so the next clock resets the PC.
        rst = 1;

        // Clear the old program to prevent stale instructions executing.
        for (j = 0; j < 256; j = j + 1)
            DUT.IM.internal_memory[j] = NOP;

        // Wait for the reset clock edge.
        @(posedge clk);
        @(negedge clk);

        // Install exactly one instruction at address zero.
        DUT.IM.internal_memory[0] = instruction;
        rst = 0;

        $display(
            "TEST INSTRUCTION=%08h rs1=%0d rs2=%0d rd=%0d",
            instruction,
            instruction[19:15],
            instruction[24:20],
            instruction[11:7]
        );

        // Execute the instruction and allow register writeback.
        @(posedge clk);
        @(negedge clk);
    end
endtask


    // Execute one instruction at a chosen PC address.
    task execute_at_pc;
        input [31:0] instruction;
        input [31:0] start_pc;
        integer j;
        begin
            rst = 1;

            for (j = 0; j < 256; j = j + 1)
                DUT.IM.internal_memory[j] = NOP;

            @(posedge clk);
            @(negedge clk);

            // Override the PC after its reset edge.
            DUT.PC.pc_out = start_pc;

            // Place the instruction at the corresponding word index.
            DUT.IM.internal_memory[start_pc >> 2] = instruction;

            rst = 0;

            @(posedge clk);
            @(negedge clk);
        end
    endtask


    // Start one instruction at a chosen PC and execute it.
    task execute_jump_at_pc;
        input [31:0] instruction;
        input [31:0] start_pc;
        integer j;
        begin
            rst = 1;

            for (j = 0; j < 256; j = j + 1)
                DUT.IM.internal_memory[j] = NOP;

            @(posedge clk);
            @(negedge clk);

            DUT.PC.pc_out = start_pc;
            DUT.IM.internal_memory[start_pc >> 2] = instruction;
            rst = 0;

            @(posedge clk);
            @(negedge clk);
        end
    endtask



    // ================================================
    // MAIN TEST SEQUENCE
    // ================================================

    initial begin

        // Initialize instruction and data memories.
        for (i = 0; i < 256; i = i + 1) begin
            DUT.IM.internal_memory[i] = NOP;
            DUT.DM.internal_memory[i] = 0;
        end

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;

        // ================================================
        // EXISTING LOAD / STORE TESTS
        // ================================================

        $display("\n===== LOAD / STORE TESTS =====");

        // Prepare the original memory test program.
        DUT.DM.internal_memory[0] = 32'h80F234AB;

        DUT.IM.internal_memory[0] = 32'h00000093; // ADDI x1,x0,0
        DUT.IM.internal_memory[1] = 32'h00308103; // LB x2,3(x1)
        DUT.IM.internal_memory[2] = 32'h0030C183; // LBU x3,3(x1)
        DUT.IM.internal_memory[3] = 32'h00209203; // LH x4,2(x1)
        DUT.IM.internal_memory[4] = 32'h0020D283; // LHU x5,2(x1)
        DUT.IM.internal_memory[5] = 32'h0000A303; // LW x6,0(x1)
        DUT.IM.internal_memory[6] = 32'h00200423; // SB x2,8(x0)
        DUT.IM.internal_memory[7] = 32'h00401523; // SH x4,10(x0)
        DUT.IM.internal_memory[8] = 32'h00602623; // SW x6,12(x0)

        repeat (10) @(posedge clk);
        @(negedge clk);

        check_reg(2, 32'hFFFFFF80, "LB sign extension");
        check_reg(3, 32'h00000080, "LBU zero extension");
        check_reg(4, 32'hFFFF80F2, "LH sign extension");
        check_reg(5, 32'h000080F2, "LHU zero extension");
        check_reg(6, 32'h80F234AB, "LW full word");

        check_mem(2, 32'h80F20080, "SB and SH");
        check_mem(3, 32'h80F234AB, "SW full word");

        // ================================================
        // R-TYPE ALU TESTS
        // ================================================

        $display("\n===== R-TYPE ALU TESTS =====");

        // ADD x10, x1, x2 => 12 + 3 = 15
        DUT.IM.internal_memory[0] = NOP;
        DUT.RF.registers[1] = 12;
        DUT.RF.registers[2] = 3;
        execute_one(enc_r(7'b0000000,2,1,3'b000,10,7'b0110011));
        check_reg(10, 32'd15, "ADD");

        // SUB => 12 - 3 = 9
        DUT.RF.registers[1] = 12;
        DUT.RF.registers[2] = 3;
        execute_one(enc_r(7'b0100000,2,1,3'b000,10,7'b0110011));
        check_reg(10, 32'd9, "SUB");

        // AND => F0 & 3C = 30
        DUT.RF.registers[1] = 32'hF0;
        DUT.RF.registers[2] = 32'h3C;
        execute_one(enc_r(7'b0000000,2,1,3'b111,10,7'b0110011));
        check_reg(10, 32'h30, "AND");

        // OR => F0 | 0F = FF
        DUT.RF.registers[1] = 32'hF0;
        DUT.RF.registers[2] = 32'h0F;
        execute_one(enc_r(7'b0000000,2,1,3'b110,10,7'b0110011));
        check_reg(10, 32'hFF, "OR");

        // XOR => AA ^ 0F = A5
        DUT.RF.registers[1] = 32'hAA;
        DUT.RF.registers[2] = 32'h0F;
        execute_one(enc_r(7'b0000000,2,1,3'b100,10,7'b0110011));
        check_reg(10, 32'hA5, "XOR");

        // SLL => 1 << 4 = 16
        DUT.RF.registers[1] = 1;
        DUT.RF.registers[2] = 4;
        execute_one(enc_r(7'b0000000,2,1,3'b001,10,7'b0110011));
        check_reg(10, 32'd16, "SLL");

        // SRL => 128 >> 3 = 16
        DUT.RF.registers[1] = 128;
        DUT.RF.registers[2] = 3;
        execute_one(enc_r(7'b0000000,2,1,3'b101,10,7'b0110011));
        check_reg(10, 32'd16, "SRL");

        // SRA => signed 0x80000000 >>> 4 = F8000000
        DUT.RF.registers[1] = 32'h80000000;
        DUT.RF.registers[2] = 4;
        execute_one(enc_r(7'b0100000,2,1,3'b101,10,7'b0110011));
        check_reg(10, 32'hF8000000, "SRA");

        // SLT: -1 < 1 => 1
        DUT.RF.registers[1] = 32'hFFFFFFFF;
        DUT.RF.registers[2] = 1;
        execute_one(enc_r(7'b0000000,2,1,3'b010,10,7'b0110011));
        check_reg(10, 32'd1, "SLT signed comparison");

        // SLTU: 0xFFFFFFFF < 1 unsigned => 0
        DUT.RF.registers[1] = 32'hFFFFFFFF;
        DUT.RF.registers[2] = 1;
        execute_one(enc_r(7'b0000000,2,1,3'b011,10,7'b0110011));
        check_reg(10, 32'd0, "SLTU unsigned comparison");


        // ================================================
        // I-TYPE ALU TESTS
        // ================================================

        $display("\n===== I-TYPE ALU TESTS =====");

        // ADDI: 12 + 5 = 17
        DUT.RF.registers[1] = 12;
        execute_one(enc_i(12'd5, 5'd1, 3'b000, 5'd10, 7'b0010011));
        check_reg(10, 32'd17, "ADDI");

        // SLTI: signed 12 < 20 => 1
        DUT.RF.registers[1] = 12;
        execute_one(enc_i(12'd20, 5'd1, 3'b010, 5'd10, 7'b0010011));
        check_reg(10, 32'd1, "SLTI");

        // SLTIU: unsigned 12 < 20 => 1
        DUT.RF.registers[1] = 12;
        execute_one(enc_i(12'd20, 5'd1, 3'b011, 5'd10, 7'b0010011));
        check_reg(10, 32'd1, "SLTIU");

        // XORI: AA ^ 0F = A5
        DUT.RF.registers[1] = 32'hAA;
        execute_one(enc_i(12'h00F, 5'd1, 3'b100, 5'd10, 7'b0010011));
        check_reg(10, 32'hA5, "XORI");

        // ORI: F0 | 0F = FF
        DUT.RF.registers[1] = 32'hF0;
        execute_one(enc_i(12'h00F, 5'd1, 3'b110, 5'd10, 7'b0010011));
        check_reg(10, 32'hFF, "ORI");

        // ANDI: F0 & 3C = 30
        DUT.RF.registers[1] = 32'hF0;
        execute_one(enc_i(12'h03C, 5'd1, 3'b111, 5'd10, 7'b0010011));
        check_reg(10, 32'h30, "ANDI");

        // SLLI: 1 << 4 = 16
        DUT.RF.registers[1] = 1;
        execute_one(enc_i(12'h004, 5'd1, 3'b001, 5'd10, 7'b0010011));
        check_reg(10, 32'd16, "SLLI");

        // SRLI: 128 >> 3 = 16
        DUT.RF.registers[1] = 128;
        execute_one(enc_i(12'h003, 5'd1, 3'b101, 5'd10, 7'b0010011));
        check_reg(10, 32'd16, "SRLI");

        // SRAI: signed 80000000 >>> 4 = F8000000
        DUT.RF.registers[1] = 32'h80000000;
        execute_one(enc_i(12'h404, 5'd1, 3'b101, 5'd10, 7'b0010011));
        check_reg(10, 32'hF8000000, "SRAI");


        // ================================================
        // U-TYPE TESTS: LUI and AUIPC
        // ================================================

        $display("\n===== U-TYPE TESTS =====");

        // LUI: load 0x12345 into bits [31:12].
        execute_one(32'h12345537); // LUI x10, 0x12345
        check_reg(10, 32'h12345000, "LUI upper immediate");


        // AUIPC at PC = 0:
        // 0 + 0x12345000 = 0x12345000
        execute_one(32'h12345517); // AUIPC x10, 0x12345
        check_reg(10, 32'h12345000, "AUIPC at PC zero");


        // AUIPC at PC = 4:
        // 4 + 0x00012000 = 0x00012004
        execute_at_pc(32'h00012517, 32'h00000004);
        check_reg(10, 32'h00012004, "AUIPC at nonzero PC");


        // ================================================
        // BRANCH TESTS: 6 instructions, taken and not taken
        // ================================================

        $display("\n===== BRANCH TESTS =====");

        // BEQ: equal -> taken
        DUT.RF.registers[1] = 5;
        DUT.RF.registers[2] = 5;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b000));
        check_pc(32'd8, "BEQ taken");

        // BEQ: unequal -> not taken
        DUT.RF.registers[1] = 5;
        DUT.RF.registers[2] = 6;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b000));
        check_pc(32'd4, "BEQ not taken");

        // BNE: unequal -> taken
        DUT.RF.registers[1] = 5;
        DUT.RF.registers[2] = 6;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b001));
        check_pc(32'd8, "BNE taken");

        // BNE: equal -> not taken
        DUT.RF.registers[1] = 5;
        DUT.RF.registers[2] = 5;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b001));
        check_pc(32'd4, "BNE not taken");

        // BLT signed: -1 < 1 -> taken
        DUT.RF.registers[1] = 32'hFFFFFFFF;
        DUT.RF.registers[2] = 1;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b100));
        check_pc(32'd8, "BLT signed taken");

        // BLT signed: 1 < -1 -> false
        DUT.RF.registers[1] = 1;
        DUT.RF.registers[2] = 32'hFFFFFFFF;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b100));
        check_pc(32'd4, "BLT signed not taken");

        // BGE signed: 1 >= -1 -> taken
        DUT.RF.registers[1] = 1;
        DUT.RF.registers[2] = 32'hFFFFFFFF;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b101));
        check_pc(32'd8, "BGE signed taken");

        // BGE signed: -1 >= 1 -> false
        DUT.RF.registers[1] = 32'hFFFFFFFF;
        DUT.RF.registers[2] = 1;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b101));
        check_pc(32'd4, "BGE signed not taken");

        // BLTU unsigned: 1 < 0xFFFFFFFF -> taken
        DUT.RF.registers[1] = 1;
        DUT.RF.registers[2] = 32'hFFFFFFFF;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b110));
        check_pc(32'd8, "BLTU unsigned taken");

        // BLTU unsigned: 0xFFFFFFFF < 1 -> false
        DUT.RF.registers[1] = 32'hFFFFFFFF;
        DUT.RF.registers[2] = 1;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b110));
        check_pc(32'd4, "BLTU unsigned not taken");

        // BGEU unsigned: 0xFFFFFFFF >= 1 -> taken
        DUT.RF.registers[1] = 32'hFFFFFFFF;
        DUT.RF.registers[2] = 1;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b111));
        check_pc(32'd8, "BGEU unsigned taken");

        // BGEU unsigned: 1 >= 0xFFFFFFFF -> false
        DUT.RF.registers[1] = 1;
        DUT.RF.registers[2] = 32'hFFFFFFFF;
        execute_one(enc_b(13'd8, 5'd2, 5'd1, 3'b111));
        check_pc(32'd4, "BGEU unsigned not taken");


        // ================================================
        // JAL / JALR TESTS
        // ================================================

        $display("\n===== JAL / JALR TESTS =====");

        // JAL: PC=0, offset=8 -> target 8, link=4
        execute_jump_at_pc(32'h0080056F, 32'd0); // JAL x10, +8
        check_reg(10, 32'd4, "JAL link address");
        check_pc(32'd8, "JAL jump target");

        // JAL at nonzero PC: PC=4, offset=8 -> target 12, link=8
        execute_jump_at_pc(32'h0080056F, 32'd4);
        check_reg(10, 32'd8, "JAL link at nonzero PC");
        check_pc(32'd12, "JAL target at nonzero PC");

        // JALR: rs1=16, imm=4 -> target 20, link=4
        DUT.RF.registers[1] = 16;
        execute_jump_at_pc(enc_i(12'd4, 5'd1, 3'b000, 5'd10, 7'b1100111), 32'd0);
        check_reg(10, 32'd4, "JALR link address");
        check_pc(32'd20, "JALR jump target");

        // JALR clears bit zero: rs1=17, imm=4 -> raw 21, target 20
        DUT.RF.registers[1] = 17;
        execute_jump_at_pc(enc_i(12'd4, 5'd1, 3'b000, 5'd10, 7'b1100111), 32'd0);
        check_reg(10, 32'd4, "JALR link with odd base");
        check_pc(32'd20, "JALR clears target bit zero");


        // ================================================
        // CUSTOM MAC INSTRUCTION TESTS
        // ================================================

        $display("\n===== MAC TESTS =====");

        // MAC encoding: funct7=0000001, funct3=000,
        // opcode=0001011

        // Test 1: 3 * 4 + 5 = 17
        DUT.RF.registers[1] = 32'd3;
        DUT.RF.registers[2] = 32'd4;
        DUT.RF.registers[10] = 32'd5;

        execute_one(enc_r(7'b0000001, 5'd2, 5'd1,
                          3'b000, 5'd10, 7'b0001011));
        check_reg(10, 32'd17, "MAC basic multiply accumulate");

        // Test 2: Repeated accumulation: 17 + (3 * 4) = 29
        execute_one(enc_r(7'b0000001, 5'd2, 5'd1,
                          3'b000, 5'd10, 7'b0001011));
        check_reg(10, 32'd29, "MAC repeated accumulation");

        // Test 3: Zero operand: 29 + (0 * 4) = 29
        DUT.RF.registers[1] = 32'd0;
        execute_one(enc_r(7'b0000001, 5'd2, 5'd1,
                          3'b000, 5'd10, 7'b0001011));
        check_reg(10, 32'd29, "MAC zero operand");

        // Test 4: Destination x0 must not be overwritten
        DUT.RF.registers[1] = 32'd3;
        DUT.RF.registers[2] = 32'd4;

        execute_one(enc_r(7'b0000001, 5'd2, 5'd1,
                          3'b000, 5'd0, 7'b0001011));
        check_reg(0, 32'd0, "MAC destination x0 remains zero");


        // ================================================
        // CPU-LEVEL BRANCH COUNTER TEST
        // ================================================

        $display("\n===== CPU BRANCH COUNTER TEST =====");

        // Reset counters and PC once
        rst = 1;
        @(posedge clk);
        @(negedge clk);

        // Install BEQ x1, x2, +8
        // Set x1 == x2 so the branch is taken
        DUT.RF.registers[1] = 32'd7;
        DUT.RF.registers[2] = 32'd7;
        DUT.IM.internal_memory[0] =
            enc_b(13'd8, 5'd2, 5'd1, 3'b000);

        rst = 0;
        @(posedge clk);
        @(negedge clk);

        if (DUT.branch_counter !== 32'd1) begin
            $display("FAIL: CPU branch counter expected 1, got %0d",
                     DUT.branch_counter);
            tests_failed = tests_failed + 1;
        end
        else begin
            $display("PASS: CPU branch counter increments once");
            tests_passed = tests_passed + 1;
        end


        // ================================================
        // CPU-LEVEL LOAD COUNTER TEST
        // ================================================

        $display("\n===== CPU LOAD COUNTER TEST =====");

        // Reset CPU and counters once
        rst = 1;
        @(posedge clk);
        @(negedge clk);

        // LW x10, 0(x1)
        DUT.RF.registers[1] = 32'd0;
        DUT.DM.internal_memory[0] = 32'h12345678;
        DUT.IM.internal_memory[0] =
            enc_i(12'd0, 5'd1, 3'b010, 5'd10, 7'b0000011);

        rst = 0;
        @(posedge clk);
        @(negedge clk);

        if (DUT.load_counter !== 32'd1) begin
            $display("FAIL: load counter expected 1, got %0d",
                     DUT.load_counter);
            tests_failed = tests_failed + 1;
        end
        else begin
            $display("PASS: CPU load counter increments once");
            tests_passed = tests_passed + 1;
        end

        check_reg(10, 32'h12345678, "Counter test LW result");


        // CPU-LEVEL STORE COUNTER TEST
        $display("\n===== CPU STORE COUNTER TEST =====");

        rst = 1;
        @(posedge clk);
        @(negedge clk);

        DUT.RF.registers[1] = 32'd0;
        DUT.RF.registers[2] = 32'hDEADBEEF;
       DUT.IM.internal_memory[0] = {
    7'b0000000, 5'd2, 5'd1, 3'b010, 5'd0, 7'b0100011
};

        rst = 0;
        @(posedge clk);
        @(negedge clk);

        if (DUT.store_counter !== 32'd1) begin
            $display("FAIL: store counter expected 1, got %0d",
                     DUT.store_counter);
            tests_failed = tests_failed + 1;
        end else begin
            $display("PASS: CPU store counter increments once");
            tests_passed = tests_passed + 1;
        end


        // CPU-LEVEL MAC COUNTER TEST
        $display("\n===== CPU MAC COUNTER TEST =====");

        rst = 1;
        @(posedge clk);
        @(negedge clk);

        DUT.RF.registers[1] = 32'd3;
        DUT.RF.registers[2] = 32'd4;
        DUT.RF.registers[10] = 32'd5;

        // MAC x10, x1, x2: x10 = x10 + x1*x2 = 17
        DUT.IM.internal_memory[0] = {
            7'b0000001, 5'd2, 5'd1,
            3'b000, 5'd10, 7'b0001011
        };

        rst = 0;
        @(posedge clk);
        @(negedge clk);

        if (DUT.mac_counter !== 32'd1) begin
            $display("FAIL: MAC counter expected 1, got %0d",
                     DUT.mac_counter);
            tests_failed = tests_failed + 1;
        end else begin
            $display("PASS: CPU MAC counter increments once");
            tests_passed = tests_passed + 1;
        end

        check_reg(10, 32'd17, "MAC counter test result");


        // CPU-LEVEL INSTRUCTION COUNTER TEST
        $display("\n===== CPU INSTRUCTION COUNTER TEST =====");

        rst = 1;
        @(posedge clk);
        @(negedge clk);

        DUT.RF.registers[1] = 32'd10;
        DUT.IM.internal_memory[0] =
            enc_i(12'd5, 5'd1, 3'b000, 5'd10, 7'b0010011);

        rst = 0;
        @(posedge clk);
        @(negedge clk);

        if (DUT.inst_counter !== 32'd1) begin
            $display("FAIL: instruction counter expected 1, got %0d",
                     DUT.inst_counter);
            tests_failed = tests_failed + 1;
        end else begin
            $display("PASS: CPU instruction counter increments once");
            tests_passed = tests_passed + 1;
        end

        check_reg(10, 32'd15, "Instruction counter ADDI result");


        // ================================================
        // SUMMARY
        // ================================================

        $display("\n===== REGRESSION SUMMARY =====");
        $display("Passed: %0d", tests_passed);
        $display("Failed: %0d", tests_failed);
        $display("Total : %0d", tests_passed + tests_failed);

        if (tests_failed != 0)
            $fatal(1, "CPU regression failed");
        else begin
            $display("CPU regression passed");
            $finish;
        end
    end

endmodule
