`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/01 15:37:27
// Design Name: 
// Module Name: SIM_spi_drive
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


module SIM_spi_drive();

localparam      CLK_PERIOD          = 10;
localparam      P_USER_DATA_WIDTH   = 9;
localparam      P_READ_DATA_WIDTH   = 9;

reg iclk, irst;

initial begin
    iclk = 0;
    irst = 1;
    #(CLK_PERIOD) @(posedge iclk) irst=0;
end

always
begin
    #(CLK_PERIOD/2);
    iclk = ~iclk;
end


reg [P_USER_DATA_WIDTH-1:0]     ri_user_data;
reg                             ri_user_valid;

wire [P_READ_DATA_WIDTH-1:0]    wo_user_data;
wire                            wo_user_valid;

wire            wo_cs;
wire            o_ready;
wire            wo_spi_clk;
wire            wo_mosi;

wire            w_active = ri_user_valid & o_ready;


spi_drive#(
    .P_USER_DATA_WIDTH(P_USER_DATA_WIDTH),
    .P_READ_DATA_WIDTH(P_READ_DATA_WIDTH),
    .P_CPOL           (1),
    .P_CPHL           (0)       //  01不兼容
)spi_drive_d0
(
    .i_clk              (iclk),
    .i_rst              (irst),
    .i_user_data        (ri_user_data),           
    .i_user_valid       (ri_user_valid),

    .i_spi_miso         (wo_mosi),
    .o_spi_mosi         (wo_mosi),
    .o_cs               (wo_cs),
    .o_ready            (o_ready),     
    .o_spi_clk          (wo_spi_clk),

    .o_user_data        (wo_user_data),
    .o_user_valid       (wo_user_valid)
);



always@(posedge wo_spi_clk, posedge irst)
begin
    if(irst || o_ready)
    begin
        ri_user_data    <=  9'h88;
        ri_user_valid   <='d1;
    end
    else if(w_active)
        ri_user_valid   <='d0;
    else
    begin
        ri_user_data    <=  ri_user_data;
        ri_user_valid   <= ri_user_valid;
    end
end


// always@(posedge iclk, posedge irst)
// begin
//     if()
    
//     else if()
    
//     else

// end



endmodule
