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
wire                            wi_spi_miso;
wire                            w_write_req;
wire                            w_read_req;

wire                            WPn;
wire                            HOLDn;

wire    w_active = wo_ready & ri_user_op_valid;

reg [P_USER_OPE_LEN-1:0]        ri_user_op_data;        // 接收 userdata 输出 mosi  
reg [8:0]                       ri_user_op_len;   
reg                             ri_user_op_valid; 

reg [8:0]                       ri_write_len;       
reg [7:0]                       ri_write_data;
reg [8:0]                       ri_read_len;
reg [2:0]                       ri_user_op_type;
// reg [7:0]                       r_miso_test_data;
// reg [4:0]                       r_miso_test_clk;
reg                             ri_spi_miso;


pullup  (wo_spi_mosi);
pullup  (wo_spi_mosi);
pullup  (WPn);
pullup  (HOLDn);

W25Q128JVxIM W25Q128JVxIM_w0(                   // flash model
    .CSn                (wo_cs),
    .CLK                (wo_spi_clk), 
    .DIO                (wo_spi_mosi), 
    .DO                 (wi_spi_miso), 
    .WPn                (WPn), 
    .HOLDn              (HOLDn)
);

flash_drive#(
    .P_OP_MAX_LEN           (256),
    .P_USER_OPE_LEN         (32 ),    
    .P_READ_DATA_WIDTH      (8  ),  
    .P_CPOL                 (0  ), 
    .P_CPHL                 (0  )
)(
    .i_clk                  (clk),  
    .i_rst                  (rst),

    .i_op_typ               (),
    .i_op_addr              (),
    .i_op_num               (),
    .i_op_valid             (),
    .i_write_data           (),
    .i_write_sop            (),
    .i_write_eop            (),
    .i_write_valid          (),
    .o_op_ready             (),
    .o_read_data            (),
    .o_read_sop             (),
    .o_read_eop             (),
    .o_read_valid           (),

    .i_spi_miso             (),         
    .o_spi_mosi             (),             
    .o_cs                   (),
    .o_spi_clk              ()
);






















endmodule
