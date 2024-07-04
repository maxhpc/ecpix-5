// maxhpc: Maxim Vorontsov

`ifndef MAXHPC_FIFO_DC
`define MAXHPC_FIFO_DC

`include "maxhpc_dpram.sv"

`define ALWAYS(CLOCK,RESET) \
 `ifdef ASYNC_RESET \
  always @(CLOCK, RESET) \
 `else \
  always @(CLOCK) \
 `endif

module maxhpc_fifo_dc #(parameter
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
,FAST_MODE  = "OFF" // Can be turned on ONLY if 6*Freq(wclk)>Freq(rclk).
/**/
)(
/* write */
 input                     wclr
,input                     wclk
,input                     wr
,input      [DATA_WD-1: 0] d
,output reg                wempty
,output reg                wfull
,output reg[DEPTH_WD-1: 0] wusedw
/**/
,
/* read */
 input                     rclr
,input                     rclk
,input                     rd
,output     [DATA_WD-1: 0] q
,output                    rempty
,output                    rfull
,output    [DEPTH_WD-1: 0] rusedw
/**/
);

/* */
function[DEPTH_WD:0] F_BIN2GRAY(input[DEPTH_WD:0] BIN_CODE);
 reg[DEPTH_WD:0] GRAY_CODE;
 int I;
begin
 GRAY_CODE = BIN_CODE;
 for (I=DEPTH_WD-1; I>=0; I=I-1)
  GRAY_CODE[I] = BIN_CODE[I+1] ^^ BIN_CODE[I];
 F_BIN2GRAY = GRAY_CODE;
end endfunction

function[DEPTH_WD:0] F_GRAY2BIN(input[DEPTH_WD:0] GRAY_CODE);
 reg[DEPTH_WD:0] BIN_CODE;
 int I;
begin
 BIN_CODE = GRAY_CODE;
 for (I=DEPTH_WD-1; I>=0; I=I-1)
  BIN_CODE[I] = BIN_CODE[I+1] ^^ GRAY_CODE[I];
 F_GRAY2BIN = BIN_CODE;
end endfunction
/**/

/* */
reg Rwr;
reg[DATA_WD-1:0] Rd;
reg[DEPTH_WD:0] Xwptr, wptr_gray;
//
reg[DEPTH_WD:0] Xrptr, Xrptr_gray;
wire[DEPTH_WD:0] rptr_gray;
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
reg[DEPTH_WD:0] lat_Xrptr_gray[0:1];
/**/

/* */
maxhpc_dpram #(
 .ADDR_WD(DEPTH_WD)
,.DATA_WD(DATA_WD )
) array(
/* Port A */
 .a_clk (wclk                       )
,.a_ce  (1'b1                       )
,.a_we  ((INPUT_REG=="ON")? Rwr : wr)
,.a_addr(Xwptr[DEPTH_WD-1:0]        )
,.a_d   ((INPUT_REG=="ON")? Rd  : d )
,.a_q   ()
/**/
,
/* Port B */
 .b_clk (rclk               )
,.b_ce  (re0                )
,.b_we  (1'b0               )
,.b_addr(Xrptr[DEPTH_WD-1:0])
,.b_d   ()
,.b_q   (ram_q              )
/**/
);
defparam
 array.USE_EAB = USE_EAB;
/**/

/* */
`ALWAYS(posedge wclk, posedge wclr)
 if (wclr) Rwr <= 1'b0;
 else Rwr <= wr;

always @(posedge wclk)
 Rd <= d;

`ALWAYS(posedge wclk, posedge wclr)
 if (wclr) Xwptr <= 0;
 else
  if ((INPUT_REG=="ON")? Rwr : wr) Xwptr <= Xwptr +1;

`ALWAYS(posedge wclk, posedge wclr)
 if (wclr) wptr_gray <= 0;
 else
  if (FAST_MODE!="ON") wptr_gray <= F_BIN2GRAY(Xwptr);
  else if ((INPUT_REG=="ON")? Rwr : wr) wptr_gray <= F_BIN2GRAY(Xwptr+1);

reg[DEPTH_WD:0] Sw_rptr_gray, SSw_rptr_gray;
`ALWAYS(posedge wclk, posedge wclr)
 if (wclr) {Sw_rptr_gray, SSw_rptr_gray} <= 0;
 else {Sw_rptr_gray, SSw_rptr_gray} <= {rptr_gray, Sw_rptr_gray};

`ALWAYS(posedge wclk, posedge wclr)
 if (wclr) wempty <= 1'b1;
 else wempty <= ~|({DEPTH_WD+1{1'b1}}&(Xwptr-F_GRAY2BIN(SSw_rptr_gray))) && !wr && !((INPUT_REG=="ON") && Rwr);

`ALWAYS(posedge wclk, posedge wclr)
 if (wclr) {wfull, wusedw} <= 0;
 else {wfull, wusedw} <= Xwptr-F_GRAY2BIN(SSw_rptr_gray) +((INPUT_REG=="ON")? {wr}+{Rwr} : {wr});
//
`ALWAYS(posedge rclk, posedge rclr)
 if (rclr) begin
  Xrptr <= 0;
  Xrptr_gray <= 0;
 end else
  if (read) begin
   Xrptr <= Xrptr +1;
   Xrptr_gray <= F_BIN2GRAY(Xrptr +1);
  end

reg[DEPTH_WD:0] Sr_wptr_gray, SSr_wptr_gray;
`ALWAYS(posedge rclk, posedge rclr)
 if (rclr) {Sr_wptr_gray, SSr_wptr_gray} <= 0;
 else {Sr_wptr_gray, SSr_wptr_gray} <= {wptr_gray, Sr_wptr_gray};
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
assign rptr_gray = (
 ((SHOWAHEAD=="ON")&&(OUTPUT_REG=="ON"))? lat_Xrptr_gray[1] :
 ((SHOWAHEAD=="ON")^^(OUTPUT_REG=="ON"))? lat_Xrptr_gray[0] :
 Xrptr_gray
);
assign q = (OUTPUT_REG=="ON")? Hram_q : ram_q;

`ALWAYS(posedge rclk, posedge rclr)
 if (rclr) Xrempty <= 1'b1;
 else Xrempty <= ~|({DEPTH_WD+1{1'b1}}&(F_GRAY2BIN(SSr_wptr_gray)-Xrptr -{read}));

`ALWAYS(posedge rclk, posedge rclr)
 if (rclr) {Xrfull, Xrusedw} <= 0;
 else {Xrfull, Xrusedw} <= F_GRAY2BIN(SSr_wptr_gray)-Xrptr -{read};

`ALWAYS(posedge rclk, posedge rclr)
 if (rclr) begin
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

`ALWAYS(posedge rclk, posedge rclr)
 if (rclr) {lat_Xrptr_gray[1], lat_Xrptr_gray[0]} <= 0;
 else begin
  if (re0) lat_Xrptr_gray[0] <= Xrptr_gray;
  if (re1) lat_Xrptr_gray[1] <= lat_Xrptr_gray[0];
 end

always @(posedge rclk)
 if (re1) Hram_q <= ram_q;
/**/

endmodule
`undef ALWAYS
`endif
