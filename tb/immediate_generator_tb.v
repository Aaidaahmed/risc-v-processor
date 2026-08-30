`include "cpu_defines.v"

module immediate_generator_tb;

reg [31:0]instruction;
reg [2:0]imm_type;

wire [31:0]immediate;

immediate_generator DUT(
    .instruction(instruction),
    .imm_type(imm_type),
    .immediate(immediate)
);

initial begin
    $dumpfile("waves/immediate_generator.vcd");
    $dumpvars(0,immediate_generator_tb);
end

task check_immediate_generator;
    input [31:0]expected_immediate;
    input [20*8-1:0]type;

    begin
        if(expected_immediate != immediate)
        begin
            $display("FAIL: %s Expected = %h Got = %h", type, expected_immediate, immediate);
        end
        else
        begin
            $display("PASS: %s Expected = %h Got = %h", type, expected_immediate, immediate);
        end
    end
endtask

initial
begin
    
    //I-TYPE
    instruction = 32'b000000010100_00000_000_00000_0010011;//immediate=20 rs1=0 funct3=000 rd=0 opcode=001011
    imm_type = `IMM_I;
    #1;
    check_immediate_generator(32'd20, "I-TYPE");
    #2;

    //S-TYPE
    instruction = 32'b0000000_00100_00001_000_10100_0100011;//immediate=20(7bits) rs2=3 rs1=1 funct3=000 immediate=4(5bits) opcode=001011//0000000_10100
    imm_type = `IMM_S;
    #1;
    check_immediate_generator(32'd20 , "S-TYPE");
    #2;

    //U-TYPE
    instruction = 32'b00000000000000010100_00000_0110111;//immediate=0_00000000000_00010100_000000000000 rd=0 opcode=0110111
    imm_type = `IMM_U;
    #1;
    check_immediate_generator(32'h00014000, "U-TYPE");
    #2;

    //B-TYPE
    instruction = 32'b0_000000_00010_00001_000_0100_0_1100011;//immediate=(1bit) immediate=(6bits) rs2=2 rs1=1 funct3=000 immediate=(4bits) immediate=(1bit)opcode=001011 
    //immediate = 32'd20 = 00 00000 00000 00000 00000 00000 10100
    //B -0
    imm_type = `IMM_B;
    #1;
    check_immediate_generator(32'd8, "B-TYPE");
    #2;

    //J-TYPE
    instruction = 32'b0_0000001010_0_00000000_00000_1101111;//immediate=(1bit) immediate=(10bits) immediate=(1bit) immediate=00000000(8bits) rd=5 opcode=001011
    imm_type = `IMM_J;
    #1;
    check_immediate_generator(32'd20, "J-TYPE");
    #2;

    //NONE-TYPE
    instruction = 32'hDEADBEEF;//immediate=20 rs1=0 funct3=000 rd=0 opcode=001011
    imm_type = `IMM_NONE;
    #1;
    check_immediate_generator(32'b0, "NONE-TYPE");

    #10;
    $finish;
end

endmodule