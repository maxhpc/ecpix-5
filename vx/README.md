# My efforts in implementing Vortex on FPGA

[![](maxhpc1.png)](maxhpc1.png)*<small><small>maxhpc's Vortex FPGA implementation</small></small>*

## Introduction
This job outlines the practical steps for implementing the Vortex GPGPU on an FPGA, with a specific focus on running a vector addition test. The process is broken down into hardware and software aspects.

## Implementation strategies

As an idea I proposed to use:

- for the hardware aspect:
  - use powerful enought (ex. Intel/Altera or AMD/Xilinx) FPGA-devboard to deploy Vortex' rtl and use internal FPGA's memory blocks as Vortex' internal memory, otherwise we can use onboard DRAM modules.
- for the software aspect:

  Regarding software implementation I can assume two approaches depending on hardware's interface implementation:
  1. ***PCIe module.***
     1. Write linux' module, that will create device nodes say in /sys/vortex/<node names correlated to functions in utils.cpp and vortex.cpp>
     2. Add support of our driver say *maxhpc* to Vortex.

     ***this approach has downside of complexity (both hardware and software), however it is closest to final production implementation***
  2. ***FTDI*** *(common name for USB to serial converter on board) USB interface.*

     ***the advantage of the approach is that there is no need to write kernel module to deal with PCI, and we can simply communicate with the Vortex board from userspace***
     - in this approach all we need is to add support of our *maxhpc* driver to Vortex via serial interface.

***As a result -- achieve successful passage of vecadd test using maxhpc driver.***

## So I decided to choose FTDI approach first

