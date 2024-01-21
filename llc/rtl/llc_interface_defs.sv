// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0

`include "cache_consts.svh"
`include "cache_types.svh"

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

interface llc_dma_rsp_out_t;
   coh_msg_t           coh_msg;        // data, e-data, inv-ack, rsp-data-dma
   line_addr_t         addr;
   line_t              line;
   invack_cnt_t        invack_cnt;     // used to mark last line of RSP_DATA_DMA
   llc_coh_dev_id_t    req_id;
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

interface llc_dma_req_in_t;
   mix_msg_t        coh_msg;   // gets, getm, puts, putm, dma_read, dma_write
   hprot_t          hprot;     // used for dma write burst end (0) and non-aligned addr (1)
   line_addr_t      addr;
   line_t           line;      // used for dma burst length too
   llc_coh_dev_id_t req_id;
   word_offset_t    word_offset;
   word_offset_t    valid_words;

   modport in (input coh_msg, hprot, addr, line, req_id, word_offset, valid_words);
   modport out (output coh_msg, hprot, addr, line, req_id, word_offset, valid_words);

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

interface line_breakdown_llc_t;
    llc_tag_t tag;
    llc_set_t set;

    modport in (input tag, set); 
    modport out (output tag, set); 

endinterface

