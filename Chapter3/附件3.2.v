module spi_control_pulse_asyn_v2#(
           parameter TRANS_NUM = 32'd1024, //count of the needed data
           parameter FLUSH_NUM = 32'd1024
       )
       (
           input clk,//系统时钟
           input rstn,//系统rst
           input pulse,//data_ready信号
           input[7:0] set_count_gpio,//设置的dr数量
           input[7:0] skip_count_gpio,//需要跳过的dr计数
           input[7:0] cut_count_gpio,//需要截断的dr计数
           input rdre,//data_ready信号
           input wr_flag,//状态标识符，当接收到上位机发送数据时设为1，短时间后拉低（gpio实现）

           input [15:0] data_spi_read,//spi_master的输出结果
           input [23:0] data_spi_write_gpio,//上位机下发的需要写入的spi控制字

           output reg spi_ctrl,//spi写入控制端口
           output reg [23:0] data_spi_write,//需要写入spi的内容

           // axis signal
           input dma_ready,//dma初始化完成信号
           input m_axis_clk,
           output [31:0] m_axis_tdata,
           output [3:0] m_axis_tkeep,
           output m_axis_tlast,
           output m_axis_tvalid,
           input m_axis_tready,

           //debug signal
           output reg [3:0] current_state,
           output reg [11:0] counter
       );

// ????

localparam IDLE   = 4'b0000,
           READ1  = 4'b0001,
           READ2  = 4'b0010,
           READ3  = 4'b0011,
           READ4  = 4'b0100,
           READ5  = 4'b0101,
           READ6  = 4'b0110,
           READ7  = 4'b0111,
           READ8  = 4'b1000,
           WRITE  = 4'b1001;
//reg [3:0] current_state, current_state;
//reg [11:0] counter;
reg [15:0] num_ch;
reg [(TRANS_NUM*32-1):0] user_data_buffer; //user_data_buffer,buffer size is 1024*32 bit
reg [(TRANS_NUM*32-1):0] r_user_data_buffer; //user_data_buffer register,for axis trans
reg [31:0] rx_data_cnt; //number of buffer received data

assign m_axis_tkeep = 4'b1111;
//检测rdre信号边沿，判断读spi时机
reg [1:0] edge_rdre;
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
    begin
        edge_rdre <= 2'b0;
    end
    else
    begin
        edge_rdre <= {edge_rdre[0],rdre};
    end
