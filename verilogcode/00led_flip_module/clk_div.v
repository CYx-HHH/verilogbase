`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/01/20 17:41:09
// Design Name: 
// Module Name: clk_div
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


                                        // 对时钟信号调整，输出指定周期时钟信号
module clk_div#(
    parameter   P_CLK_DIV_CNT=2         // 指定时钟周期
//    parameter   P_RST_CNT=1           // 指定复位周期，至少为1 
)(
    input       i_rst               ,   // 输入复位         
    input       i_clk               ,   // 输入时钟
    output      o_clk_div               // 输出时钟信号
//    output      o_rst_div             // 输出复位信号
);

reg [15:0]  r_clk_cnt                               ;
reg         ro_o_clk_div                            ; 

//reg [15:0]  r_rst_cnt                               ;
//reg         ro_o_rst_div                            ;
//wire        w_clk_div                               ;      


assign      o_clk_div = ro_o_clk_div                ;

//assign      o_rst_div = ro_o_rst_div                ;


// if(P_RST_CNT == 0)begin
//     assign w_clk_div = 1;
// end else
//     assign w_clk_div = P_RST_CNT;



                                            // 时钟计数器
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)begin
        r_clk_cnt <= 'd0;
    end 
    else if(r_clk_cnt == (P_CLK_DIV_CNT >> 1) - 1) begin
        r_clk_cnt <= 'd0;
    end 
    else 
    begin
        r_clk_cnt <= r_clk_cnt + 1;
    end
end

                                            // 时钟信号翻转，条件为cnt/复位周期
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)begin
        ro_o_clk_div <= 'd1;
    end else if(r_clk_cnt == (P_CLK_DIV_CNT >> 1) - 1) begin
        ro_o_clk_div <= ~ro_o_clk_div;
    end else begin
        ro_o_clk_div <= ro_o_clk_div;
    end
end


//                                          // 复位计数器
// always@(posedge ro_o_clk_div, posedge i_rst)
// begin
//     if(i_rst || (w_clk_div == 1))begin
//         r_rst_cnt <= 'd0;               
//     end else if(r_rst_cnt == (w_clk_div-1)) begin
//         r_rst_cnt <= r_rst_cnt;          // 周期到, 保持不变
//     end else begin
//         r_rst_cnt <= r_rst_cnt + 1;      // 计数
//     end
// end

//                                          // 复位信号翻转
// always@(posedge ro_o_clk_div, posedge i_rst)
// begin
//     if(i_rst)begin
//         ro_o_rst_div <= 'd1;             // 复位拉高
//     end else if(r_rst_cnt == (w_clk_div-1)) begin
//         ro_o_rst_div <= 'd0;             // 复位周期到，拉低
//     end else begin
//         ro_o_rst_div <= ro_o_rst_div;    // 保持不变
//     end
// end

endmodule

