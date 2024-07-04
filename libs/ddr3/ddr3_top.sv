// maxhpc: Maxim Vorontsov

`include "core_ddr3_controller/examples/ecpix_ecp5/ecp5pll.sv"
`include "core_ddr3_controller/src_v/phy/ecp5/ddr3_dfi_phy.v"
`include "core_ddr3_controller/src_v/ddr3_axi_retime.v"
`include "core_ddr3_controller/src_v/ddr3_axi_pmem.v"
`include "core_ddr3_controller/src_v/ddr3_dfi_seq.v"
`include "core_ddr3_controller/src_v/ddr3_core.v"
`include "core_ddr3_controller/src_v/ddr3_axi.v"

module ddr3_top
(
/* */
 input rst
,input clk
,
 input ddrclk
/**/
,
/* DDR3 */
 output[14:0] ddr3_a
,output[ 2:0] ddr3_ba
,output       ddr3_ras_n
,output       ddr3_cas_n
,output       ddr3_we_n
,output[ 1:0] ddr3_dm
,inout [15:0] ddr3_dq
,inout [ 1:0] ddr3_dqs_p
,output       ddr3_clk_p
,output       ddr3_cke
,output       ddr3_odt
/**/
,
/* AXI4 */
 input [ 3:0] axi4_awid
,input [31:0] axi4_awaddr
,input [ 7:0] axi4_awlen
,input [ 1:0] axi4_awburst
,input        axi4_awvalid
,output       axi4_awready
,
 input [31:0] axi4_wdata
,input [ 3:0] axi4_wstrb
,input        axi4_wlast
,input        axi4_wvalid
,output       axi4_wready
,
 output[ 3:0] axi4_bid
,output[ 1:0] axi4_bresp
,output       axi4_bvalid
,input        axi4_bready
,
 input [ 3:0] axi4_arid
,input [31:0] axi4_araddr
,input [ 7:0] axi4_arlen
,input [ 1:0] axi4_arburst
,input        axi4_arvalid
,output       axi4_arready
,
 output[ 3:0] axi4_rid
,output[31:0] axi4_rdata
,output[ 1:0] axi4_rresp
,output       axi4_rlast
,output       axi4_rvalid
,input        axi4_rready
/**/
);
/* DDR Core + PHY */
wire[14:0] dfi_address_w;
wire[ 2:0] dfi_bank_w;
wire       dfi_cas_n_w;
wire       dfi_cke_w;
wire       dfi_cs_n_w;
wire       dfi_odt_w;
wire       dfi_ras_n_w;
wire       dfi_reset_n_w;
wire       dfi_we_n_w;
wire[31:0] dfi_wrdata_w;
wire       dfi_wrdata_en_w;
wire[ 3:0] dfi_wrdata_mask_w;
wire       dfi_rddata_en_w;
wire[31:0] dfi_rddata_w;
wire       dfi_rddata_valid_w;
wire[ 1:0] dfi_rddata_dnv_w;
ddr3_dfi_phy
u_phy
(
     .clk_i(clk)
    ,.rst_i(rst)

    ,.clk_ddr_i(ddrclk)

    ,.dfi_address_i(dfi_address_w)
    ,.dfi_bank_i(dfi_bank_w)
    ,.dfi_cas_n_i(dfi_cas_n_w)
    ,.dfi_cke_i(dfi_cke_w)
    ,.dfi_cs_n_i(dfi_cs_n_w)
    ,.dfi_odt_i(dfi_odt_w)
    ,.dfi_ras_n_i(dfi_ras_n_w)
    ,.dfi_reset_n_i(dfi_reset_n_w)
    ,.dfi_we_n_i(dfi_we_n_w)
    ,.dfi_wrdata_i(dfi_wrdata_w)
    ,.dfi_wrdata_en_i(dfi_wrdata_en_w)
    ,.dfi_wrdata_mask_i(dfi_wrdata_mask_w)
    ,.dfi_rddata_en_i(dfi_rddata_en_w)
    ,.dfi_rddata_o(dfi_rddata_w)
    ,.dfi_rddata_valid_o(dfi_rddata_valid_w)
    ,.dfi_rddata_dnv_o(dfi_rddata_dnv_w)
    
    ,.ddr3_ck_p_o(ddr3_clk_p)
    ,.ddr3_cke_o(ddr3_cke)
    ,.ddr3_reset_n_o()
    ,.ddr3_ras_n_o(ddr3_ras_n)
    ,.ddr3_cas_n_o(ddr3_cas_n)
    ,.ddr3_we_n_o(ddr3_we_n)
    ,.ddr3_cs_n_o()
    ,.ddr3_ba_o(ddr3_ba)
    ,.ddr3_addr_o(ddr3_a)
    ,.ddr3_odt_o(ddr3_odt)
    ,.ddr3_dm_o(ddr3_dm)
    ,.ddr3_dqs_p_io(ddr3_dqs_p)
    ,.ddr3_dq_io(ddr3_dq)
);

ddr3_axi
#(
     .DDR_WRITE_LATENCY(3)
    ,.DDR_READ_LATENCY(3)
    ,.DDR_MHZ(50)
)
u_ddr
(
    // Inputs
     .clk_i(clk)
    ,.rst_i(rst)
    ,.inport_awvalid_i(axi4_awvalid)
    ,.inport_awaddr_i(axi4_awaddr)
    ,.inport_awid_i(axi4_awid)
    ,.inport_awlen_i(axi4_awlen)
    ,.inport_awburst_i(axi4_awburst)
    ,.inport_wvalid_i(axi4_wvalid)
    ,.inport_wdata_i(axi4_wdata)
    ,.inport_wstrb_i(axi4_wstrb)
    ,.inport_wlast_i(axi4_wlast)
    ,.inport_bready_i(axi4_bready)
    ,.inport_arvalid_i(axi4_arvalid)
    ,.inport_araddr_i(axi4_araddr)
    ,.inport_arid_i(axi4_arid)
    ,.inport_arlen_i(axi4_arlen)
    ,.inport_arburst_i(axi4_arburst)
    ,.inport_rready_i(axi4_rready)
    ,.dfi_rddata_i(dfi_rddata_w)
    ,.dfi_rddata_valid_i(dfi_rddata_valid_w)
    ,.dfi_rddata_dnv_i(dfi_rddata_dnv_w)

    // Outputs
    ,.inport_awready_o(axi4_awready)
    ,.inport_wready_o(axi4_wready)
    ,.inport_bvalid_o(axi4_bvalid)
    ,.inport_bresp_o(axi4_bresp)
    ,.inport_bid_o(axi4_bid)
    ,.inport_arready_o(axi4_arready)
    ,.inport_rvalid_o(axi4_rvalid)
    ,.inport_rdata_o(axi4_rdata)
    ,.inport_rresp_o(axi4_rresp)
    ,.inport_rid_o(axi4_rid)
    ,.inport_rlast_o(axi4_rlast)
    ,.dfi_address_o(dfi_address_w)
    ,.dfi_bank_o(dfi_bank_w)
    ,.dfi_cas_n_o(dfi_cas_n_w)
    ,.dfi_cke_o(dfi_cke_w)
    ,.dfi_cs_n_o(dfi_cs_n_w)
    ,.dfi_odt_o(dfi_odt_w)
    ,.dfi_ras_n_o(dfi_ras_n_w)
    ,.dfi_reset_n_o(dfi_reset_n_w)
    ,.dfi_we_n_o(dfi_we_n_w)
    ,.dfi_wrdata_o(dfi_wrdata_w)
    ,.dfi_wrdata_en_o(dfi_wrdata_en_w)
    ,.dfi_wrdata_mask_o(dfi_wrdata_mask_w)
    ,.dfi_rddata_en_o(dfi_rddata_en_w)
);
/**/

endmodule
