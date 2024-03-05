`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/04 15:30:01
// Design Name: 
// Module Name: user_gen
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


module user_gen(
    input                           i_clk,  
    input                           i_rst,
    input   [1:0]                   o_op_typ,
    input   [23:0]                  o_op_addr,
    input   [8:0]                   o_op_num,
    input                           o_op_valid,
    input   [7:0]                   o_write_data,
    input                           o_write_sop,
    input                           o_write_eop,
    input                           o_write_valid,
    output                          i_op_ready,
    output  [7:0]                   i_read_data,
    output                          i_read_sop,
    output                          i_read_eop,
    output                          i_read_valid,

    input                           o_spi_miso,
    output                          i_spi_mosi,
    output                          i_cs,
    output                          i_spi_clk
);
endmodule
