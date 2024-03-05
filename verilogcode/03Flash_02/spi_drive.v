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

/*
程序作为matser miso输入，mosi输出

写 有写计数器

读 有读计数器

操作=指令+地址   32bit
*/
module spi_drive#(
    parameter   P_USER_OPE_LEN      = 32,
    parameter   P_READ_DATA_WIDTH   = 8,
    parameter   P_CPOL              = 0,
    parameter   P_CPHL              = 0
)
(
    input                           i_clk,
    input                           i_rst,
    input   [P_USER_OPE_LEN-1:0]    i_user_op_data,     //  和user操作接口
    input   [7:0]                   i_user_op_len,      //  8 32
    input                           i_user_op_valid,    
    input   [2:0]                   i_user_op_type,
    input   [7:0]                   i_user_write_data,  
    input   [8:0]                   i_write_len,        // 256  
    input   [8:0]                   i_read_len,

    input                           i_spi_miso,         //  和flash操作接口
    output                          o_spi_mosi,         
    
    output                          o_cs,   
    output                          o_spi_clk,
    output                          o_user_ready,  
    output                          o_user_write_req,   
    output  [7:0]                   o_user_read_data,
    output                          o_user_read_valid
);


reg                             ro_cs;
reg                             ro_ready;
reg                             ro_spi_clk;

// 传输计数结束后，user有效和ready有效/片选 占一个spi clk,要识别run下降沿 
reg                             r_run;      
reg                             r_run_1d;

reg                             ro_spi_mosi;    
reg [P_USER_OPE_LEN-1:0]        ri_user_op_data;        // 接收 userdata 输出 mosi  
reg [2:0]                       ri_user_op_type;
reg [15:0]                      r_clk_len; 

reg [P_USER_OPE_LEN-1:0]        r_spi_dcnt;             // 01234567
reg                             r_spi_clk_cnt;          // 01010101

reg [7:0]                       ri_write_data;
reg [3:0]                       r_write_clk;            // 1-8
reg                             ro_user_write_req;
reg                             ro_user_write_req_1d;

reg [7:0]                       ro_read_data;
reg [3:0]                       r_read_clk;             // 1-8   
reg                             ro_read_valid;

wire w_active = i_user_op_valid & o_user_ready;  
wire w_run_negedge = !r_run & r_run_1d;                 // 下降沿 


assign      o_spi_clk           = ro_spi_clk;
assign      o_cs                = ro_cs;
assign      o_user_ready        = ro_ready;
assign      o_spi_mosi          = ro_spi_mosi;

assign      o_user_read_data    = ro_read_data;
assign      o_user_read_valid   = ro_read_valid;
assign      o_user_write_req    = ro_user_write_req;


always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)     //### 改一下
        r_run <= 'd0;
    else if(w_active)
        r_run <= 'd1;
    else if(r_spi_dcnt == r_clk_len - 1 && r_spi_clk_cnt)
        r_run <= 'd0;
    else 
        r_run <= r_run;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_run_1d <= 'd0;
    else 
        r_run_1d <= r_run;
end

always@(posedge i_clk, posedge i_rst)   
begin
    if(i_rst)
        ro_cs <= 'd1;
    else if(w_active)
        ro_cs <= 'd0;
    else if(w_run_negedge)                  
        ro_cs <= 'd1;
    else
        ro_cs <= ro_cs;
end

always@(posedge i_clk, posedge i_rst)   // 0101 标识上升下降沿
begin
    if(i_rst)
        r_spi_clk_cnt <= 1'b0;
    else if(r_run)
        r_spi_clk_cnt <= r_spi_clk_cnt+1;
    else
        r_spi_clk_cnt <= 1'b0;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_ready <= 'd1;
    else if(w_run_negedge)
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
    else if (r_run)
        ro_spi_clk <= ~ro_spi_clk;
    else 
        ro_spi_clk <= P_CPOL;
end

always@(posedge i_clk, posedge i_rst)   //  0 1 2 3 ...
begin
    if(i_rst)
        r_spi_dcnt <= 'd0;
    else if((r_spi_dcnt == r_clk_len - 1) && r_spi_clk_cnt)    // 下降沿的时候
        r_spi_dcnt <= 'd0;
    else if(r_run && r_spi_clk_cnt)
        r_spi_dcnt <= r_spi_dcnt + 'd1;
    else
        r_spi_dcnt <= r_spi_dcnt; 
end

always@(posedge i_clk, posedge i_rst) 
begin
    if(i_rst)
        r_clk_len <= 'd0;  
    else if(w_active)
        if(ri_user_op_type == 0)
            r_clk_len <= i_user_op_len;
        else if(ri_user_op_type == 1)
            r_clk_len <= i_user_op_len + i_read_len;
        else if(ri_user_op_type == 2)
            r_clk_len <= i_user_op_len + i_write_len;
        else
            r_clk_len <= r_clk_len;
    else
        r_clk_len <= r_clk_len;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ri_user_op_type <= 'd0;
    else if(w_active)
        ri_user_op_type <= i_user_op_type;
    else
        ri_user_op_type <= ri_user_op_type;
