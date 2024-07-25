// maxhpc: Maxim Vorontsov

`ifdef VX_STUB

`include "VX_define.vh"

module Vortex import VX_gpu_pkg::*; (
 // Clock
 input clk
,input reset
,// Memory request
 output logic                      mem_req_valid
,output logic                      mem_req_rw
,output[`VX_MEM_BYTEEN_WIDTH-1:0]  mem_req_byteen
,output[  `VX_MEM_ADDR_WIDTH-1:0]  mem_req_addr
,output[  `VX_MEM_DATA_WIDTH-1:0]  mem_req_data
,output[   `VX_MEM_TAG_WIDTH-1:0]  mem_req_tag
,input                             mem_req_ready
,// Memory response    
 input                         mem_rsp_valid
,input[`VX_MEM_DATA_WIDTH-1:0] mem_rsp_data
,input[ `VX_MEM_TAG_WIDTH-1:0] mem_rsp_tag
,output logic                  mem_rsp_ready
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
assign mem_rsp_ready = mem_rsp_valid;

assign mem_req_addr = 'h100;
//assign mem_req_rw = 1'b1;
assign mem_req_byteen = {4'h0,4'h2,4'h3,4'h4,4'h5,4'h6,4'h7,4'h8
                        ,4'h9,4'hA,4'hB,4'hC,4'hD,4'hE,4'hF,4'h1
                        };
assign mem_req_data = {32'h11111111,32'h22222222,32'h33333333,32'h44444444,32'h55555555,32'h66666666,32'h77777777,32'h88888888
                      ,32'h99999999,32'hAAAAAAAA,32'hBBBBBBBB,32'hCCCCCCCC,32'hDDDDDDDD,32'hEEEEEEEE,32'hFFFFFFFF,32'h12345678
                      };

always @(posedge clk, posedge reset)
 if (reset) begin
  mem_req_valid <= 1'b0;
  mem_req_rw <= 1'b0;
 end
  else begin
   mem_req_valid <= 1'b1;
   //
   if (mem_req_valid && mem_req_ready) begin
    mem_req_rw <= !mem_req_rw;
   end
  end

`else
assign mem_rsp_ready = mem_rsp_valid;

reg[32:0] mem_reqCnt = 65000;
 //assign mem_req_valid = mem_reqCnt[32];
// assign mem_req_addr = 'h100;
 assign mem_req_addr = 'hFFFFFFFF;
// assign mem_req_rw = 1'b1;
 assign mem_req_byteen = {4'h0,4'h2,4'h3,4'h4,4'h5,4'h6,4'h7,4'h8
                         ,4'h9,4'hA,4'hB,4'hC,4'hD,4'hE,4'hF,4'h1
                         };
 assign mem_req_data = {32'h11111111,32'h22222222,32'h33333333,32'h44444444,32'h55555555,32'h66666666,32'h77777777,32'h88888888
                       ,32'h99999999,32'hAAAAAAAA,32'hBBBBBBBB,32'hCCCCCCCC,32'hDDDDDDDD,32'hEEEEEEEE,32'hFFFFFFFF,32'h12345678
                       };
always @(posedge clk) begin
 mem_reqCnt <= mem_reqCnt[31:0]-1;
 if (mem_reqCnt[32]) begin
  mem_req_valid <= 1'b1;
 end
 //
 if (mem_req_valid && mem_req_ready) begin
  mem_req_rw <= !mem_req_rw;
 end
end

`endif

endmodule

`endif
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
