//******************************************************************************
// sdpram.v
// Copyright 2016 Sencore, Inc. All rights reserved.
//
// This module infers a Distributed RAM or Block RAM depending on the RAM
// dimensions and synthesis tool settings.  It provides symmetrical write and
// read ports, each with clock enable.  A separate clock input is provided for
// each port so they may be synchronous or asynchronous.
//******************************************************************************

module sdpram
#(
   parameter DWID       = 32,             // RAM entry width
   parameter AWID       = 10,             // RAM address bits (depth = 2^AWID)
   parameter CK_MODE    = "ASYNC",        // "ASYNC" or "SYNC"
   parameter WR_MODE    = "READ_FIRST",   // "READ_FIRST" or "WRITE_FIRST"
   parameter RAM_STYLE  = "block",        // "block", "distributed" or "registers"
   parameter RDATA_REG  = 0,              // output data register
   parameter INIT_FILE  = "",             // optional RAM initialization file
   parameter DATA_TYPE  = "HEX"           // "HEX" or "BIN"
)
(
   input             wclk,
   input             we,
   input  [AWID-1:0] waddr,
   input  [DWID-1:0] wdata,

   input             rclk,
   input             re,
   input  [AWID-1:0] raddr,
   output [DWID-1:0] rdata
);

   localparam DEPTH = 2**AWID;

   (* ram_style = RAM_STYLE *)
   reg [DWID-1:0] ram_cell [DEPTH-1:0];

   reg            re_q1;
   reg [DWID-1:0] rdata_latency1 = {DWID {1'b0}};
   reg [DWID-1:0] rdata_latency2 = {DWID {1'b0}};

   generate

      if (INIT_FILE == "")
      begin: ram_init_zero
         integer ram_index;
         initial
            for (ram_index = 0; ram_index < DEPTH; ram_index = ram_index + 1)
               ram_cell[ram_index] = {DWID {1'b0}};
      end

      else
      begin: ram_init_file
         initial
            if (DATA_TYPE == "BIN")
               $readmemb(INIT_FILE, ram_cell, 0, DEPTH-1);
            else
               $readmemh(INIT_FILE, ram_cell, 0, DEPTH-1);
      end

   endgenerate

   // write
   always @(posedge wclk)
      if (we == 1'b1)
         ram_cell[waddr] <= wdata;

   // read
   always @(posedge rclk)
   begin
      if (re == 1'b1)
      begin
         if (CK_MODE == "SYNC" && WR_MODE == "WRITE_FIRST" && we == 1'b1 && waddr == raddr)
            rdata_latency1 <= wdata;
         else
            rdata_latency1 <= ram_cell[raddr];
      end
   end

   // optional output register
   always @(posedge rclk)
   begin
      re_q1 <= re;

      if(re_q1 == 1'b1)
         rdata_latency2 <= rdata_latency1;
   end

   assign rdata = (RDATA_REG == 1) ? rdata_latency2 : rdata_latency1;

endmodule
