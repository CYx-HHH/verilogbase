`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2024 09:09:23 PM
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

//
//  
//  fifo串口回环测试，数据 rx---》rxdata---》txdata---》tx 
//  复位怎么处理？        锁相环信号稳定后复位

module uart_top(
    input         i_clk ,
    //input       i_rst,
    input         i_uart_rx,
    output        o_uart_tx 
);


localparam      buad_rate           =   6   ;       
localparam      clk_rate            =   12  ;    
localparam      uart_data_width     =   8   ;   
localparam      check               =   2   ; 
localparam      stop_width          =   1   ;
localparam      rst_cycle           =   3   ;


wire        w_clk_50M;
wire        w_clk_rst;
wire        w_pll_lock;

assign      w_clk_rst   =   ~w_pll_lock;
//assign      w_clk_rst   =  i_rst;


wire  [uart_data_width-1  :0]     w_rx_data;
wire  [uart_data_width-1  :0]     w_tx_data;
wire                              w_rx_valid;
wire                              w_tx_ready;

wire                              w_full;
wire                              w_empty;
wire                              w_user_clk;
wire                              w_user_rst;

reg                               r_tx_valid;
reg                               r_rden;
reg                               r_wren;
reg                               r_rd_lock;

///// 仿真没有clk wizard

sys_clk_pll pll_u0
(
    .clk_out1     (w_clk_50M    ),    
    .locked       (w_pll_lock   ),                  // 信号稳定拉高   
    .clk_in1      (i_clk        )       
);

//assign  w_clk_50M  =  i_clk;


//
//  接收接收方数据---写使能，           再传给发送端---读使能
//  fifo空的时候不读使能，              fifo满的时候不写使能，
//  发送端ready的时候可以读，           接收端valid的时候可以写
//  
//
fifo_8x1024 fifo_u0 (
  .clk          (w_clk_50M    ),          // input wire clk
  .din          (w_rx_data    ),          // input wire [7 : 0] din
  .wr_en        (r_wren       ),          // input wire wr_en
  .rd_en        (r_rden       ),          // input wire rd_en
  .dout         (w_tx_data    ),          // output wire [7 : 0] dout
  .full         (w_full       ),          // output wire full
  .empty        (w_empty      )           // output wire empty
);


uart_drive#(
    .buad_rate              (buad_rate        ),
    .clk_rate               (clk_rate         ),
    .uart_data_width        (uart_data_width  ),   // 8b
    .check                  (check            ),   // 0: no check, 1: odd check, 2: even check
    .stop_width             (stop_width       ),
    .rst_cycle              (rst_cycle        )
)uart_d0
(
    .i_clk                  (w_clk_50M        ),
    .i_rst                  (w_clk_rst        ),
    .i_rx                   (i_uart_rx        ),
    .o_tx                   (o_uart_tx        ),
    .ouser_rx_data          (w_rx_data        ),
    .ouser_rx_valid         (w_rx_valid       ),
    .iuser_tx_data          (w_tx_data        ),
    .iuser_tx_valid         (r_rden           ),        //  赋值给r_tx_valid，也不会延后一拍
    .ouser_tx_ready         (w_tx_ready       ),
    .ouser_clk              (w_user_clk       ),        //  发送方的用户时钟
    .ouser_rst              (w_user_rst       )    
);


//  为什么给fifo加一个读锁，txready信号会抖动吗
//  因为txready拉高两个周期，一次读两个数据但只能传8bit，会丢数据
always@(posedge w_user_clk)
begin
    if(w_user_rst)
      r_wren <= 1'b0;
    else
      r_wren <= w_rx_valid && !w_full;
end

always@(posedge w_user_clk)
begin
    if(w_user_rst)
      r_rd_lock <= 1'b0;
    else if(w_tx_ready && !w_empty)
      r_rd_lock <= 1'b1;
    else
      r_rd_lock <= 1'b0;
end

always@(posedge w_user_clk)
begin
    if(w_user_rst)
      r_rden <= 1'b0;
    else if(r_rd_lock)
      r_rden <= 1'b0;
    else
      r_rden <= w_tx_ready && !w_empty;
end


// always@(posedge w_user_clk)    
// begin
//     if(w_user_rst)
//       r_tx_valid <= 1'b0;
//     else
//       r_tx_valid <= r_rden;
// end


endmodule
