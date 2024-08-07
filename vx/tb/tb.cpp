// maxhpc: Maxim Vorontsov

#include "Vmaxhpc.h"
#if VM_TRACE_VCD
#include <verilated_vcd_c.h>
#endif

class tb {
 VerilatedContext Vcnxt;
 Vmaxhpc          dut{&Vcnxt};
 #if VM_TRACE_VCD
  VerilatedVcdC trace;
 #endif

 public:
  tb() {
   Verilated::randSeed(0);
   #if VM_TRACE_VCD
    Verilated::traceEverOn(true);
    dut.trace(&trace, 99);
    trace.open("trace.vcd");
   #endif
   //
   //
   reset();
   //
//   run(100);
//   dut.uart_rxd = 0;
//   run(50);
//   dut.uart_rxd = 1;
   run(200000);
  }

  ~tb() {
   #if VM_TRACE_VCD
    trace.close();
   #endif
  }

  void reset() {
   dut.rst_fpga_ = 1;
   //
   dut.uart_rxd = 1;
   dut.gsrn = 0;
   for (uint32_t i=0; i<100; i++) {
    tick();
   }
   dut.gsrn = 1;
  }

  void run(uint64_t n) {
   while (Vcnxt.time()<n) {
    tick();
if (Vcnxt.time()%10000 == 0) {
 printf("TS: %d\n", Vcnxt.time());
}
   }
  }

private:
 void tick() {
   // clk rising edge
   dut.fpga_sysclk = 1;
   this->eval();
   // clk falling edge
   dut.fpga_sysclk = 0;
   this->eval();
  }

  void eval() {
   dut.eval();
   #if VM_TRACE_VCD
    trace.dump(Vcnxt.time());
   #endif
   Vcnxt.timeInc(1);
  }
};

int main() {
 tb tb;
 return 0;
}
// vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
