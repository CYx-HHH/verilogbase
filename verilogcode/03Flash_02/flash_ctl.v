`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/02/29 19:45:54
// Design Name: 
// Module Name: flash_ctl
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


module flash_ctl#(
    parameter   P_OP_MAX_LEN        = 256,// 32   256bits  32bytes  1og2(256)=8  
                P_USER_OPE_LEN      = 32,
                P_READ_DATA_WIDTH   = 8,
                P_CPOL              = 0,
                P_CPHL              = 0
)(
    input                           i_clk,
    input                           i_rst,
    
    input    [1:0]                  i_op_typ,
    input    [23:0]                 i_op_addr,
    input    [8:0]                  i_op_num,

    input                           i_op_valid,
    output                          o_op_ready,

    output   [7:0]                  o_read_data,
    output                          o_read_sop,
    output                          o_read_eop,
    output                          o_read_valid,

    input   [7:0]                   i_write_data,
    input                           i_write_sop,
    input                           i_write_eop,
    input                           i_write_valid,

    //--------------------------------------------
    output   [P_USER_OPE_LEN-1:0]   o_spi_op_data,     // 指令+地址    
    output   [8 :0]                 o_spi_op_len,              
    output   [2:0]                  o_spi_op_type,
    output                          o_spi_op_valid,   
    output   [7:0]                  o_spi_write_data,  // 并行，写到spi-flash  fifo缓冲  
    output   [15:0]                 o_clk_len,          

    input                           i_spi_ready,
    input                           i_spi_write_req,
    input    [7:0]                  i_spi_read_data,   // 并行，从spi-flash读到的数据，
    input                           i_spi_read_valid
);


localparam      P_IDLE          = 0,
                P_RUN           = 1,
                P_CLEAR         = 2,
                P_READ_INS      = 3,
                P_READ_DATA     = 4,
                P_WRITE_EN      = 5,
                P_WRITE_INS     = 6,
                P_WRITE_DATA    = 7,
                P_BUSY          = 8,
                P_BUSY_CHECK    = 9,
                P_BUSY_WAIT     = 10;

localparam      P_SPI_INS      = 0,
                P_SPI_READ      = 1,
                P_SPI_WRITE     = 2;

reg     [1:0]                   ri_op_typ;      // 0擦除 1读 2写
reg     [23:0]                  ri_op_addr;
reg     [8:0]                   ri_op_num;
reg                             ro_op_ready;

reg     [7:0]                   ri_write_data;
reg                             ri_write_sop;
reg                             ri_write_eop;
reg                             ri_write_valid;
reg     [7:0]                   ro_read_data;
reg                             ro_read_sop;
reg                             ro_read_eop;
reg                             ro_read_valid;

reg     [P_USER_OPE_LEN-1:0]    ro_spi_op_data;   
reg     [8:0]                   ro_spi_op_len;   
reg                             ro_spi_op_valid;
reg     [2:0]                   ro_spi_op_type;
// reg     [7:0]                   ro_spi_write_data;
reg     [7:0]                   ri_spi_read_data;
// reg                             ri_spi_read_valid;
reg     [15:0]                  ro_clk_len;      
    
reg     [3:0]                   r_st_current;
reg     [3:0]                   r_st_next;
reg     [7:0]                   r_st_cnt;
reg                             r_fifo_2u_rden;
reg                             r_fifo_2u_wren;
reg                             r_fifo_2u_empty;
reg                             r_fifo_2u_rden_1d;
reg                             r_fifo_2u_rden_pos;

wire        w_spi_active;
wire        w_op_active;
wire [7:0]  wo_read_data;
wire        w_fifo_2u_empty;

assign      o_op_ready       = ro_op_ready;          
assign      o_spi_op_data    = ro_spi_op_data;               
assign      o_spi_op_len     = ro_spi_op_len;                    
assign      o_spi_op_valid   = ro_spi_op_valid;  
assign      o_spi_op_type    = ro_spi_op_type;
              
assign      o_clk_len       = ro_clk_len;                            

assign      o_read_data     = ro_read_data;
assign      o_read_sop      = ro_read_sop;      
assign      o_read_eop      = ro_read_eop;
assign      o_read_valid    = ro_read_valid;

assign      w_op_active     = i_op_valid & ro_op_ready;
assign      w_spi_active    = i_spi_ready & ro_spi_op_valid;


fifo_flash_2u fifo_flash_2u_0   // flash to user
(
    .clk    (i_clk),
    .srst   (i_rst),
    .din    (ri_spi_read_data), 
    .wr_en  (r_fifo_2u_wren),
    .rd_en  (r_fifo_2u_rden), 
    .dout   (wo_read_data),
    .full   (),
    .empty  (w_fifo_2u_empty) 
);

fifo_u2_flash fifo_u2_flash_0   // user to flash
(
    .clk    (i_clk),
    .srst   (i_rst),
    .din    (ri_write_data),   
    .wr_en  (ri_write_valid),   
    .rd_en  (i_spi_write_req),   
    .dout   (o_spi_write_data),   
    .full   (),   
    .empty  ()   
);


always@(*)
begin
    case(r_st_current)
        P_IDLE:         r_st_next = w_op_active         ? P_RUN         : P_IDLE;
        P_RUN:          r_st_next = i_op_typ == 1       ? P_READ_INS    : P_WRITE_EN;
        P_CLEAR:        r_st_next = w_spi_active        ? P_BUSY        : P_CLEAR;
        P_READ_INS:     r_st_next = w_spi_active        ? P_READ_DATA   : P_READ_INS;
        P_WRITE_EN:     r_st_next = w_spi_active        ? (i_op_typ== 0 ? P_CLEAR 
                                                        : P_WRITE_INS)  : P_WRITE_EN;
        P_WRITE_INS:    r_st_next = w_spi_active        ? P_WRITE_DATA  : P_WRITE_INS;
        P_READ_DATA:    r_st_next = i_spi_ready         ? P_BUSY        : P_READ_DATA;
        P_WRITE_DATA:   r_st_next = i_spi_ready         ? P_BUSY        : P_WRITE_DATA;
        P_BUSY:         r_st_next = w_spi_active        ? P_BUSY_CHECK  : P_BUSY;
        P_BUSY_CHECK:   r_st_next = i_spi_read_valid    ? i_spi_read_data[0]  
                                                        ? P_BUSY_WAIT       
                                                        : P_IDLE   : P_BUSY_CHECK;
        P_BUSY_WAIT:    r_st_next = r_st_cnt==255       ? P_BUSY        : P_BUSY_WAIT;
        default:        r_st_next = P_RUN;
    endcase            
end


always@(posedge i_clk, posedge i_rst)   
begin
    if(i_rst)
        r_st_current <= P_IDLE;
    else
        r_st_current <= r_st_next;
end

always@(posedge i_clk, posedge i_rst)  
begin
    if(i_rst) 
        r_st_cnt <= 'd0;
    else if(r_st_current != r_st_next)
        r_st_cnt <= 'd0;
    else 
        r_st_cnt <= r_st_cnt + 1;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        ri_op_typ <= 'd0;   
        ri_op_addr <= 'd0;
        ri_op_num <= 'd0;
    end else if(w_spi_active) begin
        ri_op_typ <= i_op_typ;
        ri_op_addr <= i_op_addr;
        ri_op_num <= i_op_num;
    end else begin
        ri_op_typ <= ri_op_typ;
        ri_op_addr <= ri_op_addr;
        ri_op_num <= ri_op_num;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)begin
        ro_spi_op_data <= 'd0;
        ro_spi_op_len <= 'd0;
        ro_spi_op_type <= 'd0;
        ro_spi_op_valid <= 'd0;
        ro_clk_len <= 'd0;
    end else if(r_st_current == P_CLEAR) begin
        ro_spi_op_data <= {8'h20,ri_op_addr};   
        ro_spi_op_len <= P_USER_OPE_LEN;        // 32
        ro_spi_op_type <= P_SPI_INS;
        ro_spi_op_valid <= 'd1;
        ro_clk_len <= P_USER_OPE_LEN;
    end else if(r_st_current == P_READ_INS) begin
        ro_spi_op_data <= {8'h03,ri_op_addr};   // 读数据
        ro_spi_op_len <= P_USER_OPE_LEN;
        ro_spi_op_type <= P_SPI_READ;
        ro_spi_op_valid <= 'd1;
        ro_clk_len <= P_USER_OPE_LEN + (ri_op_num<<3);            // bits
    end else if(r_st_current == P_WRITE_EN) begin
        ro_spi_op_data <= {8'h06,ri_op_addr};   // 写使能
        ro_spi_op_len <= 'd8;
        ro_spi_op_type <= P_SPI_INS;
        ro_spi_op_valid <= 'd1;
        ro_clk_len <= 'd8;
    end else if(r_st_current == P_WRITE_INS) begin
        ro_spi_op_data <= {8'h02, ri_op_addr};  // 页编程
        ro_spi_op_len <= P_USER_OPE_LEN;
        ro_spi_op_type <= P_SPI_WRITE;
        ro_spi_op_valid <= 'd1;
        ro_clk_len <= P_USER_OPE_LEN + (ri_op_num<<3);
    end else if(r_st_current == P_BUSY) begin
        ro_spi_op_data <= {8'h05, ri_op_addr};  // 读忙
        ro_spi_op_len <= 'd8;
        ro_spi_op_type <= P_SPI_READ;
        ro_spi_op_valid <= 'd1;
        ro_clk_len <= 'd16;                     // bits
    end else begin
        ro_spi_op_data <= ro_spi_op_data;
        ro_spi_op_len <= ro_spi_op_len;
        ro_spi_op_type <= ro_spi_op_type;
        ro_spi_op_valid <= 'd0;
        ro_clk_len <= ro_clk_len;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_op_ready <= 'd1;
    else if(w_op_active)
        ro_op_ready <= 'd0;
    else if(r_st_current == P_IDLE)
        ro_op_ready <= 'd1;
    else
        ro_op_ready <= ro_op_ready;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        ri_write_data <= 'd0;
        ri_write_sop <= 'd0;
        ri_write_eop <= 'd0;
        ri_write_valid <= 'd0;
    end else if(i_op_typ == P_SPI_WRITE) begin
        ri_write_data <= i_write_data;
        ri_write_sop <= i_write_sop;
        ri_write_eop <= i_write_eop;
        ri_write_valid <= i_write_valid;
    end else begin
        ri_write_data <= ri_write_data;
        ri_write_sop <= ri_write_sop;
        ri_write_eop <= ri_write_eop;
        ri_write_valid <= ri_write_valid;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ri_spi_read_data <= 'd0;
    else if(ro_spi_op_type==P_SPI_READ && i_spi_read_valid) 
        ri_spi_read_data <= i_spi_read_data;
    else 
        ri_spi_read_data <= ri_spi_read_data;
end

// always@(posedge i_clk, posedge i_rst)
// begin
//     if(i_rst)
//         ri_spi_read_valid <= 'd0;
//     else if(ro_spi_op_type == P_SPI_READ)
//         ri_spi_read_valid <= i_spi_read_valid;
//     else
//         ri_spi_read_valid <= ri_spi_read_valid;
// end
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_read_data <= 'd0;
    else if(r_fifo_2u_rden)
        ro_read_data <= wo_read_data;
    else
        ro_read_data <= ro_read_data;
end 

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_read_sop <= 'd0;
    else if(r_fifo_2u_rden_pos)
        ro_read_sop <= 'd1;
    else
        ro_read_sop <= 'd0;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_read_eop <= 'd0;
    else if(w_fifo_2u_empty && !r_fifo_2u_empty && ro_read_valid)    
        ro_read_eop <= 'd1;
    else
        ro_read_eop <= 'd0;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ro_read_valid <= 'd0;
    else if(r_fifo_2u_rden_pos)
        ro_read_valid <= 'd1;
    else if(ro_read_eop)                               
        ro_read_valid <= 'd0;
    else
        ro_read_valid <= ro_read_valid;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_fifo_2u_rden <= 'd0;
    else if(ro_read_eop)
        r_fifo_2u_rden <= 'd0;
    else if(r_st_current == P_READ_DATA && r_st_next != P_READ_DATA)    // 快跳转时一次性从fifo读出。
        r_fifo_2u_rden <= 'd1;
    else
        r_fifo_2u_rden <= r_fifo_2u_rden;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_fifo_2u_rden_1d <= 'd0;
    else
        r_fifo_2u_rden_1d <= r_fifo_2u_rden; 
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_fifo_2u_rden_pos <= 'd0;
    else 
        r_fifo_2u_rden_pos <= !r_fifo_2u_rden_1d & r_fifo_2u_rden;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        r_fifo_2u_wren <= 'd0;
    else if(r_st_current == P_READ_DATA)    // 写数据才能进fifo
        r_fifo_2u_wren <= i_spi_read_valid;
    else
        r_fifo_2u_wren <= r_fifo_2u_wren;
end

always@(posedge i_clk, posedge i_rst)       // 寄存一下 
begin
    if(i_rst)
        r_fifo_2u_empty <= 'd1;
    else
        r_fifo_2u_empty <= w_fifo_2u_empty;
end

endmodule
