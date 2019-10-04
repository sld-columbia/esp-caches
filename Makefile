FLAGS ?=
FLAGS += -NOWarn SCK505
FLAGS += -SCTOP sc_main

INCDIR ?=
INCDIR += -I./rtl
INCDIR += -I./sim
INCDIR += -I./defs
INCDIR += -I$(STRATUS_PATH)/share/stratus/include

SC_TB ?=
SC_TB += src/llc_tb.cpp
SC_TB += src/sc_main.cpp

#SC_SRC ?=
#/SC_SRC += src/scc.cpp

RTL_COSIM_SRC ?=
RTL_COSIM_SRC += sim/llc_wrap.cpp

RTL_SRC ?=
RTL_SRC += rtl/llc_wrapper.sv

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
