`timescale 1ns / 1ps


//
// 没有ready信号，只有valid
// 接收 数据和校验位 就可以了
// 对于接收到的rx只慢一拍
//
// 异步时钟，亚稳态需要打两拍
//

module uart_rx#(
    parameter       buad_rate        =   9600       ,
    parameter       clk_rate         =   50_000_000 ,
    parameter       uart_data_width  =   8          ,   // 8b
    parameter       check            =   1          ,   // 0: no check, 1: odd check, 2: even check
    parameter       stop_width       =   1
)(
    input           i_clk   ,
    input           i_rst   ,
    input           i_rx    ,
    output [uart_data_width-1 : 0]   o_rx_data,
    output          o_rx_valid
);


localparam      rx_data_width = (check == 0)? uart_data_width + stop_width 
                                            : uart_data_width + stop_width+1;   // 没有开始位的位数

reg    [7:0]                                r_cnt       ;
reg    [uart_data_width-1 : 0]              ro_rx_data  ;
reg                                         ro_rx_valid ;
reg                                         ri_rx       ;
reg                                         r_check     ;
reg                                         r_run       ;   // 开始数据接收标志
reg                                         ri_rx2      ;   // 亚稳态

assign     o_rx_data            =           ro_rx_data  ;
assign     o_rx_valid           =           ro_rx_valid ;


always@(posedge i_clk)
begin
    if(i_rst)
        ri_rx <= 1'b0;
    else
        ri_rx <= i_rx;                          // 在每个时钟上升沿 读线；线信号需要reg寄存一下
end

always@(posedge i_clk)
begin
    if(i_rst)
        ri_rx2 <= 1'b0;
    else
        ri_rx2 <= ri_rx;                        // 在每个时钟上升沿 读线；线信号需要reg寄存一下
end

always@(posedge i_clk)
begin
    if(i_rst || r_cnt == rx_data_width)         // 结束
        r_run <= 1'b0;
    else if(ri_rx2 && !ri_rx)                   // 起始，打两拍判断
        r_run <= 1'b1;
    else
        r_run <= r_run;
end

always@(posedge i_clk)
begin
    if(i_rst)
        r_cnt <= 'd0;
    else if(r_cnt == rx_data_width)        
        r_cnt <= 'd0;
    else if(r_run)                         
        r_cnt <= r_cnt + 1;
    else 
        r_cnt <= 'd0;
end

always@(posedge i_clk)
begin
    if(i_rst)
        ro_rx_data <= 'd0;
    else if(r_cnt > 0 && r_cnt < uart_data_width+1)
        ro_rx_data <= {ro_rx_data[uart_data_width-2:0], ri_rx2};
    else
        ro_rx_data <= ro_rx_data;
end

always@(posedge i_clk)
begin
    if(i_rst)
        r_check <= 1'b0;
    else if(r_cnt > 0 && r_cnt < uart_data_width+1)
        r_check <= r_check ^ ri_rx2;
    else
        r_check <= r_check;
end

always@(posedge i_clk)
begin
    if(i_rst)
        ro_rx_valid <= 1'd0;
    else if(r_cnt == uart_data_width+1)
        ro_rx_valid <= (ri_rx2 == ((check == 2) ? r_check : ~r_check));
    else 
        ro_rx_valid <= 'd0;
end

endmodule