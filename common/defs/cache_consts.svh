// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0

`ifndef __CACHES_CONSTS_SVH__
`define __CACHES_CONSTS_SVH__

`include "cache_cfg.svh"

/*
 * System
 */

// System configuration
`define MAX_N_L2 16
`define MAX_N_L2_BITS $clog2(`MAX_N_L2)
`define MAX_N_LLC 64
`define MAX_N_LLC_BITS $clog2(`MAX_N_LLC)

/*
 * Caches
 */

//
// Common
//


`ifndef BIG_ENDIAN
`ifndef LITTLE_ENDIAN
`define LITTLE_ENDIAN
`endif
`endif

`ifndef ADDR_BITS
`define ADDR_BITS	32 // defined in l2,llc/stratus/project.tcl
`endif
`ifndef BYTE_BITS
`define BYTE_BITS	3 // defined in l2,llc/stratus/project.tcl
`endif
`ifndef WORD_BITS
`define WORD_BITS	1 // defined in l2,llc/stratus/project.tcl
`endif

`define OFFSET_BITS	(`BYTE_BITS + `WORD_BITS)

`define LINE_RANGE_HI	(`ADDR_BITS - 1)
`define LINE_RANGE_LO	`OFFSET_BITS
`define TAG_RANGE_HI	`LINE_RANGE_HI
`define SET_RANGE_LO	`LINE_RANGE_LO
`define OFF_RANGE_HI	(`OFFSET_BITS - 1)
`define OFF_RANGE_LO	0
`define W_OFF_RANGE_HI	`OFF_RANGE_HI
`define W_OFF_RANGE_LO	(`OFFSET_BITS - `WORD_BITS)
`define B_OFF_RANGE_HI	(`W_OFF_RANGE_LO - 1)
`define B_OFF_RANGE_LO	`OFF_RANGE_LO

