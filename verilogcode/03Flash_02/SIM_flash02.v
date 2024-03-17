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


module SIM_flash02();

localparam           CLK_PERIOD = 10;     



reg     rst, clk;

initial begin
    clk = 0;
    rst = 1;
    #100 @(posedge clk)   rst = 0; 
end

always
begin
#(CLK_PERIOD/2) clk = ~clk;
end


wire                            wo_cs;
wire                            wo_spi_clk;
         
wire                            wo_spi_mosi;    
wire                            wi_spi_miso;

wire                            WPn;
wire                            HOLDn;


pullup  (wo_spi_mosi);
pullup  (wi_spi_miso);
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

spi_top spi_top_u0(
    .i_clk     (clk),           
    .i_spi_miso(wi_spi_miso),
    .o_spi_mosi(wo_spi_mosi),
    .o_cs      (wo_cs),
    .o_spi_clk (wo_spi_clk)
);




















endmodule
