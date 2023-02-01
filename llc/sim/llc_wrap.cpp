// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

#include "llc_wrap.h"

void llc_wrapper_conv::thread_llc_req_in_data_conv(){
    llc_req_in_t<CACHE_ID_WIDTH> tmp = llc_req_in.data.read();
    llc_req_in_data_conv_coh_msg = tmp.coh_msg;
    llc_req_in_data_conv_hprot = tmp.hprot;
    llc_req_in_data_conv_addr = tmp.addr;
    llc_req_in_data_conv_line = tmp.line;
    llc_req_in_data_conv_req_id = tmp.req_id;
    llc_req_in_data_conv_word_offset = tmp.word_offset;
    llc_req_in_data_conv_valid_words = tmp.valid_words;
}

void llc_wrapper_conv::thread_llc_dma_req_in_data_conv(){
    llc_req_in_t<LLC_COH_DEV_ID_WIDTH> tmp = llc_dma_req_in.data.read();
    llc_dma_req_in_data_conv_coh_msg = tmp.coh_msg;
    llc_dma_req_in_data_conv_hprot = tmp.hprot;
    llc_dma_req_in_data_conv_addr = tmp.addr;
    llc_dma_req_in_data_conv_line = tmp.line;
    llc_dma_req_in_data_conv_req_id = tmp.req_id;
    llc_dma_req_in_data_conv_word_offset = tmp.word_offset;
    llc_dma_req_in_data_conv_valid_words = tmp.valid_words;
}

void llc_wrapper_conv::thread_llc_rsp_in_data_conv(){
    llc_rsp_in_t tmp = llc_rsp_in.data.read();
    llc_rsp_in_data_conv_coh_msg = tmp.coh_msg;
    llc_rsp_in_data_conv_addr = tmp.addr;
    llc_rsp_in_data_conv_line = tmp.line;
    llc_rsp_in_data_conv_req_id = tmp.req_id;
}

void llc_wrapper_conv::thread_llc_mem_rsp_data_conv(){
    llc_mem_rsp_t tmp = llc_mem_rsp.data.read();
    llc_mem_rsp_data_conv_line = tmp.line;
}

void llc_wrapper_conv::thread_llc_rst_tb_data_conv(){
    llc_rst_tb_data_conv = llc_rst_tb.data.read();
}

void llc_wrapper_conv::thread_llc_rsp_out_data_conv(){
    llc_rsp_out_t<CACHE_ID_WIDTH> tmp;
    tmp.coh_msg = llc_rsp_out_data_conv_coh_msg.read();
    tmp.addr = llc_rsp_out_data_conv_addr.read();
    tmp.line = llc_rsp_out_data_conv_line.read();
    tmp.invack_cnt = llc_rsp_out_data_conv_invack_cnt.read();
    tmp.req_id = llc_rsp_out_data_conv_req_id.read();
    tmp.dest_id = llc_rsp_out_data_conv_dest_id.read();
    tmp.word_offset = llc_rsp_out_data_conv_word_offset.read();
    llc_rsp_out.data.write(tmp);
}

void llc_wrapper_conv::thread_llc_dma_rsp_out_data_conv(){
    llc_rsp_out_t<LLC_COH_DEV_ID_WIDTH> tmp;
    tmp.coh_msg = llc_dma_rsp_out_data_conv_coh_msg.read();
    tmp.addr = llc_dma_rsp_out_data_conv_addr.read();
    tmp.line = llc_dma_rsp_out_data_conv_line.read();
    tmp.invack_cnt = llc_dma_rsp_out_data_conv_invack_cnt.read();
    tmp.req_id = llc_dma_rsp_out_data_conv_req_id.read();
    tmp.dest_id = llc_dma_rsp_out_data_conv_dest_id.read();
    tmp.word_offset = llc_dma_rsp_out_data_conv_word_offset.read();
    llc_dma_rsp_out.data.write(tmp);
}

void llc_wrapper_conv::thread_llc_fwd_out_data_conv(){
    llc_fwd_out_t tmp; 
    tmp.coh_msg = llc_fwd_out_data_conv_coh_msg.read();
    tmp.addr = llc_fwd_out_data_conv_addr.read();
    tmp.req_id = llc_fwd_out_data_conv_req_id.read();
    tmp.dest_id = llc_fwd_out_data_conv_dest_id.read();
    llc_fwd_out.data.write(tmp);
}

void llc_wrapper_conv::thread_llc_mem_req_data_conv(){
    llc_mem_req_t tmp;
    tmp.hwrite = llc_mem_req_data_conv_hwrite.read();
    tmp.hsize = llc_mem_req_data_conv_hsize.read();
    tmp.hprot = llc_mem_req_data_conv_hprot.read();
    tmp.addr = llc_mem_req_data_conv_addr.read();
    tmp.line = llc_mem_req_data_conv_line.read();
    llc_mem_req.data.write(tmp);
}

void llc_wrapper_conv::thread_llc_rst_tb_done_data_conv(){
    bool tmp = llc_rst_tb_done_data_conv.read();
    llc_rst_tb_done.data.write(tmp);
}

#ifdef STATS_ENABLE
void llc_wrapper_conv::thread_llc_stats_data_conv(){
    bool tmp = llc_stats_data_conv.read();
    llc_stats.data.write(tmp);
}
#endif

NCSC_MODULE_EXPORT(llc_wrapper_conv) 
