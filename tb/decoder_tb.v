`include "cpu_defines.v"


module decoder_tb;
//all inputs become reg. something that drives the module
//all outputs become wire

// Inputs (driven by the testbench)
reg [31:0]instruction;

// Outputs (driven by the DUT)
wire [3:0]alu_op;
wire alu_src;
wire reg_write;
wire mem_write;
wire mem_read;
wire branch;
wire jump;
wire [2:0]imm_type;


//Instantiate DUT
decoder DUT(
    .instruction(instruction),
    .alu_op(alu_op),
    .alu_src(alu_src),
    .reg_write(reg_write),
    .mem_write(mem_write),
    .mem_read(mem_read),
    .branch(branch),
    .jump(jump),
    .imm_type(imm_type)
);

//task checker
/*SYNTAX
task task_name;
    inputs;
    begin
    end
endtask*/
task check_decoder;

    integer error;

    input [3:0]expected_alu_op;
    input expected_alu_src;
    input expected_reg_write;
    input expected_mem_read;
    input expected_mem_write;
    input expected_branch;
    input expected_jump;
    input [2:0]expected_imm_type;

    begin

        error = 0;//no error

        if(alu_op != expected_alu_op)
        begin
            error = 1;
            $display("Failed: alu_op incorrect");
        end
        if(alu_src != expected_alu_src)
        begin
            error = 1;
            $display("Failed: alu_src incorrect");
        end
        if(reg_write != expected_reg_write)
        begin
            error = 1;
            $display("Failed: reg_write incorrect");
        end
        if(mem_write != expected_mem_write)
        begin
            error = 1;
            $display("Failed: mem_write incorrect");
        end
        if(mem_read != expected_mem_read)
        begin
            error = 1;
            $display("Failed: mem_read incorrect");
        end
        if(branch != expected_branch)
        begin
            error = 1;
            $display("Failed: branch incorrect");
        end
        if(jump != expected_jump)
        begin
            error = 1;
            $display("Failed: jump incorrect");
        end
        if(imm_type != expected_imm_type)
        begin
            error = 1;
            $display("Failed: imm_type incorrect");
        end

        if(error == 0)
        begin
            $display("PASS: The decoder outout matches the expected values");
        end
        if(error == 1)
        begin
            $display("FAILED");
        end
    end
endtask

initial 
begin

    $dumpfile("waves/decoder.vcd");
    $dumpvars(0,decoder_tb);


    $monitor("Time=%0t|instruction=%h|alu_op=%b|alu_src=%b|reg_write=%b|mem_read=%b|mem_write=%b|branch=%b|jump=%b|imm_type=%b",
    $time,
    instruction,
    alu_op,
    alu_src,
    reg_write,
    mem_read,
    mem_write,
    branch,
    jump,
    imm_type);

    //instr = ADD x5,x8,x6;
    instruction = {
        7'b0000000,//funct7
        5'd6,//rs2 = x6
        5'd8,//rs1 = x8
        3'b000,//funct3
        5'd5,//rd = x5
        7'b0110011//opcode
    };

    #10;

    //task checker - mthd3 of self checking
    check_decoder(
        `ALU_ADD,
        1'b0,
        1'b1,
        1'b0,
        1'b0,
        1'b0,
        1'b0,
        `IMM_NONE
    );
    
    
    $finish;
    
    /*//self checking tb - mthd1 (very straighforward, but does not tell us which signal failed)
    if(alu_op == ALU_add && alu_src == 1'b0 && reg_write == 1'b1 && mem_read == 1'b0 && mem_write == 1'b0 &&
    branch == 1'b0 && jump == 1'b0 && imm_type == IMM_NONE)
    begin
        $display("PASS: ADD decoded successfully");
    end
    else
    begin
        $display("FAIL: ADD decode failed");
    end

    // mthd2(extensive but tells us which signal failed)
    if(alu_op != ALU_add)
    begin
        $display("FAIL: alu_op incorrect");
    end
    if(alu_src != 1'b0)
    begin
        $display("FAIL: alu_src incorrect");
    end
    if(reg_write != 1'b1)
    begin
        $display("FAIL: reg_write incorrect");
    end
    if(mem_read != 1'b0)
    begin
        $display("FAIL: mem_read incorrect");
    end
    if(mem_write != 1'b0)
    begin
        $display("FAIL: mem_write incorrect");
    end
    if(branch != 1'b0)
    begin
        $display("FAIL: branch incorrect");
    end
    if(jump != 1'b0)
    begin
        $display("FAIL: jump incorrect");
    end
    if(imm_type != IMM_NONE )
    begin
        $display("FAIL: imm_type incorrect");
    end*/

    //mthd3 - professional, and clear

end
endmodule