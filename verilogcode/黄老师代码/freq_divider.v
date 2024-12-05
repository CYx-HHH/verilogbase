module freq_divider #
(
   parameter   QWID           = 16                 //P\Q�˿ڵ�λ��
)
(
   //input
   input                      clk               ,  //��ʱ��
   input       [QWID-1:0]     p                 ,  //ʱ�ӷ�Ƶ��P����
   input       [QWID-1:0]     q                 ,  //ʱ�ӷ�Ƶ��Q����
   //
   output reg                 en = 0            ,  //enΪ(P/Q)*FREQ(clk)Ƶ�ε������ź�
   output reg                 df = 0            ,  //dfΪ(P/Q)*FREQ(clk)Ƶ�εķ�Ƶ�ź�
   output reg  [QWID-1:0]     cc = 0               //ccΪ(P/Q)*FREQ(clk)Ƶ�εļ�����
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