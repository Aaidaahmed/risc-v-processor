module branch_unit_tb;

wire branch_taken ;

reg [31:0]rs1_data;
reg [31:0]rs2_data;
reg [2:0]funct3;

branch_unit DUT(
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .funct3(funct3),
    .branch_taken(branch_taken)
);

task check_branch_unit;
    input expected_branch_taken;
    input [20*8-1:0]branch_inst_name;
    begin
        if(expected_branch_taken != branch_taken)
        begin
            $display("FAIL: %s Expected = %h Got = %h", branch_inst_name, expected_branch_taken, branch_taken);
        end
        else
        begin
            $display("PASS: %s Expected = %h Got = %h", branch_inst_name, expected_branch_taken, branch_taken);
        end
    end
endtask

initial 
begin
    //BEQ
    rs1_data = 32'd10;
    rs2_data = 32'd10;
    funct3 = `BEQ;
    #1;
    check_branch_unit(1'b1,"BEQ");
    #1;

    rs1_data = 32'd10;
    rs2_data = 32'd20;
    funct3 = `BEQ;
    #1;
    check_branch_unit(1'b0,"BEQ");
    #1;
//-------------------------------------------------------
    //BNE
    rs1_data = 32'd10;
    rs2_data = 32'd35;
    funct3 = `BNE;
    #1;
    check_branch_unit(1'b1,"BNE");
    #1;

    rs1_data = 32'd10;
    rs2_data = 32'd10;
    funct3 = `BNE;
    #1;
    check_branch_unit(1'b0,"BNE");
    #1;
//----------------------------------------------------------
    //BLT
    rs1_data = -5;
    rs2_data = 6;
    funct3 = `BLT;
    #1;
    check_branch_unit(1'b1,"BLT");
    #1;

    rs1_data = -1;
    rs2_data = -1;
    funct3 = `BLT;
    #1;
    check_branch_unit(1'b0,"BLT");
    #1;

    rs1_data = -3;
    rs2_data = -5;
    funct3 = `BLT;
    #1;
    check_branch_unit(1'b0,"BLT");
    #1;
//----------------------------------------------------------
    //BGE
    rs1_data = 10;
    rs2_data = -1;
    funct3 = `BGE;
    #1;
    check_branch_unit(1'b1,"BGE");
    #1;

    rs1_data = 0;
    rs2_data = 0;
    funct3 = `BGE;
    #1;
    check_branch_unit(1'b1,"BGE");
    #1;

    rs1_data = -1;
    rs2_data = 1;
    funct3 = `BGE;
    #1;
    check_branch_unit(1'b0,"BGE");
    #1;
//----------------------------------------------------------
    //BLTU
    rs1_data = 32'd10;
    rs2_data = 32'd13;
    funct3 = `BLTU;
    #1;
    check_branch_unit(1'b1,"BLTU");
    #1;

    rs1_data = 32'd10;
    rs2_data = 32'd10;
    funct3 = `BLTU;
    #1;
    check_branch_unit(1'b0,"BLTU");
    #1;

    rs1_data = 32'd10;
    rs2_data = 32'd5;
    funct3 = `BLTU;
    #1;
    check_branch_unit(1'b0,"BLTU");
    #1;
//----------------------------------------------------------
    //BGEU
    rs1_data = 32'd20;
    rs2_data = 32'd13;
    funct3 = `BGEU;
    #1;
    check_branch_unit(1'b1,"BGEU");
    #1;

    rs1_data = 32'd10;
    rs2_data = 32'd10;
    funct3 = `BGEU;
    #1;
    check_branch_unit(1'b1,"BGEU");
    #1;

    rs1_data = 32'd10;
    rs2_data = 32'd50;
    funct3 = `BGEU;
    #1;
    check_branch_unit(1'b0,"BGEU");
    #1;
//----------------------------------------------------------
end
endmodule