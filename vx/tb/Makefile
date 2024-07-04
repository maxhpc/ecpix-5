# maxhpc: Maxim Vorontsov

SRC = ../vx.sv
INC = -I../../libs
INC+= -I../../libs/ddr3

VLFLAGS+= --trace
VLFLAGS+= -Wno-fatal

CFLAGS+= -O9

all:
	verilator ${VLFLAGS} -CFLAGS ${CFLAGS} --cc --exe tb.cpp ${SRC} ${INC}
	+make -C obj_dir -f Vvx.mk

clean:
	rm -rf obj_dir *.vcd
