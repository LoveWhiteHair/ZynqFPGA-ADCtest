`timescale 1ns / 1ps

module spi_master(
    input             rstn,
    input             clk,
    
    output reg        sclke,
    output reg        cse,
    output reg        mosie,
    input             misoe,
    output reg [15:0] data_spi_read,
    output reg        sig_spi_read,//为1，表示spi正在读数据
    input      [23:0] data_spi_write
    );

//    reg         sclke;
//    reg         cse;  
//    reg         mosie;    
//    reg [23:0]  data_spi_read;
//    reg         sig_spi_read;
//    wire [23:0] data_spi_write;
        
    reg [5:0]   count_clk; 
always@(posedge clk or negedge rstn) begin
    if(!rstn)
        count_clk <= 6'b0;
	else if(count_clk == 6'd51)
	   count_clk <= 6'd0;
	else 
	   count_clk <= count_clk + 1'b1;	 
 end
 
    reg [23:0]  mosi_reg;
    reg [15:0]  miso_reg;
always@(posedge clk or negedge rstn) begin
    if(!rstn) begin
        sclke <= 1'b0;
        cse <= 1'b1;        
        mosie <= 1'b0;
        mosi_reg <= 24'b0;
        //data_spi_read <= 16'b0;
    end 
    else begin
        case(count_clk)
            0:begin // reset
              cse <= 1'b1;
              mosie <= 1'b0;
              sclke <= 1'b0;
              mosi_reg <= data_spi_write;
            end
            1:begin
              cse <= 1'b0;
              sclke <= 1'b0;
              mosi_reg <= data_spi_write;
              mosie <= data_spi_write[23];
            end
            2:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[23];
            end
            3:begin
                sclke <= 1'b0;
                //MISO[23]
            end
            4:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[22];
            end
            5:begin
                sclke <= 1'b0;
                 //MISO[22]
            end
            6:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[21];
            end 
            7:begin
                sclke <= 1'b0;
                 //MISO[21]
            end
            8:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[20];
            end 
            9:begin
                sclke <= 1'b0;
                 //MISO[20]
            end
            10:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[19];
            end 
            11:begin
                sclke <= 1'b0;
                 //MISO[19]
            end
            12:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[18];
            end 
            13:begin
                sclke <= 1'b0;
                 //MISO[18]
            end
            14:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[17];
            end
            15:begin
                sclke <= 1'b0;
                 //MISO[17]
            end
            16:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[16];
            end 
            17:begin
                sclke <= 1'b0;
                 //MISO[16]
            end
            18:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[15];
            end
            19:begin
                sclke <= 1'b0;
                miso_reg[15] <= misoe;
            end
            20:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[14];
            end
            21:begin
                sclke <= 1'b0;
                miso_reg[14] <= misoe;
            end
            22:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[13];
            end
            23:begin
              sclke <= 1'b0;
              miso_reg[13] <= misoe;
            end
            24:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[12];
            end
            25:begin
                sclke <= 1'b0;
                miso_reg[12] <= misoe;
            end
            26:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[11];
            end
            27:begin
                sclke <= 1'b0;
                miso_reg[11] <= misoe;
            end
            28:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[10];
            end
            29:begin
                sclke <= 1'b0;
                 miso_reg[10] <= misoe;
            end
            30:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[9];
            end
            31:begin
                sclke <= 1'b0;
                miso_reg[9] <= misoe;
            end
            32:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[8];
            end
            33:begin
                sclke <= 1'b0;
                 miso_reg[8] <= misoe;
            end
            34:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[7];
            end
            35:begin
                sclke <= 1'b0;
                miso_reg[7] <= misoe;
            end
            36:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[6];
            end
            37:begin
                sclke <= 1'b0;
                miso_reg[6] <= misoe;
            end
            38:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[5];
            end
            39:begin
                sclke <= 1'b0;
                miso_reg[5] <= misoe;
            end
            40:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[4];
            end
            41:begin
                sclke <= 1'b0;
                miso_reg[4] <= misoe;
            end
            42:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[3];
            end
            43:begin
                sclke <= 1'b0;
                miso_reg[3] <= misoe;
            end
            44:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[2];
            end
            45:begin
                sclke <= 1'b0;
                miso_reg[2] <= misoe;
            end
            46:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[1];
            end
            47:begin
                sclke <= 1'b0;
                miso_reg[1] <= misoe;
            end
            48:begin
              sclke <= 1'b1;
              mosie <= mosi_reg[0];
            end            
            49:begin
                sclke <= 1'b0;
                data_spi_read <= {miso_reg[15:1],misoe};
            end
            50:begin
                cse <= 1'b1;
            end 
            default:begin
                sclke <= 1'b0;
                cse <= 1'b1;        
                mosie <= 1'b0;
                mosi_reg <= 24'b0;
                //data_spi_read <= 16'b0;
            end           
        endcase
    end
end

//always@(posedge clk or negedge rstn) begin
//    if(!rstn) begin
//        data_spi_read <= 16'b0;
//    end
//    else if(count_clk == 6'd49) begin
//        data_spi_read <= {miso_reg[15:1],misoe};
//    end
//    else begin
//        data_spi_read <= data_spi_read;
//    end
//end


endmodule

