// Copyright (c) 2011-2019 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

//  llc_wrapper.sv
//  Author: Joseph Zuckerman
//  Packs incoming signals into interfaces to pass to LLC controller

module llc_rtl_top(clk, rst, llc_req_in_valid, llc_req_in_data_coh_msg, llc_req_in_data_hprot, llc_req_in_data_addr, llc_req_in_data_line, llc_req_in_data_req_id, llc_req_in_data_word_offset, llc_req_in_data_valid_words, llc_req_in_ready, llc_dma_req_in_valid, llc_dma_req_in_data_coh_msg, llc_dma_req_in_data_hprot, llc_dma_req_in_data_addr, llc_dma_req_in_data_line, llc_dma_req_in_data_req_id, llc_dma_req_in_data_word_offset, llc_dma_req_in_data_valid_words, llc_dma_req_in_ready, llc_rsp_in_valid, llc_rsp_in_data_coh_msg, llc_rsp_in_data_addr, llc_rsp_in_data_line, llc_rsp_in_data_req_id, llc_rsp_in_ready, llc_mem_rsp_valid, llc_mem_rsp_data_line, llc_mem_rsp_ready, llc_rst_tb_valid, llc_rst_tb_data, llc_rst_tb_ready, llc_rsp_out_valid, llc_rsp_out_data_coh_msg, llc_rsp_out_data_addr, llc_rsp_out_data_line, llc_rsp_out_data_invack_cnt, llc_rsp_out_data_req_id, llc_rsp_out_data_dest_id, llc_rsp_out_data_word_offset, llc_rsp_out_ready, llc_dma_rsp_out_valid, llc_dma_rsp_out_data_coh_msg, llc_dma_rsp_out_data_addr, llc_dma_rsp_out_data_line, llc_dma_rsp_out_data_invack_cnt, llc_dma_rsp_out_data_req_id, llc_dma_rsp_out_data_dest_id, llc_dma_rsp_out_data_word_offset, llc_dma_rsp_out_ready, llc_fwd_out_valid, llc_fwd_out_data_coh_msg, llc_fwd_out_data_addr, llc_fwd_out_data_req_id, llc_fwd_out_data_dest_id, llc_fwd_out_ready, llc_mem_req_valid, llc_mem_req_data_hwrite, llc_mem_req_data_hsize, llc_mem_req_data_hprot, llc_mem_req_data_addr, llc_mem_req_data_line, llc_mem_req_ready, llc_rst_tb_done_valid, llc_rst_tb_done_data, llc_rst_tb_done_ready
`ifdef STATS_ENABLE
	,llc_stats_valid, llc_stats_data, llc_stats_ready
`endif
);
      input logic clk;
      input logic rst;
      
      //llc req in 
      input mix_msg_t llc_req_in_data_coh_msg;
      input logic[1:0] llc_req_in_data_hprot;
      input line_addr_t llc_req_in_data_addr;
      input line_t llc_req_in_data_line;
      input cache_id_t llc_req_in_data_req_id;
      input word_offset_t llc_req_in_data_word_offset;
      input word_offset_t llc_req_in_data_valid_words;
      input logic llc_req_in_valid;
      output logic llc_req_in_ready;
            
      llc_req_in_t llc_req_in_i();
      assign llc_req_in_i.coh_msg     = llc_req_in_data_coh_msg;
      assign llc_req_in_i.hprot       = llc_req_in_data_hprot[0];
      assign llc_req_in_i.addr        = llc_req_in_data_addr;
      assign llc_req_in_i.line        = llc_req_in_data_line;
      assign llc_req_in_i.req_id      = llc_req_in_data_req_id;
      assign llc_req_in_i.word_offset = llc_req_in_data_word_offset;
      assign llc_req_in_i.valid_words = llc_req_in_data_valid_words;

      //llc dma req in 
      input mix_msg_t llc_dma_req_in_data_coh_msg;
      input logic[1:0] llc_dma_req_in_data_hprot;
      input line_addr_t llc_dma_req_in_data_addr;
      input line_t llc_dma_req_in_data_line;
      input cache_id_t llc_dma_req_in_data_req_id;
      input word_offset_t llc_dma_req_in_data_word_offset;
      input word_offset_t llc_dma_req_in_data_valid_words;
      input logic llc_dma_req_in_valid;
      output logic llc_dma_req_in_ready;
      
      llc_req_in_t llc_dma_req_in_i();
      assign llc_dma_req_in_i.coh_msg     = llc_dma_req_in_data_coh_msg;
      assign llc_dma_req_in_i.hprot       = llc_dma_req_in_data_hprot[0];
      assign llc_dma_req_in_i.addr        = llc_dma_req_in_data_addr;
      assign llc_dma_req_in_i.line        = llc_dma_req_in_data_line;
      assign llc_dma_req_in_i.req_id      = llc_dma_req_in_data_req_id;
      assign llc_dma_req_in_i.word_offset = llc_dma_req_in_data_word_offset;
      assign llc_dma_req_in_i.valid_words = llc_dma_req_in_data_valid_words;

      //llc rsp in
      input coh_msg_t llc_rsp_in_data_coh_msg;
      input line_addr_t llc_rsp_in_data_addr;
      input line_t llc_rsp_in_data_line;
      input cache_id_t llc_rsp_in_data_req_id;
      input logic llc_rsp_in_valid;
      output logic llc_rsp_in_ready;
     
      llc_rsp_in_t llc_rsp_in_i();
      assign llc_rsp_in_i.coh_msg = llc_rsp_in_data_coh_msg;
      assign llc_rsp_in_i.addr    = llc_rsp_in_data_addr;
      assign llc_rsp_in_i.line    = llc_rsp_in_data_line;
      assign llc_rsp_in_i.req_id  = llc_rsp_in_data_req_id;
  
      //llc mem rsp 
      input line_t llc_mem_rsp_data_line;
      input logic llc_mem_rsp_valid;
      output logic llc_mem_rsp_ready;
      
      llc_mem_rsp_t llc_mem_rsp_i();
      assign llc_mem_rsp_i.line = llc_mem_rsp_data_line;
      
      //llc rst tb
      input logic llc_rst_tb_valid;
      input logic llc_rst_tb_data;
      output logic llc_rst_tb_ready;
      
      logic llc_rst_tb_i; 
      assign llc_rst_tb_i = llc_rst_tb_data;
 
      //llc rsp out
      input logic llc_rsp_out_ready;
      output logic llc_rsp_out_valid;
      output coh_msg_t llc_rsp_out_data_coh_msg;
      output line_addr_t llc_rsp_out_data_addr;
      output line_t llc_rsp_out_data_line;
      output invack_cnt_t llc_rsp_out_data_invack_cnt;
      output cache_id_t llc_rsp_out_data_req_id;
      output cache_id_t llc_rsp_out_data_dest_id;
      output word_offset_t llc_rsp_out_data_word_offset;

      llc_rsp_out_t llc_rsp_out();
      assign llc_rsp_out_data_coh_msg = llc_rsp_out.coh_msg;
      assign llc_rsp_out_data_addr = llc_rsp_out.addr;
      assign llc_rsp_out_data_line = llc_rsp_out.line;
      assign llc_rsp_out_data_invack_cnt = llc_rsp_out.invack_cnt;
      assign llc_rsp_out_data_req_id = llc_rsp_out.req_id;
      assign llc_rsp_out_data_dest_id = llc_rsp_out.dest_id;
      assign llc_rsp_out_data_word_offset = llc_rsp_out.word_offset;
        
      //llc dma rsp out
      input logic llc_dma_rsp_out_ready;
      output logic llc_dma_rsp_out_valid;
      output coh_msg_t llc_dma_rsp_out_data_coh_msg;
      output line_addr_t  llc_dma_rsp_out_data_addr;
      output line_t llc_dma_rsp_out_data_line;
      output invack_cnt_t llc_dma_rsp_out_data_invack_cnt;
      output cache_id_t llc_dma_rsp_out_data_req_id;
      output cache_id_t llc_dma_rsp_out_data_dest_id;
      output word_offset_t llc_dma_rsp_out_data_word_offset;

      llc_rsp_out_t llc_dma_rsp_out();
      assign llc_dma_rsp_out_data_coh_msg = llc_dma_rsp_out.coh_msg;
      assign llc_dma_rsp_out_data_addr = llc_dma_rsp_out.addr;
      assign llc_dma_rsp_out_data_line = llc_dma_rsp_out.line;
      assign llc_dma_rsp_out_data_invack_cnt = llc_dma_rsp_out.invack_cnt;
      assign llc_dma_rsp_out_data_req_id = llc_dma_rsp_out.req_id;
      assign llc_dma_rsp_out_data_dest_id = llc_dma_rsp_out.dest_id;
      assign llc_dma_rsp_out_data_word_offset = llc_dma_rsp_out.word_offset;
     
      //llc fwd out 
      input logic llc_fwd_out_ready;
      output logic llc_fwd_out_valid;
      output mix_msg_t llc_fwd_out_data_coh_msg;
      output line_addr_t llc_fwd_out_data_addr;
      output cache_id_t llc_fwd_out_data_req_id;
      output cache_id_t llc_fwd_out_data_dest_id;
      
      llc_fwd_out_t llc_fwd_out(); 
      assign llc_fwd_out_data_coh_msg = llc_fwd_out.coh_msg;
      assign llc_fwd_out_data_addr = llc_fwd_out.addr;
      assign llc_fwd_out_data_req_id = llc_fwd_out.req_id;
      assign llc_fwd_out_data_dest_id = llc_fwd_out.dest_id;

      //llc mem req
      input logic llc_mem_req_ready;
      output logic llc_mem_req_valid;
      output logic llc_mem_req_data_hwrite;
      output hsize_t llc_mem_req_data_hsize;
      output logic[1:0] llc_mem_req_data_hprot;
      output line_addr_t llc_mem_req_data_addr;
      output line_t llc_mem_req_data_line;

      llc_mem_req_t llc_mem_req();
      assign llc_mem_req_data_hwrite = llc_mem_req.hwrite;
      assign llc_mem_req_data_hsize = llc_mem_req.hsize;
      assign llc_mem_req_data_hprot = {1'b0, llc_mem_req.hprot};
      assign llc_mem_req_data_addr = llc_mem_req.addr;
      assign llc_mem_req_data_line = llc_mem_req.line;
      
      //llc rst tb done  
      input logic llc_rst_tb_done_ready;
      output logic llc_rst_tb_done_valid;
      output logic llc_rst_tb_done_data;
      
      logic llc_rst_tb_done;
      assign llc_rst_tb_done_data = llc_rst_tb_done; 

      //llc  stats
`ifdef STATS_ENABLE
      input logic llc_stats_ready;
      output logic llc_stats_valid;
      output logic llc_stats_data;
      
      logic llc_stats;
      assign llc_stats_data = llc_stats;
`endif

      llc_core llc_core_u(.*);

endmodule

