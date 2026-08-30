`include "cpu_defines.v"
module custom_execution_unit(
    input [31:0]rs1_data,
    input [31:0]rs2_data,
    input [31:0]rd_data,

    input [2:0]funct3,
    input [6:0]funct7,

    output reg[31:0]result
);

always @(*)begin
result = 32'd0;
$display("CEU: funct7=%b funct3=%b rs1=%0d rs2=%0d rd=%0d",
             funct7, funct3, rs1_data, rs2_data, rd_data);
    case({funct7,funct3})

        {`MAC_FUNCT7, `MAC_FUNCT3}:
        begin
            result = rd_data + (rs1_data * rs2_data);
            $display("MAC EXECUTED result=%0d", result);
        end
        default:
        begin
            result = 32'd0;
        end
    endcase
end
endmodule