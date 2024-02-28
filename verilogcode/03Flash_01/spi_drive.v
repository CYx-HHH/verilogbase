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
    parameter   P_USER_OPE_TYPE     = 2,  // 0指令 1读 2写
    parameter   P_USER_OPE_LEN      = 32,
  //  parameter   P_USER_DATA_WIDTH   = 8,
    parameter   P_READ_DATA_WIDTH   = 8,
    parameter   P_CPOL              = 0,
    parameter   P_CPHL              = 0
)
(
    input                           i_clk,
    input                           i_rst,
    input   [P_USER_OPE_LEN-1:0]    i_user_op_data,     //  和user操作接口
    input                           i_user_op_len,      //  8 32
    input                           i_user_op_valid,    

    input   [7:0]                   i_user_write_data,  
    input   [8:0]                   i_write_len,        // 256  
    input   [8:0]                   i_read_len,

    input                           i_spi_miso,         //  和flash操作接口
    output                          o_spi_mosi,         
    
    output                          o_cs,
    output                          o_user_ready,     
    output                          o_spi_clk,

    output                          o_write_req,
    output                          o_read_req,

    output  [7:0]                   o_user_read_data,
    output                          o_user_read_valid
);


// o_read_req, r_read_req和 r_read_req_1d 用来仿真，和主要逻辑无关，可以删掉


reg                             ro_cs;
reg                             ro_ready;
reg                             ro_spi_clk;

// 传输计数结束后，user有效和ready有效/片选 占一个spi clk,要识别run下降沿 
reg                             r_run;      
reg                             r_run_1d;

reg                             ro_spi_mosi;    
reg [P_USER_OPE_LEN-1:0]        ri_user_op_data;        // 接收 userdata 输出 mosi  
reg [8:0]                       ri_user_op_len; //##

reg [P_USER_OPE_LEN-1:0]        r_spi_dcnt;             // 01234567
reg                             r_spi_clk_cnt;          // 01010101

reg [P_READ_DATA_WIDTH-1:0]     ri_spi_miso;                // 接收 miso data 输出 userdata


// clk产生周期性读写请求（8bit单位），len和cnt标识读写过程整体的开始和结束
reg [8:0]                       ri_write_len;       // 256 bytes   
reg [7:0]                       ri_write_data;
reg [8:0]                       r_write_cnt;
reg [3:0]                       r_write_clk;        // 1-8
reg                             r_write_req;
reg                             r_write_req_1d;

reg [8:0]                       ri_read_len;        // 256 bytes   

reg [7:0]                       ro_read_data;
reg [8:0]                       r_read_cnt;
reg [3:0]                       r_read_clk;         // 1-8   
reg                             r_read_req;
reg                             ro_read_valid;
reg                             r_read_req_1d;

wire w_active = i_user_op_valid & o_user_ready;  
wire w_run_negedge = !r_run & r_run_1d;                 // 下降沿 


assign      o_spi_clk           = ro_spi_clk;
assign      o_cs                = ro_cs;
assign      o_user_ready        = ro_ready;
assign      o_spi_mosi          = ro_spi_mosi;
assign      o_user_read_data    = ro_read_data;
assign      o_user_read_valid   = ro_read_valid;
assign      o_write_req         = r_write_req;
assign      o_read_req          = !r_read_req & r_read_req_1d;


always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)     //### 改一下
        r_run <= 'd0;
    else if(w_active)
        r_run <= 'd1;
    else if(P_USER_OPE_TYPE == 0 && (r_spi_dcnt == P_USER_OPE_LEN - 1 && r_spi_clk_cnt))
        r_run <= 'd0;
    else if(P_USER_OPE_TYPE == 1 && r_spi_clk_cnt && r_read_cnt == ri_read_len && r_read_clk == 8)
        r_run <= 'd0;
    else if(P_USER_OPE_TYPE == 2 && r_spi_clk_cnt && r_write_cnt == ri_write_len && r_write_clk == 8)
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

