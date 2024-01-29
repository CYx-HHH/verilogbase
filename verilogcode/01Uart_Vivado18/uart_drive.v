`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/22 17:38:37
// Design Name: 
// Module Name: uart_drive
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


module uart_drive#(
    parameter           P_SYSTEM_CLK        =50_000_000     ,
    parameter           P_UART_BURD_RATE    =9600           ,
    parameter           P_UART_DATA_WIDTH   =8              ,
    parameter           P_UART_CHECK_ON     =1              ,   // None=0 Odd-1 Even-2
    parameter           P_UART_STOP_WIDTH   =1                  // 波特率
)(  
    input               i_clk                               ,
    input               i_rst                               ,
    
    input [P_UART_DATA_WIDTH-1 :0]      i_user_tx_data      ,   // 接收user输入
    input                               i_user_tx_valid     ,   // 接收输入有效

    output                              o_user_tx_ready     ,   // 输出准备好
    
    output                              o_uart_tx           ,   // 串口发送 
    input                               i_uart_rx           ,   // 串口接收
   
    output [P_UART_DATA_WIDTH-1 :0]     o_uart_rx_data      ,   // 数据输出
    output                              o_uart_rx_valid     ,   // 数据是否有效-校验

    output                              o_uart_clk          ,   // 串口时钟
    output                              o_uart_rst              // 串口复位
);

localparam  L_DIV_CLK = P_SYSTEM_CLK/P_UART_BURD_RATE;


wire                                w_baud_clk;
wire                                w_baud_rst;
wire                                w_rx_clk;
wire                                w_rx_rst;

wire                                w_uart_rx_valid;
wire [P_UART_DATA_WIDTH-1 :0]       wo_uart_rx_data;

reg [2:0]                           r_overvalue;
reg [2:0]                           r_overvalue_1d;
reg                                 r_overlock;
reg                                 ro_uart_rx_valid;
reg                                 r_rx_clk_rst;
reg [P_UART_DATA_WIDTH-1 :0]        ro_uart_rx_data;
// assign  o_uart_rx_data   =  ro_uart_rx_data;
// assign  o_uart_rx_valid  =  ro_uart_rx_valid;

assign  o_uart_clk      =  w_baud_clk;
assign  o_uart_rst      =  w_baud_rst;

assign  o_uart_rx_valid =  ro_uart_rx_valid;
assign  o_uart_rx_data  =  ro_uart_rx_data;


clk_div#(
    .P_CLK_DIV_CNT          (L_DIV_CLK)         // 指定时钟周期
)
clk_div_c0(
    .i_rst                  (i_rst),   // 输入复位         
    .i_clk                  (i_clk),   // 输入时钟
    .o_clk_div              (w_baud_clk)    // 输出时钟信号
);


rst_generate#(
    .P_RST_CYCLE            (10)
)
rst_generate_r0(
    .i_clk                  (w_baud_clk),
    .o_rst                  (w_baud_rst)
);


clk_div#(
    .P_CLK_DIV_CNT          (L_DIV_CLK)         // 指定时钟周期
)
clk_div_c1(
    .i_rst                  (r_rx_clk_rst),     // 分频模块校准时钟         
    .i_clk                  (i_clk),            // 输入时钟
    .o_clk_div              (w_rx_clk)          // 输出时钟信号
);


uart_tx#(
    .P_SYSTEM_CLK           (P_SYSTEM_CLK       ),
    .P_UART_BURD_RATE       (P_UART_BURD_RATE   ),
    .P_UART_DATA_WIDTH      (P_UART_DATA_WIDTH  ),
    .P_UART_CHECK_ON        (P_UART_CHECK_ON    ),  // None=0 Odd-1 Even-2
    .P_UART_STOP_WIDTH      (P_UART_STOP_WIDTH  )   // 波特率
)
uart_tx_t0(
    .i_clk                  (w_baud_clk         ),
    .i_rst                  (w_baud_rst         ),       
    .i_user_tx_valid        (i_user_tx_valid    ),  // 接收输入有效    .
    .i_user_tx_data         (i_user_tx_data     ),  // 接收user输入
    
    .o_user_tx_ready        (o_user_tx_ready    ),  // 输出准备好
    .o_uart_tx              (o_uart_tx          )   // 串口输出 
);


uart_rx#(
    .P_SYSTEM_CLK           (P_SYSTEM_CLK       ),
    .P_UART_BURD_RATE       (P_UART_BURD_RATE   ),
    .P_UART_DATA_WIDTH      (P_UART_DATA_WIDTH  ),
    .P_UART_CHECK_ON        (P_UART_CHECK_ON    ),  // None=0 Odd-1 Even-2
    .P_UART_STOP_WIDTH      (P_UART_STOP_WIDTH  )   // 波特率
)
uart_rx_r0(  
    .i_clk                  (w_rx_clk           ),
    .i_rst                  (r_rx_clk_rst       ),
    .i_uart_rx              (i_uart_rx          ),  // 串口输入
    
    .o_uart_rx_valid        (w_uart_rx_valid    ),  // 数据是否有效-校验
    .o_uart_rx_data         (wo_uart_rx_data    )   // 数据输出
);



/*校准时钟*/

always@(posedge i_clk, posedge i_rst)
begin                                   // 000 001 valid=0 
    if(i_rst)
        r_overvalue <= 'd0;
    else if(!r_overlock)
        r_overvalue <= {r_overvalue[1: 0], i_uart_rx};
    else 
        r_overvalue <= 'd0;
end

always@(posedge i_clk, posedge i_rst)   // 状态锁，低有效
begin
    if(i_rst)
        r_overlock <= 'd0;
    else if(!w_uart_rx_valid && ro_uart_rx_valid)           //  下降沿
        r_overlock <= 'd0;
    else if(r_overvalue != 'd0 && r_overvalue_1d == 'd0)     //  上升沿
        r_overlock <= 'd1;
    else
        r_overlock <= r_overlock;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_overvalue_1d <= 'd0;
    else
        r_overvalue_1d <= r_overvalue;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_uart_rx_valid <= 'd0;
    else
        ro_uart_rx_valid <= w_uart_rx_valid;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_uart_rx_data <= 'd0;
    else
        ro_uart_rx_data <= wo_uart_rx_data;
end

always@(posedge i_clk, posedge i_rst)   //  复位高有效
begin
    if(i_rst || (!w_uart_rx_valid && ro_uart_rx_valid))
        r_rx_clk_rst <= 'd1;
    else if(r_overvalue != 'd0 && r_overvalue_1d == 'd0)
        r_rx_clk_rst <= 'd0;
    else
        r_rx_clk_rst <= r_rx_clk_rst;
end

endmodule
