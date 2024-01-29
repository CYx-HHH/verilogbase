`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/22 17:38:37
// Design Name: 
// Module Name: uart_tx
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

// 发送方 也需要打两拍-
// 分频 PLL
/*
    输入时钟频率可配置---就是波特率？---根据输入时钟来每秒传输bit
    波特率可配置-带宽 bps   每秒多少bits    一个周期1bit，5M节拍/波特率得到分频值
    数据位可配置-位宽       每次握手传输位数
    校验位可配置-启用/禁用
    停止位可配置-位宽

*/ 


/* 发送方：我空闲了，准备好发送了            上层用户：开始传数据    */

module uart_tx#(
    parameter           P_SYSTEM_CLK        =50_000_000 ,
    parameter           P_UART_BURD_RATE    =9600       ,
    parameter           P_UART_DATA_WIDTH   =8          ,
    parameter           P_UART_CHECK_ON     =1          ,   // None=0 Odd-1 Even-2
    parameter           P_UART_STOP_WIDTH   =1              // 波特率
)(
    input               i_clk                           ,
    input               i_rst                           ,

    input                           i_user_tx_valid     ,   // 接收输入有效
    input [P_UART_DATA_WIDTH-1 :0]  i_user_tx_data      ,   // 接收user输入

    // output  [15:0]                          o_cnt,
    // output                          o_tx_check,
    // output                          o_tx_active,
    // output  [P_UART_DATA_WIDTH-1 :0]                          o_data,

    output                          o_user_tx_ready     ,   // 输出准备好
    output                          o_uart_tx               // 串口输出 
);




wire                                w_tx_active         ;   // tx是否空闲/是否能发数据
reg  [P_UART_DATA_WIDTH-1 :0]       r_user_tx_data      ;   // 接收user输入---慢了一拍/并转串

reg                                 ro_user_tx_ready    ;   // 输出准备
reg                                 ro_uart_tx          ;   // 串口输出    

reg                                 r_tx_check          ;   // 校验 
reg [15:0]                          r_cnt               ;   // 计数器
/*计数器位宽高于16bit时，组合逻辑的逻辑级数过高，谨慎使用。*/



// wire        o_cnt           ;
// wire        o_tx_check      ;
// wire        o_tx_active     ;
// wire        o_data          ;


// 绑引脚
assign   w_tx_active        =   i_user_tx_valid & o_user_tx_ready   ;
assign   o_user_tx_ready    =   ro_user_tx_ready                    ;
assign   o_uart_tx          =   ro_uart_tx                          ;

// assign   o_cnt              =   r_cnt                               ;
// assign   o_tx_check         =   r_tx_check                          ;
// assign   o_tx_active        =   w_tx_active                         ;
// assign   o_data             =   i_user_tx_data;




// 起始位/1b + 数据位/x + 校验位/1b + 停止位/y     1+x+1+y     停止位可省
/* 计数器打拍，清零 */

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_cnt <= 'd0;               
    else if(r_cnt == (2 + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH) - 1 && P_UART_CHECK_ON > 0)
        r_cnt <= 'd0;
    else if(r_cnt == ((2 + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH) - 2) && !P_UART_CHECK_ON)
        r_cnt <= 'd0;
    else if(!ro_user_tx_ready)                // ready为0开始计数； 012345678 9 10 
        r_cnt <= r_cnt + 1;
    else
        r_cnt <= r_cnt;
end

/* 什么时候能发数据/发完结束*/

always@(posedge i_clk, posedge i_rst)   // ready只有发数据才0，其他都是1
begin
    if(i_rst)
        ro_user_tx_ready <= 1'd1;
    else if(w_tx_active)
        ro_user_tx_ready <= 1'd0;
    else if(r_cnt == ((2 + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH) - 1) && P_UART_CHECK_ON > 0)
        ro_user_tx_ready <= 1'd1;
    else if(r_cnt == ((2 + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH) - 2) && !P_UART_CHECK_ON)
        ro_user_tx_ready <= 1'd1;
    else
        ro_user_tx_ready <= ro_user_tx_ready;
end

/* 发数据，接收用户数据-慢了一拍-并转串 */

always@(posedge i_clk, posedge i_rst)   // 串转并
begin
    if(i_rst)
        r_user_tx_data <= 'd0;
    else if(w_tx_active)
        r_user_tx_data <= i_user_tx_data;
    else if(!ro_user_tx_ready)
        r_user_tx_data <= r_user_tx_data>>1;
    else
        r_user_tx_data <= 'd0;
end

//cnt       0 0 1 2 3 4 5 6 7 8 c s s         active为1开始计数；
//cnt       0 0 0 1 2 3 4 5 6 7 8 c s s       ready为0计数慢一拍（因为active为1后一拍 ready为0
//data          0 1 2 3 4 5 6 7 8 c s s
//ready     1 1 0 0 0 0 0 0 0 0 0 0 0 1
//wxactive  0 1 0 0 0 0 0 0 0 0 0 0 0 1
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_uart_tx <= 1'd1;
    else if(w_tx_active)        // 起始位 拉低 0 0 1 1 
        ro_uart_tx <= 1'd0;
    else if(!ro_user_tx_ready && r_cnt < P_UART_DATA_WIDTH)    // 数据位 第0位传第一个数据
        ro_uart_tx <= r_user_tx_data[0];
    else if(!ro_user_tx_ready && r_cnt == (P_UART_DATA_WIDTH) && P_UART_CHECK_ON > 0)    // 校验位
        ro_uart_tx <= P_UART_CHECK_ON==2? r_tx_check : ~r_tx_check;
    else if(!ro_user_tx_ready && r_cnt <= (P_UART_DATA_WIDTH + P_UART_STOP_WIDTH-1) && !P_UART_CHECK_ON)  // 停止位
        ro_uart_tx <= 1'd1;
    else if(!ro_user_tx_ready && r_cnt <= (P_UART_DATA_WIDTH + P_UART_STOP_WIDTH) && P_UART_CHECK_ON > 0)   // 停止位
        ro_uart_tx <= 1'd1;
    else
        ro_uart_tx <= ro_uart_tx;   // 保持
end

/* 校验位产生   */

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_tx_check <= 1'd0;
    else if(P_UART_CHECK_ON > 0 && r_cnt < P_UART_DATA_WIDTH)  
        r_tx_check <=  r_tx_check ^ r_user_tx_data[0];      // 偶数0，奇数1  
    else
        r_tx_check <= 1'd0;
end
endmodule
