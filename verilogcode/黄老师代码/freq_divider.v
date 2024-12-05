module freq_divider #
(
   parameter   QWID           = 16                 //P\Q端口的位宽
)
(
   //input
   input                      clk               ,  //主时钟
   input       [QWID-1:0]     p                 ,  //时钟分频比P参数
   input       [QWID-1:0]     q                 ,  //时钟分频比Q参数
   //
   output reg                 en = 0            ,  //en为(P/Q)*FREQ(clk)频次的脉冲信号
   output reg                 df = 0            ,  //df为(P/Q)*FREQ(clk)频次的分频信号
   output reg  [QWID-1:0]     cc = 0               //cc为(P/Q)*FREQ(clk)频次的计数器
);

//*****************************************************************************
// Signals
//*****************************************************************************
reg   [QWID-1:0]              psq = 0;
reg   [QWID-1:0]              cnt = 0;

//*****************************************************************************
// Processes
//*****************************************************************************
always @ ( posedge clk )
   psq <= {p,1'b0} - q;

always @ ( posedge clk )
begin
   if ( cnt >= q )
      cnt <= cnt + psq;
   else
      cnt <= cnt + {p,1'b0};
end

always @ ( posedge clk )
begin
   if ( cnt >= q )
      en <= ~df;
   else
      en <= 0;
end

always @ ( posedge clk )
begin
   if ( cnt >= q )
   begin
      df <=~df;
      cc <= cc + {1'b0,~df};
   end
end

endmodule