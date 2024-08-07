// maxhpc: Maxim Vorontsov

module leds(
/* Clock */
 input fpga_sysclk,
 input SDCrd_26MHz,
 input vcxo_fpga,
 input clk_1_80MHz//TODO ,
 //TODO input refclk_100MHz_p,
 //TODO input refclk_100MHz_n
/**/
,
/* Reset */
 input rst_ulpi_,
 input hdmi_rst_,
 input phy_rst_,
 input rst_ft2232_,
 input rst_fpga_,
 inout rst_sys_,
 input gsrn
/**/
,
/* RGB LED */
 output[2:0] led_rgb0,
 output[2:0] led_rgb1,
 output[2:0] led_rgb2,
 output[2:0] led_rgb3
/**/
,
/* FT2232 */
 output uart_txd,
 input  uart_rxd
/**/
,
/* MicroSD */
 output SDCrd_sel,
 output SDCrd_clk,
 input  SDCrd_clkfb,
 output SDCrd_dircmd,
 inout  SDCrd_cmd,
 inout  SDCrd_d01_p,
 inout  SDCrd_d01_n,
 inout  SDCrd_d2,
 inout  SDCrd_d3,
 output SDCrd_dir0,
 output SDCrd_dir1_3,
 input  SDCrd_cd//TODO ,
 //TODO inout  GTP4_tx_p,
 //TODO inout  GTP4_tx_n,
 //TODO inout  GTP4_rx_p,
 //TODO inout  GTP4_rx_n
/**/
//TODO ,
/* SATA */
 //TODO inout GTP3_tx_p,
 //TODO inout GTP3_tx_n,
 //TODO inout GTP3_rx_p,
 //TODO inout GTP3_rx_n
/**/
,
/* PMOD Conn */
 inout[7:0] PMOD0
 ,
 inout[7:0] PMOD1
 ,
 inout[7:0] PMOD2
 ,
 inout[7:0] PMOD3
 ,
 inout PMOD4_0_p,
 inout PMOD4_0_n,
 inout PMOD4_1_p,
 inout PMOD4_1_n,
 inout PMOD4_2_p,
 inout PMOD4_2_n,
 inout PMOD4_3_p,
 inout PMOD4_3_n
 ,
 inout[7:0] PMOD5
 ,
 inout[7:0] PMOD6
 ,
 inout[7:0] PMOD7
/**/
,
/* DDR3 */
 output       ddr_ck_p,
 output       ddr_ck_n,
 output       ddr_cke,
 output[ 2:0] ddr_ba,
 output[14:0] ddr_a,
 input [15:0] ddr_d,
 output       ddr_we_,
 output       ddr_cas_,
 output       ddr_ras_,
 inout        ddr_ldqs_p,
 inout        ddr_ldqs_n,
 inout        ddr_udqs_p,
 inout        ddr_udqs_n,
 output       ddr_ldm,
 output       ddr_udm,
 output       ddr_odt
/**/
,
/* ULPI */
 inout[7:0] ulpi_data,
 output     ulpi_stp,
 input      ulpi_nxt,
 input      ulpi_dir,
 input      ulpi_clkout
/**/
//TODO ,
/* SS MUX */
 //TODO inout gtp1_tx_p,
 //TODO inout gtp1_tx_n,
 //TODO inout gtp1_rx_p,
 //TODO inout gtp1_rx_n,
 //TODO inout gtp2_tx_p,
 //TODO inout gtp2_tx_n,
 //TODO inout gtp2_rx_p,
 //TODO inout gtp2_rx_n,
 //TODO inout fpga_auxclk_p,
 //TODO inout fpga_auxclk_n
/**/
,
/* HDMI */
 output hdmi_scl,
 inout  hdmi_sda,
 input  hdmi_int
 ,
 output       hdmi_hsync,
 output       hdmi_vsync,
 output       hdmi_de,
 output[11:0] hdmi_r,
 output[11:0] hdmi_g,
 output[11:0] hdmi_b,
 output       hdmi_pclk
 ,
 output      AudioMCLK,
 output[3:0] i2s,
 output      i2s_ws,
 output      i2s_sck
/**/
,
/* Ethernet */
 output[3:0] phy_txd,
 output      phy_txen,
 output      phy_gtxclk,
 inout [3:0] phy_rxd
 ,
 input phy_int_
 ,
 output phy_mdc,
 input  phy_mdio
/**/
);
/* Reset */
 assign rst_sys_ = 1'bz;
/**/

reg[32:0] pre;
 wire ce = pre[32];
always @(posedge fpga_sysclk, negedge rst_fpga_)
 if (!rst_fpga_) begin
  pre <= -1;
 end
  else begin
   if (ce) begin
    pre <= (100_000_000/*Hz*/)/(30/*Hz*/) -2;
   end
    else begin
     pre <= pre-1;
    end
  end

reg[11:0] cnt;
 assign {led_rgb3,led_rgb2,led_rgb1,led_rgb0} = ~cnt;
always @(posedge fpga_sysclk, negedge rst_fpga_)
 if (!rst_fpga_) begin
  cnt <= 0;
 end
  else begin
   if (ce) begin
    cnt <= cnt +1;
   end
  end

endmodule