end

always@(posedge i_clk, posedge i_rst)   // opdata并转串。
begin
    if(i_rst) 
        ri_user_op_data <=  'd0;
    else if(w_active) 
        ri_user_op_data <= i_user_op_data<<1;
    else if(!w_run_negedge && r_spi_clk_cnt &&(r_spi_dcnt <= P_USER_OPE_LEN-1)) 
        ri_user_op_data <= ri_user_op_data<<1;          // 先发高位
    else 
        ri_user_op_data <= ri_user_op_data;
end

always@(posedge i_clk, posedge i_rst)   //  发送数据 user--->mosi   
begin
    if(i_rst)
        ro_spi_mosi <= 'd0;
    else if(w_active)
        ro_spi_mosi <= i_user_op_data[P_USER_OPE_LEN - 1];
    else if(r_spi_clk_cnt && !w_run_negedge)                //  写指令+地址
        if(r_spi_dcnt <= P_USER_OPE_LEN - 1)
            ro_spi_mosi <= ri_user_op_data[P_USER_OPE_LEN - 1];
        else if(ri_user_op_type == 2 && r_spi_dcnt < r_clk_len)
            ro_spi_mosi <= ri_write_data[7];
        else 
            ro_spi_mosi <= ro_spi_mosi;
    else
        ro_spi_mosi <= ro_spi_mosi;
end


always@(posedge i_clk, posedge i_rst)   // 串转并 miso--->user 读数据
begin
    if(i_rst)
        ro_read_data <='d0;
    else if(ri_user_op_type == 1 && !r_spi_clk_cnt)
        if(r_spi_dcnt < r_clk_len)
            ro_read_data <= {ro_read_data[P_READ_DATA_WIDTH-2 : 0], i_spi_miso};
        else 
            ro_read_data <= ro_read_data;
    else
        ro_read_data <= ro_read_data;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_read_valid <='d0;
    else if(ri_user_op_type == 1 && !r_spi_clk_cnt && r_read_clk == 8)
        ro_read_valid <='d1;
    else
        ro_read_valid <='d0;
end


always@(posedge i_clk, posedge i_rst)   //  写请求
begin
    if(i_rst)
        ro_user_write_req <= 'd0;
    else if(ri_user_op_type == 2 && !r_spi_clk_cnt)
        if((r_spi_dcnt < r_clk_len - 5 && r_write_clk == 7)|| (r_spi_dcnt == P_USER_OPE_LEN - 2))
            ro_user_write_req <= 'd1;
        else 
            ro_user_write_req <= 'd0;
    else
        ro_user_write_req <= 'd0;
end

always@(posedge i_clk, posedge i_rst)   //  写请求_1d
begin
    if(i_rst) begin
        ro_user_write_req_1d <= 'd0;
    end else begin
        ro_user_write_req_1d <= ro_user_write_req;
    end
end

always@(posedge i_clk, posedge i_rst)   //  写clk
begin
    if(i_rst)
        r_write_clk <= 'd0; 
    else if(ri_user_op_type == 2 && !r_spi_clk_cnt)
        if(w_run_negedge || (r_spi_dcnt == r_clk_len - 1 && r_write_clk == 8))
            r_write_clk <= 'd0;
        else if(ro_user_write_req_1d)
            r_write_clk <= 'd1;
        else if(r_write_clk)
            r_write_clk <= r_write_clk + 1;
        else 
            r_write_clk <= r_write_clk;
    else
        r_write_clk <= r_write_clk;
end

always@(posedge i_clk, posedge i_rst)   //  写数据
begin
    if(i_rst)
        ri_write_data <= 'd0;
    else if(ri_user_op_type == 2)
        if(ro_user_write_req_1d)
            ri_write_data <= i_user_write_data;
        else if(r_write_clk && r_write_clk <= 8 && r_spi_clk_cnt)        // 并转串
            ri_write_data <= ri_write_data<< 1;         
        else 
            ri_write_data <= ri_write_data;
    else
        ri_write_data <= ri_write_data;
end

always@(posedge i_clk, posedge i_rst)   //  读clk
begin
    if(i_rst)
        r_read_clk <= 'd0;
    else if(ri_user_op_type == 1 && r_spi_clk_cnt)
        if(r_read_clk == 8 && r_spi_dcnt < r_clk_len - 5)
            r_read_clk <= 'd1;
        else if(r_read_clk == 8 && r_spi_dcnt == r_clk_len - 1)
            r_read_clk <= 'd0;
        else if(r_read_clk || (r_spi_dcnt == P_USER_OPE_LEN-1))
            r_read_clk <= r_read_clk + 'd1;
        else 
            r_read_clk <= r_read_clk;
    else
        r_read_clk <= r_read_clk;
end

endmodule
