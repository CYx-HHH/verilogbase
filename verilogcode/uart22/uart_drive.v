/***
    使用异步复位，原复位周期太小会识别不出来.i_rst/i_clk--->buad_clk--->buad_rst

    在接收端异步时钟动态校正，解决误码率高的问题，即时钟累积误差过大的问题。
    需要过采样识别起始位下降沿

    对发送发，根据 波特率时钟 产生周期复位
    对接收方，根据 其时钟信号 产生周期复位

    最后，对外用户时钟是波特率时钟，采集好的信号不是波特率时钟，需要同步（且打两拍
*/


module uart_drive#(
    parameter       buad_rate        =   115200     ,
    parameter       clk_rate         =   1152000   ,
    parameter       uart_data_width  =   8          ,   // 8b
    parameter       check            =   1          ,   // 0: no check, 1: odd check, 2: even check
    parameter       stop_width       =   1          ,
    parameter       rst_cycle        =   5
)
(
    input                               i_clk,
    input                               i_rst,
    input                               i_rx ,
    output                              o_tx ,

    output  [uart_data_width-1 : 0]     ouser_rx_data  ,
    output                              ouser_rx_valid ,
    input   [uart_data_width-1 : 0]     iuser_tx_data  ,
    input                               iuser_tx_valid ,
    output                              ouser_tx_ready ,
    output                              ouser_clk      ,
    output                              ouser_rst
);



reg [2:0]                       r_overvalue;
reg [2:0]                       r_overvalue_1d;     // 过采样
reg                             r_overlock;

reg [uart_data_width-1 : 0]     rx_overdata;        // 打一拍
reg [uart_data_width-1 : 0]     rx_overdata_1d; 
reg                             rx_overvalid;
reg                             rx_overvalid_1d;


wire                            wo_rx_valid;
wire [uart_data_width-1 : 0]    wo_rx_data;

wire                            w_buad_clk;
wire                            w_buad_rst;
wire                            w_rx_clk;
wire                            w_rx_rst;



assign      ouser_rx_data   =   rx_overdata_1d;
assign      ouser_rx_valid  =   rx_overvalid_1d;

assign      ouser_clk       =   w_buad_clk;
assign      ouser_rst       =   w_buad_rst;

localparam  CLK_DIV = clk_rate / buad_rate;


even_clk_div#(
    .CLK_DIV_CNT    (CLK_DIV    )   
)tx_clk0(
    .i_clk          (i_clk      ),
    .i_rst          (i_rst      ),
    .o_clk          (w_buad_clk )
);

even_clk_div#(
    .CLK_DIV_CNT    (CLK_DIV    )   
)rx_clk0(
    .i_clk          (i_clk      ),
    .i_rst          (i_rst      ),
    .o_clk          (w_rx_clk   )
);


rst_gen#(
    .RST_CYCLE      (rst_cycle  )
)rst_tx0(
    .i_clk          (w_buad_clk ),
    .o_rst          (w_buad_rst )
);

rst_gen#(
    .RST_CYCLE      (rst_cycle  )
)rst_rx0(
    .i_clk          (w_rx_clk   ),
    .o_rst          (w_rx_rst   )
);


uart_tx#(
    .buad_rate          (buad_rate      ),
    .clk_rate           (clk_rate       ),
    .uart_data_width    (uart_data_width),   // 8b
    .check              (check          ),   // 0: no check, 1: odd check, 2: even check
    .stop_width         (stop_width     )
)tx_drive0(
    .i_clk              (w_buad_clk     ),
    .i_rst              (w_buad_rst     ),
    .i_tx_data          (iuser_tx_data  ),
    .i_tx_valid         (iuser_tx_valid ),
    .o_tx_ready         (ouser_tx_ready ),
    .o_tx               (o_tx           )
);


uart_rx#(
    .buad_rate          (buad_rate      ),
    .clk_rate           (clk_rate       ),
    .uart_data_width    (uart_data_width),   // 8b
    .check              (check          ),   // 0: no check, 1: odd check, 2: even check
    .stop_width         (stop_width     )
)rx_drive0(
    .i_clk              (w_rx_clk       ),
    .i_rst              (w_rx_rst       ),
    .i_rx               (i_rx           ),
    .o_rx_data          (wo_rx_data     ),
    .o_rx_valid         (wo_rx_valid    )
);


/////////////////////////////////////////////
/////   可以用overlock信号，对rx模块周期性复位，此时rx复位完成即接收数据，无判断起始位和打两拍处理
/////   异步时钟动态校正，  这里没用不想改了  
/////////////////////////////////////////////       
always@(posedge i_clk)
begin
    if(i_rst)
        r_overvalue <= 3'b0;
    else if(!r_overlock)
        r_overvalue <= {r_overvalue[1:0], i_rx};    //  过采样
    else
        r_overvalue <= 'd0; 
end

always@(posedge i_clk)
begin
    if(i_rst)
        r_overvalue_1d <= 3'b0;
    else
        r_overvalue_1d <= r_overvalue;              
end

always@(posedge i_clk)                              //  识别起始位上升沿 有效位下降沿
begin
    if(i_rst)
        r_overlock <= 'b0;
    else if(r_overvalue_1d == 3'b0 && r_overvalue != 3'b0)
        r_overlock <= 1'b1;
    else if(rx_overvalid && !wo_rx_valid)
        r_overlock <= 1'b0;
    else
        r_overlock <= r_overlock;
end


/////   异步时钟同步：数据接收rx同步用户波特率时钟，打一拍
always@(posedge w_buad_clk)
begin
    if(w_buad_rst)
        rx_overvalid <= 'd0;
    else 
        rx_overvalid <= wo_rx_valid; 
end

always@(posedge w_buad_clk)
begin
    if(w_buad_rst)
        rx_overvalid_1d <= 'd0;
    else 
        rx_overvalid_1d <= rx_overvalid; 
end

always@(posedge w_buad_clk)
begin
    if(w_buad_rst)
        rx_overdata <= 'd0;
    else
        rx_overdata <= wo_rx_data;
end

always@(posedge w_buad_clk)
begin
    if(w_buad_rst)
        rx_overdata_1d <= 'd0;
    else
        rx_overdata_1d <= rx_overdata;
end

endmodule

