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
INCDIR += -I$(ESPROOT)/systemc/l2/tb
INCDIR += -I$(STRATUS_PATH)/share/stratus/include
INCDIR += +incdir+../common/defs


L2_TB ?= 
L2_TB +=$(ESPROOT)/systemc/l2/tb/l2_tb.cpp
L2_TB += sim/sc_main.cpp

#SC_SRC ?=
#/SC_SRC += src/scc.cpp

L2_COSIM_SRC ?=
L2_COSIM_SRC += sim/l2_wrap.cpp

L2_SRC ?= 
L2_SRC += rtl/*.sv 

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

l2-sim: $(L2_TB) $(L2_COSIM_SRC) $(RTL_SRC) $(L2_SRC)
	ncsc_run -DRTL_SIM $(INCDIR) $(FLAGS) $^

l2-sim-gui: $(L2_TB) $(L2_COSIM_SRC) $(RTL_SRC) $(L2_SRC)
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
