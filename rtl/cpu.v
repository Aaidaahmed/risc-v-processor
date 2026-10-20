`include "cpu_defines.v"

module cpu(
    input clk,
    input rst
);

//////////////////////////////////////////////////////////////////////////////////////////////////////

//IF STAGE - INSTRUCTION FETCH

wire [31:0]pc_out; //PC -> Instruction Memory -> Decoder
wire [31:0]next_pc;
wire [31:0]instruction;

program_counter PC(
    .clk(clk),
    .rst(rst),
    .pc_out(pc_out),
    .next_pc(next_pc)
);

instruction_memory IM(
    .address(pc_out),
    .instruction(instruction)
);

////////////////////////////////////////////////////////////////////////////////////////////////////////

//ID STAGE - INSTRUCTION DECODE

wire [3:0]alu_op;
wire [2:0]imm_type;
wire alu_a_sel;
wire alu_src;
wire reg_write;
wire mem_write;
wire mem_read;
wire [2:0]wb_sel;
wire branch;
wire jump;
wire [1:0] mem_size;
wire load_unsigned;

decoder DEC(
    .instruction(instruction),

    .alu_op(alu_op),
    .alu_a_sel(alu_a_sel),
    .imm_type(imm_type),

    .alu_src(alu_src),

    .reg_write(reg_write),

    .mem_write(mem_write),
    .mem_read(mem_read),
    .wb_sel(wb_sel),

    .branch(branch),
    .jump(jump),
    .jump_reg(jump_reg),

    .mem_size(mem_size),
    .load_unsigned(load_unsigned)
);


wire [4:0]rs1;
wire [4:0]rs2;
wire [4:0]rd;
wire [4:0]rd_read;

assign rs1 = instruction[19:15];
assign rs2 = instruction[24:20];
assign rd  = instruction[11:7];

wire [31:0]read_data1;
wire [31:0]read_data2;
wire [31:0]read_data3;


register_file RF(
    .clk(clk),
    .write_enable(reg_write),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .rd_read(rd),
    .write_data(write_data),
    .read_data1(read_data1),
    .read_data2(read_data2),
    .read_data3(read_data3)
);

wire [31:0]immediate;
immediate_generator IMM_GEN(
    .instruction(instruction),
    .imm_type(imm_type),
    .immediate(immediate)
);

wire [31:0]operand_a;
wire [31:0]operand_b;
assign operand_a = (alu_a_sel)? pc_out : read_data1;
assign operand_b = (alu_src)? immediate : read_data2;

wire [31:0]alu_result;
alu ALU(
    .operand_a(operand_a),
    .operand_b(operand_b),
    .alu_op(alu_op),
    .result(alu_result)
);

wire [31:0]memory_data;
reg [31:0]write_data;
wire mem_write_dm;
wire mem_read_dm;
wire [31:0]load_result;


assign mem_write_dm = mem_write && !gpio_selected;
assign mem_read_dm = mem_read && !gpio_selected;


assign load_result =
    (mem_size == `MEM_BYTE) ?
        (load_unsigned ? {24'b0, memory_data[7:0]} :
                         {{24{memory_data[7]}}, memory_data[7:0]}) :
    (mem_size == `MEM_HALFWORD) ?
        (load_unsigned ? {16'b0, memory_data[15:0]} :
                         {{16{memory_data[15]}}, memory_data[15:0]}) :
        memory_data;



data_memory DM(
    .clk(clk),
    .address(alu_result),
    .write_data(read_data2),
    .write_enable(mem_write_dm),
    .read_data(memory_data),
    .mem_size(mem_size)
);

wire branch_taken;
wire [2:0]funct3;
assign funct3 = instruction[14:12];
wire jump_reg;

branch_unit BU(
    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .funct3(funct3),
    .branch_taken(branch_taken)
);

wire [31:0]branch_address;
assign branch_address = pc_out + immediate;

assign next_pc = (branch && branch_taken) ? branch_address : (jump) ? branch_address : jump_reg ? alu_result : (pc_out + 4);

always @(*)begin
    case(wb_sel)
        `WB_ALU:
            write_data = alu_result;
        `WB_MEM:
            begin
                if(gpio_selected)
                    write_data = gpio_read_data;
                else
                    write_data = load_result;
            end
        `WB_IMM:
            write_data = immediate;
        `WB_PC4:
            write_data = pc_out + 4;
        `WB_MAC:
            write_data = mac_result;
        default:
            write_data = 32'd0;
    endcase
end

wire [31:0]mac_result;
wire [6:0]funct7;

assign funct7 = instruction[31:25];

custom_execution_unit CEU(
    .rs1_data(read_data1),
    .rs2_data(read_data2),
    .rd_data(read_data3),
    .funct3(funct3),
    .funct7(funct7),
    .result(mac_result)
);

wire [31:0]cycle_counter;
wire [31:0]inst_counter;
wire [31:0]load_counter;
wire [31:0]store_counter;
wire [31:0]branch_counter;
wire [31:0]mac_counter;

wire instruction_valid;
wire mac_executed;

assign instruction_valid = (^instruction !== 1'bx);
assign mac_executed = (wb_sel == `WB_MAC) && reg_write;

csr_unit CSR(
    .clk(clk),
    .rst(rst),

    .instruction_valid(instruction_valid),
    
    .mem_read(mem_read),
    .mem_write(mem_write),

    .branch_taken(branch && branch_taken),

    .mac_executed(mac_executed),

    .cycle_counter(cycle_counter),
    .inst_counter(inst_counter),
    .load_counter(load_counter),
    .store_counter(store_counter),
    .branch_counter(branch_counter),
    .mac_counter(mac_counter)
    );

wire [31:0]gpio_read_data;
wire [31:0]gpio_out;
wire gpio_selected;

assign gpio_selected = (alu_result == 32'h10000000)||(alu_result == 32'h10000004);

gpio GPIO(
    .clk(clk),
    .write_enable(mem_write && gpio_selected),
    .read_enable(mem_read && gpio_selected),
    .address(alu_result),
    .write_data(read_data2),
    .read_data(gpio_read_data),
    .gpio_out(gpio_out)
);

endmodule