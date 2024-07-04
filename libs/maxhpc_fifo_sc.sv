// maxhpc: Maxim Vorontsov

`ifndef MAXHPC_FIFO_SC
`define MAXHPC_FIFO_SC

`include "maxhpc_dpram.sv"

`define ALWAYS(CLOCK,RESET) \
 `ifdef ASYNC_RESET \
  always @(CLOCK, RESET) \
 `else \
  always @(CLOCK) \
 `endif

module maxhpc_fifo_sc #(parameter
/* Global parameters */
 DEPTH_WD   = 4
,DATA_WD    = 8
//
,SHOWAHEAD  = "OFF"
/**/
/* Extra parameters */
,INPUT_REG  = "OFF"
,OUTPUT_REG = "ON"
,USE_EAB    = "ON"
/**/
)(
 input                    clear
,input                    clock
,
 input                    wr
,input      [DATA_WD-1:0] d
,output                   wempty
,output reg               wfull
,output reg[DEPTH_WD-1:0] wusedw
,
 input                    rd
,output     [DATA_WD-1:0] q
,output                   rempty
,output                   rfull
,output    [DEPTH_WD-1:0] rusedw
);
/* */
reg Rwr;
reg[DATA_WD-1:0] Rd;
reg Rread;
reg[DEPTH_WD-1:0] Xwptr;
reg[2:0] wempty_cnt;
//
reg[DEPTH_WD-1:0] rptr;
//
reg Xrempty;
reg Xrfull;
reg[DEPTH_WD-1:0] Xrusedw;

wire read;
wire shft_en0, shft_en1;
wire re0, re1;
wire[DATA_WD-1:0] ram_q;
reg[DATA_WD-1:0] Hram_q;

reg lat_Xrempty[0:1];
reg lat_Xrfull[0:1];
reg[DEPTH_WD-1:0] lat_Xrusedw[0:1];
/**/

/* */
maxhpc_dpram #(
 .ADDR_WD(DEPTH_WD)
,.DATA_WD(DATA_WD )
) array(
/* Port A */
 .a_clk (clock                      )
,.a_ce  (1'b1                       )
,.a_we  ((INPUT_REG=="ON")? Rwr : wr)
,.a_addr(Xwptr                      )
,.a_d   ((INPUT_REG=="ON")? Rd  : d )
,.a_q   ()
/**/
,
/* Port B */
 .b_clk (clock)
,.b_ce  (re0  )
,.b_we  (1'b0 )
,.b_addr(rptr )
,.b_d   ()
,.b_q   (ram_q)
/**/
);
defparam
 array.USE_EAB = USE_EAB;
/**/

/* */
assign wempty = wempty_cnt[2];

`ALWAYS(posedge clock, posedge clear)
 if (clear) Rwr <= 1'b0;
 else Rwr <= wr;

always @(posedge clock)
 Rd <= d;

`ALWAYS(posedge clock, posedge clear)
 if (clear) Rread <= 1'b0;
 else Rread <= read;

`ALWAYS(posedge clock, posedge clear)
 if (clear) Xwptr <= 0;
 else
  if ((INPUT_REG=="ON")? Rwr : wr) Xwptr <= Xwptr +1;

