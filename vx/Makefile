# maxhpc: Maxim Vorontsov

PROJECT = maxhpc
VORTEX_ROOT = /home/gypak/riscv/maxhpc/vortex
SRC = $(wildcard *.sv)
SRC+= ${VORTEX_ROOT}/hw/rtl/VX_gpu_pkg.sv
SV2V_FLAGS+= -I${VORTEX_ROOT}/hw/rtl
SV2V_FLAGS+= -DSYNTHESIS
SV2V_FLAGS+= -DVX_STUB

include ../build.mk
