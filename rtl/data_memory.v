`include "cpu_defines.v"

module data_memory(
    input clk,
    input [31:0] address,
    input [31:0] write_data,
    input write_enable,
    input [1:0] mem_size,
    output reg [31:0] read_data
);

reg [31:0] internal_memory [0:255];

// Read logic: select byte, halfword, or word
always @(*) begin
    case (mem_size)
        `MEM_BYTE: begin
            read_data =
                (internal_memory[address[31:2]] >>
                (8 * address[1:0])) & 32'h000000FF;
        end

        `MEM_HALFWORD: begin
            if (address[0] == 1'b0)
                read_data =
                    (internal_memory[address[31:2]] >>
                    (16 * address[1])) & 32'h0000FFFF;
            else
                read_data = 32'b0;
        end

        `MEM_WORD: begin
            read_data = internal_memory[address[31:2]];
        end

        default: read_data = 32'b0;
    endcase
end

// Write logic: update only the selected byte lanes
always @(posedge clk) begin
    if (write_enable) begin
        case (mem_size)

            `MEM_BYTE: begin
                case (address[1:0])
                    2'b00: internal_memory[address[31:2]][7:0]
                                <= write_data[7:0];
                    2'b01: internal_memory[address[31:2]][15:8]
                                <= write_data[7:0];
                    2'b10: internal_memory[address[31:2]][23:16]
                                <= write_data[7:0];
                    2'b11: internal_memory[address[31:2]][31:24]
                                <= write_data[7:0];
                endcase
            end

            `MEM_HALFWORD: begin
                if (address[0] == 1'b0) begin
                    if (address[1] == 1'b0)
                        internal_memory[address[31:2]][15:0]
                            <= write_data[15:0];
                    else
                        internal_memory[address[31:2]][31:16]
                            <= write_data[15:0];
                end
            end

            `MEM_WORD: begin
                if (address[1:0] == 2'b00)
                    internal_memory[address[31:2]] <= write_data;
            end

            default: begin
                // Unsupported access size: no write
            end
        endcase
    end
end

endmodule


//why instruction memory need no clk while data mem does
/*Instruction Memory
Read-only during execution.
Never modified.
Doesn't need a clock.
Output changes only because the address (PC) changes.

Data Memory
Must support writes (sw).
Writing changes the stored contents.
We want writes to happen only on a clock edge.
Therefore it needs a clock.*/