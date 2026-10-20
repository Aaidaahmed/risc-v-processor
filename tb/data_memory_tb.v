`include "cpu_defines.v"

module data_memory_tb;
reg clk;
reg [31:0]address;
reg [31:0]write_data;
reg write_enable;
reg [1:0] mem_size;

wire [31:0]read_data;

data_memory DUT(
    .clk(clk),
    .address(address),
    .write_data(write_data),
    .write_enable(write_enable),
    .read_data(read_data),
    .mem_size(mem_size)
);

initial 
begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial
begin
    $monitor("Time=%0t | clk=%b | address=%0d | write_enable=%b | write_data=%h | read_data=%h",
             $time,
             clk,
             address,
             write_enable,
             write_data,
             read_data);
end

initial
begin
    $dumpfile("waves/data_memory.vcd");
    $dumpvars(0,data_memory_tb);
end

initial
begin
    //READ TEST 
    DUT.internal_memory[0] = 32'hFEEDCEED;
    DUT.internal_memory[1] = 32'hDEDD000D;

    //default val
    mem_size = `MEM_WORD;
    write_enable = 0;
    write_data = 0;

    address = 0;
    #10;

    address = 4;
    #10;

    //WRITE TEST 
    address = 8;
    write_data = 32'hAAAAAAAA;
    write_enable = 1;
    @(posedge clk);
    #1;
    write_enable = 0;
    address = 8;
    #10;

    // ========================================
    // BYTE WRITE AND READ TEST
    // ========================================
    $display("\n--- BYTE ACCESS TEST ---");

    @(negedge clk);
    address = 8;
    mem_size = `MEM_BYTE;
    write_data = 32'h000000AB;
    write_enable = 1'b1;

    @(negedge clk);
    write_enable = 1'b0;
    #1;

    if (read_data !== 32'h000000AB)
        $display("FAIL: Byte read, expected 000000AB, got %h", read_data);
    else
        $display("PASS: Byte write/read");

    // ========================================
    // HALFWORD WRITE AND READ TEST
    // ========================================
    $display("\n--- HALFWORD ACCESS TEST ---");

    @(negedge clk);
    address = 10;
    mem_size = `MEM_HALFWORD;
    write_data = 32'h00001234;
    write_enable = 1'b1;

    @(negedge clk);
    write_enable = 1'b0;
    #1;

    if (read_data !== 32'h00001234)
        $display("FAIL: Halfword read, expected 00001234, got %h", read_data);
    else
        $display("PASS: Halfword write/read");

    // ========================================
    // PARTIAL WRITE PRESERVATION TEST
    // ========================================
    $display("\n--- BYTE PRESERVATION TEST ---");

    @(negedge clk);
    address = 8;
    mem_size = `MEM_WORD;
    write_enable = 1'b0;
    #1;

    if (read_data !== 32'h1234AAAB)
        $display("FAIL: Expected 1234AAAB, got %h", read_data);
    else
        $display("PASS: Partial writes preserved neighboring bytes");
    $finish;
end
endmodule