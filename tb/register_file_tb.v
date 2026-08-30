module register_file_tb;

reg clk;
reg write_enable;

reg [4:0]rs1;
reg [4:0]rs2;
reg [4:0]rd;

reg [31:0]write_data;

wire [31:0]read_data1;
wire [31:0]read_data2;

//Instantiate DUT

register_file DUT(
    .clk(clk),
    .write_enable(write_enable),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .write_data(write_data),
    .read_data1(read_data1),
    .read_data2(read_data2)
);

task check_register_file;
    input [31:0]expected_read_data1;
    input [31:0]expected_read_data2;
    input [20*8-1:0]test_name;
    begin
        if((expected_read_data1 == read_data1) && (expected_read_data2 == read_data2))
        begin
            $display("PASS: %s - Expected read_data1 = %0d Got = %0d | Expected read_data2 = %0d Got = %0d ",
            test_name, expected_read_data1, read_data1, expected_read_data2, read_data2 );
        end
        else
        begin
            if(expected_read_data1 != read_data1)
            begin
                $display("FAIL: %s - Expected read_data1 = %0d Got = %0d", test_name, expected_read_data1, 
                read_data1);
            end
            if(expected_read_data2 != read_data2)
            begin
                $display("FAIL: %s - Expected read_data2 = %0d Got = %0d", test_name, expected_read_data2, 
                read_data2);
            end
        end

    end
endtask

//Clock generator
initial begin
    clk = 0;
    forever #5 clk = ~clk; 
end

initial begin
    $dumpfile("waves/register_file.vcd");
    $dumpvars(0, register_file_tb);
end

initial 
begin
    //Initialize signals
    rs1 = 5'b0;
    rs2 = 5'b0;
    rd  = 5'b0;
    write_enable = 0;
    write_data   = 0;
    #2;

    //TEST 1 - Write to x5 and read x5
    $display("\n========== TEST 1 ==========");
    rd = 5'd5;
    write_data = 32'd100;
    write_enable = 1;
    @(posedge clk);
        #1;// this is to avoid race condition. both always@(posedge clk) and @(posedge clk) run at the same time
        //so we give the simulator some time to process the values
        write_enable = 0;
        rs1 = 32'd5;
        rs2 = 32'd0;
        #1;
        check_register_file(100,0,"Write to x5");
        #10;

    //TEST 2 - Write to another register reg 16
    $display("\n========== TEST 2 ==========");
    rd = 32'd16;
    write_enable = 1;
    write_data = 32'd55;
    @(posedge clk);
        #1;
        write_enable = 0;
        rs1 = 32'd16;//not mentioning rs2 here since it is already initialized to 0
        #1;
        check_register_file(55,0,"Write to x16"); 
        #10;

    //TEST 3 - Dual Read ex: add x7,x20,x12;
    $display("\n========== TEST 3 ==========");
    rd = 32'd20;
    write_enable = 1;
    write_data = 32'd90;
    @(posedge clk);
    #1;
    rd = 32'd12;
    write_data = 32'd25;
    @(posedge clk);
        #1;
        write_enable = 0;
        rs1 = 32'd20;
        rs2 = 32'd12;
        #1;
        check_register_file(90,25,"Dual read"); 

    //TEST 4 - Write to x0
    $display("\n========== TEST 4 ==========");
    rd = 0;
    write_data = 32'd200;
    write_enable = 1;
    @(posedge clk);
        #1;
        write_enable = 0;
        rs1 = 32'd0;
        rs2 = 32'd0;
        #1;
        check_register_file(0,0,"Write to x0");
        #10;

    //TEST 5 - Read x0;
    $display("\n========== TEST 5 ==========");
    rs1 = 32'd0;
    rs2 = 32'd0;
    #1;
    check_register_file(0,0,"Read x0");
    #5;
    $finish;
end
endmodule