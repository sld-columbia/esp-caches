// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
`ifndef __CACHES_CFG_SVH__
`define __CACHES_CFG_SVH__

//define CPU ARCH here
`define LEON

`ifdef LEON
`define BIG_ENDIAN
`define BYTE_BITS    2
`define WORD_BITS    2
`define L2_WAYS      4
`define L2_SETS      256
`endif

`ifdef ARIANE
`define LLSC
`define LITTLE_ENDIAN
`define BYTE_BITS    3
`define WORD_BITS    1
`define L2_WAYS      4
`define L2_SETS      256
`endif

`ifdef IBEX
`define LITTLE_ENDIAN
`define BYTE_BITS    2
`define WORD_BITS    2
`define L2_WAYS      4
`define L2_SETS      256
`endif

`endif // __CACHES_CFG_SVH__
