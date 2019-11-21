// Copyright (`c) 2011-2019 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0

`ifndef __CACHE_TYPES_SVH__
`define __CACHE_TYPES_SVH__

`include "cache_consts.svh"

/*
 * Cache data types
 */
typedef logic[(`CPU_MSG_TYPE_WIDTH-1):0]	cpu_msg_t; // CPU bus requests
typedef logic[(`COH_MSG_TYPE_WIDTH-1):0]	coh_msg_t; // Requests without DMA, Forwards, Responses
typedef logic[(`MIX_MSG_TYPE_WIDTH-1):0]	mix_msg_t; // Requests if including DMA
typedef logic[(`HSIZE_WIDTH-1):0]		hsize_t;
typedef logic[(`HPROT_WIDTH-1):0]    	hprot_t;
typedef logic[(`INVACK_CNT_WIDTH-1):0]	invack_cnt_t;
typedef logic[(`INVACK_CNT_CALC_WIDTH-1):0]	invack_cnt_calc_t;
typedef logic[(`ADDR_BITS-1):0]		addr_t;
typedef logic[(`LINE_ADDR_BITS-1):0]		line_addr_t;
typedef logic[(`L2_ADDR_BITS-1):0]           l2_addr_t;
typedef logic[(`LLC_ADDR_BITS-1):0]          llc_addr_t;
typedef logic[(`BITS_PER_WORD-1):0]		word_t;
typedef logic[(`BITS_PER_LINE-1):0]	line_t;
typedef logic[(`L2_TAG_BITS-1):0]		l2_tag_t;
typedef logic[(`LLC_TAG_BITS-1):0]		llc_tag_t;
typedef logic[(`L2_SET_BITS-1):0]		l2_set_t;
typedef logic[(`LLC_SET_BITS-1):0]		llc_set_t;
//@TODO
//`if (L2_WAY_BITS == 1)
//typedef logic[(2-1):0] l2_way_t;
//`else
typedef logic[(`L2_WAY_BITS-1):0] l2_way_t;
//`endif
typedef logic[(`LLC_WAY_BITS-1):0]		llc_way_t;
typedef logic[(`OFFSET_BITS-1):0]		offset_t;
typedef logic[(`WORD_BITS-1):0]		word_offset_t;
typedef logic[(`BYTE_BITS-1):0]		byte_offset_t;
typedef logic[(`STABLE_STATE_BITS-1):0]	state_t;
typedef logic[(`LLC_STATE_BITS-1):0]	        llc_state_t;
typedef logic[(`UNSTABLE_STATE_BITS-1):0]	unstable_state_t;
typedef logic[(`CACHE_ID_WIDTH-1):0]         cache_id_t;
typedef logic[(`MAX_N_L2_BITS-1):0]		owner_t;
typedef logic[(`MAX_N_L2-1):0]		sharers_t;
typedef logic[(`DMA_BURST_LENGTH_BITS-1):0]  dma_length_t;

/*
 * L2 cache coherence channels types
 */

/* L1 to L2 */

// L1 request
interface l2_cpu_req_t;
	cpu_msg_t cpu_msg;
    hsize_t  hsize;
    hprot_t hprot;
    addr_t addr;
    word_t word;

    modport in (input cpu_msg, hsize, hprot, addr, word); 
    modport out (output cpu_msg, hsize, hprot, addr, word); 

endinterface

/* L2 to L1 */

// read data response
interface l2_rd_rsp_t;
    line_t line;

    modport in (input line);
    modport out (output line); 

endinterface

// invalidate address
typedef line_addr_t l2_inval_t;

/* L2/LLC to L2 */
interface  l2_fwd_in_t;
    mix_msg_t coh_msg;
    line_addr_t addr;
    cache_id_t req_id;

    modport in (input coh_msg, addr, req_id); 
    modport out (output coh_msg, addr, req_id); 

endinterface

// responses
interface l2_rsp_in_t;
    coh_msg_t		coh_msg;	// data, e-data, inv-ack, put-ack
    line_addr_t		addr;
    line_t		line;
    invack_cnt_t	invack_cnt;

    modport in (input coh_msg, addr, line, invack_cnt);
    modport out (output coh_msg, addr, line, invack_cnt); 

endinterface

interface llc_rsp_out_t;
    coh_msg_t		coh_msg; // data, e-data, inv-ack, rsp-data-dma
    line_addr_t		addr;
    line_t		line;
    invack_cnt_t	invack_cnt; // used to mark last line of RSP_DATA_DMA
    cache_id_t          req_id;
    cache_id_t          dest_id;
    word_offset_t       word_offset;
    
    modport in (input coh_msg, addr, line, invack_cnt, req_id, dest_id, word_offset); 
    modport out (output coh_msg, addr, line, invack_cnt, req_id, dest_id, word_offset); 
    
endinterface

interface llc_fwd_out_t;
    mix_msg_t		coh_msg;	// fwd_gets, fwd_getm, fwd_inv
    line_addr_t		addr;
    cache_id_t          req_id;
    cache_id_t          dest_id;

    modport in (input coh_msg, addr, req_id, dest_id); 
    modport out (output coh_msg, addr, req_id, dest_id); 

endinterface
/* L2 to L2/LLC */

// requests
interface l2_req_out_t;
    coh_msg_t	coh_msg;	// gets, getm, puts, putm
    hprot_t	hprot;
    line_addr_t	addr;
    line_t	line;

    modport in (input coh_msg, hprot, addr, line); 
    modport out (output coh_msg, hprot, addr, line); 

endinterface

interface llc_req_in_t;
    mix_msg_t	  coh_msg;	// gets, getm, puts, putm, dma_read, dma_write
    hprot_t	  hprot; // used for dma write burst end (0) and non-aligned addr (1)
    line_addr_t	  addr;
    line_t	  line; // used for dma burst length too
    cache_id_t    req_id;
    word_offset_t word_offset;
    word_offset_t valid_words;

    modport in (input coh_msg, hprot, addr, line, req_id, word_offset, valid_words);
    modport out (output coh_msg, hprot, addr, line, req_id, word_offset, valid_words);

endinterface

// responses
interface l2_rsp_out_t;
    coh_msg_t	coh_msg;	// gets, getm, puts, putm
    cache_id_t  req_id;
    logic[1:0]  to_req;
    line_addr_t	addr;
    line_t	line;

    modport in (input coh_msg, req_id, to_req, addr, line); 
    modport out (output coh_msg, req_id, to_req, addr, line); 

endinterface

interface llc_rsp_in_t;
    coh_msg_t coh_msg;
    line_addr_t	addr;
    line_t	line;
    cache_id_t  req_id;

    modport in (input coh_msg, addr, line, req_id);
    modport out (output coh_msg, addr, line, req_id);

endinterface
   
/* LLC to Memory */

// requests
interface llc_mem_req_t;
    logic	hwrite;	// r, w, r atom., w atom., flush
    hsize_t	hsize;
    hprot_t	hprot;
    line_addr_t	addr;
    line_t	line;

    modport in (input hwrite, hsize, hprot, addr, line); 
    modport out (output hwrite, hsize, hprot, addr, line); 

endinterface

// responses

interface llc_mem_rsp_t;
    line_t line;

    modport in (input line); 
    modport out (output line); 

endinterface

interface line_breakdown_l2_t;
    l2_tag_t tag;
    l2_set_t set;

    modport in (input tag, set); 
    modport out (output tag, set); 

endinterface

interface line_breakdown_llc_t;
    llc_tag_t tag;
    llc_set_t set;

    modport in (input tag, set); 
    modport out (output tag, set); 

endinterface

/*
 * Ongoing transaction buffer tuypes
 */

// ongoing request buffer
typedef struct packed{
    cpu_msg_t           cpu_msg;
    l2_tag_t		tag;
    l2_tag_t            tag_estall;
    l2_set_t		set;
    l2_way_t            way;
    hsize_t             hsize;
    word_offset_t	w_off;
    byte_offset_t	b_off;
    unstable_state_t	state;
    hprot_t		hprot;
    invack_cnt_calc_t	invack_cnt;
    word_t		word;
    line_t		line;
} reqs_buf_t; 

//    modport in (input cpu_msg, tag, tag_estall, set, way, hsize, w_off, b_off, state, hprot, invack_cnt, word, line); 
//    modport out (output cpu_msg, tag, tag_estall, set, way, hsize, w_off, b_off, state, hprot, invack_cnt, word, line);
//endinterface

// forward stall backup
interface fwd_stall_backup_t;
    coh_msg_t coh_msg;
    line_addr_t addr;
endinterface

// addr breakdown
interface addr_breakdown_t;
    addr_t              line;
    line_addr_t         line_addr;
    addr_t              word;
    l2_tag_t            tag;
    l2_set_t            set;
    word_offset_t       w_off;
    byte_offset_t       b_off;
    
    modport in (input line, line_addr, word, tag, set, w_off, b_off); 
    modport out (output line, line_addr, word, tag, set, w_off, b_off); 

endinterface

`endif // __CACHE_TYPES_HPP__