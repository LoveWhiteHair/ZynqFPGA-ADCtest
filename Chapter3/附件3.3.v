`timescale 1ns / 1ps

module clk_output#(
           parameter DIVIDE_FACTOR = 32'd320
       )
       (
           input clk_in,
           input rstn,
           output reg clk_out
       );
reg [15:0] count;
always@(posedge clk_in or negedge rstn)
begin
    if(!rstn)
    begin
        count <= 'd0;
        clk_out <= 0;
    end
    else
    begin
        if(count == (DIVIDE_FACTOR/2 - 1))
        begin
            count <= 'd0;
            clk_out <= ~clk_out;
        end
        else
        begin
            count <= count + 'd1;
        end
    end
end



endmodule