`timescale 1ns / 1ps
module asyn_data_receiver #(
           parameter TRANS_NUM = 32'd1024, //count of the needed data
           parameter FLUSH_NUM = 32'd1024
       )
       (
           input resetn, //system reset
		   //user signal
           input data_clk, //user data clk(dr signal)
           input [31:0] user_data, //user input data
           // axis signal
           input m_axis_clk,
           output [31:0] m_axis_tdata,
           output [3:0] m_axis_tkeep,
           output m_axis_tlast,
           output m_axis_tvalid,
           input m_axis_tready
       );
assign m_axis_tkeep = 4'b1111;
/*** save adc data when a dr posegde comes ***/
reg [(TRANS_NUM*32-1):0] user_data_buffer; //user_data_buffer,buffer size is 16384*32 bit
reg [(TRANS_NUM*32-1):0] r_user_data_buffer; //user_data_buffer register,for axis trans
reg [31:0] rx_data_cnt; //number of buffer received data
always@(posedge data_clk or negedge resetn)
begin
    if(!resetn)
    begin
        user_data_buffer <= 0;
    end
    else
    begin
        user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],user_data};//delete old data and append new data
    end
end

/*** rx_data_cnt counter for trans start signal ***/
reg trans_start,trans_start_0, trans_start_1;//trans start signal register
wire pos_trans_start;//real trans start signal
assign pos_trans_start = trans_start_0 & (~trans_start_1);//detect the posedge
always@(posedge data_clk or negedge resetn)
begin
    if(!resetn)
    begin
        rx_data_cnt <= 32'b0;
		trans_start <= 1'd0;
    end
    else if (rx_data_cnt == FLUSH_NUM-1)
    begin
        rx_data_cnt <= 32'b0;
		trans_start <= 1'd1;//when received FLUSH_NUM data,ready for 1 transfer
    end
    else
    begin
        rx_data_cnt <= rx_data_cnt +1'b1;
		trans_start <= 1'd0;
    end
end
always @(posedge m_axis_clk or negedge resetn)
begin
    if(~resetn)
    begin
        trans_start_0 <= 1'd0;
        trans_start_1 <= 1'd0;
    end
    else
    begin
        trans_start_0 <= trans_start;
        trans_start_1 <= trans_start_0;
    end
end

/*** axis signal reg ***/
//state parameter
localparam IDLE = 2'b00;
localparam TRANS = 2'b01;
localparam DONE = 2'b10;
localparam TOP_INDEX = TRANS_NUM*32-1;
reg [1:0] state;
//axis output signal
reg [31:0] trans_cnt;
reg [31:0] r_tdata;
reg r_tvalid, r_tlast;

/*** axis logic ***/
/* data logic */
always @(posedge m_axis_clk or negedge resetn)
begin
    if(!resetn)
    begin
        state <= IDLE;
        r_tdata <= 32'd0;
        r_tvalid <= 1'b0;
    end
    else
    begin
        r_tdata <= 32'd0;
        r_tvalid <= 1'b0;
        case(state)
            IDLE:
            begin
                //if trans_start signal with a posedge and axis ready,turn TRANS
                if(pos_trans_start && m_axis_tready)
                begin
                    state <= TRANS;
					r_user_data_buffer <= user_data_buffer; //save the current 16384 adc data
                end
                else
                begin
                    state <= IDLE;
                end
            end
            //if axis trans TRANS_NUM data,turn DONE
            TRANS:
            begin
                if(trans_cnt < TRANS_NUM)
                begin
                    state <= TRANS;
                    r_tvalid <= 1'b1;
                    r_tdata <= r_user_data_buffer[(TOP_INDEX-32*trans_cnt)-:32];//cut the data from the buffer
                end
                else
                begin
                    state <= DONE;
                end
            end
            DONE:
            begin
                state <= IDLE;
            end
            default:
            begin
                state <= IDLE;
            end
        endcase
    end
end
/* tlast logic */
always @(posedge m_axis_clk or negedge resetn)
begin
    if(!resetn)
    begin
        r_tlast <= 1'b0;
    end
    else
    begin
        if(state == TRANS && trans_cnt == TRANS_NUM-1)//the last transfer data
        begin
            r_tlast <= 1'b1;
        end
        else
        begin
            r_tlast <= 1'b0;
        end
    end
end
/* trans signal counter */
always @(posedge m_axis_clk or negedge resetn)
begin
    if(!resetn)
    begin
        trans_cnt <= 0;
    end
    else
    begin
        if(state == TRANS)
        begin
            trans_cnt <= trans_cnt + 1;
        end
        else
        begin
            trans_cnt <= 32'd0;
        end
    end
end
assign m_axis_tdata = r_tdata;
assign m_axis_tlast = r_tlast;
assign m_axis_tvalid = r_tvalid;
endmodule