`ALWAYS(posedge clock, posedge clear)
 if (clear) wempty_cnt <= ~0;
 else
  if (wr || !rempty) wempty_cnt <= 0;
  else if (!wempty) wempty_cnt <= wempty_cnt[1:0] +1;

`ALWAYS(posedge clock, posedge clear)
 if (clear) {wfull, wusedw} <= 0;
 else
  if (wr && !rd) {wfull, wusedw} <= wusedw +1;
  else if (!wr && rd) {wfull, wusedw} <= {DEPTH_WD{1'b1}}&(wusedw -1);
  else if (wempty) {wfull, wusedw} <= 0; // Just sync.
//
`ALWAYS(posedge clock, posedge clear)
 if (clear) rptr <= 0;
 else
  if (read) rptr <= rptr +1;
  else if (wempty) rptr <= Xwptr; // Just sync.
//
assign read = (
 ((SHOWAHEAD=="ON")&&(OUTPUT_REG=="ON"))? !Xrempty && (lat_Xrempty[0] || lat_Xrempty[1] || rd) :
 ((SHOWAHEAD=="ON")^^(OUTPUT_REG=="ON"))? !Xrempty && (lat_Xrempty[0] || rd) :
 rd
);
assign shft_en0 = (
 ((SHOWAHEAD=="ON")&&(OUTPUT_REG=="ON"))? !Xrempty || lat_Xrempty[1] || rd :
 ((SHOWAHEAD=="ON")^^(OUTPUT_REG=="ON"))? !Xrempty || rd :
 1'b0
);
assign shft_en1 = ((SHOWAHEAD=="ON")&&(OUTPUT_REG=="ON"))? !lat_Xrempty[0] || rd : 1'b0;
assign re0 = (
 ((SHOWAHEAD=="ON")&&(OUTPUT_REG=="ON"))? lat_Xrempty[0] || lat_Xrempty[1] || rd :
 ((SHOWAHEAD=="ON")^^(OUTPUT_REG=="ON"))? lat_Xrempty[0] || rd :
 rd
);
assign re1 = (
 ((OUTPUT_REG=="ON")&&(SHOWAHEAD=="ON"))? lat_Xrempty[1] || rd :
 ((OUTPUT_REG=="ON")&&(SHOWAHEAD!="ON"))? rd :
 1'b0
);
assign rempty = (
 ((SHOWAHEAD=="ON")&&(OUTPUT_REG=="ON"))? lat_Xrempty[1] :
 ((SHOWAHEAD=="ON")^^(OUTPUT_REG=="ON"))? lat_Xrempty[0] :
 Xrempty
);
assign {rfull, rusedw} = (
 ((SHOWAHEAD=="ON")&&(OUTPUT_REG=="ON"))? {lat_Xrfull[1], lat_Xrusedw[1]} :
 ((SHOWAHEAD=="ON")^^(OUTPUT_REG=="ON"))? {lat_Xrfull[0], lat_Xrusedw[0]} :
 {Xrfull, Xrusedw}
);
assign q = (OUTPUT_REG=="ON")? Hram_q : ram_q;

`ALWAYS(posedge clock, posedge clear)
 if (clear) Xrempty <= 1'b1;
 else
  if (Rwr) Xrempty <= 1'b0;
  else if (re0) Xrempty <= Xrempty || (Xrusedw==1);

`ALWAYS(posedge clock, posedge clear)
 if (clear) {Xrfull, Xrusedw} <= 0;
 else
  if (Rwr && !read) {Xrfull, Xrusedw} <= Xrusedw +1;
  else if (!Rwr && read) {Xrfull, Xrusedw} <= {DEPTH_WD{1'b1}}&(Xrusedw -1);

`ALWAYS(posedge clock, posedge clear)
 if (clear) begin
  {lat_Xrempty[1], lat_Xrempty[0]} <= ~0;
  {lat_Xrfull[1], lat_Xrfull[0]} <= 0;
  {lat_Xrusedw[1], lat_Xrusedw[0]} <= 0;
 end else begin
  if (shft_en0) begin
   lat_Xrempty[0] <= Xrempty;
   lat_Xrfull[0] <= Xrfull;
   lat_Xrusedw[0] <= Xrusedw;
  end

  if (shft_en1) begin
   lat_Xrempty[1] <= lat_Xrempty[0];
   lat_Xrfull[1] <= lat_Xrfull[0];
   lat_Xrusedw[1] <= lat_Xrusedw[0];
  end
 end

always @(posedge clock)
 if (re1) Hram_q <= ram_q;
/**/

endmodule
`undef ALWAYS
`endif
