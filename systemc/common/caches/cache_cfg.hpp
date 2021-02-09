// Copyright (c) 2011-2021 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0
#ifndef __CACHES_CFG_SVH__
#define __CACHES_CFG_SVH__

//set LITTLE_ENDIAN for Ariane, BIG_ENDIAN for Leon
#define BIG_ENDIAN
//3 for Ariane, 2 for Leon
#define BYTE_BITS    2
//1 for Ariane, 2 for Leon
#define WORD_BITS    2
#define L2_WAYS      4
#define L2_SETS      1024

#endif // __CACHES_CFG_SVH__