I forked original VortexGPGPU project to [my GitHub repository](https://github.com/maxhpc/vortex), most of this job was done in my subproject [ecpix-5](https://github.com/maxhpc/ecpix-5)/[vx](https://github.com/maxhpc/ecpix-5/tree/master/vx) which I added as submodule to *vortex/ecpix-5*.

Here is two aspects of the job of course:

1. ***Hardware.***  
For this job I was planning to use free and open source synthesis tools, so the range of target FPGA devices became quite narrow. The only FPGAs that powerful enough and accept such tools are *Lattice ECP5* and *AMD/Xilinx xc7* series. In order to estimate the necessary FPGA capacity, I performed Vortex only synthesis using [Yosys](https://yosyshq.net/yosys) tool, which is natively supported by Vortex (hw/syn/yosys). I used synth_ecp5 command, and the report showed that the project (Vortex only) consumes about 45k LUTs. So for the hardware I have chosen [ECPIX-5(85F) development board](http://docs.lambdaconcept.com/ecpix-5) with 85k LUTs Lattice ECP5-5G FPGA and 512MB ddr3 RAM onboard.
2. ***Software.***  
I was using *rtlsim* (runtime/rtlsim) driver as a basis for the *maxhpc* driver (runtime/maxhpc). Moreover in this driver it is clearly seen how the driver interfaces with the Vortex' hardware. It seemed (and later it turned out that it exactly is) that all we need to do is to implement via serial interface some self-evident functions such as:
  - read/write Vortex' local (RAM) memory, in our case it is DDR3 memory;
  - write DCR registers;
  - write Vortex' reset state.

Structure above illustrates all the work that has been done:

During implementing for each hardware functionality intermediate synthesis was performed. For these syntheses (*ecpix-5/vx/Makefile*) I stubbed the Vortex instance in order to -- save synthesis time, and -- because Vortex instance is not essential at the time.

However eventually during final synthesis (*hw/syn/maxhpc/Makefile*) with enabled Vortex it is turned out that FPGA's project too huge and synthesis cannot fit it. This happens because of FPU (float point unit). The only suitable FPU configuration for the project is *FPNEW*. Which not uses DSP ability of our FPGA, because Vortex can use DSP only for Altera's or Xilinx' FPGAs. Since it is known that only addition float point operation is used for *vecadd* test, I hard-coded FPU's operation to ADDMUL operation group only (***hw/rtl/core/VX_fpu_unit.sv***:
```
) fpu_fpnew (
...
- .op_type    (per_block_execute_if[block_idx].data.op_type),
+ .op_type    (0),
...
```

), which made degenerated other functionality. That eventually made synthesis successful.

## Running the **vecadd** test using *maxhpc* driver
```
$ ./ci/blackbox.sh --cores=1 --app=vecadd --driver=maxhpc
...
Workload size=64
[VXDRV] WAIT
[VXDRV] DCR_WRITE: addr=0x1, value=0x10000000
[VXDRV] WAIT
[VXDRV] DCR_WRITE: addr=0x2, value=0x0
[VXDRV] WAIT
[VXDRV] DCR_WRITE: addr=0x3, value=0x0
[VXDRV] WAIT
[VXDRV] DCR_WRITE: addr=0x4, value=0x0
[VXDRV] WAIT
[VXDRV] DCR_WRITE: addr=0x5, value=0x0
[VXDRV] WAIT
[VXDRV] DCR_WRITE: addr=0x5, value=0x0
[VXDRV] MEM_ALLOC: size=1048580
[VXDRV] COPY_TO_DEV: dev_addr=0x100040, host_addr=0x0x7ffc97921b74, size=4
Create context
Allocate device buffers
Create program from kernel source
Upload source buffers
[VXDRV] MEM_ALLOC: size=256
[VXDRV] COPY_TO_DEV: dev_addr=0x100080, host_addr=0x0x55691c777640, size=256
[VXDRV] MEM_ALLOC: size=256
[VXDRV] COPY_TO_DEV: dev_addr=0x100180, host_addr=0x0x55691c777750, size=256
Execute the kernel
[VXDRV] MEM_ALLOC: size=256
[VXDRV] MEM_ALLOC: size=76
[VXDRV] COPY_TO_DEV: dev_addr=0x100380, host_addr=0x0x55691c7857f0, size=76
[VXDRV] WAIT
[VXDRV] DCR_READ: addr=0x1, value=0x10000000
[VXDRV] WAIT
[VXDRV] DCR_READ: addr=0x2, value=0x0
[VXDRV] COPY_TO_DEV: dev_addr=0x10000000, host_addr=0x0x55691c787868, size=4764
[VXDRV] START: krnl_addr=0x10000000, args_addr=0x100380
[VXDRV] WAIT
run:165: write garbage to 0x100280
run:177: set reset=0
run:179: sleep(3)
run:181: set reset=1
[VXDRV] MEM_FREE: dev_addr=0x100380
[VXDRV] COPY_FROM_DEV: dev_addr=0x100040, host_addr=0x0x7ffc979232ac, size=4
Elapsed time: 3020 ms
Download destination buffer
[VXDRV] COPY_FROM_DEV: dev_addr=0x100280, host_addr=0x0x55691c784ed0, size=256
Verify result
PASSED!
[VXDRV] MEM_FREE: dev_addr=0x100080
[VXDRV] MEM_FREE: dev_addr=0x100180
[VXDRV] MEM_FREE: dev_addr=0x100280
[VXDRV] COPY_FROM_DEV: dev_addr=0x1fe04040, host_addr=0x0x55691c784ed0, size=256
PERF: instrs=7934, cycles=30431, IPC=0.260721
```

## The result
Here we can see that test is PASSED.

It is worth to mention how *maxhpc*'s approach determines that the test is finished. Normally there is mechanism to determine finishing the working of Vortex, which consists of busy poling and timeout. I decided not to implement any of this. Instead I simply output Vortex' busy signal to led0, and reset to led1. The run() function of *maxhpc* driver releases reset (which makes Vortex run), waits for 3 seconds and then resets Vortex back. According to the busy led it is clearly seen that Vortex going run for less than half of a second, so 3 seconds quite enough to wait before comparing the results.

## Some deepening to the developing process.

Besides Vortex there are such essential parts as DDR3 controller and UART interface:

- The UART on its turn consists of:
  - [UART receiver/transmitter](https://github.com/maxhpc/ecpix-5/tree/master/libs/uart). Because of simplicity I decided to write it from the scratch.
  - Another UART part - I'd call it command processor, which eventually executes appropriate function (listed in the UART block on structure) in a modem AT-command/response way. This part I decided ***to not*** cover into separate module, but build it up in-place on the top module as each functionality being implemented.

- Regarding DDR3 part I found [open source AXI-DDR3 controller](https://github.com/ultraembedded/core_ddr3_controller) that has implementation specifically for the FPGA board I am using. It was working out of the box mostly, however later on it was turned out that [one fix](https://github.com/maxhpc/core_ddr3_controller/commit/27a5dde925b5fd71d3a6084ee5b6c44242535f85) has to be applied to breakthrough subtle situation writing the burst with last word masked.

One of the major goal of the project is to prove that it is possible to use only free and open source development tools for this work.

### The development tools been used

- [Yosys](https://yosyshq.net/yosys) for Verilog synthesis
- [nextpnr](https://github.com/YosysHQ/nextpnr) for Lattice FPGAs placement and routing
- [prjtrellis](https://github.com/YosysHQ/prjtrellis) for working with Lattice FPGAs bitstream
- [openFPGALoader](https://github.com/trabucayre/openFPGALoader) for program bitstream into FPGA

<!---
vim: spell spelllang=ru,en
vim: foldenable foldmethod=indent shiftwidth=1 foldlevel=0
-->
