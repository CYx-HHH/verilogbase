`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/22 17:38:37
// Design Name: 
// Module Name: uart_rx
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


/* 随时随地可以接收 */
module uart_rx#(
    parameter           P_SYSTEM_CLK        =50_000_000 ,
    parameter           P_UART_BURD_RATE    =9600       ,
    parameter           P_UART_DATA_WIDTH   =8          ,
    parameter           P_UART_CHECK_ON     =1          ,   // None=0 Odd-1 Even-2
    parameter           P_UART_STOP_WIDTH   =1              // 波特率
)(
    input               i_clk                           ,
    input               i_rst                           ,
    input               i_uart_rx                       ,   // 串口输入

    output                              o_uart_rx_valid ,   // 数据是否有效-校验
    output [P_UART_DATA_WIDTH-1 :0]     o_uart_rx_data      // 数据输出
);


reg                                 ro_uart_rx_valid    ;   // 数据是否有效-校验
reg [P_UART_DATA_WIDTH-1 :0]        ro_uart_rx_data     ;   // 数据输出

reg [15:0]                          r_cnt               ;
reg                                 r_rx_check          ;
reg [1 :0]                          r_uart_rx           ;   // 打两拍


reg [15:0]                          r_delay2_cnt        ;   // 延时时钟


assign o_uart_rx_data   =   ro_uart_rx_data;
assign o_uart_rx_valid  =   ro_uart_rx_valid;


/* 节拍器 */

// Verilog

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_cnt <='d0;
    else if(r_cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH +1 && P_UART_CHECK_ON > 0)
        r_cnt <='d0;
    else if(r_cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH && P_UART_CHECK_ON == 0)
        r_cnt <='d0;
    else if(i_uart_rx ==0 || r_cnt > 0)     // 用 r_uart_rx[0] cnt会慢一拍，cnt变成0012345678 
        r_cnt <= r_cnt +1;
    else
        r_cnt <= r_cnt;
end

/* 时钟对齐，打两拍和校准（在drive里实现）   */

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_uart_rx <= 'b11;
    else 
        r_uart_rx <={r_uart_rx[0], i_uart_rx};
end

// // 0 0 1 1 0 0 0
// // 1 1 1 0 0 1 1
// always@(posedge i_clk, posedge i_rst)   
// begin
//     if(i_rst || !r_rx_cache_clk)
//         r_flag <='d0;
//     else if(r_cnt == P_UART_DATA_WIDTH)
//         r_flag <='d1;
//     else 
//         r_flag <= r_flag;
// end

// always@(posedge i_clk, posedge i_rst)
// begin
//     if(i_rst || !r_flag)
//         r_rx_cache_clk <= ~r_flag;
//     else if(r_flag)
//         r_rx_cache_clk <= ~r_flag;
//     else 
//         r_rx_cache_clk <= r_rx_cache_clk;
// end
// i_uart_rx    0 1 2 3 4 5 6 7 8 9 10
// rcnt         0 1 2 3 4 5
// delaycnt     0 0 0 1 2 3 4 5  delay_cnt慢一拍
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_delay2_cnt <= 'd0;
    else if(r_delay2_cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH + 1 &&  P_UART_CHECK_ON > 0)
        r_delay2_cnt <= 'd0;
    else if(r_delay2_cnt == P_UART_DATA_WIDTH + P_UART_STOP_WIDTH &&  P_UART_CHECK_ON == 0)
        r_delay2_cnt <= 'd0;
    else if(r_uart_rx[1] == 0 || r_delay2_cnt > 0) 
        r_delay2_cnt <= r_delay2_cnt + 1;
    else 
        r_delay2_cnt <= r_delay2_cnt;   
end



/* 数据接收 */

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)          
        ro_uart_rx_data <= 'd0;
    else if(r_delay2_cnt >=1 && r_delay2_cnt <= P_UART_DATA_WIDTH)     // 数据位 延两拍
        ro_uart_rx_data <= {r_uart_rx[1], ro_uart_rx_data[P_UART_DATA_WIDTH-1: 1]}; //接收低位
                      // {ro_uart_rx_data[P_UART_DATA_WIDTH - 2: 0], r_uart_rx[1]} //接收高位
    else
        ro_uart_rx_data <= 'd0;
end


/* 校验 */
//  时序问题
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst || r_cnt == 0)
        r_rx_check <='d0;        
    else if(r_delay2_cnt >=1 && r_delay2_cnt <= P_UART_DATA_WIDTH && P_UART_CHECK_ON > 0)
        r_rx_check <= r_rx_check ^ r_uart_rx[1];
    else
        r_rx_check <= 'd0;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_uart_rx_valid <= 1'd0;
    else if(P_UART_CHECK_ON == 0)
        ro_uart_rx_valid <= 'd0;
    else if(r_delay2_cnt == P_UART_DATA_WIDTH && P_UART_CHECK_ON ==1 && r_uart_rx[0] == !r_rx_check)
        ro_uart_rx_valid <= 'd1;
    else if(r_delay2_cnt == P_UART_DATA_WIDTH && P_UART_CHECK_ON == 2 && r_uart_rx[0] == r_rx_check)
        ro_uart_rx_valid <= 'd1;
    else
        ro_uart_rx_valid <= 'd0;
end


endmodule
