// maxhpc: Maxim Vorontsov

`ifdef VX_STUB

`include "VX_define.vh"

module Vortex import VX_gpu_pkg::*; (
 // Clock
 input clk
,input reset
,// Memory request
 output logic                           mem_req_valid
,output logic                           mem_req_rw
,output logic[`VX_MEM_BYTEEN_WIDTH-1:0] mem_req_byteen
,output[  `VX_MEM_ADDR_WIDTH-1:0]       mem_req_addr
,output[  `VX_MEM_DATA_WIDTH-1:0]       mem_req_data
,output[   `VX_MEM_TAG_WIDTH-1:0]       mem_req_tag
,input                                  mem_req_ready
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

assign mem_req_addr = 'h400A;
reg[2:0] tttRW;
 assign mem_req_rw = tttRW[0];
assign mem_req_byteen = {4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF
                        ,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF
                        };
assign mem_req_data = {32'h11111111,32'h22222222,32'h33333333,32'h44444444,32'h55555555,32'h66666666,32'h77777777,32'h88888888
                      ,32'h99999999,32'hAAAAAAAA,32'hBBBBBBBB,32'hCCCCCCCC,32'hDDDDDDDD,32'hEEEEEEEE,32'hFFFFFFFF,32'h12345678
                      };

reg[32:0] mem_reqCnt;
always @(posedge clk, posedge reset)
 if (reset) begin
  mem_req_valid <= 1'b0;
  //
  tttRW <= 3'b011;
  mem_reqCnt <= 100;
 end
  else begin
   mem_reqCnt <= mem_reqCnt[31:0]-1;
   if (mem_reqCnt[32]) begin
    mem_req_valid <= 1'b1;
   end
   //
   if (mem_req_valid && mem_req_ready) begin
    mem_req_valid <= 1'b0;
    tttRW <= {tttRW[0],tttRW[2:1]};
   end
  end

`else
 assign mem_rsp_ready = mem_rsp_valid;

 reg[32:0] mem_reqCnt = 65000;
  //assign mem_req_valid = mem_reqCnt[32];
// assign mem_req_rw = 1'b1;
 reg[2:0] tttRW = 3'b111;
  assign mem_req_rw = tttRW[0];
//  assign mem_req_addr = 'h100;
 reg[`VX_MEM_ADDR_WIDTH-1:0] tttAddr='hFFFFFFFF;
  assign mem_req_addr = /*tttAddr*/'h400A;
 assign mem_req_byteen = {4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF
                         ,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF,4'hF
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
  mem_req_valid <= 1'b0;
//  tttRW <= {tttRW[0],tttRW[2:1]};
//  tttRW <= $random();
//  tttAddr <= $random();
//  mem_req_byteen <= {$random(), $random()};
 end
end

`endif

endmodule

`endif
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
