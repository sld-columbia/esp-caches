`ifndef __CACHES_CFG_SVH__
`define __CACHES_CFG_SVH__

//set LITTLE_ENDIAN for Ariane, BIG_ENDIAN for Leon
`define BIG_ENDIAN
`define ADDR_BITS    32
`define BYTE_BITS    2
`define WORD_BITS    2
`define L2_WAYS      8
`define L2_SETS      256

`endif // __CACHES_CFG_SVH__
