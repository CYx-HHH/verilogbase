## NetFPGA SUME
**开发板**

板子可作为PCIE外接设备使用，也可以独立使用，根据PCIE的pin口是8pin还是6pin（另2pin短接）决定。

FPGA可以烧录bin程序到flash，恢复配置（支持四个独立程序），也可以通过jtag下载bit文件。

Jtag主要从Usb-Jtag口配置，也可用外部Jtag编程器连J9.

CPLD是通过一个BSS寄存器决定配置程序，可通过Adept的dsumecfg工具配置从flash读/写程序。使用dsumecfg需要连usb-jtag口。

板子上电后如果jumper/JP1没有短路，则自动从flash恢复配置；无论JP1是都短路，都可用Jtag配置覆盖当前配置，配置有效LD4亮，配置错误LD5亮。如果jumper/JP1没短接，BTN按钮触发CPLD加载flash中的配置，否则清空flash配置。


**开源套件/项目**

主要从tcl文件恢复vivado工程，tcl本质是调用vivado接口的脚本。结合makefile调用tcl文件，能够实现批量处理程序。sume由多个自定义IP核组成，结合python和C进行测试，支持导出elf文件给嵌入式开发(SDK)使用.

`.xci`文件是IP核实例，包含用户特定的配置信息（尤其是自定义IP核），可以生成仿真，综合阶段的文件。
`.coe`文件是ROM初始化文件。
coe文件和xci文件一一对应，且需要在同一目录下。


**套件组成**

sume是网卡驱动程序，包括`input_arbiter`, `axis_fifo`, `nf_riffa_dma`, `output_queues`等组成部分。

数据包从`nf_10g_interface`的接收端`RX`进入模块，该模块主要有PMA，PCS（处理从外部SFP接口接收数据包。然后将数据包交给10g mac程序处理，转为256bit的AXI4数据）;

接口`RX`连接到`input_arbiter`，该模块有5个输入（4个10g接口，一个dma），每个输入连接到一个`small_fall-through_fifo`队列.

`arbiter`从`fifo`队列中轮询选择数据包发送到输出端口查询模块（`output port lookup`）；

输出端口模块将数据包交给输出队列，同样有5个输出队列（4个10g接口，一个dma），奇数队列将数据包发往输出端口，偶数发往`DMA`。其中`DMA`模块包括PCIE，DMA，以及axi4互联模块。

`riffa DMA`通过`PCIE`接口接收数据包以及数据包事务（寄存器访问等），将数据包和寄存器访问分别转为axi-stream和axi-lite接口的流，支持缓冲区处理以及有专门的驱动。


**编译测试用例和网卡程序**
1. 测试程序 acceptance_test
    
   主要功能：使用python调用dsumecfg等命令将默认bit文件写入flash，检测端口状态。

   默认python2，配置会出现缺少依赖问题，类似Widget...GUI之类的报错。于是使用python3，改了调用接口。

2. 网卡程序 reference_nic
   
   编译会报错，会对一些管脚约束严重警告，需要更改。编译到10g IP核license报错，使用到官方IP核。