always@(posedge i_clk, posedge i_rst)   // 以下降沿为准，片选比下降沿慢一个拍
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
    if(i_rst || (w_run_negedge))
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
    else if((r_spi_dcnt == P_USER_OPE_LEN - 1) && r_spi_clk_cnt)    // 下降沿的时候
        r_spi_dcnt <= 'd0;
    else if(r_run && r_spi_clk_cnt && !r_write_cnt && !r_read_cnt)
        r_spi_dcnt <= r_spi_dcnt + 'd1;
    else
        r_spi_dcnt <= r_spi_dcnt; 
end

always@(posedge i_clk, posedge i_rst)   // opdata并转串。
begin
    if(i_rst) begin
        ri_user_op_data <=  'd0;
        ri_user_op_len <= 'd0;
    end else if(r_write_cnt || r_read_cnt) 
    begin
        ri_user_op_data <=  'd0;
        ri_user_op_len <= 'd0;
    end else if(w_active) 
    begin
        ri_user_op_data <= i_user_op_data<<1;
        ri_user_op_len <= i_user_op_len;
    end else if(!w_run_negedge && r_spi_clk_cnt &&(r_spi_dcnt <= P_USER_OPE_LEN-1)) 
    begin
        ri_user_op_data <= ri_user_op_data<<1;          // 先发高位
    end else 
    begin
        ri_user_op_data <= ri_user_op_data;
        ri_user_op_len <= ri_user_op_len;
    end
end

always@(posedge i_clk, posedge i_rst)   //  发送数据 user--->mosi   opdata + writedata + readdata
begin
    if(i_rst)
        ro_spi_mosi <= 'd0;
    else if(w_active)
        ro_spi_mosi <= i_user_op_data[P_USER_OPE_LEN - 1];
    else if(!w_run_negedge && !r_write_cnt && !r_read_cnt)                //  写指令+地址
        if((r_spi_clk_cnt) && r_spi_dcnt <= P_USER_OPE_LEN-1)
            ro_spi_mosi <= ri_user_op_data[P_USER_OPE_LEN - 1];
        else 
            ro_spi_mosi <= ro_spi_mosi;
    else if(!w_run_negedge && P_USER_OPE_TYPE == 2 && r_spi_clk_cnt)                       //  写数据
        if(r_write_clk && r_write_clk <= 8)
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
    else if(P_USER_OPE_TYPE == 1 && !r_spi_clk_cnt)
        if(r_read_clk && r_read_cnt <= ri_read_len)
            ro_read_data <= {ro_read_data[P_READ_DATA_WIDTH-2 : 0], i_spi_miso};
        else 
            ro_read_data <= ro_read_data;
    else
        ro_read_data <= ro_read_data;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ri_read_len <= 'd0;
    else if(P_USER_OPE_TYPE == 1 && w_active)
        ri_read_len <= i_read_len >> 3;     //转成字节数
    else
        ri_read_len <= ri_read_len;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_read_valid <='d0;
    else if(P_USER_OPE_TYPE == 1 && !r_spi_clk_cnt && r_read_clk == 8)
        ro_read_valid <='d1;
    else
        ro_read_valid <='d0;
end


always@(posedge i_clk, posedge i_rst)   //  写请求
begin
    if(i_rst)
        r_write_req <= 'd0;
    else if(P_USER_OPE_TYPE == 2 && !r_spi_clk_cnt)
        if((r_write_cnt < ri_write_len && r_write_clk == 7)|| (r_spi_dcnt == P_USER_OPE_LEN - 2))
            r_write_req <= 'd1;
        else 
            r_write_req <= 'd0;
    else
        r_write_req <= 'd0;
end

always@(posedge i_clk, posedge i_rst)   //  写请求_1d
begin
    if(i_rst)
        r_write_req_1d <= 'd0;
    else 
        r_write_req_1d <= r_write_req;
