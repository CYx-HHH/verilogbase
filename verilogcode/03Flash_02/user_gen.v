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


module user_gen#(
    parameter   P_OP_MAX_LEN        = 256,
                P_USER_OPE_LEN      = 32,
                P_READ_DATA_WIDTH   = 8 
)(
    input                           i_clk,  
    input                           i_rst,

    input                           i_op_ready,
    input   [7:0]                   i_read_data,
    input                           i_read_sop,
    input                           i_read_eop,
    input                           i_read_valid,   // 从flash读取的数据

    output  [1:0]                   o_op_typ,       // 0擦除 1读 2写
    output  [23:0]                  o_op_addr,
    output  [8:0]                   o_op_num,
    output                          o_op_valid,
    output  [7:0]                   o_write_data,
    output                          o_write_sop,
    output                          o_write_eop,
    output                          o_write_valid,

    input                           i_spi_clk
);


localparam                      P_USER_IDLE  = 0,
                                P_USER_CLEAR = 1,
                                P_USER_READ  = 2,
                                P_USER_WRITE = 3;   


reg     [1:0]                       ro_op_typ;
reg     [23:0]                      ro_op_addr;
reg     [8:0]                       ro_op_num;
reg                                 ro_op_valid;
reg     [7:0]                       ro_write_data;
reg                                 ro_write_sop;
reg                                 ro_write_eop;
reg                                 ro_write_valid;

reg     [3:0]                       r_st_current;
reg     [3:0]                       r_st_next;
reg     [7:0]                       r_write_cnt;

reg                                 ri_ready;
reg                                 ri_ready_1d;


wire    w_active    = i_op_ready & o_op_valid;
wire    w_ready_pos = ri_ready & !ri_ready_1d;


assign  o_op_typ                    = ro_op_typ; 
assign  o_op_addr                   = ro_op_addr;    
assign  o_op_num                    = ro_op_num; 
assign  o_op_valid                  = ro_op_valid;   
assign  o_write_data                = ro_write_data; 
assign  o_write_sop                 = ro_write_sop;  
assign  o_write_eop                 = ro_write_eop;  
assign  o_write_valid               = ro_write_valid;        


always@(*)
begin
    case(r_st_current)
        P_USER_IDLE :   r_st_next = P_USER_CLEAR;
        P_USER_CLEAR:   r_st_next = w_ready_pos ? P_USER_WRITE  : P_USER_CLEAR;
        P_USER_READ :   r_st_next = w_ready_pos ? P_USER_IDLE   : P_USER_READ;
        P_USER_WRITE:   r_st_next = w_ready_pos ? P_USER_READ   : P_USER_WRITE;
        default:        r_st_next = P_USER_IDLE ;
    endcase
end


always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst)
        r_st_current <= 'd0;
    else
        r_st_current <= r_st_next;
end

always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst) begin    
        ro_op_addr      <= 'd0;      
        ro_op_num       <= 'd0;    
        ro_op_typ       <= 'd0;           
    end else if(r_st_next == P_USER_CLEAR && r_st_current != P_USER_CLEAR) begin
        ro_op_addr      <= 'd0; 
        ro_op_num       <= 'd0;
        ro_op_typ       <= 'd0;             
    end else if(r_st_next == P_USER_READ && r_st_current != P_USER_READ) begin
        ro_op_addr      <= 24'd100; 
        ro_op_num       <= 'd8;        // bytes
        ro_op_typ       <= 'd1;            
    end else if(r_st_next == P_USER_WRITE && r_st_current != P_USER_WRITE) begin
        ro_op_addr      <= 24'd300; 
        ro_op_num       <= 'd8;
        ro_op_typ       <= 'd2;          
    end else begin
        ro_op_addr      <= ro_op_addr;     
        ro_op_num       <= ro_op_num;            
        ro_op_typ       <= ro_op_typ;        
    end
end

always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst)
        ro_op_valid <= 'd0;
    else if(w_active)
        ro_op_valid <= 'd0;
    else if(r_st_next == P_USER_CLEAR && r_st_current != P_USER_CLEAR)
        ro_op_valid <= 'd1;
    else if(r_st_next == P_USER_READ && r_st_current != P_USER_READ)
        ro_op_valid <= 'd1;
    else if(r_st_next == P_USER_WRITE && r_st_current != P_USER_WRITE)
        ro_op_valid <= 'd1;
    else
        ro_op_valid <= ro_op_valid;
end

always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst)
        ro_write_data <= 'd0;
    else if(r_st_current == P_USER_WRITE && ro_write_valid)
        ro_write_data <= ro_write_data + 'd1;
    else
        ro_write_data <= ro_write_data;
end

always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst)
        r_write_cnt <= 'd0;
    else if(r_write_cnt && r_write_cnt == ro_op_num-1)
        r_write_cnt <= 'd0;
    else if(r_st_current == P_USER_WRITE || r_write_cnt)
        r_write_cnt <= r_write_cnt + 'd1;
    else
        r_write_cnt <= r_write_cnt;
end

always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst)
        ro_write_valid <= 'd0;
    else if(r_write_cnt && r_write_cnt == ro_op_num-1)
        ro_write_valid <= 'd0;
    else if(r_st_next == P_USER_WRITE && r_st_current != P_USER_WRITE)
        ro_write_valid <= 'd1;
    else
        ro_write_valid <= ro_write_valid;
end

always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst)
        ro_write_sop <= 'd0;
    else if(r_st_next == P_USER_WRITE && r_st_current != P_USER_WRITE)
        ro_write_sop <= 'd1;
    else
        ro_write_sop <= 'd0;
end

always @(posedge i_clk or posedge i_rst)
begin
    if(i_rst)
        ro_write_eop <= 'd0;
    else if(r_write_cnt && r_write_cnt == ro_op_num-2 && ro_write_valid)
        ro_write_eop <= 'd1;
    else
        ro_write_eop <= 'd0;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ri_ready <= 'd0;
    else
        ri_ready <= i_op_ready;
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst)
        ri_ready_1d <= 'd0;
    else
        ri_ready_1d <= ri_ready;
end



endmodule