`define SET_OFFSET	(1 << `OFFSET_BITS)
`define WORD_OFFSET	(1 << `BYTE_BITS)
`define LINE_ADDR_BITS  (`ADDR_BITS - `SET_RANGE_LO)

// Cache sizes
`define BYTES_PER_WORD		(1 << `BYTE_BITS)
`define BITS_PER_WORD		(`BYTES_PER_WORD << 3)
`define BITS_PER_HALFWORD	(`BITS_PER_WORD >> 1)
`define BITS_PER_DOUBLEWORD (`BITS_PER_WORD << 1)
`define BITS_PER_LINE		(`BITS_PER_WORD * `WORDS_PER_LINE)
`define WORDS_PER_LINE		(1 << `WORD_BITS)

// Cache data types width
`define CPU_MSG_TYPE_WIDTH	2
`define COH_MSG_TYPE_WIDTH	2
`define DMA_MSG_TYPE_WIDTH      1
`define MIX_MSG_TYPE_WIDTH	(`COH_MSG_TYPE_WIDTH + `DMA_MSG_TYPE_WIDTH)
`define HSIZE_WIDTH		3
`define HPROT_WIDTH	    1	
`define INVACK_CNT_WIDTH	`MAX_N_L2_BITS
`define INVACK_CNT_CALC_WIDTH   (`INVACK_CNT_WIDTH + 1)
`define CACHE_ID_WIDTH          `MAX_N_L2_BITS
`define LLC_COH_DEV_ID_WIDTH    `MAX_N_LLC_BITS
`define BRESP_WIDTH 2
`define AMO_WIDTH 6
//
// L2
//

`ifndef L2_WAYS
`define L2_WAYS      8 // defined in l2/stratus/project.tcl
`endif

`ifndef L2_SETS
`define L2_SETS      256  // defined in l2/stratus/project.tcl
`endif

`define L2_WAY_BITS	$clog2(`L2_WAYS)
`define L2_SET_BITS	$clog2(`L2_SETS)
`define L2_LINES	(`L2_SETS * `L2_WAYS)
`define L2_ADDR_BITS    (`L2_SET_BITS+`L2_WAY_BITS)
`define L2_TAG_BITS	(`ADDR_BITS - `OFFSET_BITS - `L2_SET_BITS)
`define L2_TAG_RANGE_LO	(`ADDR_BITS - `L2_TAG_BITS)
`define L2_SET_RANGE_HI	(`L2_TAG_RANGE_LO - 1)
`define L2_TAG_OFFSET	(1 << `L2_TAG_RANGE_LO)

// Ongoing transaction buffers
`define N_REQS		4	// affects REQS_BITS
`define REQS_BITS	2	// depends on N_REQS
`define REQS_BITS_P1	3	// depends on N_REQS + 1

//
// LLC
//

`ifndef LLC_WAYS
`define LLC_WAYS      16 // defined in l2/stratus/project.tcl
`endif

`ifndef LLC_SETS
`define LLC_SETS      2048  // defined in l2/stratus/project.tcl
`endif

`define LLC_WAY_BITS		$clog2(`LLC_WAYS)
`define LLC_SET_BITS		$clog2(`LLC_SETS)
`define LLC_LINES		(`LLC_SETS * `LLC_WAYS)
`define LLC_ADDR_BITS           (`LLC_SET_BITS+`LLC_WAY_BITS)
`define LLC_TAG_BITS		(`ADDR_BITS - `OFFSET_BITS - `LLC_SET_BITS)
`define LLC_TAG_RANGE_LO	(`ADDR_BITS - `LLC_TAG_BITS)
`define LLC_SET_RANGE_HI	(`LLC_TAG_RANGE_LO - 1)
`define LLC_TAG_OFFSET		(1 << `LLC_TAG_RANGE_LO)
`define LLC_LOOKUP_WAYS         16

/*
 * Testbench 
 */

// L2 operation behavior
`define HIT		0
`define MISS		1
`define MISS_EVICT	2

// Invalidation acknowledges order
`define DATA_FIRST	0
`define DATA_HALFWAY	1
`define DATA_LAST	2

// Fwd testing case
`define FWD_NONE	0
`define FWD_NOSTALL	1
`define FWD_STALL	2
`define FWD_STALL_XMW	3
`define FWD_STALL_EVICT	4

// DMA operations testbench
`define NO_DIRTY	0
`define DIRTY		1
`define NO_EVICT	0
`define EVICT		1

/*
 * Coherence
 */

/* Protocol states */

// N bits to indicate the state
`define STABLE_STATE_BITS	2	// depends on ` of stable states
`define LLC_STATE_BITS	        3 	// M, E, S, I, S^D, VALID, EID
`define UNSTABLE_STATE_BITS	4	// depends on ` of unstable states

// Stable states (last 3 for LLC only)
`define INVALID			0
`define SHARED			1
`define EXCLUSIVE		2
`define MODIFIED		3
`define SD                      4
`define VALID                   5
`define EID                     6
// `define MID merged with EID

// Unstable states
`define ISD			1
`define IMAD			2
`define IMADW			3
`define IMA			4
`define IMAW			5
`define SMAD			6
`define SMADW			7
`define SMA			8
`define SMAW			9
`define XMW			10
`define IIA			11
`define SIA			12
`define MIA			13

/*
 * Protocol messages
 */

// CPU requests (L1 to L2)
`define READ		0
`define READ_ATOMIC	1
`define WRITE		2
`define WRITE_ATOMIC	3

// LLC requests (LLC to mem)
`define LLC_READ  0
`define LLC_WRITE 1

// Coherence planes
`define REQ_PLANE 0
`define FWD_PLANE 1
`define RSP_PLANE 2

// requests (L2 to L3)
`define REQ_GETS		0
`define REQ_GETM		1
`define REQ_PUTS		2
`define REQ_PUTM		3
`define REQ_DMA_READ		4
`define REQ_DMA_WRITE		5
`define REQ_DMA_READ_BURST	6
`define REQ_DMA_WRITE_BURST	7

// forwards (L3 to L2)
`define FWD_GETS	0
`define FWD_GETM	1
`define FWD_INV		2
`define FWD_PUTACK	3
`define FWD_GETM_LLC    4
`define FWD_INV_LLC     5

// response (L2 to L2, L2 to L3, L3 to L2)
`define RSP_DATA	0
`define RSP_EDATA	1
`define RSP_INVACK	2
`define RSP_DATA_DMA    3
`define RSP_PUTACK	3

// DMA burst
`define DMA_BURST_LENGTH_BITS 32

/*
 * AMBA Bus
 */

// hsize
`define BYTE		0
`define HALFWORD	1
`define WORD_32		2
`define WORD_64     3
`define WORDS_128   4
`define WORDS_256	5

//this is used for requests from LLC to memory
//the number of byte bits matches the hsize encoding
//for a word for both LEON (2) and ARIANE (3) 
`define WORD `BYTE_BITS

// hprot
`define INSTR 0
`define DATA  1

/* 
 * Debug and report (currently not in use)
 */


//@TODO issue with stats enabled
`define STATS_ENABLE 1

//memory

`define BRAM_SIZE_16_BITS 1024
`define BRAM_SIZE_1_BIT 16384
`define BRAM_SIZE_8_BITS 2048
`define BRAM_SIZE_4_BITS 4096
`define BRAM_SIZE_32_BITS 512
`define BRAM_SIZE_2_BITS 8192

`define BRAM_512_ADDR_WIDTH 9
`define BRAM_1024_ADDR_WIDTH 10
`define BRAM_2048_ADDR_WIDTH 11
`define BRAM_4096_ADDR_WIDTH 12
`define BRAM_8192_ADDR_WIDTH 13
`define BRAM_16384_ADDR_WIDTH 14

//LLC
`define LLC_NUM_PORTS ((`LLC_WAYS >= 16) ? 16 : ((`LLC_WAYS >= 8) ? 8 : 4))
//each BRAM is split between 2 ways
//each way has LLC_SETS entries
//this is the number of banks needed to hold each way
//@TODO make evict ways and tags flexible for size
`define LLC_HPROT_BRAMS_PER_WAY ((`LLC_SETS + (`BRAM_SIZE_1_BIT /2) -1)  / (`BRAM_SIZE_1_BIT / 2))
`define LLC_HPROT_BRAM_INDEX_BITS $clog2(`LLC_HPROT_BRAMS_PER_WAY)
`define LLC_SHARERS_BRAMS_PER_WAY ((`LLC_SETS + (`BRAM_SIZE_16_BITS /2) -1)  / (`BRAM_SIZE_16_BITS / 2))
`define LLC_SHARERS_BRAM_INDEX_BITS $clog2(`LLC_SHARERS_BRAMS_PER_WAY)
`define LLC_OWNER_BRAMS_PER_WAY ((`LLC_SETS + (`BRAM_SIZE_4_BITS /2) -1)  / (`BRAM_SIZE_4_BITS / 2))
`define LLC_OWNER_BRAM_INDEX_BITS $clog2(`LLC_OWNER_BRAMS_PER_WAY)
`define LLC_DIRTY_BIT_BRAMS_PER_WAY ((`LLC_SETS + (`BRAM_SIZE_1_BIT /2) -1)  / (`BRAM_SIZE_1_BIT / 2))
`define LLC_DIRTY_BIT_BRAM_INDEX_BITS $clog2(`LLC_DIRTY_BIT_BRAMS_PER_WAY)
`define LLC_STATE_BRAMS_PER_WAY ((`LLC_SETS + (`BRAM_SIZE_4_BITS /2) -1)  / (`BRAM_SIZE_4_BITS / 2))
`define LLC_STATE_BRAM_INDEX_BITS $clog2(`LLC_STATE_BRAMS_PER_WAY)
`define LLC_TAG_BRAMS_PER_WAY ((`LLC_SETS + (`BRAM_SIZE_8_BITS /2) -1)  / (`BRAM_SIZE_8_BITS / 2))
`define LLC_TAG_BRAM_INDEX_BITS $clog2(`LLC_TAG_BRAMS_PER_WAY)

