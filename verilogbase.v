
module Adder(input wire [3:0] a, b, output wire [4:0] sum);
    assign sum = a + b;
endmodule
//
//模块名和工程名必须一样
module add#(
    parameter p_b=3, 
    parameter p_c=5 // 顶层参数
)
// 输入输出接口
{
    input a,
    input b,
    output c,
    inout d
};

// 寄存器类型-只能写在always里
reg r_a;
reg r_b;
// reg赋初值很消耗资源
// 线类型-assign里
wire [1:0] w_b; //默认1bit
wire [1:0] w_c; 

localparam p_d = 2; //本地参数 默认32bit 本地可修改

assign w_b = p_d;
assign w_c = p_b;

// FPGA里不能直接用组合逻辑设计除法器，取余运算；
// 要时序逻辑多个时钟周期
// assign w_f = 5%2

wire [1:0] w_d;
wire [1:0] w_e;
wire [1:0] w_f;

// 阻塞赋值和非阻塞赋值
    // 组合逻辑只能阻塞赋值，不受时钟控制，单纯信号一级一级传播
    // 只有在上一单元被赋值后 才会被赋值
assign w_d = 1;
assign w_e = w_d;

// always里只能reg类型，assign变量只能是wire类型
// 非阻塞赋值和时钟信号一起使用
    // 在每个时钟上升沿同时读取信号，使用reg寄存器类型
always@(posedge i_clk)
begin
    r_a <= 1
    r_b <= r_a
end

// if-else
always@(posedge i_clk)
begin
    if(w_d && w_e)  // 都为1
    begin
        r_a <= 2 << 2;
    end
    else if(!w_e)
        r_a <= 0;
    else
        r_a<=2;

// 截位[] 拼接[,] 逻辑取反! 按位取反~ 按位与或&|
// 逻辑取反只有十进制位的真/假，即二进制的0000和0001
// case语句类似if
always@(posedge i_clk)
begin
    if(r_a == 1)begin
        r_b <= 1
    end else if(r_a == 2)begin
        r_b <= 2
    end else begin
        r_b <= 3
    end 
end

always@(posedge i_clk)
begin
    case(r_a)
        1:begin
            r_b <= 1
        end
        2:begin
            r_b <= 2
        end
        default:begin
            r_b <= 3；
        end
    endcase 
end

always@(*) 
// 不受时钟控制，只受赋值信号控制，会被强行综合成组合逻辑电路
// 语句发生改变，信号就发生改变
begin
end
endmodule




