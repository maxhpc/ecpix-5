// maxhpc: Maxim Vorontsov

module uart #(parameter
 CLK_HZ = 100000000
,BAUD   = 1000000
)(
 `include "../ecpix5_ports.hv"
);
/* Reset */
 assign rst_sys_ = 1'bz;
/**/

/* UART */
 /* rxd filter */
  reg filt_rxd;

  localparam FILT_WD = $clog2((CLK_HZ/BAUD)/4);

  reg Ruart_rxd;
  always @(posedge fpga_sysclk)
   if (!rst_fpga_) begin
    Ruart_rxd <= uart_rxd;
   end
    else begin
     Ruart_rxd <= uart_rxd;
    end

  reg[FILT_WD:0] rxd_filtCnt;
  always @(posedge fpga_sysclk)
   if (!rst_fpga_) begin
    filt_rxd <= Ruart_rxd;
    rxd_filtCnt <= 0;
   end
    else begin
     rxd_filtCnt[FILT_WD] <= 1'b0;
     rxd_filtCnt <= rxd_filtCnt+1;
     if (filt_rxd == Ruart_rxd) begin
      rxd_filtCnt <= 0;
     end
     if (rxd_filtCnt[FILT_WD]) begin
      filt_rxd <= Ruart_rxd;
     end
    end
 /**/
 /* RX */
  reg[7:0] rx_byte;
  reg      rx_stb;

  reg Rfilt_rxd;
  always @(posedge fpga_sysclk)
   if (!rst_fpga_) begin
    Rfilt_rxd <= filt_rxd;
   end
    else begin
     Rfilt_rxd <= filt_rxd;
    end

  reg[32:0] rx_smplCnt;
  always @(posedge fpga_sysclk, negedge rst_fpga_)
   if (!rst_fpga_) begin
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
  always @(posedge fpga_sysclk, negedge rst_fpga_)
   if (!rst_fpga_) begin
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
 assign {led_rgb3,led_rgb2,led_rgb1,led_rgb0} = rx_byte;
 /* TX */
  reg[7:0] tx_byte;
  reg      tx_req;
  wire     tx_idle;

  reg[32:0] tx_smplCnt;
  always @(posedge fpga_sysclk, negedge rst_fpga_)
   if (!rst_fpga_) begin
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
  reg                uart_txd;
  always @(posedge fpga_sysclk, negedge rst_fpga_)
   if (!rst_fpga_) begin
    uart_txd <= 1'b1;
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
        uart_txd <= 1'b0;
        //
        tx_bitCnt <= 8 -2;
        tx_state <= (1<<TX_DATA);
       end
      end
      (1<<TX_DATA): begin
       if (tx_smplCnt[32]) begin
        uart_txd <= tx_data[0];
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
        uart_txd <= 1'b1;
        tx_state <= (1<<TX_IDLE);
       end
      end
     endcase
    end
 /**/
 /* loopback */
  always @(posedge fpga_sysclk, negedge rst_fpga_)
   if (!rst_fpga_) begin
    tx_req <= 1'b0;
   end
    else begin
     if (!tx_idle) begin
      tx_req <= 1'b0;
     end
     if (rx_stb) begin
      tx_byte <= rx_byte+1;
      tx_req <= 1'b1;
     end
    end
 /**/
/**/

endmodule
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
