`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2024 07:13:17 PM
// Design Name: 
// Module Name: rst_gen
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


module rst_gen#(
    parameter     RST_CYCLE = 100
)(
    input           i_clk,
    output          o_rst
);


reg [7:0]   rcnt    =   8'b0;  // 尽量不要用赋初值的方式
reg         ro_rst  =   'b1;

assign      o_rst   =   ro_rst;


always @(posedge i_clk)
begin
    if(rcnt == RST_CYCLE || RST_CYCLE == 0)
        ro_rst <= 1'b0;
    else 
        ro_rst <= 1'b1;
end

always@(posedge i_clk)
begin
    if(rcnt == RST_CYCLE || RST_CYCLE == 0)
        rcnt <= rcnt;
    else
        rcnt <= rcnt + 1;
end
endmodule
