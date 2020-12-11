# Copyright (c) 2011-2019 Columbia University, System Level Design Group
# SPDC-License-Identifier: Apache-2.0

VIVADO = $(XILINX_VIVADO)
ESP_ROOT ?= ../../../..
ACCEL = $(ESP_ROOT)/accelerators/stratus_hls/common/inc

FLAGS ?=
FLAGS += -NOWarn SCK505
FLAGS += -SCTOP sc_main
FLAGS += -DCLOCK_PERIOD=12.5
FLAGS += -DRTL_CACHE
FLAGS += -DSTATS_ENABLE
FLAGS += -TOP glbl
FLAGS += -access +R
FLAGS += -xmvlog_args,"-define XILINX_FPGA"

INCDIR ?=
INCDIR += -I$(ACCEL)
INCDIR += -I../systemc/common/caches
INCDIR += -I../systemc/llc/tb
INCDIR += -I../systemc/l2/tb
INCDIR += -I$(STRATUS_PATH)/share/stratus/include
INCDIR += +incdir+../common/defs
INCDIR += +incdir+.

L2_TB ?=
L2_TB +=../systemc/l2/tb/l2_tb.cpp
L2_TB += sim/sc_main.cpp

L2_COSIM_SRC ?=
L2_COSIM_SRC += sim/l2_wrap.cpp

L2_SRC ?=
L2_SRC += rtl/*.sv

RTL_SRC ?=
RTL_SRC += $(ESP_ROOT)/tech/virtex7/mem/*.v
RTL_SRC += $(VIVADO)/data/verilog/src/glbl.v
RTL_SRC += $(VIVADO)/data/verilog/src/retarget/RAMB*.v
RTL_SRC += $(VIVADO)/data/verilog/src/unisims/RAMB*.v
RTL_SRC += ../common/rtl/*.sv

l2-sim: $(L2_TB) $(L2_COSIM_SRC) $(RTL_SRC) $(L2_SRC)
	cp cache_cfg.svh ../systemc/common/caches/cache_cfg.hpp
	sed -i 's/`/#/g' ../systemc/common/caches/cache_cfg.hpp
	ncsc_run -DRTL_SIM $(INCDIR) $(FLAGS) $^
	rm ../systemc/common/caches/cache_cfg.hpp

l2-sim-gui: $(L2_TB) $(L2_COSIM_SRC) $(RTL_SRC) $(L2_SRC)
	cp cache_cfg.svh ../systemc/common/caches/cache_cfg.hpp
	sed -i 's/`/#/g' ../systemc/common/caches/cache_cfg.hpp
	ncsc_run -DRTL_SIM $(INCDIR) $(FLAGS) -GUI $^
	rm ../systemc/common/caches/cache_cfg.hpp

clean:
	rm -rf 			\
		*.log 		\
		*.so 		\
		INCA_libs	\
		.simvision	\
		*.key		\
		*.shm		\
		*.err 		\
        *.diag

.PHONY: sc-sim sc-sim-gui clean
