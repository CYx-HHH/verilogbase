`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/22 17:11:31
// Design Name: 
// Module Name: SIM_flash01
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


module SIM_flash01();

localparam      CLK_PERIOD = 10;
localparam      P_USER_OPE_TYPE     = 1;       
localparam      P_USER_OPE_LEN      = 32;     
localparam      P_READ_DATA_WIDTH   = 8;
localparam      P_CPOL              = 0;
localparam      P_CPHL              = 0;

reg     rst, clk;

initial begin
    rst = 1;
    clk = 0;
    #25 @(posedge clk)   rst = 0; 
end

always
begin

#(CLK_PERIOD/2) clk = ~clk;
end


wire                            wo_cs;
wire                            wo_ready;
wire                            wo_spi_clk;
wire [7:0]                      wo_read_data;
wire                            wo_read_valid;           

wire                            wo_spi_mosi;    
wire                            w_write_req;
wire                            w_read_req;


wire    w_active = wo_ready & ri_user_op_valid;

reg [P_USER_OPE_LEN-1:0]        ri_user_op_data;        // 接收 userdata 输出 mosi  
reg [8:0]                       ri_user_op_len;   
reg                             ri_user_op_valid; 

// 传输计数结束后，user有效和ready有效/片选 占一个spi clk,要识别下降沿 
reg                             r_run;      
reg                             r_run_1d;

// clk产生周期性读写请求（8bit单位），len和cnt标识读写过程整体的开始和结束
reg [8:0]                       ri_write_len;       // 256 bytes   
reg [7:0]                       ri_write_data;
reg [8:0]                       ri_read_len;
reg [7:0]                       r_miso_test_data;
reg [4:0]                       r_miso_test_clk;

reg                             ri_spi_miso;


spi_drive#(
    .P_USER_OPE_TYPE        (P_USER_OPE_TYPE),  // 0指令 1读 2写
    .P_USER_OPE_LEN         (P_USER_OPE_LEN ),
    .P_READ_DATA_WIDTH      (P_READ_DATA_WIDTH),
    .P_CPOL                 (P_CPOL         ),
    .P_CPHL                 (P_CPHL         )
) spi_s0
(
    .i_clk                  (clk),
    .i_rst                  (rst),
    .i_user_op_data         (ri_user_op_data),      //  和user操作接口
    .i_user_op_len          (ri_user_op_len ),       //  8 32
    .i_user_op_valid        (ri_user_op_valid),    
    .i_user_write_data      (ri_write_data  ),  
    .i_write_len            (ri_write_len   ),         // 256   
    .i_read_len             (ri_read_len    ),

    .i_spi_miso             (ri_spi_miso    ),          //  读取的数据
    .o_spi_mosi             (wo_spi_mosi    ),
    .o_write_req            (w_write_req    ),
    .o_read_req             (w_read_req     ),
    .o_cs                   (wo_cs          ),
    .o_user_ready           (wo_ready       ),     
    .o_spi_clk              (wo_spi_clk     ),
    .o_user_read_data       (wo_read_data   ),
    .o_user_read_valid      (wo_read_valid  )
);


always@(posedge clk, posedge rst)   // 握手信号
begin
    if(rst || w_active)
        ri_user_op_valid <= 'd0;
    else if(wo_ready)
        ri_user_op_valid <= 'd1;
    else 
        ri_user_op_valid <= ri_user_op_valid;
end

always@(posedge clk, posedge rst)   
begin
    if(rst) begin
        ri_user_op_data <= {8'h6, 24'h00};
        ri_user_op_len  <= 'd32;
    end else if(w_active) begin
        ri_user_op_data <= ri_user_op_data +'d1;
        ri_user_op_len  <= 'd32;
    end else begin
        ri_user_op_data <= ri_user_op_data;
        ri_user_op_len <= ri_user_op_len;
    end
end

always@(posedge clk, posedge rst)
begin
    if(rst) begin
        ri_write_data <= 8'h55;
        ri_write_len <= 'd16;               // bit
    end else if(w_write_req) begin
        ri_write_data <= ri_write_data + 'd1;
    end else begin
        ri_write_data <= ri_write_data;
        ri_write_len <= ri_write_len;
    end
end

//  read_req 和 miso_test_data 仅限于仿真测试
always@(negedge wo_spi_clk, posedge rst)
begin
    if(rst) begin
        r_miso_test_clk <= 'd0;
        ri_read_len <= 'd16;                // bit
        ri_spi_miso <= 'd0;
    end 
    else if(w_read_req) begin
        r_miso_test_clk <= 'd1;
        ri_spi_miso <= r_miso_test_data[7];
    end 
    else if(r_miso_test_clk && r_miso_test_clk < 8) begin
        r_miso_test_clk <= r_miso_test_clk + 'd1;
        ri_spi_miso <= r_miso_test_data[7];
    end 
    else if(r_miso_test_clk == 8) begin
        r_miso_test_clk <= 'd0;
        ri_spi_miso <= r_miso_test_data[7];
    end 
    else begin 
        ri_read_len <= ri_read_len;
        r_miso_test_clk <= r_miso_test_clk;
        ri_spi_miso <= ri_spi_miso;
    end
end


always@(negedge wo_spi_clk, posedge rst)    // 下降沿产生数据
begin
    if(rst)
        r_miso_test_data <= 'd1;
    // else if(w_read_req)
    //     r_miso_test_data <= r_miso_test_data + 'd1;
    else if(r_miso_test_clk && r_miso_test_clk < 8)
        r_miso_test_data <= r_miso_test_data << 1;
    else if(r_miso_test_clk && r_miso_test_clk == 8)
        r_miso_test_data <= (r_miso_test_data << 1) + 'h55;
    else
        r_miso_test_data <= r_miso_test_data;
end

endmodule
