`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/04/2024 08:16:41 PM
// Design Name: 
// Module Name: uart_tx
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

// start 1b
// data  8b
// check 1b
// stop  1b

module uart_tx#(
    parameter       buad_rate        =   9600,
    parameter       clk_rate         =   50_000_000,
    parameter       uart_data_width  =   8   ,   // 8b
    parameter       check            =   1   ,   // 0: no check, 1: odd check, 2: even check
    parameter       stop_width       =   1
)(
    input           i_clk,
    input           i_rst,
    input [uart_data_width-1 : 0]   i_tx_data,
    
    input           i_tx_valid,
    output          o_tx_ready,
    output          o_tx
);


reg [uart_data_width-1 : 0]     ri_tx_data  ;
reg [7 : 0]                     r_cnt       ;
reg                             ro_tx_ready ;
reg                             ro_tx       ;
reg                             r_check     ;


wire                            w_active    ;

assign      o_tx_ready  =       ro_tx_ready;
assign      o_tx        =       ro_tx      ;
assign      w_active    =       (i_tx_valid & ro_tx_ready);    // 握手有效


localparam  tx_data_width = (check == 0) ? uart_data_width + stop_width+1 
                                         : uart_data_width + stop_width+2;


always@(posedge i_clk)
begin
    if(i_rst)
        ro_tx_ready <= 1'b1;
    else if(w_active)
        ro_tx_ready <= 1'b0;
    else if(r_cnt == tx_data_width)
        ro_tx_ready <= 1'b1;
    else
        ro_tx_ready <= ro_tx_ready;
end

always@(posedge i_clk)
begin
    if(i_rst)
        r_cnt <= 'd0;    
    else if(r_cnt == tx_data_width)
        r_cnt <= 'd0;
    else if(w_active || !ro_tx_ready)       // 握手后运行状态
        r_cnt <= r_cnt + 1;
end

always@(posedge i_clk)
begin
    if(i_rst)
        ro_tx <= 1'b1;
    else if(w_active)
        ro_tx <= 1'b0;
    else if(!ro_tx_ready && r_cnt < uart_data_width + 1)
        ro_tx <= ri_tx_data[0];
    else if(!ro_tx_ready && check > 0 && r_cnt == tx_data_width - stop_width-1)
        ro_tx <= (check == 2)? r_check : ~r_check;
    else if(!ro_tx_ready && r_cnt >= tx_data_width - stop_width)
        ro_tx <= 1'b1;
    else
        ro_tx <= 1'b1;
end

always@(posedge i_clk)
begin
    if(i_rst)
        ri_tx_data <= 'd0;
    else if(w_active)
        ri_tx_data <= {i_tx_data[uart_data_width-2:0], i_tx_data[uart_data_width-1]};
    else if(!ro_tx_ready && r_cnt < uart_data_width)
        ri_tx_data <= {ri_tx_data[uart_data_width-2:0], ri_tx_data[uart_data_width-1]}; // 换位，传输高位
    else 
        ri_tx_data <= ri_tx_data;
end

always@(posedge i_clk)
begin
    if(i_rst || ro_tx_ready)
        r_check <= 'd0;
    else if(!ro_tx_ready && check > 0 && r_cnt < uart_data_width + 1)
        r_check <= r_check ^ ri_tx_data[0];                             // 这个时候还没换位，下个节拍生效
    else
        r_check <= r_check;
end


endmodule
