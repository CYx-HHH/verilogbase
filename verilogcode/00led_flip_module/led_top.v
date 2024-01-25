`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/20 17:41:09
// Design Name: 
// Module Name: led_top
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

// 调用实例化模块，组合实现功能
module led_top(
    input           i_clk,
    output[1:0]     o_led
);


wire w_clk_5MHZ;
wire w_clk_locked;

//  50MHZ=50,000,000  50KHZ=50,000 


CLK_PLL CLK_PLL_U0
 (
  .clk_in1      (i_clk          ),
  .clk_out1     (w_clk_5MHZ     ),
  .locked       (w_clk_locked   )
 );

led_drive#(
    .P_LED_NUMBER           (2      )   ,   // LED个数
    .P_LED_CNT              (5000   )   ,   // LED翻转时间
    .P_LED_ON               (1      )       // LED亮灭
)led_drive_u0
(       
    .i_clk                  (w_clk_5MHZ )     ,   // 5M
    .i_rst                  (~w_clk_locked)   ,
    .o_led                  (o_led       )         // 输出LED组
);




//  仿真
// reg clk,rst;
// initial begin
//     clk = 1'b0;
//     rst = 1'b1;
//     #10 rst = 1'b0;
//     #10 rst = 1'b1;

// end

// always begin
//     clk=0;
//     #10;
//     clk=1;
//     #10;
// end


endmodule
