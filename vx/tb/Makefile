# maxhpc: Maxim Vorontsov

VORTEX_HOME = ../../..

SRC = ${VORTEX_HOME}/hw/rtl/VX_gpu_pkg.sv
SRC+= ../maxhpc.sv
SRC+= ../vx_stub.sv

INC = -I../../libs
INC+= -I../../libs/ddr3
INC+= -I${VORTEX_HOME}/hw/rtl

VLFLAGS+= -top maxhpc
VLFLAGS+= --trace
VLFLAGS+= -Wno-fatal
VLFLAGS+= -DMAXHPC
VLFLAGS+= -DVX_STUB

CFLAGS+= -O9
CFLAGS+= -DMAXHPC

all:
	verilator ${VLFLAGS} -CFLAGS '${CFLAGS}' --cc --exe tb.cpp ${SRC} ${INC}
	+make -C obj_dir -f Vmaxhpc.mk

clean:
	rm -rf obj_dir *.vcd
