module data_memory(
    input clk,
    input [31:0]address,
    input [31:0]write_data,
    input write_enable,

    output [31:0]read_data

);

reg [31:0]internal_memory[0:255];

//READ - COMBINATIONAL LOGIC
assign read_data = internal_memory[address[31:2]];

//WRITE - SEQUENTIAL LOGIC
always@(posedge clk)
begin
    if(write_enable)
    begin
        internal_memory[address[31:2]] <= write_data; //non-blocking assignment since it os sequential logic.  
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