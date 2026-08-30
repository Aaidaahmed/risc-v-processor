`include "cpu_defines.v"

module alu_tb;

//inputs to DUT - reg type
reg [31:0]operand_a;
reg [31:0]operand_b;
reg [3:0]alu_op;

//outputs of DUT - wire type
wire [31:0]result;

//DUT instantiation
alu DUT(
    .operand_a(operand_a),
    .operand_b(operand_b),
    .alu_op(alu_op),
    .result(result)
);

task check_alu;
    input signed [31:0]expected_result;
    input [8*8-1:0]test_name;
    begin
        if(result != expected_result)
        begin
            $display("FAIL : %s | Expected : %0d (0x%08h) | Got : %0d (0x%08h)",test_name ,
            $signed(expected_result) ,expected_result ,$signed(result) ,result);
        end
        else
        begin
            $display("PASS : %s | Expected : %0d (0x%08h) | Got : %0d (0x%08h)",test_name ,
            $signed(expected_result) ,expected_result ,$signed(result) ,result);
        end
    end
endtask

initial
begin
    $dumpfile("waves\\alu.vcd");
    $dumpvars(0,alu_tb);

    //$monitor("time = %0t | result = %b", $time, result);

    operand_a = 32'd10;
    operand_b = 32'd20;

    alu_op = `ALU_ADD;
    #1;
    check_alu(32'd30,"ADD");

    alu_op = `ALU_SUB;
    #1;
    check_alu(-32'sd10,"SUB");

    alu_op = `ALU_AND;
    #1;
    check_alu(32'd0,"AND");

    alu_op = `ALU_OR;
    #1;
    check_alu(32'd30,"OR");

    alu_op = `ALU_XOR;
    #1;
    check_alu(32'd30,"XOR");

    alu_op = `ALU_SLL;
    #1;
    check_alu(32'h00A00000,"SLL");

    alu_op = `ALU_SRL;
    #1;
    check_alu(32'b0,"SRL");

    alu_op = `ALU_SLT;
    #1;
    check_alu(32'b1,"SLT");

    alu_op = `ALU_SLTU;
    #1;
    check_alu(32'b1,"SLTU");

    alu_op = `ALU_SRA;
    #1;
    check_alu(32'b0,"SRA");

    $finish;
end
endmodule