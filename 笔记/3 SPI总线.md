# SPI总线(Serial Peripheral interface，串行外围接口)
## 详解原理
* UART，异步串行通信，是全双工异步通信。
    异步指的是收发方通信数据线上没有统一时钟，需要用自身时钟收发数据。采样数据不稳定会产生亚稳态，为防止误码采用打两拍或时钟校准，最高能跑到2Mbps。
* SPI，全双工同步串行通信，最多需要4根线。上升/下降沿和数据统一对齐。每个时钟周期都传输数据，时钟下降沿对齐数据中部。主要应用于Flash，ADC，DAC等芯片，以及数字信号处理器核数字信号解码器等。
    - 全双工模式通信，是一个主机和一个/多个从机的主从模式，一对多。主机负责初始化帧，数据传输帧可用于读写操作，片选线可从多个从机选择一个来响应主机请求。
    - 优点，支持全双工通信；通信简单/不用时钟校准；数据传输速率快。
    - 缺点，没有应答机制，无法检测误码。
* SPI四个引脚：
    1. clk，数据时钟。不需要做过采样，时钟校正。 
    2. cs/chip select，片选信号/芯片选择，低有效为选择。 
    3. MOSI/Master output Slave input，主机输出从机输入. 
    4. MISO/Master input Slave output，主机输入从机输出.
    5. 下降沿改变数据/上升沿输出数据
* SPI模式：
    1. CPOL：时钟极性，时钟空闲的电平状态。
    2. CPHL：时钟相位，采样时刻在第几个时钟沿。
       - mode0：CPOL=0， CPHL=0，时钟空闲状态为0，采样时刻在第1个时钟沿/上升沿。
       - mode1：CPOL=0， CPHL=1，时钟空闲状态为0，采样时刻在第2个时钟沿/下降沿。
       - mode2：CPOL=1， CPHL=0，时钟空闲状态为1，采样时刻在第1个时钟沿/下降沿。
       - mode3：CPOL=1， CPHL=1，时钟空闲状态为1，采样时刻在第2个时钟沿/上升沿。
    常用模式0和模式3，且互相兼容；模式2和4兼容，但不常用。
## 实现
* 发送数据一般先发高位。时钟分频器不好实现，不好控制时钟开始结束，对一个时钟不允许同时使用上升沿和下降沿。都是在上升沿读取/采样接收到的数据，在下降沿翻转。
* 1bit计数器，每隔一个系统时钟计数。
* 上板调试：
    - 综合属性-set up debug 
        
        变量声明前添加(* mark_debug = "true" *)标记调试变量

    抓取时钟必须是最少频率为5M的自由时钟/板上时钟（不是自己定义的低频时钟）。

    在线调试的时钟-JTAG时钟频率要小于等于debug信号时钟频率的一半。
    - IP核调试-ILA，集成逻辑分析仪
        
        例化绑定信号（不可以跨文件）。综合后生成比特流。
        **使用综合属性调试完，需要在约束文件里（.xdc）把生成的约束删除掉**

