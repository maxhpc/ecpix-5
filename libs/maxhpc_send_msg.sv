// maxhpc: Maxim Vorontsov

`ifndef MAXHPC_SEND_MSG
`define MAXHPC_SEND_MSG

module maxhpc_send_msg #(parameter
/* */
 DATA_WD = 8
/**/
/* Extra parameters */
,ASYNC_EN = "YES"
/**/
)(
 input              wr_rst
,input              wr_clk
,input              wr_req
,input[DATA_WD-1:0] wr_d
//
,input                   rd_rst
,input                   rd_clk
,output reg              rd_req
,input                   rd_ack
,output reg[DATA_WD-1:0] rd_q
);

 reg wr_ev; initial wr_ev <= 1'b0;
 always @(posedge wr_clk)
  if (wr_req) wr_ev <= !wr_ev;
 reg[2:0] Swr_ev;
 always @(posedge rd_clk)
  Swr_ev[2:0] <= {Swr_ev[1:0], wr_ev};

generate if (ASYNC_EN!="NO") begin:ASYNC
 always @(posedge rd_clk, posedge rd_rst)
  if (rd_rst) rd_req <= 1'b0;
  else
   if (rd_ack) rd_req <= 1'b0;
   else if (Swr_ev[2]!=Swr_ev[1]) rd_req <= 1'b1;
end else begin:NO_ASYNC
 always @(posedge rd_clk)
  if (rd_rst) rd_req <= 1'b0;
  else
   if (rd_ack) rd_req <= 1'b0;
   else if (Swr_ev[2]!=Swr_ev[1]) rd_req <= 1'b1;
end endgenerate

 always @(posedge wr_clk)
  if (wr_req) rd_q <= wr_d;

endmodule
`endif
