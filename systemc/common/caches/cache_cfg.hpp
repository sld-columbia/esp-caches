// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __CACHES_CFG_SVH__
#define __CACHES_CFG_SVH__

// endianness
// set LITTLE_ENDIAN for Ariane and Ibex, BIG_ENDIAN for Leon
#define BIG_ENDIAN

// word size
// set 3 for Ariane; 2 for Leon, 2 for Ibex
#define BYTE_BITS 3

// cache line size
// options: 4 (16B/128b), 5 (32B/256b), 6 (64B/512b), 7 (128B/1024b)
#define CACHE_LINE_BYTES_LOG2 4

#define LLC_WAYS  16
#define LLC_SETS  512
#define WORD_BITS (CACHE_LINE_BYTES_LOG2 - BYTE_BITS)

#endif // __CACHES_CFG_SVH__
