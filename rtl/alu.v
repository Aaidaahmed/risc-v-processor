`include "cpu_defines.v"

module alu(
    input [31:0]operand_a,
    input [31:0]operand_b,
    input [3:0]alu_op,
    output reg[31:0] result 
);

always@(*)begin
    case(alu_op)
    `ALU_ADD:
    begin
        result = operand_a + operand_b;
    end
    `ALU_SUB:
    begin
        result = operand_a - operand_b;
    end
    `ALU_AND:
    begin
        result = operand_a & operand_b;
    end
    `ALU_OR:
    begin
        result = operand_a | operand_b;
    end
    `ALU_XOR:
    begin
        result = operand_a ^ operand_b;
    end
    `ALU_SLL:
    begin
        result = operand_a << operand_b[4:0];
    end
    `ALU_SRL:
    begin
        result = operand_a >> operand_b[4:0];
    end
    `ALU_SRA:
    begin
        result = $signed(operand_a) >>> operand_b[4:0];
    end
    `ALU_SLTU:
    begin
        result = (operand_a < operand_b) ? 32'd1 : 32'd0;
    end
    `ALU_SLT:
    begin
        result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
    end
    default:
    begin
        result = 32'b0;
    end
    endcase
end//combinational block

endmodule