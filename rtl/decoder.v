`include "cpu_defines.v"

//NEED TO COMPLETE OTHER INSTRUCTION TYPES **DON'T FORGETTTTTT!!!!!!!!!!**
module decoder(
    
    //INPUT DECLARATION
    input [31:0]instruction,/*input is automatically wire by default. its ok to mention
    or to not mention it*/

    //OUTPUT DECLARATION

    //ALU controls
    output reg[3:0]alu_op,/*since the o/p alu is a signal the decoder produces, and since it
    is going to be mentioned inside the always block it if of reg type*/

    output reg alu_a_sel,

    //This is the MUX o/p for the alu. to differentiate between the r and i type instructions 
    /* alu_src = 0 -> select rs2
    alu_src = 1 -> select Immediate*/
    output reg alu_src,

    //Immediate controls
    output reg[2:0]imm_type,

    //Register controls
    output reg reg_write,

    //Memory controls
    output reg mem_read,
    output reg mem_write,

    //Write back control
    output reg [2:0]wb_sel,

    //PC controls
    output reg branch,
    output reg jump,
    output reg jump_reg,

    // 0000
    output reg [1:0] mem_size,
    output reg load_unsigned
);

/*Instruction
      │
      ▼
Extract fields
      │
      ▼
Identify instruction
      │
      ▼
Generate control signals*/

/*1. Declare internal wires
        ↓
2. Assign instruction fields
        ↓
3. always @(*)
        ↓
4. Give default values
        ↓
5. case(opcode)
        ↓
6. Nested case(funct3/funct7) if needed*/

//ALU operations encoding - user defined.
/*for the alu module we need these exact localparams, one mthd is to duplicate them there
other method is to use 'include. make sure to use the 2nd method because it is more profess.
(Common in Verilog.) or
Put them in a SystemVerilog package and import them. (Modern and scalable.)*/

// we wont be using the local params anymore, because we advanced to the`include file
/*localparam ALU_ADD  = 4'b0000;
localparam ALU_SUB  = 4'b0001; 
localparam ALU_AND  = 4'b0010; 
localparam ALU_OR   = 4'b0011; 
localparam ALU_XOR  = 4'b0100; 
localparam ALU_SLL  = 4'b0101; 
localparam ALU_SRL  = 4'b0110; 
localparam ALU_SRA  = 4'b0111; 
localparam ALU_SLT  = 4'b1000; 
localparam ALU_SLTU = 4'b1001;  

//WE HAVE TO ALSO DECLARE IMM_TYPE
localparam IMM_NONE = 3'b000;
localparam IMM_I    = 3'b001;
localparam IMM_S    = 3'b010;
localparam IMM_B    = 3'b011;
localparam IMM_U    = 3'b100;
localparam IMM_J    = 3'b101;*/

//DECLARE INTERNAL WIRES
wire [6:0]opcode;
wire [4:0]rd;
wire [2:0]funct3;
wire [6:0]funct7;
wire [4:0]rs1;
wire [4:0]rs2;

//ASSIGNING VALUES TO THE INTERNAL WIRES
assign opcode = instruction[6:0]; 
assign rd     = instruction[11:7];
assign funct3 = instruction[14:12];
assign rs1    = instruction[19:15];
assign rs2    = instruction[24:20];
assign funct7 = instruction[31:25];

