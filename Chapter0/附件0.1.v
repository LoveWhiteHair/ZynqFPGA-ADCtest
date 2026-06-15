`timescale 1ns / 1ps
module adc_test(
           clk,
           din,
           rstn,
           dr,
           en
       );
input clk;
input dr;
input [10:0] din;
input rstn;
input en;

reg [(2048*11-1):0] shift_reg;

always@(posedge dr or negedge rstn)
begin
    if(!rstn)
    begin
        shift_reg <= 0;
    end
    else
    begin
        shift_reg <= {shift_reg[(2047*11-1):0],din};
    end
end

reg [(2048*11-1):0] shift_reg_o;

assign nclk = ~clk;

always@(posedge nclk or negedge rstn)
begin
    if(!rstn)
    begin
        shift_reg_o <= 0;
    end
    else
    begin
        if(en)
            shift_reg_o <= {shift_reg_o[(2047*11-1):0],11'b0000_0000_000};
        else
            shift_reg_o <= shift_reg;
    end
end

ila_0 i1(
          .clk(clk),
          .probe0(en),
          .probe1(shift_reg_o[(2048*11-1):2047*11])
      );

endmodule