module register_file(
    input clk,

    input write_enable,

    input [4:0]rs1,
    input [4:0]rs2,
    input [4:0]rd,
    input [4:0]rd_read,

    input [31:0]write_data,

    output [31:0]read_data1,
    output [31:0]read_data2,
    output [31:0]read_data3
);  

reg [31:0]registers[0:31];//RISCV has 32 registers each 32 bits long. [31:0]-width, [0:31]-no of registers

integer i;

/*A simple rule to remember is:

Combinational logic (always @(*)) → =
Sequential logic (always @(posedge clk)) → <=*/

initial 
begin
    for(i = 0; i < 32; i = i + 1)
        registers[i] = 32'b0; 
end
//------------------------------------------------------------------------
//READ LOGIC(COMBINATIONAL)

assign read_data1 = (rs1 == 0)? 32'b0 : registers[rs1];//TERNARY OPERATOR -> (condition) ? value_if_true : value_if_false
assign read_data2 = (rs2 == 0)? 32'b0 : registers[rs2];
assign read_data3 = registers[rd_read];


//------------------------------------------------------------------------
//********************************************************************************************************
//------------------------------------------------------------------------
//WRITE LOGIC(SEQUENTIAL)

always@(posedge clk)
begin
    if(write_enable == 1 && rd != 5'd0)
    begin
        registers[rd] <= write_data; // in seq logic we generally use non-blocking assignments 
        //(<=) instead of blocking assignments (=)
    end
    
end
//------------------------------------------------------------------------
endmodule