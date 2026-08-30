module data_memory_tb;
reg clk;
reg [31:0]address;
reg [31:0]write_data;
reg write_enable;

wire [31:0]read_data;

data_memory DUT(
    .clk(clk),
    .address(address),
    .write_data(write_data),
    .write_enable(write_enable),
    .read_data(read_data)
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
    $finish;
end
endmodule