`include "cpu_defines.v"

module immediate_generator(
    input [31:0]instruction,
    input [2:0]imm_type,

    output reg[31:0]immediate
);

always@(*)begin
    case(imm_type)
    `IMM_I:
    begin
        immediate = {{20{instruction[31]}},
                    instruction[31:20]};
    end
    `IMM_S:
    begin
        immediate = {{20{instruction[31]}},
                    instruction[31:25],
                    instruction[11:7]};
    end
    `IMM_B:
    begin
        immediate = {{19{instruction[31]}},
                    instruction[31],
                    instruction[7],
                    instruction[30:25],
                    instruction[11:8],
                    1'b0};
    end
    `IMM_U:
    begin
        immediate = {instruction[31:12],12'b0};
    end
    `IMM_J:
    begin
        immediate = {{11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0};
    end
    `IMM_NONE:
    begin
        immediate = 32'b0;
    end
    default:
    begin
        immediate = 32'b0;
    end
    endcase
end
endmodule