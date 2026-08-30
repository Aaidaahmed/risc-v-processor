module program_counter_tb;

//signal declarations
reg clk;
reg rst;
reg [31:0] next_pc;
wire [31:0] pc_out;
// if testbench drives the values it is reg type
// if DUT drives the value it is wire type.
// since clk, rst, next_pc are inputs driven by
// tb it is reg. 
// we observe the pc_out which is why it is wire type.

//DUT Instantiation
program_counter DUT(
    .clk(clk),
    .rst(rst),
    .next_pc(next_pc),
    .pc_out(pc_out)
);
/* what we did here is create instances. first we 
let the tb know which module we are testing , hence
module name foll by DUT which is device under test
next we create instances for the prots used in that
module*/


//Clock generator
initial begin
    clk = 0;
end

always begin
    #5 clk = ~clk;
end


//Test sequence
initial begin
    rst = 1;
    next_pc = 32'h00000000;
    #10;
    rst = 0;
    next_pc = 32'h00000004;
    #10;
    next_pc = 32'h00000008;
    #10;
    next_pc = 32'h0000000C;
    #10;
    next_pc = 32'h00000010;
    #10;


//End simulation
$finish;
end

initial begin
    $dumpfile("waves/program_counter.vcd");
    $dumpvars(0, program_counter_tb);
end
initial begin
    $monitor("time = %0t, rst = %b, next_pc = %h, pc_out = %h", $time, rst, next_pc, pc_out);
end

endmodule
