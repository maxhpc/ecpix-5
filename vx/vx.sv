// maxhpc: Maxim Vorontsov

`define NOASYNC

`include "../libs/ddr3/ddr3_top.sv"
`include "../libs/uart/uart.sv"

`define ALWAYS(CLOCK,RESET) \
 `ifndef NOASYNC \
  always @(CLOCK, RESET) \
 `else \
  always @(CLOCK) \
 `endif

`define LENGTH(ADR,SIZ,OFS) (((ADR+SIZ-1)>>(OFS))-((ADR)>>(OFS)))

module vx(
 `include "../ecpix5_ports.hv"
);
/* clocks */
 wire sysclk;
 wire ddrclk;

 `ifndef VERILATOR
  wire [3:0] clk_pll;
  wire       pll_locked;
  ecp5pll
  #(
   .in_hz(100000000)
  ,.out0_hz(50000000)
  ,.out1_hz(50000000)
  ,.out1_deg(90)
  ) pll(
   .clk_i(fpga_sysclk)
  ,.clk_o(clk_pll)
  ,.reset(1'b0)
  ,.standby(1'b0)
  ,.phasesel(2'b0)
  ,.phasedir(1'b0) 
  ,.phasestep(1'b0)
  ,.phaseloadreg(1'b0)
  ,.locked(pll_locked)
  );

  assign sysclk = clk_pll[0]; // 50MHz
  assign ddrclk = clk_pll[1]; // 50MHz (90 degree phase shift)
 `else
  assign sysclk = fpga_sysclk;
  assign ddrclk = fpga_sysclk;
 `endif
/**/
/* resets */
 reg rst_;

 assign rst_sys_ = 1'bz;

 reg[1:0] Srst_fpga_, Sgsrn;
 `ALWAYS(posedge sysclk, negedge pll_locked)
  if (!pll_locked) begin
   Srst_fpga_[1:0] <= 2'b00;
   Sgsrn[1:0] <= 2'b00;
   //
   rst_ <= 1'b0;
  end
   else begin
    Srst_fpga_[1:0] <= {Srst_fpga_[0], rst_fpga_};
    Sgsrn[1:0] <= {Sgsrn[0], gsrn};
    //
    rst_ <= Srst_fpga_[1] && Sgsrn[1];
   end
/**/

/* DDR3 */
 reg[31:0] axi4_awaddr;
 reg [7:0] axi4_awlen;
 reg       axi4_awvalid;
 wire      axi4_awready;
 //
 reg[31:0] axi4_wdata;
 reg [3:0] axi4_wstrb;
 reg       axi4_wlast;
 reg       axi4_wvalid;
 wire      axi4_wready;
 //
 reg[31:0] axi4_araddr;
 reg [7:0] axi4_arlen;
 logic     axi4_arvalid;
 wire      axi4_arready;
 //
 wire[31:0] axi4_rdata;
 wire       axi4_rlast;
 wire       axi4_rvalid;
//
wire[31:0] dfi_rddata_w;
wire       dfi_rddata_valid_w;
 ddr3_top ddr3(
 // clocks, reset
  .rst(!rst_)
 ,.clk(sysclk)
 ,
  .ddrclk(ddrclk)
 ,// DDR3
  .ddr3_a    (ddr_a                  )
 ,.ddr3_ba   (ddr_ba                 )
 ,.ddr3_ras_n(ddr_ras_               )
 ,.ddr3_cas_n(ddr_cas_               )
 ,.ddr3_we_n (ddr_we_                )
 ,.ddr3_dm   ({ddr_udm,ddr_ldm}      )
 ,.ddr3_dq   (ddr_d                  )
 ,.ddr3_dqs_p({ddr_udqs_p,ddr_ldqs_p})
 ,.ddr3_clk_p(ddr_ck_p               )
 ,.ddr3_cke  (ddr_cke                )
 ,.ddr3_odt  (ddr_odt                )
 ,// AXI4
  .axi4_awid   ('h0)
 ,.axi4_awaddr (axi4_awaddr)
 ,.axi4_awlen  (axi4_awlen)
 ,.axi4_awburst('h1)
 ,.axi4_awvalid(axi4_awvalid)
 ,.axi4_awready(axi4_awready)
 ,
  .axi4_wdata (axi4_wdata)
 ,.axi4_wstrb (axi4_wstrb)
 ,.axi4_wlast (axi4_wlast)
 ,.axi4_wvalid(axi4_wvalid)
 ,.axi4_wready(axi4_wready)
 ,
  .axi4_bid   ()
 ,.axi4_bresp ()
 ,.axi4_bvalid()
 ,.axi4_bready(1'b1)
 ,
  .axi4_arid   (0)
 ,.axi4_araddr (axi4_araddr)
 ,.axi4_arlen  (axi4_arlen)
 ,.axi4_arburst('h1)
 ,.axi4_arvalid(axi4_arvalid)
 ,.axi4_arready(axi4_arready)
 ,
  .axi4_rid   ()
 ,.axi4_rdata (axi4_rdata)
 ,.axi4_rresp ()
 ,.axi4_rlast (axi4_rlast)
 ,.axi4_rvalid(axi4_rvalid)
 ,.axi4_rready(axi4_rvalid)
 );
/**/

/* UART */
 wire[7:0] rx_byte;
 wire      rx_stb;
 //
 reg[7:0] tx_byte;
 reg      tx_req;
 wire     tx_idle;

 uart #(
  .CLK_HZ(50000000)
 ,.BAUD  (1000000)
 ) uart(
  .rst_(rst_)
 ,.clk(sysclk)
 ,
  .rxd(uart_rxd)
 ,.txd(uart_txd)
 ,
  .rx_byte(rx_byte)
 ,.rx_stb (rx_stb )
 ,
  .tx_byte(tx_byte)
 ,.tx_req (tx_req )
 ,.tx_idle(tx_idle)
 );
/**/

/* Vortex stuff */
 /* receive */
  enum {RCV_CMD
       ,RCV_CMD_STB
       ,RCV_WRWORD
       ,RCV_DDRWR
       ,RCVST_SIZE} RCVST_ENUM;
  reg[RCVST_SIZE-1:0] rcv_state;
  struct packed{
   reg   [31:0] size;
   reg   [31:0] addr;
   reg[4*8-1:0] opcode;
  } rcv_cmd;
  reg[6:0] rcv_cmdCnt;
  //
  reg[32:0] rcv_wrCnt;
  reg [1:0] rcv_wrPtr;
  reg[31:0] rcv_wrWord;
  `ALWAYS(posedge sysclk, negedge rst_)
   if (!rst_) begin
    axi4_awvalid <= 1'b0;
    axi4_wvalid  <= 1'b0;
    //
    rcv_cmdCnt <= ($bits(rcv_cmd)+7)/8 -2;
    rcv_state <= (1<<RCV_CMD);
   end
    else begin
     if (axi4_awready) begin
      axi4_awvalid <= 1'b0;
      if (axi4_awvalid) begin
       axi4_awaddr <= axi4_awaddr+4;
      end
     end
     if (axi4_wready) begin
      axi4_wvalid <= 1'b0;
      axi4_wstrb <= 4'b1111;
     end
     unique case (rcv_state)
      default: begin // (1<<RCV_CMD)
       if (rx_stb) begin
        rcv_cmd[$bits(rcv_cmd)-1-:8] <= rx_byte;
        rcv_cmd[0+:$bits(rcv_cmd)-8] <= rcv_cmd[$bits(rcv_cmd)-1-:$bits(rcv_cmd)-8];
        //
        if (rcv_cmdCnt[6]) begin
         rcv_state <= (1<<RCV_CMD_STB);
        end
        rcv_cmdCnt <= rcv_cmdCnt-1;
       end
      end
      (1<<RCV_CMD_STB): begin
       rcv_wrCnt <= rcv_cmd.size -2;
       rcv_wrPtr <= rcv_cmd.addr[1:0];
       //
       axi4_awaddr  <= rcv_cmd.addr[31:2]<<2;
       axi4_wstrb  <= 4'b1111<<rcv_cmd.addr[1:0];
       //
       case (rcv_cmd.opcode)
        "ddrW": begin
         rcv_state <= (1<<RCV_WRWORD);
        end
        //
        default: begin
         rcv_cmdCnt <= ($bits(rcv_cmd)+7)/8 -2;
         rcv_state <= (1<<RCV_CMD);
        end
       endcase
      end
      //
      (1<<RCV_WRWORD): begin
       if (rx_stb) begin
        rcv_wrCnt <= rcv_wrCnt-1;
        rcv_wrPtr <= rcv_wrPtr+1;
        case (rcv_wrPtr)
         2'h0: begin
          rcv_wrWord[0+:8] <= rx_byte;
         end
         2'h1: begin
          rcv_wrWord[8+:8] <= rx_byte;
         end
         2'h2: begin
          rcv_wrWord[16+:8] <= rx_byte;
         end
         2'h3: begin
          rcv_wrWord[24+:8] <= rx_byte;
         end
        endcase
        if ((rcv_wrPtr==3'h3) || rcv_wrCnt[32]) begin
         rcv_state <= (1<<RCV_DDRWR);
        end
       end
      end
      (1<<RCV_DDRWR): begin
       axi4_awlen   <= 8'h0;
       axi4_awvalid <= 1'b1;
       //
       axi4_wdata <= rcv_wrWord;
       axi4_wlast  <= 1'b1;
       axi4_wvalid <= 1'b1;
       //
       rcv_state <= (1<<RCV_WRWORD);
       rcv_cmdCnt <= ($bits(rcv_cmd)+7)/8 -2;
       if (rcv_wrCnt[32] && !rcv_wrCnt[0]) begin
        axi4_wstrb  <= axi4_wstrb & (4'b1111>>(2'h3 & ~(rcv_cmd.addr[1:0]+rcv_cmd.size[1:0]-1)));
        //
        rcv_state <= (1<<RCV_CMD);
       end
      end
     endcase
    end
 /**/
 /* send */
  enum {SND_IDLE
       ,SND_AXI4_ARVALID
       ,SND_AXI4_RVALID
       ,SND_AXI4_RDATA
       ,SNDST_SIZE} SNDST_ENUM;
  reg[SNDST_SIZE-1:0] snd_state;
   assign axi4_arvalid = snd_state[SND_AXI4_ARVALID];
  reg[31:0] snd_word;
  reg[32:0] snd_byteCnt;
  reg [1:0] snd_axi4rdPtr;
  `ALWAYS(posedge sysclk, negedge rst_)
   if (!rst_) begin
    tx_req <= 1'b0;
    //
    snd_state <= (1<<SND_IDLE);
   end
    else begin
     if (!tx_idle) begin
      tx_req <= 1'b0;
     end
     unique case (snd_state)
      default: begin // (1<<SND_IDLE)
       if (rcv_state[RCV_CMD_STB]) begin
        case (rcv_cmd.opcode)
         "ddrR": begin
          axi4_araddr <= rcv_cmd.addr[31:2]<<2;
          axi4_arlen   <= 8'h0;
          //
          snd_byteCnt <= rcv_cmd.size -2;
          snd_axi4rdPtr <= rcv_cmd.addr[1:0];
          //
          snd_state <= (1<<SND_AXI4_ARVALID);
         end
         //
         default: begin
         end
        endcase
       end
      end
      //
      (1<<SND_AXI4_ARVALID): begin
       if (axi4_arready) begin
        axi4_araddr <= axi4_araddr+4;
        //
        snd_state <= (1<<SND_AXI4_RVALID);
       end
      end
      //
      (1<<SND_AXI4_RVALID): begin
       if (axi4_rvalid) begin
        snd_word <= axi4_rdata>>(8*snd_axi4rdPtr);
        //
        snd_state <= (1<<SND_AXI4_RDATA);
       end
      end
      //
      (1<<SND_AXI4_RDATA): begin
       if (tx_idle && !tx_req) begin
        snd_byteCnt <= snd_byteCnt-1;
        snd_axi4rdPtr <= snd_axi4rdPtr+1;
        //
        tx_byte <= snd_word[0+:8];
        snd_word <= snd_word>>8;
        tx_req <= 1'b1;
        //
        if (snd_axi4rdPtr==3'h3) begin
         snd_state <= (1<<SND_AXI4_ARVALID);
        end
        if (snd_byteCnt[32]) begin
         snd_state <= (1<<SND_IDLE);
        end
       end
      end
     endcase
    end
 /**/
/**/

/* LEDs */
 assign {led_rgb3,led_rgb2,led_rgb1,led_rgb0} = {{3{1'b1}},{3{1'b1}},{3{1'b1}},{3{1'b1}}};
/**/

endmodule
`undef LENGTH
`undef ALWAYS
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
