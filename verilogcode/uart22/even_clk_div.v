`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2024 11:59:15 AM
// Design Name: 
// Module Name: odd_clk_div
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


module even_clk_div#(
    parameter CLK_DIV_CNT = 2   // 默认 2 分频，偶数分频
)(
    input i_clk,
    input i_rst,

    output o_clk
);

reg     [15:0]  r_cnt;
reg             ro_clk;

assign   o_clk = ro_clk;

always @(posedge i_clk)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == ((CLK_DIV_CNT>>1) - 1) || CLK_DIV_CNT==0)
        r_cnt <= 'd0;
    else    
        r_cnt <= r_cnt + 1;
end

always @(posedge i_clk)
begin
    if(i_rst)
        ro_clk <= 1'b0;
    else if(r_cnt == ((CLK_DIV_CNT>>1) - 1) || CLK_DIV_CNT==0)
        ro_clk <= ~ro_clk;
    else 
        ro_clk <= ro_clk;
end

endmodule
