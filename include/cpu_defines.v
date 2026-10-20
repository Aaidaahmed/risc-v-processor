//-------------------------------------------
//ALU OPERATIONS
//-------------------------------------------

`define ALU_ADD   4'b0000
`define ALU_SUB   4'b0001 
`define ALU_AND   4'b0010 
`define ALU_OR    4'b0011 
`define ALU_XOR   4'b0100 
`define ALU_SLL   4'b0101 
`define ALU_SRL   4'b0110 
`define ALU_SRA   4'b0111 
`define ALU_SLT   4'b1000 
`define ALU_SLTU  4'b1001 

//--------------------------------------------
//IMMEDIATE TYPES
//--------------------------------------------

`define IMM_NONE  3'b000
`define IMM_I     3'b001
`define IMM_S     3'b010
`define IMM_B     3'b011
`define IMM_U     3'b100
`define IMM_J     3'b101

//---------------------------------------------
//BRANCH INSTRUCTIONS
//---------------------------------------------

`define BEQ  3'b000
`define BNE  3'b001
`define BLT  3'b100
`define BGE  3'b101
`define BLTU 3'b110
`define BGEU 3'b111

//---------------------------------------------
//WRITE-BACK SELECT
//---------------------------------------------

`define WB_ALU 3'b000
`define WB_MEM 3'b001
`define WB_IMM 3'b010
`define WB_PC4 3'b011
`define WB_CSR 3'b100
`define WB_MAC 3'b101

//---------------------------------------------
//CUSTOM OPCODES
//---------------------------------------------

`define OPCODE_CUSTOM 7'b0001011 //custom - 0 opcode

//---------------------------------------------
//CUSTOM INSTRUCTIONS
//---------------------------------------------

`define MAC_FUNCT7 7'b0000001
`define MAC_FUNCT3 3'b000

//---------------------------------------------
//2 bit ACCESS SIZE ENCODINGS
//---------------------------------------------

`define MEM_BYTE      2'b00
`define MEM_HALFWORD  2'b01
`define MEM_WORD      2'b10