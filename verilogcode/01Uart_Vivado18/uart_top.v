`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/24 21:26:12
// Design Name: 
// Module Name: uart_top
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
module uart_top
    // input               i_clk               ,
    // input               i_uart_rx           ,      
    // output              o_uart_tx                 
;

localparam CLK_PERIOD = 10;
reg i_clk;
reg i_rst;

initial begin
    i_rst = 'b1;
    i_clk = 'b0;
    #10;
    @(posedge i_clk) i_rst = 'b0;   // 细节上升沿
end

always
begin
    #(CLK_PERIOD) i_clk = ~i_clk;
end


localparam P_UART_DATA_WIDTH = 8;

reg [P_UART_DATA_WIDTH-1 : 0]   r_tx_ger_data;
reg                             r_tx_valid;

wire [P_UART_DATA_WIDTH-1 : 0]  w_rx_ger_data;
wire                            w_rx_valid;

wire                            w_user_clk;
wire                            w_user_rst;   

wire                            w_tx_ready;
wire                            w_tx_active;
wire                            w_uart_rtx;
wire                            w_out_rx_in_fifo;
wire                            w_out_fifo_in_tx;

wire                            w_fifo_empty;
wire                            w_fifo_full;
reg                             r_fifo_wr_en;
reg                             r_fifo_rd_en;

assign  w_tx_active = w_tx_ready & r_tx_valid;


clk_div#(
    .P_CLK_DIV_CNT(2)         // 指定时钟周期
)clk_div_d3(
    .i_rst    (i_rst)           ,   // 输入复位         
    .i_clk    (i_clk)           ,   // 输入时钟
    .o_clk_div(w_user_clk)               // 输出时钟信号
);

rst_generate#(
    .P_RST_CYCLE     (2)
)rst_generate_r1(
    .i_clk(w_user_clk),
    .o_rst(w_user_rst)
);


uart_drive#(
    .P_SYSTEM_CLK       (50_000_000)     ,
    .P_UART_BURD_RATE   (9600      )     ,
    .P_UART_DATA_WIDTH  (P_UART_DATA_WIDTH)     ,
    .P_UART_CHECK_ON    (1         )     ,   // None=0 Odd-1 Even-2
    .P_UART_STOP_WIDTH  (1         )         // 波特率
)uart_drive_d2(  
    .i_clk          (i_clk)              ,
    .i_rst          (i_rst)              ,
    .i_user_tx_data (r_tx_ger_data)     ,   // 接收user输入
    .i_user_tx_valid(r_tx_valid)     ,   // 接收输入有效

    .o_user_tx_ready(w_tx_ready )     ,   // 输出准备好
    .o_uart_tx      (w_out_fifo_in_tx   )     ,   // 串口发送 
    
    .i_uart_rx      (w_out_rx_in_fifo   )     ,   // 串口接收

    .o_uart_rx_data (w_rx_ger_data)     ,   // 数据输出
    .o_uart_rx_valid(w_rx_valid)     ,   // 数据是否有效-校验
    .o_uart_clk     (w_user_clk)     ,   // 串口时钟
    .o_uart_rst     (w_user_rst)         // 串口复位
);


Uart_fifo Uart_fifo_u0(
    .clk    (w_user_clk         ),
    .srst   (w_user_rst         ),
    .din    (w_out_rx_in_fifo   ), 
    .wr_en  (r_fifo_wr_en       ),
    .rd_en  (r_fifo_rd_en       ),

    .dout   (w_out_fifo_in_tx   ),
    .full   (w_fifo_full        ),
    .empty  (w_fifo_empty       )
);

always@(posedge w_user_clk, posedge w_user_rst)
begin
    if(w_user_rst)
        r_fifo_wr_en <= 'd0;
    else if(!w_fifo_full && w_rx_valid)
        r_fifo_wr_en <= 'd1;
    else
        r_fifo_wr_en <= 'd0;
end


always@(posedge w_user_clk, posedge w_user_rst)
begin
    if(w_user_rst)
        r_fifo_rd_en <= 'd0;
    else if(!w_fifo_empty && w_tx_ready)
        r_fifo_rd_en <= 'd1;
    else
        r_fifo_rd_en <= 'd0;
end


always@(posedge w_user_clk, posedge w_user_rst)
begin
    if(w_tx_active || w_user_rst)    
        r_tx_valid <= 'd0;
    else if(w_tx_ready)     // 是线性，所以是同步赋值的 
        r_tx_valid <= r_fifo_rd_en;
    else
        r_tx_valid <= r_tx_valid;
end

always@(posedge w_user_clk, posedge w_user_rst) // 每个周期发一个数 
begin
    if(w_user_rst)
        r_tx_ger_data <= 'd0;
    else if(w_tx_active)  
        r_tx_ger_data <= r_tx_ger_data +'d1;
    else
        r_tx_ger_data <= r_tx_ger_data;     
end


endmodule
