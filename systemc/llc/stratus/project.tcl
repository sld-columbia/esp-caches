# Copyright (c) 2011-2025 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0

############################################################
# Design Parameters
############################################################

#
# Source the common configurations
#
source ../../common/syn/caches.tcl

#
# Timing constraints
#
if {$TECH eq "virtex7"} {
    set CLOCK_PERIOD 10.0
    set_attr default_input_delay      0.1
}
if {$TECH eq "zynq7000"} {
    set CLOCK_PERIOD 10.0
    set_attr default_input_delay      0.1
}
if {$TECH eq "virtexu"} {
    set CLOCK_PERIOD 8.0
    set_attr default_input_delay      0.1
}
if {$TECH eq "virtexup"} {
    set CLOCK_PERIOD 6.4
    set_attr default_input_delay      0.1
}
if {$TECH eq "cmos32soi"} {
    set CLOCK_PERIOD 1000.0
    set_attr default_input_delay      100.0
}
if {$TECH eq "gf12"} {
    set CLOCK_PERIOD 1000.0
    set_attr default_input_delay      100.0
}
set_attr clock_period $CLOCK_PERIOD

#
# System level modules to be synthesized
#
define_hls_module llc ../src/llc.cpp

#
# Testbench or system level modules
#
define_system_module tb  ../tb/llc_tb.cpp ../tb/system.cpp ../tb/sc_main.cpp

######################################################################
# HLS and Simulation configurations
######################################################################

# foreach sets [list 256 512 1024 2048 4096 8192] {

#     foreach ways [list 4 8 16 32] {

foreach sets [list 1024] {

    foreach ways [list 16] {

	foreach wbits [list 1 2] {

	    foreach bbits [list 2 3] {

		foreach abits [list 32] {

		    # Skip these configurations
		    if {$wbits == 1 && $bbits == 2} {continue}
		    if {$wbits == 2 && $bbits == 3} {continue}

		    set words_per_line [expr 1 << $wbits]
		    set bits_per_word [expr (1 << $bbits) * 8]

		    set pars "_${sets}SETS_${ways}WAYS_${words_per_line}x${bits_per_word}LINE_${abits}ADDR"

		    set iocfg "IOCFG$pars"

		    define_io_config * $iocfg -DLLC_SETS=$sets -DLLC_WAYS=$ways \
			-DADDR_BITS=$abits -DBYTE_BITS=$bbits -DWORD_BITS=$wbits

		    define_system_config tb "TESTBENCH$pars" -io_config $iocfg

		    define_sim_config "BEHAV$pars" "llc BEH" "tb TESTBENCH$pars" \
			-io_config $iocfg

		    foreach cfg [list BASIC] {

			set cname "$cfg$pars"

			define_hls_config llc $cname --clock_period=$CLOCK_PERIOD \
			    $COMMON_HLS_FLAGS -DHLS_DIRECTIVES_$cfg -io_config $iocfg

			if {$TECH_IS_XILINX == 1} {

			    define_sim_config "$cname\_V" "llc RTL_V $cname" \
				"tb TESTBENCH$pars" -verilog_top_modules glbl \
				-io_config $iocfg

			} else {

			    define_sim_config "$cname\_V" "llc RTL_V $cname" \
				"tb TESTBENCH$pars" -io_config $iocfg
			}
		    }
		}
	    }
	}
    }
}

#
# Compile Flags
#
set_attr hls_cc_options "$INCLUDES $CACHE_INCLUDES"

#
# Simulation Options
#
use_systemc_simulator xcelium
set_attr cc_options "$INCLUDES  $CACHE_INCLUDES -DCLOCK_PERIOD=$CLOCK_PERIOD"
# enable_waveform_logging -vcd
set_attr end_of_sim_command "make saySimPassed"
