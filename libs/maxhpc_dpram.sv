// maxhpc: Maxim Vorontsov

`ifndef MAXHPC_DPRAM
`define MAXHPC_DPRAM

module maxhpc_dpram #(parameter
 ADDR_WD = 8
,DATA_WD = 8
//
,DEPTH   = -1   // mostly not used
,USE_EAB = "ON" // "OFF" - force fallback to reg RAM with ram_style="logic"
)(
/* Port A */
 input               a_clk
,input               a_ce
,input               a_we
,input [ADDR_WD-1:0] a_addr
,input [DATA_WD-1:0] a_d
,output[DATA_WD-1:0] a_q
/**/
,
/* Port B */
 input               b_clk
,input               b_ce
,input               b_we
,input [ADDR_WD-1:0] b_addr
,input [DATA_WD-1:0] b_d
,output[DATA_WD-1:0] b_q
/**/
);
localparam REAL_DEPTH = (DEPTH==-1)? (1<<ADDR_WD) : DEPTH;

(* ram_style="block" *) reg[DATA_WD-1:0] arrayRAM[0:REAL_DEPTH-1];
(* ram_style="logic" *) reg[DATA_WD-1:0] arrayLogic[0:REAL_DEPTH-1];

/* Port A */
 reg[DATA_WD-1:0] a_qRAM, a_qLogic;
 always @(posedge a_clk) begin
  if (a_ce) begin
   // Write
   if (a_we) begin
    if (USE_EAB!="OFF") begin
     arrayRAM[a_addr] <= a_d;
    end
     else begin
      arrayLogic[a_addr] <= a_d;
     end
   end
   // Read
   if (USE_EAB!="OFF") begin
    a_qRAM <= arrayRAM[a_addr];
   end
    else begin
     a_qLogic <= arrayLogic[a_addr];
    end
  end
 end
 
 assign a_q = (USE_EAB!="OFF")? a_qRAM
                              : a_qLogic;
/**/

/* Port B */
 reg[DATA_WD-1:0] b_qRAM, b_qLogic;
 always @(posedge b_clk) begin
  if (b_ce) begin
   // Write
   if (b_we) begin
    if (USE_EAB!="OFF") begin
     arrayRAM[b_addr] <= b_d;
    end
     else begin
      arrayLogic[b_addr] <= b_d;
     end
   end
   // Read
   if (USE_EAB!="OFF") begin
    b_qRAM <= arrayRAM[b_addr];
   end
    else begin
     b_qLogic <= arrayLogic[b_addr];
    end
  end
 end
 
 assign b_q = (USE_EAB!="OFF")? b_qRAM
                              : b_qLogic;
/**/

endmodule
`endif
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
