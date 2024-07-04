// maxhpc: Maxim Vorontsov

`define ALWAYS(CLOCK,RESET) \
 `ifndef NOASYNC \
  always @(CLOCK, RESET) \
 `else \
  always @(CLOCK) \
 `endif

module uart #(parameter
 CLK_HZ = 100000000
,BAUD   = 1000000
)(
 input rst_
,input clk
,
 input       rxd
,output reg  txd
,
 output reg[7:0] rx_byte
,output reg      rx_stb
,
 input  [7:0] tx_byte
,input        tx_req
,output       tx_idle
);
/* rxd filter */
 reg filt_rxd;

 localparam FILT_WD = $clog2((CLK_HZ/BAUD)/4);

 reg Rrxd;
 `ALWAYS(posedge clk, negedge rst_)
  if (!rst_) begin
   Rrxd <= rxd;
  end
   else begin
    Rrxd <= rxd;
   end

 reg[FILT_WD:0] rxd_filtCnt;
 `ALWAYS(posedge clk, negedge rst_)
  if (!rst_) begin
   filt_rxd <= Rrxd;
   rxd_filtCnt <= 0;
  end
   else begin
    rxd_filtCnt[FILT_WD] <= 1'b0;
    rxd_filtCnt <= rxd_filtCnt+1;
    if (filt_rxd == Rrxd) begin
     rxd_filtCnt <= 0;
    end
    if (rxd_filtCnt[FILT_WD]) begin
     filt_rxd <= Rrxd;
    end
   end
/**/
/* RX */
 reg Rfilt_rxd;
 `ALWAYS(posedge clk, negedge rst_)
  if (!rst_) begin
   Rfilt_rxd <= filt_rxd;
  end
   else begin
    Rfilt_rxd <= filt_rxd;
   end

 reg[32:0] rx_smplCnt;
 `ALWAYS(posedge clk, negedge rst_)
  if (!rst_) begin
   rx_smplCnt <= 33'h0;
  end
   else begin
    rx_smplCnt <= rx_smplCnt-1;
    if (rx_smplCnt[32]) begin
     rx_smplCnt <= (CLK_HZ/BAUD) -2;
    end
    if (Rfilt_rxd != filt_rxd) begin
     rx_smplCnt <= (CLK_HZ/BAUD)/2 -2;
    end
   end

 enum {RX_IDLE
      ,RX_DATA
      ,RX_STOP
      ,RXST_SIZE} RX_STATES_ENUM;
 reg[RXST_SIZE-1:0] rx_state;
 reg          [4:0] rx_bitCnt;
 `ALWAYS(posedge clk, negedge rst_)
  if (!rst_) begin
   rx_stb <= 1'b0;
   rx_state <= (1<<RX_IDLE);
  end
   else begin
    rx_stb <= 1'b0;
    if (rx_smplCnt[32]) begin
     unique case (rx_state)
      default: begin // (1<<RX_IDLE)
       if (!Rfilt_rxd) begin // start
        rx_bitCnt <= 8 -2;
        rx_state <= (1<<RX_DATA);
       end
      end
      (1<<RX_DATA): begin
       rx_byte <= {Rfilt_rxd, rx_byte[7:1]};
       //
       rx_bitCnt <= rx_bitCnt-1;
       if (rx_bitCnt[4]) begin
        rx_state <= (1<<RX_STOP);
       end
      end
      (1<<RX_STOP): begin
       if (Rfilt_rxd) begin // stop
        rx_stb <= 1'b1;
       end
       rx_state <= (1<<RX_IDLE);
      end
     endcase
    end
   end
/**/
/* TX */
 reg[32:0] tx_smplCnt;
 `ALWAYS(posedge clk, negedge rst_)
  if (!rst_) begin
   tx_smplCnt <= 33'h0;
  end
   else begin
    tx_smplCnt <= tx_smplCnt-1;
    if (tx_smplCnt[32]) begin
     tx_smplCnt <= (CLK_HZ/BAUD) -2;
    end
   end

 enum {TX_IDLE
      ,TX_START
      ,TX_DATA
      ,TX_STOP
      ,TXST_SIZE} TX_STATES_ENUM;
 reg[TXST_SIZE-1:0] tx_state;
  assign tx_idle = tx_state[TX_IDLE];
 reg          [4:0] tx_bitCnt;
 reg          [7:0] tx_data;
 `ALWAYS(posedge clk, negedge rst_)
  if (!rst_) begin
   txd <= 1'b1;
   //
   tx_state <= (1<<TX_IDLE);
  end
   else begin
    unique case (tx_state)
     default: begin // (1<<TX_IDLE)
      if (tx_req) begin
       tx_data <= tx_byte;
       tx_state <= (1<<TX_START);
      end
     end
     (1<<TX_START): begin
      if (tx_smplCnt[32]) begin
       txd <= 1'b0;
       //
       tx_bitCnt <= 8 -2;
       tx_state <= (1<<TX_DATA);
      end
     end
     (1<<TX_DATA): begin
      if (tx_smplCnt[32]) begin
       txd <= tx_data[0];
       tx_data <= tx_data>>1;
       //
       tx_bitCnt <= tx_bitCnt-1;
       if (tx_bitCnt[4]) begin
        tx_state <= (1<<TX_STOP);
       end
      end
     end
     (1<<TX_STOP): begin
      if (tx_smplCnt[32]) begin
       txd <= 1'b1;
       tx_state <= (1<<TX_IDLE);
      end
     end
    endcase
   end
/**/

endmodule
`undef ALWAYS
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
