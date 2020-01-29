# Copyright (c) 2011-2019 Columbia University, System Level Design Group
# SPDC-License-Identifier: Apache-2.0

VIVADO = /opt/cad/vivado
ESPROOT = ../../esp
ACCEL = ../../accel

FLAGS ?=
FLAGS += -NOWarn SCK505
FLAGS += -SCTOP sc_main
FLAGS += -DCLOCK_PERIOD=12.5
FLAGS += -DRTL_CACHE
FLAGS += -DSTATS_ENABLE
FLAGS += -TOP glbl
FLAGS += -access +R

INCDIR ?=
INCDIR += -I$(ACCEL)
INCDIR += -I$(ESPROOT)/systemc/common/caches
INCDIR += -I$(ESPROOT)/systemc/llc/tb
INCDIR += -I$(STRATUS_PATH)/share/stratus/include
INCDIR += +incdir+../common/defs

LLC_TB ?=
LLC_TB += $(ESPROOT)/systemc/llc/tb/llc_tb.cpp
LLC_TB += sim/sc_main.cpp

#SC_SRC ?=
#/SC_SRC += src/scc.cpp

LLC_COSIM_SRC ?=
LLC_COSIM_SRC += sim/llc_wrap.cpp

LLC_SRC ?=
LLC_SRC += ./rtl/*.sv

RTL_SRC ?=
RTL_SRC += $(ESPROOT)/tech/virtex7/mem/*.v
RTL_SRC += $(VIVADO)/data/verilog/src/glbl.v
RTL_SRC += $(VIVADO)/data/verilog/src/retarget/RAMB*.v
RTL_SRC += $(VIVADO)/data/verilog/src/unisims/RAMB*.v
RTL_SRC += ../common/rtl/*.sv

#sc-sim-gui: $(SC_TB) $(SC_SRC)
#	ncsc_run  $(INCDIR) $(FLAGS) -GUI $^

#sc-sim: $(SC_TB) $(SC_SRC)
#	ncsc_run  $(INCDIR) $(FLAGS) $^

llc-sim: $(LLC_TB) $(LLC_COSIM_SRC) $(RTL_SRC) $(LLC_SRC)
	ncsc_run -DRTL_SIM $(INCDIR) $(FLAGS) $^

llc-sim-gui: $(LLC_TB) $(LLC_COSIM_SRC) $(RTL_SRC) $(LLC_SRC)
	ncsc_run -DRTL_SIM $(INCDIR) $(FLAGS) -GUI $^

clean:
	rm -rf 			\
		*.log 		\
		*.so 		\
		INCA_libs	\
		.simvision	\
		*.key		\
		*.shm		\
		*.err 		\
        *.daig

.PHONY: sc-sim sc-sim-gui clean
