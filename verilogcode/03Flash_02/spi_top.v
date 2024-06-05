`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/15 17:09:48
// Design Name: 
// Module Name: spi_top
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


module spi_top(
    input           i_clkp    , 
    input           i_clkn    ,          
    input           i_spi_miso,
    output          o_spi_mosi,
    output          o_cs      ,
    output          o_spi_clk 
);



wire                            wo_ready;
wire [7:0]                      wo_read_data;
wire                            wo_read_valid;           

wire [2:0]                      wi_op_typ;
wire [23:0]                     wi_op_addr;
wire [8:0]                      wi_op_num;
wire                            wi_op_valid;

wire [7:0]                      wi_write_data;
wire                            wi_write_sop;
wire                            wi_write_eop;
wire                            wi_write_valid;

wire                            wo_read_sop;
wire                            wo_read_eop;

wire                            w_clk_10Mhz;
wire                            w_clk_10Mhz_lock;
wire                            w_clk_10Mhz_rst; 
wire                            i_clk;

assign      w_clk_10Mhz_rst = ~w_clk_10Mhz_lock;


IBUFGDS IBUFGDS_i (     
                    .O (i_clk),

                    .I (i_clkp),

                    .IB (i_clkn)
);



SYSTEM_CLK system_clk_s0
(
    .clk_out1   (w_clk_10Mhz),     
    .locked     (w_clk_10Mhz_lock),      
    .clk_in1    (i_clk)
);


flash_drive flash_drive_f0(
    .i_clk                  (w_clk_10Mhz),  
    .i_rst                  (w_clk_10Mhz_rst),
    .i_op_typ               (wi_op_typ),
    .i_op_addr              (wi_op_addr),
    .i_op_num               (wi_op_num),
    .i_op_valid             (wi_op_valid),
    .i_write_data           (wi_write_data),
    .i_write_sop            (wi_write_sop),
    .i_write_eop            (wi_write_eop),
    .i_write_valid          (wi_write_valid),
    
    .o_op_ready             (wo_ready),
    
    .o_read_data            (wo_read_data),
    .o_read_sop             (wo_read_sop),
    .o_read_eop             (wo_read_eop),
    .o_read_valid           (wo_read_valid),

    .i_spi_miso             (i_spi_miso),         
    .o_spi_mosi             (o_spi_mosi),             
    .o_cs                   (o_cs),
    .o_spi_clk              (o_spi_clk)
);

user_gen#(
    .P_OP_MAX_LEN        (256),
    .P_USER_OPE_LEN      (32),
    .P_READ_DATA_WIDTH   (8)
)user_gen_data_u0(
    .i_clk                  (w_clk_10Mhz),  
    .i_rst                  (w_clk_10Mhz_rst),

    .i_op_ready             (wo_ready),
    .i_read_data            (wo_read_data),
    .i_read_sop             (wo_read_sop),
    .i_read_eop             (wo_read_eop),
    .i_read_valid           (wo_read_valid),   // 从flash读取的数据

    .o_op_typ               (wi_op_typ),       // 0擦除 1读 2写
    .o_op_addr              (wi_op_addr),
    .o_op_num               (wi_op_num),
    .o_op_valid             (wi_op_valid),
    .o_write_data           (wi_write_data),
    .o_write_sop            (wi_write_sop),
    .o_write_eop            (wi_write_eop),
    .o_write_valid          (wi_write_valid),
    .i_spi_clk              (o_spi_clk)
);


endmodule