//always field
always@(*)begin
    //INITIALIZE EVERY OUTPUT IE DEFAULT ASSIGNMENTS
    // DEFAULT ASSIGNMENTS PREVENTS LATCH INTERFERENCE
    alu_op    = `ALU_ADD;//0000 = ADD
    imm_type  = `IMM_NONE;//000 = NONE
    alu_a_sel = 1'b0;

    alu_src   = 1'b0;/*here we are defining the mux output to be 0 = mux o/p is from the source register.
    if alu_src = 1 => mux o/p = immediate generator
    for r-type alu_src = 0; for i type alu_src = 1*/ 

    reg_write = 1'b0;

    mem_write = 1'b0;
    mem_read  = 1'b0;
    wb_sel = `WB_ALU;

    branch    = 1'b0;
    jump      = 1'b0;
    jump_reg  = 1'b0;

    mem_size = `MEM_WORD;
    load_unsigned = 1'b0;

    //CASE
    case(opcode)

    //R - TYPE
    7'b0110011:
    begin
        case({funct7,funct3})
        10'b0000000_000:
        begin
            alu_op = `ALU_ADD;
            reg_write = 1'b1;
        end
        10'b0100000_000:
        begin
            alu_op = `ALU_SUB;
            reg_write = 1'b1;
        end
        10'b0000000_111:
        begin
            alu_op = `ALU_AND;
            reg_write = 1'b1;
        end
        10'b0000000_110:
        begin
            alu_op = `ALU_OR;
            reg_write = 1'b1;
        end
        10'b0000000_100:
        begin
            alu_op = `ALU_XOR;
            reg_write = 1'b1;
        end
        10'b0000000_001:
        begin
            alu_op = `ALU_SLL;
            reg_write = 1'b1;
        end
        10'b0000000_101:
        begin
            alu_op = `ALU_SRL;
            reg_write = 1'b1;
        end
        10'b0000000_010:
        begin
            alu_op = `ALU_SLT;
            reg_write = 1'b1;
        end
        10'b0000000_011:
        begin
            alu_op = `ALU_SLTU;
            reg_write = 1'b1;
        end
        10'b0100000_101:
        begin
            alu_op = `ALU_SRA;
            reg_write = 1'b1;
        end
        endcase
    end
    //I - TYPE
    //For I-type, what signals are common? - reg_write=1, imm_type = IMM_I, alu_src = 1(immediate). it enough we initialize this once
    7'b0010011: 
    begin
            reg_write = 1'b1;
            imm_type = `IMM_I;
            alu_src = 1'b1;
            case(funct3)
            3'b000:
            begin
                alu_op = `ALU_ADD;
            end
            3'b001:
            begin
                alu_op = `ALU_SLL;
            end
            3'b010:
            begin
                alu_op = `ALU_SLT;
            end
            3'b011:
            begin
                alu_op = `ALU_SLTU;
            end
            3'b100:
            begin
                alu_op = `ALU_XOR;
            end
            3'b101:
            begin
            case(funct7)
                7'b0000000:
                begin
                    alu_op = `ALU_SRL;
                end
                7'b0100000:
                begin
                    alu_op = `ALU_SRA;
                end
                default:
                begin
                    //ILLEGAL INSTRUCTIONS
                end
            endcase
            end
            3'b110:
            begin
                alu_op = `ALU_OR;
            end
            3'b111:
            begin
                alu_op = `ALU_AND;
            end
            endcase
    end

    //LW I-TYPE
    7'b0000011:
    begin 
        reg_write = 1'b1;

        mem_read = 1'b1;
        wb_sel = `WB_MEM;

        alu_src = 1'b1;
        imm_type = `IMM_I;

        alu_op = `ALU_ADD;

        mem_size = `MEM_WORD;

        case (funct3)
        3'b000: begin // LB
            mem_size = `MEM_BYTE;
            load_unsigned = 1'b0;
        end
        3'b001: begin // LH
            mem_size = `MEM_HALFWORD;
            load_unsigned = 1'b0;
        end
        3'b010: begin // LW
            mem_size = `MEM_WORD;
            load_unsigned = 1'b0;
        end
        3'b100: begin // LBU
            mem_size = `MEM_BYTE;
            load_unsigned = 1'b1;
        end
        3'b101: begin // LHU
            mem_size = `MEM_HALFWORD;
            load_unsigned = 1'b1;
        end
        default: begin
            mem_read = 1'b0;
            reg_write = 1'b0;
        end
    endcase
    end

    //J - TYPE
    7'b1101111: 
    begin
        reg_write = 1'b1;
        jump = 1'b1;
        imm_type = `IMM_J;
        wb_sel = `WB_PC4;
    end
    7'b1100111:
    begin
        reg_write = 1'b1;
        jump_reg = 1'b1;
        imm_type = `IMM_I;

        alu_a_sel = 1'b0;
        alu_src = 1'b1;

        alu_op = `ALU_ADD;
        wb_sel = `WB_ALU;
    end
    //U - TYPE
    7'b0010111: 
    begin
            reg_write = 1'b1;
            imm_type = `IMM_U;

            alu_a_sel = 1'b1;
            alu_src = 1'b1;

            alu_op = `ALU_ADD;
            wb_sel = `WB_ALU;
    end

    // LUI - U TYPE
    7'b0110111:
    begin
        reg_write = 1'b1;

        imm_type = `IMM_U;

        wb_sel = `WB_IMM;
    end
    //B - TYPE
    7'b1100011: 
    begin
        branch = 1'b1;
        alu_src = 1'b0;
        imm_type = `IMM_B;
    end

    //S - TYPE
    7'b0100011: 
    begin
        mem_write = 1'b1;

        alu_src = 1'b1;
        imm_type = `IMM_S;

        alu_op = `ALU_ADD;

        case (funct3)
        3'b000: mem_size = `MEM_BYTE;      // SB
        3'b001: mem_size = `MEM_HALFWORD;  // SH
        3'b010: mem_size = `MEM_WORD;      // SW
        default: mem_write = 1'b0;
    endcase
end


    `OPCODE_CUSTOM: 
    begin
        case({funct7,funct3})
            {`MAC_FUNCT7, `MAC_FUNCT3}:
            begin
                reg_write = 1'b1;
                wb_sel = `WB_MAC;
            end
            default:
            begin
                //default case
            end
        endcase
    end
    //31      25 24    20 19   15 14      12 11   7 6          0 
    //  funct7  |  rs2   |  rs1  |  funct3  |  rd  |   opcode   |
    // 0000001                       000               001011                   
    endcase

end

endmodule