end
//检测pulse下降沿
reg [1:0] edge_pulse;
reg rdre_count_start_flag;
reg [11:0]rdre_counter;
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
    begin
        edge_pulse <= 2'b0;
    end
    else
    begin
        edge_pulse <= {edge_pulse[0],pulse};
        if(edge_pulse==2'b10)//当pulse下降沿时开始计数rdre
        begin
            rdre_count_start_flag <= 1'b1;
        end
        else if(edge_pulse==2'b01)//当pulse上升沿时停止计数rdre
        begin
            rdre_count_start_flag <= 1'b0;
        end
    end
end
//rdre下降沿计数
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
    begin
        rdre_counter <= 12'd0;
    end
    else
    begin
        if(rdre_count_start_flag == 1'b1 & edge_rdre==2'b10)
        begin
            rdre_counter <= rdre_counter + 1'd1;
        end
        if(rdre_count_start_flag == 1'b0)
        begin
            rdre_counter <= 12'd0;
        end
    end
end
//检测wr_flag信号边沿，切换至状态
reg [1:0] edge_wr_flag;
reg change_write_flag;
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
    begin
        edge_wr_flag <= 2'b0;
    end
    else
    begin
        edge_wr_flag <= {edge_wr_flag[0],wr_flag};

    end
end

// 状态机
/*** rx_data_cnt counter for trans start signal ***/
reg trans_start,trans_start_0, trans_start_1;//trans start signal register
wire pos_trans_start;//real trans start signal
assign pos_trans_start = trans_start_0 & (~trans_start_1);//detect the posedge
always @(posedge clk or negedge rstn)
begin
    if (!rstn)
    begin
        current_state <= IDLE;
        counter <= 12'd0;
        user_data_buffer <= 0;
        rx_data_cnt <= 1'b0;
    end
    else
    begin
        if(edge_wr_flag==2'b01)
        begin
            change_write_flag<=1'b1;
        end
        //current_state <= current_state;
        // 状态机的逻辑
        case (current_state)
            IDLE:
            begin
                if (rdre_counter>=skip_count_gpio & edge_rdre == 2'b10 & rdre_counter<=set_count_gpio-cut_count_gpio)
                begin
                    current_state <= READ1;
                    spi_ctrl <= 1'b1;
                    counter <= 12'd0;
                    data_spi_write <= 24'h97_0000;
                    num_ch <= 16'd7;
                end
                else if (change_write_flag==1'b1)//如果检测到wr_flag上升沿
                begin
                    current_state <= WRITE;
                    spi_ctrl <= 1'b1;
                    counter <= 12'd0;
                    data_spi_write <= data_spi_write_gpio;//将用户输入的值作为即将写入spi寄存器的值
                    change_write_flag<=1'b0;
                end
                else
                begin
                    current_state <= IDLE;
                    spi_ctrl <= 1'b0;
                end
            end
            READ1:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= READ2;
                    counter <= 12'd0;
                    data_spi_write <= 24'h98_0000;
                    num_ch <= 16'd0;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ1;
                    counter <= counter + 1'b1;
                end
            end
            READ2:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= READ3;
                    counter <= 12'd0;
                    data_spi_write <= 24'h99_0000;
                    num_ch <= 16'd1;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ2;
                    counter <= counter + 1'b1;
                end
            end
            READ3:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= READ4;
                    counter <= 12'd0;
                    data_spi_write <= 24'h9a_0000;
                    num_ch <= 16'd2;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ3;
                    counter <= counter + 1'b1;
                end
            end
            READ4:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= READ5;
                    counter <= 12'd0;
                    data_spi_write <= 24'h9b_0000;
                    num_ch <= 16'd3;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ4;
                    counter <= counter + 1'b1;
                end
            end
            READ5:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= READ6;
                    counter <= 12'd0;
                    data_spi_write <= 24'h9c_0000;
                    num_ch <= 16'd4;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ5;
                    counter <= counter + 1'b1;
                end
            end
            READ6:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= READ7;
                    counter <= 12'd0;
                    data_spi_write <= 24'h9d_0000;
                    num_ch <= 16'd5;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ6;
                    counter <= counter + 1'b1;
                end
            end
            READ7:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= READ8;
                    counter <= 12'd0;
                    data_spi_write <= 24'h9e_0000;
                    num_ch <= 16'd6;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ7;
                    counter <= counter + 1'b1;
                end
            end
            READ8:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= IDLE;
                    counter <= 12'd0;
                    spi_ctrl <=1'b0;
                    user_data_buffer <= {user_data_buffer[((TRANS_NUM-1)*32-1):0],{num_ch,data_spi_read}};
                    rx_data_cnt <= rx_data_cnt +1'b1;
                end
                else
                begin
                    current_state <= READ8;
                    counter <= counter + 1'b1;
                end
            end
            WRITE:
            begin
                if (counter == 12'd51)
                begin
                    current_state <= IDLE;
                    counter <= 12'd0;
                    spi_ctrl <=1'b0;
                end
                else
                begin
                    current_state <= WRITE;
                    counter <= counter + 1'b1;
                end
            end
            default:
            begin
                current_state <= IDLE;
            end
        endcase
        if (rx_data_cnt == FLUSH_NUM)
        begin
            rx_data_cnt <= 32'b0;
            trans_start <= 1'd1;//when received FLUSH_NUM data,ready for 1 transfer
        end
        else
        begin
            trans_start <= 1'd0;
        end
    end
end



always @(posedge m_axis_clk or negedge rstn)
begin
    if(!rstn)
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
localparam AXIS_IDLE = 2'b00;
localparam AXIS_TRANS = 2'b01;
localparam AXIS_DONE = 2'b10;
localparam TOP_INDEX = TRANS_NUM*32-1;
reg [1:0] AXIS_state;
//axis output signal
reg [31:0] trans_cnt;
reg [31:0] r_tdata;
reg r_tvalid, r_tlast;

/*** axis logic ***/
/* data logic */
always @(posedge m_axis_clk or negedge rstn)
begin
    if(!rstn)
    begin
        AXIS_state <= AXIS_IDLE;
        r_tdata <= 32'd0;
        r_tvalid <= 1'b0;
    end
    else
    begin
        r_tdata <= 32'd0;
        r_tvalid <= 1'b0;
        case(AXIS_state)
            AXIS_IDLE:
            begin
                //if trans_start signal with a posedge and axis ready,turn TRANS
                if(pos_trans_start && m_axis_tready && dma_ready)
                begin
                    AXIS_state <= AXIS_TRANS;
                    r_user_data_buffer <= user_data_buffer; //save the current data
                end
                else
                begin
                    AXIS_state <= AXIS_IDLE;
                end
            end
            //if axis trans TRANS_NUM data,turn DONE
            AXIS_TRANS:
            begin
                if(trans_cnt < TRANS_NUM)
                begin
                    AXIS_state <= AXIS_TRANS;
                    r_tvalid <= 1'b1;
                    r_tdata <= r_user_data_buffer[(TOP_INDEX-32*trans_cnt)-:32];//cut the data from the buffer
                end
                else
                begin
                    AXIS_state <= AXIS_DONE;
                end
            end
            AXIS_DONE:
            begin
                AXIS_state <= AXIS_IDLE;
            end
            default:
            begin
                AXIS_state <= AXIS_IDLE;
            end
        endcase
    end
end
/* tlast logic */
always @(posedge m_axis_clk or negedge rstn)
begin
    if(!rstn)
    begin
        r_tlast <= 1'b0;
    end
    else
    begin
        if(AXIS_state == AXIS_TRANS && trans_cnt == TRANS_NUM-1)//the last transfer data
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
always @(posedge m_axis_clk or negedge rstn)
begin
    if(!rstn)
    begin
        trans_cnt <= 0;
    end
    else
    begin
        if(AXIS_state == AXIS_TRANS)
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