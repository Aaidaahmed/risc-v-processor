`include "cpu_defines.v"

module branch_unit(
    input [31:0]rs1_data,
    input [31:0]rs2_data,
    input [2:0]funct3,

    output reg branch_taken
);

always@(*)begin
    case(funct3)
    `BEQ:
    begin
        branch_taken = (rs1_data == rs2_data);//Branch if equal
    end
    `BNE:
    begin
        branch_taken = (rs1_data != rs2_data);//Branch if not equal
    end
    `BLT:
    begin
       branch_taken = ($signed(rs1_data) < $signed(rs2_data));//Branch less than 
    end
    `BGE:
    begin
       branch_taken = ($signed(rs1_data) >= $signed(rs2_data));//Branch greater than or equal 
    end
    `BLTU:
    begin
        branch_taken = (rs1_data < rs2_data);//Branch less than unsigned
    end
    `BGEU:
    begin
        branch_taken = (rs1_data >= rs2_data);//Branch greater than or equal unsigned
    end
    default:
    begin
        branch_taken = 1'b0;
    end
    endcase
    // Debug print
    $display("funct3=%b rs1=%d rs2=%d branch_taken=%b",
             funct3, rs1_data, rs2_data, branch_taken);
end
endmodule