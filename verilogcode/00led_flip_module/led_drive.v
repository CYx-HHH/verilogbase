`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/20 17:41:09
// Design Name: 
// Module Name: led_drive
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

// 接收信号，对数量LED按周期进行翻转
module led_drive#(
    parameter                   P_LED_NUMBER    = 1         ,   // LED个数
    parameter                   P_LED_CNT       = 5000      ,   // LED翻转时间
    parameter                   P_LED_ON        = 1             // LED亮灭
)(
    input                       i_rst                       ,       
    input                       i_clk                       ,   // 5M
    output[P_LED_NUMBER-1:0]    o_led                           // 输出LED组
);


reg [P_LED_NUMBER-1:0]          ro_led                      ;   // LED输出寄存器
reg [15:0]                      r_cnt                       ;   // 计数  

wire                            w_clk_1KHZ                  ;   // 1KHZ时钟信号

                                                                //      时钟分频模块
clk_div#(       
    .P_CLK_DIV_CNT      (2          )                          // 指定时钟周期
//    .P_RST_CNT          (1          )                           // 指定复位周期，至少为1 
)       
clk_div_c0(     
    .i_rst              (i_rst      )                       ,   // 输入复位         
    .i_clk              (i_clk      )                       ,   // 输入时钟
    .o_clk_div          (w_clk_1KHZ )                          // 输出时钟信号
//  .o_rst_div          (w_rst_cnt  )                           // 输出复位信号
);    


assign                  o_led = ro_led                      ;   // 将引脚绑定在输出寄存器上


always@(posedge w_clk_1KHZ, posedge i_rst)
begin
    if(i_rst)begin
        r_cnt <= 'd0;
    end else if(r_cnt == P_LED_CNT-1) begin
        r_cnt <= 'd0;
    end else begin
        r_cnt <= r_cnt + 1;
    end
end

always@(posedge w_clk_1KHZ, posedge i_rst)
begin
    if(i_rst)
        ro_led <= 'd0;
    else if(r_cnt == P_LED_CNT-1) begin
        ro_led <= ~ro_led;
    end else
        ro_led <= ro_led;
end


endmodule
