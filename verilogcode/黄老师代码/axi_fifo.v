module axi_fifo #
(
   parameter   PWID              = 2               ,
   parameter   DWID              = 32              ,
   parameter   TYPE              = "R"             ,
   parameter   RAM_STYLE         = "block"            // "block", "distributed" or "registers"
)
(
   //input
   input                         rst               ,
   input                         clk               ,
   input                         wren              ,
   input       [PWID-1:0]        waddr             ,
   input       [DWID-1:0]        data              ,
   //output
   input                         rden              ,
   input       [PWID-1:0]        raddr             ,
   output reg  [DWID-1:0]        dout={DWID{1'b0}} ,
   output                        bare              ,
   output                        half              ,
   output                        full
);

//*****************************************************************************
// Signals
//*****************************************************************************
reg   [PWID:0]                   wcnt = 0;
reg   [PWID:0]                   rcnt = 0;
wire  [PWID:0]                   pcnt = wcnt - rcnt;
(* ram_style = RAM_STYLE *)
reg   [DWID-1:0]                 dsav[2**PWID-1:0];

//*****************************************************************************
// Processes
//*****************************************************************************
assign bare = ( wcnt[0+:PWID] == rcnt[0+:PWID] &&  wcnt[PWID] == rcnt[PWID] );
assign full = ( wcnt[0+:PWID] == rcnt[0+:PWID] && ~wcnt[PWID] == rcnt[PWID] );
assign half = ( pcnt[PWID-:2] == 2'b01 );

integer index;
initial
begin
   for (index = 0; index < 2**PWID; index = index + 1)
     dsav[index] = {(DWID){1'b0}};
end

//=============================================================================
//
//=============================================================================
generate
   if ( TYPE == "W" )
   begin
      always @ ( posedge clk )
      begin
         if ( wren )
            dsav[waddr] <= data;
      end

      always @ ( posedge clk )
      begin
         if ( rst )
            dout <= {(DWID){1'b0}};
         else if ( rden )
            dout <= dsav[raddr];
         else ;
      end
   end
   //
   if ( TYPE == "R" )
   begin
      always @ ( posedge clk )
      begin
         if ( rst )
            wcnt <= {(PWID+1){1'b0}};
         else if ( wren == 1 && full == 0 )
            wcnt <= wcnt + 1;
         else ;
      end

      always @ ( posedge clk )
      begin
         if ( wren == 1 && full == 0 )
            dsav[wcnt[0+:PWID]] <= data;
      end

      always @ ( posedge clk )
      begin
         if ( rst )
            rcnt <= {(PWID+1){1'b0}};
         else if ( rden == 1 && bare == 0 )
            rcnt <= rcnt + 1;
         else ;
      end

      always @ ( posedge clk )
      begin
         if ( rst )
            dout <= {(DWID){1'b0}};
         else if ( rden == 1 && bare == 0 )
            dout <= dsav[rcnt[0+:PWID]];
         else if ( rden == 1 )
            dout <= {(DWID){1'b0}};
         else ;
      end
   end
endgenerate

endmodule