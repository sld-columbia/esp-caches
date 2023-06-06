// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
`ifndef __CACHES_CFG_SVH__
`define __CACHES_CFG_SVH__

//define CPU ARCH here
//options LEON, ARIANE, IBEX
`define ARIANE
//cache line size
//options: 4 (16B/128b), 5 (32B/256b), 6 (64B/512b), 7 (128B/1024b)
`define CACHE_LINE_BYTES_LOG2 4

`ifdef LEON
`define BIG_ENDIAN
`define BYTE_BITS    2
`define L2_WAYS      4
`define L2_SETS      256
`endif

`ifdef ARIANE
`define LLSC
`define LITTLE_ENDIAN
`define BYTE_BITS    3
`define L2_WAYS      4
`define L2_SETS      256
`endif

`ifdef IBEX
`define LITTLE_ENDIAN
`define BYTE_BITS    2
`define L2_WAYS      4
`define L2_SETS      256
`endif

`define WORD_BITS (`CACHE_LINE_BYTES_LOG2 - `BYTE_BITS)

`endif // __CACHES_CFG_SVH__
