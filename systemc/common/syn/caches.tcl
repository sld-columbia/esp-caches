# Copyright (c) 2011-2023 Columbia University, System Level Design Group
# SPDX-License-Identifier: Apache-2.0

############################################################
# Project Parameters
############################################################

#
# Source the common configurations
#
source ../../common/syn/project.tcl

#
# Add generated memory library
#
use_hls_lib "./memlib"

#
# Local synthesis attributes
#
set_attr message_detail           2
set_attr default_input_delay      0.1
set_attr default_protocol         false
set_attr inline_partial_constants true
set_attr output_style_reset_all   true
set_attr lsb_trimming             true
set_attr unroll_loops             off
#
# Speedup scheduling for high-perf design (disable most area-minimization techniques)
#
set_attr sharing_effort_parts low
set_attr sharing_effort_regs low


set CACHE_INCLUDES "-I../../common/caches"

