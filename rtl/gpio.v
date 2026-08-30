module gpio(
    input clk,

    input write_enable,
    input read_enable,
    input [31:0]address,
    input [31:0] write_data,
    output reg[31:0] read_data,
    output reg[31:0] gpio_out
);

always @(posedge clk)
begin
    if(write_enable && address == 32'h10000000)
    begin
        gpio_out <= write_data;
        
        $display("--------------------------------");
        $display("GPIO WRITE");
        $display("Address : %h", address);
        $display("LED Value : %0d", write_data);
        $display("--------------------------------");
    end
end

always @(*)
begin 
    if(read_enable && address == 32'h10000004)
        read_data = 32'd0;
    else
        read_data = 32'd0;
end
endmodule