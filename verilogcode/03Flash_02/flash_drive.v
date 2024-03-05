`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/29 19:52:11
// Design Name: 
// Module Name: flash_top
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


module flash_drive#(
    parameter   P_OP_MAX_LEN        =256,
                P_USER_OPE_LEN      =32,    
                P_READ_DATA_WIDTH   =8,  
                P_CPOL              =0, 
                P_CPHL              =0
)(
    input                           i_clk,  
    input                           i_rst,

    input   [1:0]                   i_op_typ,
    input   [23:0]                  i_op_addr,
    input   [8:0]                   i_op_num,
    input                           i_op_valid,
    input   [7:0]                   i_write_data,
    input                           i_write_sop,
    input                           i_write_eop,
    input                           i_write_valid,
    output                          o_op_ready,
    output  [7:0]                   o_read_data,
    output                          o_read_sop,
    output                          o_read_eop,
    output                          o_read_valid,

    input                           i_spi_miso,         
    output                          o_spi_mosi,         
    output                          o_cs,
    output                          o_spi_clk
);


wire     [P_USER_OPE_LEN-1:0]   wo_user_op_data;   
wire     [8:0]                  wo_user_op_len;   
wire                            wo_user_op_valid;
wire     [2:0]                  wo_user_op_type;
wire     [7:0]                  wo_user_write_data;
wire     [7:0]                  wi_user_read_data;
wire                            wi_user_read_valid;
wire     [8:0]                  wo_write_len;      
wire     [8:0]                  wo_read_len;

wire                            w_write_req;
wire                            w_user_read_data;
wire                            w_user_read_valid;
wire                            w_user_ready;


spi_drive#(
    .P_USER_OPE_LEN             (P_USER_OPE_LEN ),
    .P_READ_DATA_WIDTH          (P_READ_DATA_WIDTH),
    .P_CPOL                     (P_CPOL         ),
    .P_CPHL                     (P_CPHL         )
) 
spi_drive_d0
(
    .i_clk                      (i_clk),
    .i_rst                      (i_rst),

    .i_user_op_data             (wo_user_op_data),          
    .i_user_op_len              (wo_user_op_len),       
    .i_user_op_valid            (wo_user_op_valid), 
    .i_user_op_type             (wo_user_op_type),    
    .i_user_write_data          (wo_user_write_data),  
    .i_write_len                (wo_write_len),            
    .i_read_len                 (wo_read_len),
    .o_write_req                (w_write_req),

    .o_user_read_data           (w_user_read_data),
    .o_user_read_valid          (w_user_read_valid),
    .o_user_ready               (w_user_ready),
    .o_cs                       (o_cs),     
    .o_spi_clk                  (o_spi_clk     ),
    .i_spi_miso                 (i_spi_miso    ),          
    .o_spi_mosi                 (o_spi_mosi    )
);

flash_ctl#(
    .P_OP_MAX_LEN               (256 ),
    .P_USER_OPE_LEN             (32  ),
    .P_READ_DATA_WIDTH          (8   ),
    .P_CPOL                     (0   ),
    .P_CPHL                     (0   )
)flash_ctl_c0
(
    .i_clk                      (i_clk),
    .i_rst                      (i_rst),
    .i_op_typ                   (i_op_typ),
    .i_op_addr                  (i_op_addr),
    .i_op_num                   (i_op_num),
    .i_op_valid                 (i_op_valid),
    .o_op_ready                 (o_op_ready),
    .o_read_data                (o_read_data),
    .o_read_sop                 (o_read_sop),
    .o_read_eop                 (o_read_eop),
    .o_read_valid               (o_read_valid),
    .i_write_data               (i_write_data),
    .i_write_sop                (i_write_sop),
    .i_write_eop                (i_write_eop),
    .i_write_valid              (i_write_valid),

    .o_user_op_data             (wo_user_op_data),     // 指令+地址    
    .o_user_op_len              (wo_user_op_len),      
    .o_user_op_valid            (wo_user_op_valid),           
    .o_user_op_type             (wo_user_op_type),
    .o_user_write_data          (wo_user_write_data),  // 并行，写到spi-flash  fifo缓冲  
    .o_write_len                (wo_write_len),          
    .o_read_len                 (wo_read_len),
    .i_user_write_req           (w_write_req),
    .i_user_read_data           (w_user_read_data),   // 并行，从spi-flash读到的数据，
    .i_user_read_valid          (w_user_read_valid),
    .i_user_ready               (w_user_ready)
);


endmodule