end
always@(posedge i_clk, posedge i_rst)   //  写clk
begin
    if(i_rst)
        r_write_clk <= 'd0; 
    else if(P_USER_OPE_TYPE == 2)
        if(w_run_negedge || (r_write_cnt == ri_write_len && r_write_clk == 8 && !r_spi_clk_cnt))
            r_write_clk <= 'd0;
        else if(r_write_req_1d)
            r_write_clk <= 'd1;
        else if(r_write_clk && !r_spi_clk_cnt)
            r_write_clk <= r_write_clk + 1;
        else 
            r_write_clk <= r_write_clk;
    else
        r_write_clk <= r_write_clk;
end

always@(posedge i_clk, posedge i_rst)   //  写cnt
begin
    if(i_rst)
        r_write_cnt <= 'd0;
    else if(P_USER_OPE_TYPE == 2)
        if((r_write_cnt == ri_write_len) && r_write_clk == 8 && !r_spi_clk_cnt)     // 处理写数据结尾
            r_write_cnt <= 'd0;
        else if(r_write_req_1d)
            r_write_cnt <= r_write_cnt + 'd1;
        else 
            r_write_cnt <= r_write_cnt;
    else
        r_write_cnt <= r_write_cnt;
end

always@(posedge i_clk, posedge i_rst)   //  写数据
begin
    if(i_rst)begin
        ri_write_data <= 'd0;
        ri_write_len <= 'd0;
    end else if(P_USER_OPE_TYPE == 2)
        if(r_write_req_1d)begin
            ri_write_data <= i_user_write_data;
            ri_write_len <= i_write_len >> 3;     //转成字节数
        end else if(r_write_clk && r_write_clk <= 8 && r_spi_clk_cnt)        // 并转串
            ri_write_data <= ri_write_data<< 1;         
        else 
            ri_write_data <= ri_write_data;
    else
        ri_write_data <= ri_write_data;
end

always@(posedge i_clk, posedge i_rst)   //  读请求
begin
    if(i_rst)
        r_read_req <= 'd0;
    else if(P_USER_OPE_TYPE == 1 && !r_spi_clk_cnt) // 保持一个spi clk，确保下降沿能读取到req。
        if((r_read_cnt < ri_read_len && r_read_clk == 7)|| (r_spi_dcnt == P_USER_OPE_LEN - 2))
            r_read_req <= 'd1;
        else if((r_read_cnt < ri_read_len && r_read_clk == 8)|| (r_spi_dcnt == P_USER_OPE_LEN - 1))
            r_read_req <= 'd0;
        else 
            r_read_req <= r_read_req;
    else
        r_read_req <= 'd0;
end

always@(posedge i_clk, posedge i_rst)   //  读数据 req_1d
begin
    if(i_rst)
        r_read_req_1d <= 'd0;
    else
        r_read_req_1d <= r_read_req;
end

always@(posedge i_clk, posedge i_rst)   //  读 cnt
begin
    if(i_rst)
        r_read_cnt <= 'd0;        
    else if(P_USER_OPE_TYPE == 1)
        if(r_read_cnt == ri_read_len && r_read_clk == 8 && r_spi_clk_cnt)
            r_read_cnt <= 'd0;
        else if(r_spi_dcnt == P_USER_OPE_LEN-1 && !r_spi_clk_cnt)
            r_read_cnt <= r_read_cnt + 'd1; 
        else if((r_read_clk == 8 && r_spi_clk_cnt))
            r_read_cnt <= r_read_cnt + 'd1;
        else 
            r_read_cnt <= r_read_cnt;
    else
        r_read_cnt <= r_read_cnt;
end

always@(posedge i_clk, posedge i_rst)   //  读clk
begin
    if(i_rst)
        r_read_clk <= 'd0;
    else if(P_USER_OPE_TYPE == 1 && r_spi_clk_cnt && r_read_cnt <= ri_read_len)
        if(r_read_clk == 8 && r_read_cnt < ri_read_len)
            r_read_clk <= 'd1;
        else if(r_read_clk == 8 && r_read_cnt == ri_read_len)
            r_read_clk <= 'd0;
        else if(r_read_clk || (r_spi_dcnt == P_USER_OPE_LEN-1))
            r_read_clk <= r_read_clk + 'd1;
        else 
            r_read_clk <= r_read_clk;
    else
        r_read_clk <= r_read_clk;
end

endmodule
