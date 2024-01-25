`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/22 17:44:23
// Design Name: 
// Module Name: rst_generate
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


/* 设置复位周期数   */
module rst_generate#(
    parameter   P_RST_CYCLE     =   1
)(
    input       i_clk,
    output      o_rst
);

reg [7:0]       r_rst_cnt   ='d0    ;
reg             ro_rst      ='d1    ;

assign          o_rst       =ro_rst;

always@(posedge i_clk)
begin
    if(r_rst_cnt == P_RST_CYCLE - 1 || P_RST_CYCLE == 0)
        r_rst_cnt   <=  r_rst_cnt;
    else
        r_rst_cnt   <=  r_rst_cnt + 'b1;
end


always@(posedge i_clk)
begin
    if(r_rst_cnt == P_RST_CYCLE - 1 || P_RST_CYCLE == 0)
        ro_rst    ='d0;
    else
        ro_rst    ='d1;
end

endmodule
