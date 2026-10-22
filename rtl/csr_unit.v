module csr_unit(
    input clk,
    input rst,

    input instruction_valid,
    
    input mem_read,
    input mem_write,

    input branch_taken,
    input mac_executed,

    output reg[31:0]cycle_counter,
    output reg[31:0]inst_counter,
    output reg[31:0]load_counter,
    output reg[31:0]store_counter,
    output reg[31:0]branch_counter,
    output reg[31:0]mac_counter
);

always @(posedge clk)
begin
    if(rst)
    begin
        cycle_counter  <= 32'd0;
        inst_counter   <= 32'd0;
        load_counter   <= 32'd0;
        store_counter  <= 32'd0;
        branch_counter <= 32'd0;
        mac_counter    <= 32'd0;
    end
    else
    begin
        cycle_counter <= cycle_counter + 1;

        if(instruction_valid)
            inst_counter <= inst_counter + 1;
        if(mem_read)
            load_counter <= load_counter + 1;
        if(mem_write)
            store_counter <= store_counter + 1;
        if(branch_taken)
            branch_counter <= branch_counter + 1;
        if(mac_executed)
            mac_counter <= mac_counter + 1;
    end
end
endmodule