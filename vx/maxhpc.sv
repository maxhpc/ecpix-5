// maxhpc: Maxim Vorontsov

`define NOASYNC

`ifndef VERILATOR
`include "../libs/ddr3/core_ddr3_controller/examples/ecpix_ecp5/ecp5pll.sv"
`endif
`include "../libs/ddr3/ddr3_top.sv"
`include "../libs/uart/uart.sv"
//
`include "../libs/maxhpc_dpram.sv"

`define ALWAYS(CLOCK,RESET) \
 `ifndef NOASYNC \
  always @(CLOCK, RESET) \
 `else \
  always @(CLOCK) \
 `endif

`define LENGTH(ADR,SIZ,OFS) (((ADR+SIZ-1)>>(OFS))-((ADR)>>(OFS)))

`include "VX_define.vh"
import VX_gpu_pkg::*;

module maxhpc(
 `include "../ecpix5_ports.hv"
);
/* clocks */
 wire sysclk;
 wire ddrclk;

 `ifndef VERILATOR
  wire [3:0] clk_pll;
  wire       pll_locked;
  ecp5pll #(
   .in_hz(100000000)
  ,.out0_hz(25000000)
  ,.out1_hz(25000000)
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
  wire       pll_locked = 1'b1;

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

/* Vortex instance */
 reg vx_rst;
 // Memory request
 wire                           mem_req_valid;
 wire                           mem_req_rw;
 wire[`VX_MEM_BYTEEN_WIDTH-1:0] mem_req_byteen;
 wire[  `VX_MEM_ADDR_WIDTH-1:0] mem_req_addr;
 wire[  `VX_MEM_DATA_WIDTH-1:0] mem_req_data;
 wire[   `VX_MEM_TAG_WIDTH-1:0] mem_req_tag;
 wire                           mem_req_ready;
 // Memory response    
 reg                         mem_rsp_valid;
 reg[`VX_MEM_DATA_WIDTH-1:0] mem_rsp_data;
 reg[ `VX_MEM_TAG_WIDTH-1:0] mem_rsp_tag;
 wire                        mem_rsp_ready;
 // DCR write request
 wire                         dcr_wr_valid;
 wire[`VX_DCR_ADDR_WIDTH-1:0] dcr_wr_addr;
 wire[`VX_DCR_DATA_WIDTH-1:0] dcr_wr_data;
 // Status
 wire vx_busy;
 // maxhpc
 wire                           sim_ebreak;
 wire[`NUM_REGS-1:0][`XLEN-1:0] sim_wb_value;
 //
 Vortex vortex(
  // Clock
  .clk  (sysclk)
 ,.reset(vx_rst)
 ,// Memory request
  .mem_req_valid (mem_req_valid )
 ,.mem_req_rw    (mem_req_rw    )
 ,.mem_req_byteen(mem_req_byteen)
 ,.mem_req_addr  (mem_req_addr  )
 ,.mem_req_data  (mem_req_data  )
 ,.mem_req_tag   (mem_req_tag   )
 ,.mem_req_ready (mem_req_ready )
 ,// Memory response    
  .mem_rsp_valid(mem_rsp_valid)
 ,.mem_rsp_data (mem_rsp_data )
 ,.mem_rsp_tag  (mem_rsp_tag  )
 ,.mem_rsp_ready(mem_rsp_ready)
 ,// DCR write request
  .dcr_wr_valid(dcr_wr_valid)
 ,.dcr_wr_addr (dcr_wr_addr )
 ,.dcr_wr_data (dcr_wr_data )
 ,// Status
  .busy(vx_busy)
 ,// maxhpc
  .sim_ebreak  (sim_ebreak  )
 ,.sim_wb_value(sim_wb_value)
 );
/**/

/* DDR3 */
 wire rcv_axi4_req;
 reg  rcv_axi4_gnt;
 //
 wire rsp_axi4_req;
 reg  rsp_axi4_gnt;
 //
 wire vx_axi4_req;
 reg  vx_axi4_gnt;

 wire       axi4_awvalid;
  reg rcv_axi4_awvalid;
  reg vx_axi4_awvalid;
  assign axi4_awvalid = rcv_axi4_awvalid || vx_axi4_awvalid;
 wire[31:0] axi4_awaddr;
  reg[31:0] rcv_axi4_awaddr;
  reg[31:0] vx_axi4_awaddr;
  assign axi4_awaddr = (rcv_axi4_awvalid)? rcv_axi4_awaddr
                                         : vx_axi4_awaddr;
 wire [7:0] axi4_awlen;
  wire[7:0] rcv_axi4_awlen = 8'h00;
  wire[7:0] vx_axi4_awlen = (`VX_MEM_DATA_WIDTH/32)-1;
  assign axi4_awlen = (rcv_axi4_awvalid)? rcv_axi4_awlen
                                        : vx_axi4_awlen;
 wire       axi4_awready;
 //
 wire       axi4_wvalid;
  reg rcv_axi4_wvalid;
  reg vx_axi4_wvalid;
  assign axi4_wvalid = rcv_axi4_wvalid || vx_axi4_wvalid;
 wire[31:0] axi4_wdata;
  reg                  [31:0] rcv_axi4_wdata;
  reg[`VX_MEM_DATA_WIDTH-1:0] vx_axi4_wdata;
  assign axi4_wdata = (rcv_axi4_wvalid)? rcv_axi4_wdata
                                       : vx_axi4_wdata[31:0];
 wire [3:0] axi4_wstrb;
  reg                     [3:0] rcv_axi4_wstrb;
  reg[`VX_MEM_BYTEEN_WIDTH-1:0] vx_axi4_wstrb;
  assign axi4_wstrb = (rcv_axi4_wvalid)? rcv_axi4_wstrb
                                       : vx_axi4_wstrb[3:0];
 wire       axi4_wlast;
  wire rcv_axi4_wlast = 1'b1;
  wire vx_axi4_wlast;
  assign axi4_wlast = (rcv_axi4_wvalid)? rcv_axi4_wlast
                                       : vx_axi4_wlast;
 wire       axi4_wready;
 //
 wire       axi4_arvalid;
  wire rsp_axi4_arvalid;
  reg  vx_axi4_arvalid;
  assign axi4_arvalid = rsp_axi4_arvalid || vx_axi4_arvalid;
 wire[31:0] axi4_araddr;
  reg[31:0] rsp_axi4_araddr;
  reg[31:0] vx_axi4_araddr;
  assign axi4_araddr = (rsp_axi4_arvalid)? rsp_axi4_araddr
                                         : vx_axi4_araddr;
 wire [7:0] axi4_arlen;
  wire[7:0] rsp_axi4_arlen = 8'h00;
  wire[7:0] vx_axi4_arlen = (`VX_MEM_DATA_WIDTH/32)-1;
  assign axi4_arlen = (rsp_axi4_arvalid)? rsp_axi4_arlen
                                        : vx_axi4_arlen;
 wire       axi4_arready;
 //
 wire[31:0] axi4_rdata;
 wire       axi4_rlast;
 wire       axi4_rvalid;
 ddr3_top #(
  .DDR_MHZ(25)
 ) ddr3(
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
 ,.axi4_rready(1'b1       )
 );

 reg axi4_busy;
 `ALWAYS(posedge sysclk, negedge rst_)
  if (!rst_) begin
   axi4_busy <= 1'b0;
   //
   rcv_axi4_gnt <= 1'b0;
   rsp_axi4_gnt <= 1'b0;
   vx_axi4_gnt  <= 1'b0;
  end
   else begin
    if (
     rcv_axi4_gnt
     ||
     rsp_axi4_gnt
     ||
     vx_axi4_gnt
    ) begin
     axi4_busy <= 1'b1;
    end
    if (
     axi4_wvalid && axi4_wready && axi4_wlast
     ||
     axi4_rvalid && axi4_rlast
    ) begin
     axi4_busy <= 1'b0;
    end
    //
    //
    vx_axi4_gnt  <= vx_axi4_gnt && !(mem_req_valid && mem_req_ready);
    rsp_axi4_gnt <= rsp_axi4_gnt && !rsp_axi4_req;
    rcv_axi4_gnt <= rcv_axi4_gnt && !rcv_axi4_req;
    if (!rcv_axi4_gnt
        &&
        !rsp_axi4_gnt
        &&
        !vx_axi4_gnt
    ) begin
     vx_axi4_gnt <= !axi4_busy
                    &&
                    !rcv_axi4_req
                    &&
                    !rsp_axi4_req
                    &&
                    vx_axi4_req;
     //
     rsp_axi4_gnt <= !axi4_busy
                     &&
                     !rcv_axi4_req
                     &&
                     rsp_axi4_req;
     //
     rcv_axi4_gnt <= !axi4_busy && rcv_axi4_req;
    end
   end
/**/

/* UART */
 wire[7:0] rx_byte;
 wire      rx_stb;
 //
 reg[7:0] tx_byte;
 reg      tx_req;
 wire     tx_idle;

 uart #(
  .CLK_HZ(25000000)
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
 /* mem_req_/mem_rsp_ */
  assign vx_axi4_req = mem_req_valid;
  assign mem_req_ready = vx_axi4_gnt;

  reg      vx_axi4_read;
  reg[5:0] vx_axi4_wCnt;
   assign vx_axi4_wlast = vx_axi4_wCnt[5];
  `ALWAYS(posedge sysclk, negedge rst_)
   if (!rst_) begin
    vx_axi4_awvalid <= 1'b0;
    vx_axi4_wvalid <= 1'b0;
    vx_axi4_arvalid <= 1'b0;
    //
    vx_axi4_read <= 1'b0;
    vx_axi4_wCnt <= -1;
    //
    mem_rsp_valid <= 1'b0;
   end
    else begin
     if (vx_axi4_awvalid && axi4_awready) begin
      vx_axi4_awvalid <= 1'b0;
     end
     if (vx_axi4_arvalid && axi4_arready) begin
      vx_axi4_arvalid <= 1'b0;
     end
     if (axi4_wvalid && axi4_wready) begin
      vx_axi4_wCnt <= vx_axi4_wCnt-1;
      //
      vx_axi4_wdata <= vx_axi4_wdata>>32;
      vx_axi4_wstrb <= vx_axi4_wstrb>>4;
      //
      if (vx_axi4_wlast) begin
       vx_axi4_wvalid <= 1'b0;
      end
     end
     if (mem_req_valid && mem_req_ready) begin
      vx_axi4_awvalid <= mem_req_rw;
      vx_axi4_awaddr <= mem_req_addr<<(32-`VX_MEM_ADDR_WIDTH);
      vx_axi4_wvalid <= mem_req_rw;
      vx_axi4_wdata <= mem_req_data;
      vx_axi4_wstrb <= mem_req_byteen;
      //
      vx_axi4_wCnt <= vx_axi4_awlen -1;
      //
      //
      vx_axi4_arvalid <= !mem_req_rw;
      vx_axi4_araddr <= mem_req_addr<<(32-`VX_MEM_ADDR_WIDTH);
      mem_rsp_tag <= mem_req_tag;
     end
     if (vx_axi4_arvalid || rsp_axi4_arvalid) begin
      vx_axi4_read <= vx_axi4_arvalid;
     end
     //
     //
     if (mem_rsp_ready) begin
      mem_rsp_valid <= 1'b0;
     end
     if (axi4_rvalid) begin
      mem_rsp_data[`VX_MEM_DATA_WIDTH-1-:32] <= axi4_rdata;
      mem_rsp_data[0+:`VX_MEM_DATA_WIDTH-32] <= mem_rsp_data[`VX_MEM_DATA_WIDTH-1-:`VX_MEM_DATA_WIDTH-32];
      //
      mem_rsp_valid <= vx_axi4_read && axi4_rlast;
     end
    end
  /**/
 /**/

 /* receive command */
  enum {RCV_CMD
       ,RCV_CMD_STB
       ,RCV_AXI4_WDATA
       ,RCV_AXI4_REQ
       ,RCV_AXI4_WRITE
       ,RCV_DCR_WRITE
       ,RCVST_SIZE} RCVST_ENUM;
  reg[RCVST_SIZE-1:0] rcv_state;
   assign rcv_axi4_req = rcv_state[RCV_AXI4_REQ];
  struct packed{
   reg   [31:0] sizdat;
   reg   [31:0] addr;
   reg[4*8-1:0] opcode;
  } rcv_cmd;
   assign dcr_wr_valid = rcv_state[RCV_DCR_WRITE];
   assign dcr_wr_addr = rcv_cmd.addr;
   assign dcr_wr_data = rcv_cmd.sizdat;
   //
    wire[31:0] rcv_wtap_dat = rcv_cmd.sizdat;
    reg  [3:0] rcv_wtap_stb;
  reg[6:0] rcv_cmdCnt;
  //
  reg[32:0] rcv_wrCnt;
  reg [1:0] rcv_wrPtr;
  `ALWAYS(posedge sysclk, negedge rst_)
   if (!rst_) begin
    rcv_axi4_awvalid <= 1'b0;
    rcv_axi4_wvalid  <= 1'b0;
    //
    //
    vx_rst <= 1'b1;
    //
    //
    rcv_cmdCnt <= ($bits(rcv_cmd)+7)/8 -2;
    rcv_state <= (1<<RCV_CMD);
   end
    else begin
     if (axi4_awready) begin
      rcv_axi4_awvalid <= 1'b0;
      if (rcv_axi4_awvalid) begin
       rcv_axi4_awaddr <= rcv_axi4_awaddr+4;
      end
     end
     if (axi4_wready) begin
      rcv_axi4_wvalid <= 1'b0;
      rcv_axi4_wstrb <= 4'b1111;
     end
     //
     rcv_wtap_stb <= 0;
     //
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
      //
      (1<<RCV_CMD_STB): begin
       rcv_wrCnt <= rcv_cmd.sizdat -2;
       rcv_wrPtr <= rcv_cmd.addr[1:0];
       //
       rcv_axi4_awaddr  <= rcv_cmd.addr[31:2]<<2;
       rcv_axi4_wstrb  <= 4'b1111<<rcv_cmd.addr[1:0];
       //
       rcv_cmdCnt <= ($bits(rcv_cmd)+7)/8 -2;
       rcv_state <= (1<<RCV_CMD);
       case (rcv_cmd.opcode)
        "ddrW": begin
         rcv_state <= (1<<RCV_AXI4_WDATA);
        end
        //
        "dcrW": begin
         rcv_state <= (1<<RCV_DCR_WRITE);
        end
        //
        "rstW": begin
         vx_rst <= rcv_cmd.sizdat[0];
        end
        //
        "tapW": begin
         rcv_wtap_stb <= 1<<rcv_cmd.addr[1:0];
        end
        //
        default: begin
        end
       endcase
      end
      //
      (1<<RCV_AXI4_WDATA): begin
       if (rx_stb) begin
        rcv_wrCnt <= rcv_wrCnt-1;
        rcv_wrPtr <= rcv_wrPtr+1;
        case (rcv_wrPtr)
         2'h0: begin
          rcv_axi4_wdata[0+:8] <= rx_byte;
         end
         2'h1: begin
          rcv_axi4_wdata[8+:8] <= rx_byte;
         end
         2'h2: begin
          rcv_axi4_wdata[16+:8] <= rx_byte;
         end
         2'h3: begin
          rcv_axi4_wdata[24+:8] <= rx_byte;
         end
        endcase
        if ((rcv_wrPtr==2'h3) || rcv_wrCnt[32]) begin
         rcv_state <= (1<<RCV_AXI4_REQ);
        end
       end
      end
      //
      (1<<RCV_AXI4_REQ): begin
       if (rcv_axi4_gnt) begin
        rcv_state <= (1<<RCV_AXI4_WRITE);
       end
      end
      //
      (1<<RCV_AXI4_WRITE): begin
       rcv_axi4_awvalid <= 1'b1;
       //
       rcv_axi4_wvalid <= 1'b1;
       //
       rcv_state <= (1<<RCV_AXI4_WDATA);
       rcv_cmdCnt <= ($bits(rcv_cmd)+7)/8 -2;
       if (rcv_wrCnt[32] && !rcv_wrCnt[0]) begin
        rcv_axi4_wstrb  <= rcv_axi4_wstrb & (4'b1111>>(2'h3 & ~(rcv_cmd.addr[1:0]+rcv_cmd.sizdat[1:0]-1)));
        //
        rcv_state <= (1<<RCV_CMD);
       end
      end
      //
      (1<<RCV_DCR_WRITE): begin
       rcv_cmdCnt <= ($bits(rcv_cmd)+7)/8 -2;
       rcv_state <= (1<<RCV_CMD);
      end
     endcase
    end
 /**/
 /* respond */
  enum {RSP_IDLE
       ,RSP_AXI4_REQ
       ,RSP_AXI4_ARVALID
       ,RSP_AXI4_RVALID
       ,RSP_AXI4_RDATA
       ,RSP_TAP_READ
       ,RSPST_SIZE} RSPST_ENUM;
  reg[RSPST_SIZE-1:0] rsp_state;
   assign rsp_axi4_req = rsp_state[RSP_AXI4_REQ];
   assign rsp_axi4_arvalid = rsp_state[RSP_AXI4_ARVALID];
  reg[31:0] rsp_word;
  reg[32:0] rsp_byteCnt;
  reg [1:0] rsp_axi4rdPtr;
  //
  logic[31:0] rsp_rtaps[0:3];
  reg   [3:0] rsp_rtap_stb;
  `ALWAYS(posedge sysclk, negedge rst_)
   if (!rst_) begin
    tx_req <= 1'b0;
    //
    rsp_state <= (1<<RSP_IDLE);
   end
    else begin
     if (!tx_idle) begin
      tx_req <= 1'b0;
     end
     //
     rsp_rtap_stb <= 0;
     //
     unique case (rsp_state)
      default: begin // (1<<RSP_IDLE)
       if (rcv_state[RCV_CMD_STB]) begin
        case (rcv_cmd.opcode)
         "ddrR": begin
          rsp_axi4_araddr <= rcv_cmd.addr[31:2]<<2;
          //
          rsp_byteCnt <= rcv_cmd.sizdat -2;
          rsp_axi4rdPtr <= rcv_cmd.addr[1:0];
          //
          rsp_state <= (1<<RSP_AXI4_REQ);
         end
         //
         "tapR": begin
          rsp_byteCnt <= ($bits(rsp_word)+7)/8 -2;
          rsp_word <= rsp_rtaps[rcv_cmd.addr[1:0]];
          rsp_rtap_stb <= 1<<rcv_cmd.addr[1:0];
          //
          rsp_state <= (1<<RSP_TAP_READ);
         end
         //
         default: begin
         end
        endcase
       end
      end
      //
      (1<<RSP_AXI4_REQ): begin
       if (rsp_axi4_gnt) begin
        rsp_state <= (1<<RSP_AXI4_ARVALID);
       end
      end
      //
      (1<<RSP_AXI4_ARVALID): begin
       if (axi4_arready) begin
        rsp_axi4_araddr <= rsp_axi4_araddr+4;
        //
        rsp_state <= (1<<RSP_AXI4_RVALID);
       end
      end
      //
      (1<<RSP_AXI4_RVALID): begin
       if (axi4_rvalid) begin
        rsp_word <= axi4_rdata>>(8*rsp_axi4rdPtr);
        //
        rsp_state <= (1<<RSP_AXI4_RDATA);
       end
      end
      //
      (1<<RSP_AXI4_RDATA): begin
       if (tx_idle && !tx_req) begin
        rsp_byteCnt <= rsp_byteCnt-1;
        rsp_axi4rdPtr <= rsp_axi4rdPtr+1;
        //
        tx_byte <= rsp_word[0+:8];
        rsp_word <= rsp_word>>8;
        tx_req <= 1'b1;
        //
        if (rsp_axi4rdPtr==2'h3) begin
         rsp_state <= (1<<RSP_AXI4_REQ);
        end
        if (rsp_byteCnt[32]) begin
         rsp_state <= (1<<RSP_IDLE);
        end
       end
      end
      //
      (1<<RSP_TAP_READ): begin
       if (tx_idle && !tx_req) begin
        rsp_byteCnt <= rsp_byteCnt-1;
        //
        tx_byte <= rsp_word[0+:8];
        rsp_word <= rsp_word>>8;
        tx_req <= 1'b1;
        //
        if (rsp_byteCnt[32]) begin
         rsp_state <= (1<<RSP_IDLE);
        end
       end
      end
     endcase
    end
 /**/
/**/

/* LEDs */
// assign {led_rgb3,led_rgb2,led_rgb1,led_rgb0} = {{3{1'b1}},{3{1'b1}},{3{1'b1}},{3{1'b1}}};
 assign {led_rgb3,led_rgb2,led_rgb1,led_rgb0} = {{3{1'b1}},{3{1'b1}},{3{vx_rst}},{3{!vx_busy}}};
/**/

/* taps */
 reg[10:0] stap_wadr;
 reg[31:0] stap_wdat[0:1];
 //
 reg[10:0] stap_radr;
 maxhpc_dpram #(
  .ADDR_WD(10)
 ,.DATA_WD(32)
 ) stap_ram(
 /* Port A */
  .a_clk (sysclk)
 ,.a_ce  (!stap_wadr[10])
 ,.a_we  (!stap_wadr[10])
 ,.a_addr(stap_wadr[9:0])
 ,.a_d   (stap_wdat[1])
 ,.a_q   ()
 /**/
 ,
 /* Port B */
  .b_clk (sysclk)
 ,.b_ce  (!stap_radr[10])
 ,.b_we  (1'b0)
 ,.b_addr(stap_radr[9:0])
 ,.b_d   ()
 ,.b_q   (rsp_rtaps[3])
 /**/
 );

 reg stap_run;
 reg stap_trig;
 reg[9:0] stap_trigAdr;
  assign rsp_rtaps[2] = stap_trigAdr;
 reg[4:0] tttCnt;
 `ALWAYS(posedge sysclk, negedge rst_)
  if (!rst_) begin
   stap_run <= 1'b1;
   //stap_wadr[10] <= 1'b1;
   stap_wadr <= 0;
   //
   stap_run <= 1'b1;
   stap_trig  <= 1'b0;
tttCnt <= 0;
  end
   else begin
    /* */
    //if (!stap_wadr[10]) begin
    // stap_wadr <= stap_wadr[9:0]+1;
    //end
    //if (stap_run && stap_trig) begin
    // stap_run <= 1'b0;
    // //
    // stap_wadr[10] <= 1'b0;
    //end
    if (!stap_wadr[10]) begin
     stap_wadr[9:0] <= stap_wadr[9:0]+1;
    end
    if (stap_run && stap_trig) begin
     stap_run <= 1'b0;
     //
     stap_trigAdr <= stap_wadr[9:0];
    end
    if (!stap_run) begin
     stap_wadr[10] <= (stap_wadr[9:0]-stap_trigAdr[9:0]+1)>>(10-1);
    end
    /**/
    //
    stap_trig  <= tttCnt[4];
tttCnt <= tttCnt+1;
if (!vx_axi4_awvalid) begin
 tttCnt <= 0;
end
    stap_wdat[0] <= {                             axi4_rlast,    axi4_rvalid
                    ,vx_axi4_arvalid, axi4_wlast, axi4_wready,   vx_axi4_wvalid
                    ,vx_axi4_awvalid, mem_req_rw, mem_req_ready, mem_req_valid
                    };
    stap_wdat[1] <= stap_wdat[0];
    if (rcv_wtap_stb[2]) begin
     stap_run <= 1'b1;
     stap_trig <= 1'b0;
     stap_wadr[10] <= 1'b0;
    end
   end

 `ALWAYS(posedge sysclk, negedge rst_)
  if (!rst_) begin
   stap_radr <= 0;
  end
   else begin
    if (rsp_rtap_stb[3]) begin
     //if (!stap_radr[10]) begin
     // stap_radr <= stap_radr[9:0]+1;
     //end
     stap_radr[9:0] <= stap_radr[9:0]+1;
    end
    if (rcv_wtap_stb[3]) begin
     stap_radr <= rcv_wtap_dat;
    end
   end
 //
 //
 `ALWAYS(posedge sysclk, negedge rst_)
  if (!rst_) begin
   rsp_rtaps[0] <= 32'h00000000;
  end
   else begin
    rsp_rtaps[0] <= {stap_run, axi4_busy, vx_axi4_arvalid, vx_axi4_wvalid, vx_axi4_awvalid};
    rsp_rtaps[0][23:16] <= rsp_rtaps[0][23:16]
                          +(mem_req_valid && mem_req_ready && mem_req_rw)
                          -(vx_axi4_wvalid && axi4_wready && axi4_wlast);
    rsp_rtaps[0][31:24] <= rsp_rtaps[0][31:24]
                          +(mem_req_valid && mem_req_ready && !mem_req_rw)
                          -(vx_axi4_read && axi4_rvalid && axi4_rlast);
    if (vx_rst) begin
     rsp_rtaps[0][31:16] <= 0;
    end
   end
/**/

endmodule
`undef LENGTH
`undef ALWAYS
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
