`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/31 14:24:32
// Design Name: 
// Module Name: spi_drive
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module spi_drive#(
    parameter   P_USER_DATA_WIDTH= 8,
    parameter   P_READ_DATA_WIDTH= 8,
    parameter   P_CPOL          = 0,
    parameter   P_CPHL          = 0
)
(
    input                           i_clk,
    input                           i_rst,
    input   [P_USER_DATA_WIDTH-1:0] i_user_data,           
    input                           i_user_valid,

    input                           i_spi_miso,
    output                          o_spi_mosi,
    output                          o_cs,
    output                          o_ready,     
    output                          o_spi_clk,

    output  [P_READ_DATA_WIDTH-1:0] o_user_data,
    output                          o_user_valid
);



 wire w_active = i_user_valid & o_ready;  


reg                             ro_cs;
reg                             ro_ready;
reg                             ro_spi_clk;

reg                             ro_spi_mosi;    
reg [P_USER_DATA_WIDTH-1:0]     ri_user_data;       // 接收 userdata 输出 mosi  

reg [P_USER_DATA_WIDTH-1:0]     r_spi_dcnt;     // 01234567
reg                             r_spi_clk_cnt;  // 01010101

reg [P_READ_DATA_WIDTH-1:0]     ri_miso;            // 接收 miso data 输出 userdata
reg [P_READ_DATA_WIDTH-1:0]     ro_user_data;
reg                             ro_user_valid;
//reg                           r_run;


assign      o_spi_clk       = ro_spi_clk;
assign      o_cs            = ro_cs;
assign      o_ready         = ro_ready;
assign      o_spi_mosi      = ro_spi_mosi;
assign      o_user_data     = ro_user_data;
assign      o_user_valid    = ro_user_valid;


always@(posedge i_clk, posedge i_rst)   // 以片选为准
begin
    if(i_rst)
        ro_cs <= 'd1;
    else if(w_active)
        ro_cs <= 'd0;
    else if(r_spi_dcnt == P_USER_DATA_WIDTH-1 && r_spi_clk_cnt)   // 下降沿的时候
        ro_cs <= 'd1;
    else
        ro_cs <= ro_cs;
end

always@(posedge i_clk, posedge i_rst)       // 0101 标识上升下降沿
begin
    if(i_rst)
        r_spi_clk_cnt <= 1'b0;
    else if(!o_cs)
        r_spi_clk_cnt <= r_spi_clk_cnt+1;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst || (r_spi_dcnt == P_USER_DATA_WIDTH-1 && r_spi_clk_cnt))
        ro_ready <= 'd1;
    else if(w_active)
        ro_ready <= 'd0;
    else 
        ro_ready <= ro_ready;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_spi_clk <= P_CPOL;
    else if (!o_cs)
        ro_spi_clk <= ~ro_spi_clk;
    else 
        ro_spi_clk <= P_CPOL;
end

always@(posedge i_clk, posedge i_rst)   //  rcnt 0 1 2 3 4 5 6 7 
begin
    if(i_rst)
        r_spi_dcnt <= 'd0;
    else if((r_spi_dcnt == P_USER_DATA_WIDTH - 1) && r_spi_clk_cnt)// 下降沿的时候
        r_spi_dcnt <= 'd0;
    else if(!o_cs && r_spi_clk_cnt)
        r_spi_dcnt <= r_spi_dcnt + 'd1;
    else
        r_spi_dcnt <= r_spi_dcnt; 
end

always@(posedge i_clk, posedge i_rst)   // 并转串。
begin
    if(i_rst)
        ri_user_data <=  'd0;
    else if(w_active)
        ri_user_data <= i_user_data<<1;
    else if(!o_cs && r_spi_clk_cnt)
        ri_user_data <= ri_user_data<<1;  // 先发高位
    else
        ri_user_data <= ri_user_data;
end

always@(posedge i_clk, posedge i_rst)   //  发送数据 user--->mosi
begin
    if(i_rst)
        ro_spi_mosi<= 'd0;
    else if(w_active)
        ro_spi_mosi<= i_user_data[P_USER_DATA_WIDTH-1];
    else if(!o_cs && (r_spi_clk_cnt))
        ro_spi_mosi<= ri_user_data[P_USER_DATA_WIDTH-1];
    else 
        ro_spi_mosi<= ro_spi_mosi;
end

always@(posedge i_clk, posedge i_rst)// 串转并 miso--->user 没必要存一拍直接输出
begin
    if(i_rst)
        ro_user_data <='d0;
    else if(!o_cs &&(!r_spi_clk_cnt) && r_spi_dcnt ==0)
        ro_user_data <= {7'b0, i_spi_miso};
    else if(!o_cs &&(!r_spi_clk_cnt))
        ro_user_data <= {ro_user_data[P_READ_DATA_WIDTH-2 : 0], i_spi_miso};
    else 
        ro_user_data <= ro_user_data;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_user_valid <='d0;
    else if(r_spi_dcnt == P_READ_DATA_WIDTH-1 && r_spi_clk_cnt)
        ro_user_valid <='d1;
    else
        ro_user_valid <='d0;
end


endmodule
