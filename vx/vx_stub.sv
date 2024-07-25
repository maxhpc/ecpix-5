// maxhpc: Maxim Vorontsov

`ifdef VX_STUB

`include "VX_define.vh"

module Vortex import VX_gpu_pkg::*; (
 // Clock
 input clk
,input reset
,// Memory request
 output logic                      mem_req_valid
,output                            mem_req_rw
,output[`VX_MEM_BYTEEN_WIDTH-1:0]  mem_req_byteen
,output[  `VX_MEM_ADDR_WIDTH-1:0]  mem_req_addr
,output[  `VX_MEM_DATA_WIDTH-1:0]  mem_req_data
,output[   `VX_MEM_TAG_WIDTH-1:0]  mem_req_tag
,input                             mem_req_ready
,// Memory response    
 input                         mem_rsp_valid
,input[`VX_MEM_DATA_WIDTH-1:0] mem_rsp_data
,input[ `VX_MEM_TAG_WIDTH-1:0] mem_rsp_tag
,output                        mem_rsp_ready
,// DCR write request
 input                         dcr_wr_valid
,input[`VX_DCR_ADDR_WIDTH-1:0] dcr_wr_addr
,input[`VX_DCR_DATA_WIDTH-1:0] dcr_wr_data
,// Status
 output busy
,// maxhpc
 output                           sim_ebreak
,output[`NUM_REGS-1:0][`XLEN-1:0] sim_wb_value
);

`ifndef VERILATOR
assign mem_req_valid = 1'b0;
assign mem_rsp_ready = 1'b0;

`else
assign mem_rsp_ready = mem_rsp_valid;

reg[32:0] mem_reqCnt = 65000;
// assign mem_req_valid = mem_reqCnt[32];
 assign mem_req_addr = 'h100;
 assign mem_req_rw = 1'b0;
 assign mem_req_byteen = {`VX_MEM_BYTEEN_WIDTH{1'b1}};
always @(posedge clk) begin
 mem_reqCnt <= mem_reqCnt[31:0]-1;
 if (mem_reqCnt[32]) begin
  mem_req_valid <= 1'b1;
 end
end

`endif

endmodule

`endif
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