//assuming 16 or fewer ways - need to change this
//only need one entry per set
`define LLC_EVICT_WAY_BRAMS ((`LLC_SETS + (`BRAM_SIZE_4_BITS /2) -1)  / (`BRAM_SIZE_4_BITS / 2))
`define LLC_EVICT_WAY_BRAM_INDEX_BITS $clog2(`LLC_EVICT_WAY_BRAMS)

`define LLC_LINE_BRAMS_PER_WAY ((`LLC_SETS + (`BRAM_SIZE_16_BITS /2) -1)  / (`BRAM_SIZE_16_BITS / 2))
`define LLC_LINE_BRAM_INDEX_BITS $clog2(`LLC_LINE_BRAMS_PER_WAY)

//each line is 128 bits, so need to split data across multiple BRAMs
`define LLC_BRAMS_PER_LINE (`BITS_PER_LINE / 16)
`define LLC_BRAMS_PER_TAG  ((`LLC_TAG_BITS + 8 - 1) / 8)

//assuming sets <= 4096, so tag > 16
`define LLC_TAG_BRAM_WIDTH (`LLC_BRAMS_PER_TAG * 8)
`define LLC_EVICT_WAY_BRAM_WIDTH 4 
`define LLC_STATE_BRAM_WIDTH 4

//L2
`define L2_NUM_PORTS ((`L2_WAYS >= 8) ? 8 : ((`L2_WAYS >= 4) ? 4 : 2))
//each BRAM is split between 2 ways
//each way has L2_SETS entries
//this is the number of banks needed to hold each way
//@TODO make evict ways and tags flexible for size
`define L2_HPROT_BRAMS_PER_WAY ((`L2_SETS + (`BRAM_SIZE_1_BIT /2) -1)  / (`BRAM_SIZE_1_BIT / 2))
`define L2_HPROT_BRAM_INDEX_BITS $clog2(`L2_HPROT_BRAMS_PER_WAY)
`define L2_STATE_BRAMS_PER_WAY ((`L2_SETS + (`BRAM_SIZE_2_BITS /2) -1)  / (`BRAM_SIZE_2_BITS / 2))
`define L2_STATE_BRAM_INDEX_BITS $clog2(`L2_STATE_BRAMS_PER_WAY)
`define L2_TAG_BRAMS_PER_WAY ((`L2_SETS + (`BRAM_SIZE_8_BITS /2) -1)  / (`BRAM_SIZE_8_BITS / 2))
`define L2_TAG_BRAM_INDEX_BITS $clog2(`L2_TAG_BRAMS_PER_WAY)

//assuming 16 or fewer ways - need to change this
//only need one entry per set
`define L2_EVICT_WAY_BRAMS ((`L2_SETS + (`BRAM_SIZE_4_BITS /2) -1)  / (`BRAM_SIZE_4_BITS / 2))
`define L2_EVICT_WAY_BRAM_INDEX_BITS $clog2(`L2_EVICT_WAY_BRAMS)

`define L2_LINE_BRAMS_PER_WAY ((`L2_SETS + (`BRAM_SIZE_16_BITS /2) -1)  / (`BRAM_SIZE_16_BITS / 2))
`define L2_LINE_BRAM_INDEX_BITS $clog2(`L2_LINE_BRAMS_PER_WAY)

//each line is 128 bits, so need to split data across multiple BRAMs
`define L2_BRAMS_PER_LINE (`BITS_PER_LINE / 16)
`define L2_BRAMS_PER_TAG ((`L2_TAG_BITS + 8 - 1) / 8)

//L2 REQ DEFINES
`define L2_REQS_LOOKUP 3'b000
`define L2_REQS_PEEK_REQ 3'b001
`define L2_REQS_PEEK_FLUSH 3'b010
`define L2_REQS_PEEK_FWD 3'b011
`define L2_REQS_IDLE 3'b100

`define L2_LOOKUP 1'b0
`define L2_LOOKUP_FWD 1'b1

`define BRESP_OKAY 2'b00
`define BRESP_EXOKAY 2'b01
`define BRESP_SLVERR 2'b10
`define BRESP_DECERR 2'b11

//ASIC DEFINES
`define ASIC_SRAM_SIZE 512
`define ASIC_SRAM_ADDR_WIDTH 9
`define L2_ASIC_SRAMS_PER_WAY ((`L2_SETS + `ASIC_SRAM_SIZE - 1)  / `ASIC_SRAM_SIZE)
`define L2_ASIC_SRAM_INDEX_BITS $clog2(`L2_ASIC_SRAMS_PER_WAY)
`define L2_ASIC_SRAMS_PER_LINE (`BITS_PER_LINE / 64)
`define L2_ASIC_MIXED_SRAM_HPROT_INDEX 23
`define L2_ASIC_MIXED_SRAM_STATE_INDEX_HI 22
`define L2_ASIC_MIXED_SRAM_STATE_INDEX_LO (22 - `STABLE_STATE_BITS + 1)
`define L2_ASIC_MIXED_SRAM_TAG_INDEX_HI (`L2_TAG_BITS - 1)
`define L2_ASIC_MIXED_SRAM_TAG_INDEX_LO 0

`define LLC_ASIC_SRAMS_PER_WAY ((`LLC_SETS + `ASIC_SRAM_SIZE - 1)  / `ASIC_SRAM_SIZE)
`define LLC_ASIC_SRAM_INDEX_BITS $clog2(`LLC_ASIC_SRAMS_PER_WAY)
`define LLC_ASIC_SRAMS_PER_LINE (`BITS_PER_LINE / 64)
`define LLC_ASIC_MIXED_SRAM_HPROT_INDEX 27
`define LLC_ASIC_MIXED_SRAM_DIRTY_BIT_INDEX 26
`define LLC_ASIC_MIXED_SRAM_STATE_INDEX_HI 25
`define LLC_ASIC_MIXED_SRAM_STATE_INDEX_LO (25 - `LLC_STATE_BITS + 1)
`define LLC_ASIC_MIXED_SRAM_OWNER_INDEX_HI (`LLC_ASIC_MIXED_SRAM_STATE_INDEX_LO - 1)
`define LLC_ASIC_MIXED_SRAM_OWNER_INDEX_LO (`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_HI - `MAX_N_L2_BITS + 1)
`define LLC_ASIC_MIXED_SRAM_TAG_INDEX_HI (`LLC_TAG_BITS - 1)
`define LLC_ASIC_MIXED_SRAM_TAG_INDEX_LO 0


`endif // __CACHES_CONSTS_SVH__
