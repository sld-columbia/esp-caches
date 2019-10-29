VIVADO = /opt/cad/vivado
ESPROOT = ../esp
ACCEL = ../accel

FLAGS ?=
FLAGS += -NOWarn SCK505
FLAGS += -SCTOP sc_main
FLAGS += -DCLOCK_PERIOD=12.5
FLAGS += -DRTL_CACHE
FLAGS += -DSTATS_ENABLE
FLAGS += -TOP glbl
FLAGS += -access +R

INCDIR ?=
INCDIR += -I./rtl
INCDIR += -I./sim
INCDIR += -I$(ACCEL)
INCDIR += -I$(ESPROOT)/systemc/common/caches
INCDIR += -I$(ESPROOT)/systemc/llc/tb
INCDIR += -I$(STRATUS_PATH)/share/stratus/include
INCDIR += +incdir+defs 

SC_TB ?=
SC_TB += $(ESPROOT)/systemc/llc/tb/llc_tb.cpp
SC_TB += sim/sc_main.cpp

#SC_SRC ?=
#/SC_SRC += src/scc.cpp

RTL_COSIM_SRC ?=
RTL_COSIM_SRC += sim/llc_wrap.cpp

RTL_SRC ?=
#RTL_SRC += rtl/llc_wrapper.sv rtl/llc.sv rtl/lookup_way.sv rtl/localmem.sv rtl/read_set.sv rtl/input_decoder.sv
RTL_SRC += ./rtl/*.sv
RTL_SRC += $(ESPROOT)/tech/virtex7/mem/*.v
RTL_SRC += $(VIVADO)/data/verilog/src/glbl.v
RTL_SRC += $(VIVADO)/data/verilog/src/retarget/RAMB*.v
RTL_SRC += $(VIVADO)/data/verilog/src/unisims/RAMB*.v
#RTL_SRC += rtl/llc_wrapper.sv
#RTL_SRC += rtl/llc.sv

#sc-sim-gui: $(SC_TB) $(SC_SRC)
#	ncsc_run  $(INCDIR) $(FLAGS) -GUI $^

#sc-sim: $(SC_TB) $(SC_SRC)
#	ncsc_run  $(INCDIR) $(FLAGS) $^

rtl-sim: $(SC_TB) $(RTL_COSIM_SRC) $(RTL_SRC)
	ncsc_run -DRTL_SIM $(INCDIR) $(FLAGS) $^

rtl-sim-gui: $(SC_TB) $(RTL_COSIM_SRC) $(RTL_SRC)
	ncsc_run -DRTL_SIM $(INCDIR) $(FLAGS) -GUI $^


clean:
	rm -rf 			\
		*.log 		\
		*.so 		\
		INCA_libs	\
		.simvision	\
		*.key		\
		*.shm

.PHONY: sc-sim sc-sim-gui clean
