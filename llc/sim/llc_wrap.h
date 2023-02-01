// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

#ifndef __RTL_WRAPPER__
#define __RTL_WRAPPER__

#include "systemc.h"
#include <cynw_flex_channels.h>
#include "cache_types.hpp"
#include "cache_consts.hpp"

class llc_rtl_top : public ncsc_foreign_module 
{
public:
    sc_in<bool> clk;
    sc_in<bool> rst;

    //llc req in
    sc_in<mix_msg_t> llc_req_in_data_coh_msg;
    sc_in<hprot_t> llc_req_in_data_hprot;
    sc_in<line_addr_t> llc_req_in_data_addr;
    sc_in<line_t> llc_req_in_data_line;
    sc_in<cache_id_t> llc_req_in_data_req_id;
    sc_in<word_offset_t> llc_req_in_data_word_offset;
    sc_in<word_offset_t> llc_req_in_data_valid_words;
    sc_in<bool> llc_req_in_valid;
    sc_out<bool> llc_req_in_ready;

    //llc dma req in 
    sc_in<mix_msg_t> llc_dma_req_in_data_coh_msg;
    sc_in<hprot_t> llc_dma_req_in_data_hprot;
    sc_in<line_addr_t> llc_dma_req_in_data_addr;
    sc_in<line_t> llc_dma_req_in_data_line;
    sc_in<llc_coh_dev_id_t> llc_dma_req_in_data_req_id;
    sc_in<word_offset_t> llc_dma_req_in_data_word_offset;
    sc_in<word_offset_t> llc_dma_req_in_data_valid_words;
    sc_in<bool> llc_dma_req_in_valid;
    sc_out<bool> llc_dma_req_in_ready;
    
    //llc rsp
    sc_in<coh_msg_t> llc_rsp_in_data_coh_msg;
    sc_in<line_addr_t> llc_rsp_in_data_addr;
    sc_in<line_t> llc_rsp_in_data_line;
    sc_in<cache_id_t> llc_rsp_in_data_req_id;
    sc_in<bool> llc_rsp_in_valid;
    sc_out<bool> llc_rsp_in_ready;

    //llc mem rsp
    sc_in<line_t> llc_mem_rsp_data_line;
    sc_in<bool> llc_mem_rsp_valid;
    sc_out<bool> llc_mem_rsp_ready;

    //llc rst tb
    sc_in<bool> llc_rst_tb_valid;
    sc_in<bool> llc_rst_tb_data;
    sc_out<bool> llc_rst_tb_ready;

    //llc rsp put
    sc_in<bool> llc_rsp_out_ready;
    sc_out<bool> llc_rsp_out_valid;
    sc_out<coh_msg_t> llc_rsp_out_data_coh_msg;
    sc_out<line_addr_t> llc_rsp_out_data_addr;
    sc_out<line_t> llc_rsp_out_data_line;
    sc_out<invack_cnt_t> llc_rsp_out_data_invack_cnt;
    sc_out<cache_id_t> llc_rsp_out_data_req_id;
    sc_out<cache_id_t> llc_rsp_out_data_dest_id;
    sc_out<word_offset_t> llc_rsp_out_data_word_offset;

    //llc dma rsp out
    sc_in<bool> llc_dma_rsp_out_ready;
    sc_out<bool> llc_dma_rsp_out_valid;
    sc_out<coh_msg_t> llc_dma_rsp_out_data_coh_msg;
    sc_out<line_addr_t > llc_dma_rsp_out_data_addr;
    sc_out<line_t> llc_dma_rsp_out_data_line;
    sc_out<invack_cnt_t> llc_dma_rsp_out_data_invack_cnt;
    sc_out<llc_coh_dev_id_t> llc_dma_rsp_out_data_req_id;
    sc_out<cache_id_t> llc_dma_rsp_out_data_dest_id;
    sc_out<word_offset_t> llc_dma_rsp_out_data_word_offset;

    //llc fwd out
    sc_in<bool> llc_fwd_out_ready;
    sc_out<bool> llc_fwd_out_valid;
    sc_out<mix_msg_t> llc_fwd_out_data_coh_msg;
    sc_out<line_addr_t> llc_fwd_out_data_addr;
    sc_out<cache_id_t> llc_fwd_out_data_req_id;
    sc_out<cache_id_t> llc_fwd_out_data_dest_id;

    //llc mem req
    sc_in<bool> llc_mem_req_ready;
    sc_out<bool> llc_mem_req_valid;
    sc_out<bool> llc_mem_req_data_hwrite;
    sc_out<hsize_t> llc_mem_req_data_hsize;
    sc_out<hprot_t> llc_mem_req_data_hprot;
    sc_out<line_addr_t> llc_mem_req_data_addr;
    sc_out<line_t> llc_mem_req_data_line;

    //llc rst tb done
    sc_in<bool> llc_rst_tb_done_ready;
    sc_out<bool> llc_rst_tb_done_valid;
    sc_out<bool> llc_rst_tb_done_data;

#ifdef STATS_ENABLE
    sc_in<bool> llc_stats_ready;
    sc_out<bool> llc_stats_valid;
    sc_out<bool> llc_stats_data;
#endif

    llc_rtl_top(sc_module_name name) 
        : ncsc_foreign_module(name)
        , clk("clk")
        , rst("rst")
        , llc_req_in_valid("llc_req_in_valid")
        , llc_req_in_data_coh_msg("llc_req_in_data_coh_msg")
        , llc_req_in_data_hprot("llc_req_in_data_hprot")
        , llc_req_in_data_addr("llc_req_in_data_addr")
        , llc_req_in_data_line("llc_req_in_data_line")
        , llc_req_in_data_req_id("llc_req_in_data_req_id")
        , llc_req_in_data_word_offset("llc_req_in_data_word_offset")
        , llc_req_in_data_valid_words("llc_req_in_data_valid_words")
        , llc_req_in_ready("llc_req_in_ready")
        , llc_dma_req_in_valid("llc_dma_req_in_valid")
        , llc_dma_req_in_data_coh_msg("llc_dma_req_in_data_coh_msg")
        , llc_dma_req_in_data_hprot("llc_dma_req_in_data_hprot")
        , llc_dma_req_in_data_addr("llc_dma_req_in_data_addr")
        , llc_dma_req_in_data_line("llc_dma_req_in_data_line")
        , llc_dma_req_in_data_req_id("llc_dma_req_in_data_req_id")
        , llc_dma_req_in_data_word_offset("llc_dma_req_in_data_word_offset")
        , llc_dma_req_in_data_valid_words("llc_dma_req_in_data_valid_words")
        , llc_dma_req_in_ready("llc_dma_req_in_ready")
        , llc_rsp_in_valid("llc_rsp_in_valid")
        , llc_rsp_in_data_coh_msg("llc_rsp_in_data_coh_msg")
        , llc_rsp_in_data_addr("llc_rsp_in_data_addr")
        , llc_rsp_in_data_line("llc_rsp_in_data_line")
        , llc_rsp_in_data_req_id("llc_rsp_in_data_req_id")
        , llc_rsp_in_ready("llc_rsp_in_ready")
        , llc_mem_rsp_valid("llc_mem_rsp_valid")
        , llc_mem_rsp_data_line("llc_mem_rsp_data_line")
        , llc_mem_rsp_ready("llc_mem_rsp_ready")
        , llc_rst_tb_valid("llc_rst_tb_valid")
        , llc_rst_tb_data("llc_rst_tb_data")
        , llc_rst_tb_ready("llc_rst_tb_ready")
        , llc_rsp_out_valid("llc_rsp_out_valid")
        , llc_rsp_out_data_coh_msg("llc_rsp_out_data_coh_msg")
        , llc_rsp_out_data_addr("llc_rsp_out_data_addr")
        , llc_rsp_out_data_line("llc_rsp_out_data_line")
        , llc_rsp_out_data_invack_cnt("llc_rsp_out_data_invack_cnt")
        , llc_rsp_out_data_req_id("llc_rsp_out_data_req_id")
        , llc_rsp_out_data_dest_id("llc_rsp_out_data_dest_id")
        , llc_rsp_out_data_word_offset("llc_rsp_out_data_word_offset")
        , llc_rsp_out_ready("llc_rsp_out_ready")
        , llc_dma_rsp_out_valid("llc_dma_rsp_out_valid")
        , llc_dma_rsp_out_data_coh_msg("llc_dma_rsp_out_data_coh_msg")
        , llc_dma_rsp_out_data_addr("llc_dma_rsp_out_data_addr")
        , llc_dma_rsp_out_data_line("llc_dma_rsp_out_data_line")
        , llc_dma_rsp_out_data_invack_cnt("llc_dma_rsp_out_data_invack_cnt")
        , llc_dma_rsp_out_data_req_id("llc_dma_rsp_out_data_req_id")
        , llc_dma_rsp_out_data_dest_id("llc_dma_rsp_out_data_dest_id")
        , llc_dma_rsp_out_data_word_offset("llc_dma_rsp_out_data_word_offset")
        , llc_dma_rsp_out_ready("llc_dma_rsp_out_ready")
        , llc_fwd_out_valid("llc_fwd_out_valid")
        , llc_fwd_out_data_coh_msg("llc_fwd_out_data_coh_msg")
        , llc_fwd_out_data_addr("llc_fwd_out_data_addr")
        , llc_fwd_out_data_req_id("llc_fwd_out_data_req_id")
        , llc_fwd_out_data_dest_id("llc_fwd_out_data_dest_id")
        , llc_fwd_out_ready("llc_fwd_out_ready")
        , llc_mem_req_valid("llc_mem_req_valid")
        , llc_mem_req_data_hwrite("llc_mem_req_data_hwrite")
        , llc_mem_req_data_hsize("llc_mem_req_data_hsize")
        , llc_mem_req_data_hprot("llc_mem_req_data_hprot")
        , llc_mem_req_data_addr("llc_mem_req_data_addr")
        , llc_mem_req_data_line("llc_mem_req_data_line")
        , llc_mem_req_ready("llc_mem_req_ready")
        , llc_rst_tb_done_valid("llc_rst_tb_done_valid")
        , llc_rst_tb_done_data("llc_rst_tb_done_data")
        , llc_rst_tb_done_ready("llc_rst_tb_done_ready")
#ifdef STATS_ENABLE
        , llc_stats_valid ("llc_stats_valid")
        , llc_stats_data("llc_stats_data")
        , llc_stats_ready("llc_stats_ready")
#endif
{}

        const char* hdl_name() const { return "llc_rtl_top"; }
};

class llc_wrapper_conv : public sc_module 
{
public: 
    sc_in<bool> clk;
    sc_in<bool> rst;

    cynw::cynw_get_port_base<llc_req_in_t<CACHE_ID_WIDTH> > llc_req_in;
    cynw::cynw_get_port_base<llc_req_in_t<LLC_COH_DEV_ID_WIDTH> > llc_dma_req_in;
    cynw::cynw_get_port_base<llc_rsp_in_t> llc_rsp_in;
    cynw::cynw_get_port_base<llc_mem_rsp_t> llc_mem_rsp;
    cynw::cynw_get_port_base<bool> llc_rst_tb;
    
    cynw::cynw_put_port_base<llc_rsp_out_t<CACHE_ID_WIDTH> > llc_rsp_out;
    cynw::cynw_put_port_base<llc_rsp_out_t<LLC_COH_DEV_ID_WIDTH> > llc_dma_rsp_out;
    cynw::cynw_put_port_base<llc_fwd_out_t> llc_fwd_out;
    cynw::cynw_put_port_base<llc_mem_req_t> llc_mem_req;
    cynw::cynw_put_port_base<bool> llc_rst_tb_done;

#ifdef STATS_ENABLE
    cynw::cynw_put_port_base<bool> llc_stats;
#endif
   
    SC_CTOR(llc_wrapper_conv)
        : clk("clk")
        , rst("rst")
        , llc_req_in("llc_req_in")
        , llc_dma_req_in("llc_dma_req_in")
        , llc_rsp_in("llc_rsp_in")
        , llc_mem_rsp("llc_mem_rsp")
        , llc_rst_tb("llc_rst_tb")
        , llc_rsp_out("llc_rsp_out")
        , llc_dma_rsp_out("llc_dma_rsp_out")
        , llc_fwd_out("llc_fwd_out")
        , llc_mem_req("llc_mem_req")
        , llc_rst_tb_done("llc_rst_tb_done")
        , llc_req_in_data_conv_coh_msg("llc_req_in_data_conv_coh_msg")
        , llc_req_in_data_conv_hprot("llc_req_in_data_conv_hprot")
        , llc_req_in_data_conv_addr("llc_req_in_data_conv_addr")
        , llc_req_in_data_conv_line("llc_req_in_data_conv_line")
        , llc_req_in_data_conv_req_id("llc_req_in_data_conv_req_id")
        , llc_req_in_data_conv_word_offset("llc_req_in_data_conv_word_offset")
        , llc_req_in_data_conv_valid_words("llc_req_in_data_conv_valid_words")
        , llc_dma_req_in_data_conv_coh_msg("llc_dma_req_in_data_conv_coh_msg")
        , llc_dma_req_in_data_conv_hprot("llc_dma_req_in_data_conv_hprot")
        , llc_dma_req_in_data_conv_addr("llc_dma_req_in_data_conv_addr")
        , llc_dma_req_in_data_conv_line("llc_dma_req_in_data_conv_line")
        , llc_dma_req_in_data_conv_req_id("llc_dma_req_in_data_conv_req_id")
        , llc_dma_req_in_data_conv_word_offset("llc_dma_req_in_data_conv_word_offset")
        , llc_dma_req_in_data_conv_valid_words("llc_dma_req_in_data_conv_valid_words")
        , llc_rsp_in_data_conv_coh_msg("llc_rsp_in_data_conv_coh_msg")
        , llc_rsp_in_data_conv_addr("llc_rsp_in_data_conv_addr")
        , llc_rsp_in_data_conv_line("llc_rsp_in_data_conv_line")
        , llc_rsp_in_data_conv_req_id("llc_rsp_in_data_conv_req_id")
        , llc_mem_rsp_data_conv_line("llc_mem_rsp_data_conv_line")
        , llc_rst_tb_data_conv("llc_rst_tb_data_conv")
        , llc_rsp_out_data_conv_coh_msg("llc_rsp_out_data_conv_coh_msg")
        , llc_rsp_out_data_conv_addr("llc_rsp_out_data_conv_addr")
        , llc_rsp_out_data_conv_line("llc_rsp_out_data_conv_line")
        , llc_rsp_out_data_conv_invack_cnt("llc_rsp_out_data_conv_invack_cnt")
        , llc_rsp_out_data_conv_req_id("llc_rsp_out_data_conv_req_id")
        , llc_rsp_out_data_conv_dest_id("llc_rsp_out_data_conv_dest_id")
        , llc_rsp_out_data_conv_word_offset("llc_rsp_out_data_conv_word_offset")
        , llc_dma_rsp_out_data_conv_coh_msg("llc_dma_rsp_out_data_conv_coh_msg")
        , llc_dma_rsp_out_data_conv_addr("llc_dma_rsp_out_data_conv_addr")
        , llc_dma_rsp_out_data_conv_line("llc_dma_rsp_out_data_conv_line")
        , llc_dma_rsp_out_data_conv_invack_cnt("llc_dma_rsp_out_data_conv_invack_cnt")
        , llc_dma_rsp_out_data_conv_req_id("llc_dma_rsp_out_data_conv_req_id")
        , llc_dma_rsp_out_data_conv_dest_id("llc_dma_rsp_out_data_conv_dest_id")
        , llc_dma_rsp_out_data_conv_word_offset("llc_dma_rsp_out_data_conv_word_offset")
        , llc_fwd_out_data_conv_coh_msg("llc_fwd_out_data_conv_coh_msg")
        , llc_fwd_out_data_conv_addr("llc_fwd_out_data_conv_addr")
        , llc_fwd_out_data_conv_req_id("llc_fwd_out_data_conv_req_id")
        , llc_fwd_out_data_conv_dest_id("llc_fwd_out_data_conv_dest_id")
        , llc_mem_req_data_conv_hwrite("llc_mem_req_data_conv_hwrite")
        , llc_mem_req_data_conv_hsize("llc_mem_req_data_conv_hsize")
        , llc_mem_req_data_conv_hprot("llc_mem_req_data_conv_hprot")
        , llc_mem_req_data_conv_addr("llc_mem_req_data_conv_addr")
        , llc_mem_req_data_conv_line("llc_mem_req_data_conv_line")
        , llc_rst_tb_done_data_conv("llc_rst_tb_done_data_conv")
#ifdef STATS_ENABLE
        , llc_stats_data_conv("llc_stats_data_conv")
#endif
        , cosim("cosim") 
    {
        SC_METHOD(thread_llc_req_in_data_conv);
        sensitive << llc_req_in.data;
        SC_METHOD(thread_llc_dma_req_in_data_conv);
        sensitive << llc_dma_req_in.data;
        SC_METHOD(thread_llc_rsp_in_data_conv);
        sensitive << llc_rsp_in.data;
        SC_METHOD(thread_llc_mem_rsp_data_conv);
        sensitive << llc_mem_rsp.data;
        SC_METHOD(thread_llc_rst_tb_data_conv);
        sensitive << llc_rst_tb.data;

        SC_METHOD(thread_llc_rsp_out_data_conv);
        sensitive << llc_rsp_out_data_conv_coh_msg << llc_rsp_out_data_conv_addr << llc_rsp_out_data_conv_line << llc_rsp_out_data_conv_invack_cnt 
                  << llc_rsp_out_data_conv_req_id << llc_rsp_out_data_conv_dest_id << llc_rsp_out_data_conv_word_offset;
        SC_METHOD(thread_llc_dma_rsp_out_data_conv);
        sensitive << llc_dma_rsp_out_data_conv_coh_msg << llc_dma_rsp_out_data_conv_addr << llc_dma_rsp_out_data_conv_line << llc_dma_rsp_out_data_conv_invack_cnt 
                  << llc_dma_rsp_out_data_conv_req_id << llc_dma_rsp_out_data_conv_dest_id << llc_dma_rsp_out_data_conv_word_offset;
        SC_METHOD(thread_llc_fwd_out_data_conv);
        sensitive << llc_fwd_out_data_conv_coh_msg << llc_fwd_out_data_conv_addr << llc_fwd_out_data_conv_req_id << llc_fwd_out_data_conv_dest_id; 
        SC_METHOD(thread_llc_mem_req_data_conv);
        sensitive << llc_mem_req_data_conv_hwrite << llc_mem_req_data_conv_hsize << llc_mem_req_data_conv_hprot << llc_mem_req_data_conv_addr << llc_mem_req_data_conv_line; 
        SC_METHOD(thread_llc_rst_tb_done_data_conv);
        sensitive << llc_rst_tb_done_data_conv; 
#ifdef STATS_ENABLE
        SC_METHOD(thread_llc_stats_data_conv);
        sensitive << llc_stats_data_conv;
#endif

        cosim.clk(clk);
        cosim.rst(rst);
        cosim.llc_req_in_valid(llc_req_in.valid);
        cosim.llc_req_in_data_coh_msg(llc_req_in_data_conv_coh_msg);
        cosim.llc_req_in_data_hprot(llc_req_in_data_conv_hprot);
        cosim.llc_req_in_data_addr(llc_req_in_data_conv_addr);
        cosim.llc_req_in_data_line(llc_req_in_data_conv_line);
        cosim.llc_req_in_data_req_id(llc_req_in_data_conv_req_id);
        cosim.llc_req_in_data_word_offset(llc_req_in_data_conv_word_offset);
        cosim.llc_req_in_data_valid_words(llc_req_in_data_conv_valid_words);
        cosim.llc_req_in_ready(llc_req_in.ready);
        cosim.llc_dma_req_in_valid(llc_dma_req_in.valid);
        cosim.llc_dma_req_in_data_coh_msg(llc_dma_req_in_data_conv_coh_msg);
        cosim.llc_dma_req_in_data_hprot(llc_dma_req_in_data_conv_hprot);
        cosim.llc_dma_req_in_data_addr(llc_dma_req_in_data_conv_addr);
        cosim.llc_dma_req_in_data_line(llc_dma_req_in_data_conv_line);
        cosim.llc_dma_req_in_data_req_id(llc_dma_req_in_data_conv_req_id);
        cosim.llc_dma_req_in_data_word_offset(llc_dma_req_in_data_conv_word_offset);
        cosim.llc_dma_req_in_data_valid_words(llc_dma_req_in_data_conv_valid_words);
        cosim.llc_dma_req_in_ready(llc_dma_req_in.ready);
        cosim.llc_rsp_in_valid(llc_rsp_in.valid);
        cosim.llc_rsp_in_data_coh_msg(llc_rsp_in_data_conv_coh_msg);
        cosim.llc_rsp_in_data_addr(llc_rsp_in_data_conv_addr);
        cosim.llc_rsp_in_data_line(llc_rsp_in_data_conv_line);
        cosim.llc_rsp_in_data_req_id(llc_rsp_in_data_conv_req_id);
        cosim.llc_rsp_in_ready(llc_rsp_in.ready);
        cosim.llc_mem_rsp_valid(llc_mem_rsp.valid);
        cosim.llc_mem_rsp_data_line(llc_mem_rsp_data_conv_line);
        cosim.llc_mem_rsp_ready(llc_mem_rsp.ready);
        cosim.llc_rst_tb_valid(llc_rst_tb.valid);
        cosim.llc_rst_tb_data(llc_rst_tb_data_conv);
        cosim.llc_rst_tb_ready(llc_rst_tb.ready);
        cosim.llc_rsp_out_valid(llc_rsp_out.valid);
        cosim.llc_rsp_out_data_coh_msg(llc_rsp_out_data_conv_coh_msg);
        cosim.llc_rsp_out_data_addr(llc_rsp_out_data_conv_addr);
        cosim.llc_rsp_out_data_line(llc_rsp_out_data_conv_line);
        cosim.llc_rsp_out_data_invack_cnt(llc_rsp_out_data_conv_invack_cnt);
        cosim.llc_rsp_out_data_req_id(llc_rsp_out_data_conv_req_id);
        cosim.llc_rsp_out_data_dest_id(llc_rsp_out_data_conv_dest_id);
        cosim.llc_rsp_out_data_word_offset(llc_rsp_out_data_conv_word_offset);
        cosim.llc_rsp_out_ready(llc_rsp_out.ready);
        cosim.llc_dma_rsp_out_valid(llc_dma_rsp_out.valid);
        cosim.llc_dma_rsp_out_data_coh_msg(llc_dma_rsp_out_data_conv_coh_msg);
        cosim.llc_dma_rsp_out_data_addr(llc_dma_rsp_out_data_conv_addr);
        cosim.llc_dma_rsp_out_data_line(llc_dma_rsp_out_data_conv_line);
        cosim.llc_dma_rsp_out_data_invack_cnt(llc_dma_rsp_out_data_conv_invack_cnt);
        cosim.llc_dma_rsp_out_data_req_id(llc_dma_rsp_out_data_conv_req_id);
        cosim.llc_dma_rsp_out_data_dest_id(llc_dma_rsp_out_data_conv_dest_id);
        cosim.llc_dma_rsp_out_data_word_offset(llc_dma_rsp_out_data_conv_word_offset);
        cosim.llc_dma_rsp_out_ready(llc_dma_rsp_out.ready);
        cosim.llc_fwd_out_valid(llc_fwd_out.valid);
        cosim.llc_fwd_out_data_coh_msg(llc_fwd_out_data_conv_coh_msg);
        cosim.llc_fwd_out_data_addr(llc_fwd_out_data_conv_addr);
        cosim.llc_fwd_out_data_req_id(llc_fwd_out_data_conv_req_id);
        cosim.llc_fwd_out_data_dest_id(llc_fwd_out_data_conv_dest_id);
        cosim.llc_fwd_out_ready(llc_fwd_out.ready);
        cosim.llc_mem_req_valid(llc_mem_req.valid);
        cosim.llc_mem_req_data_hwrite(llc_mem_req_data_conv_hwrite);
        cosim.llc_mem_req_data_hsize(llc_mem_req_data_conv_hsize);
        cosim.llc_mem_req_data_hprot(llc_mem_req_data_conv_hprot);
        cosim.llc_mem_req_data_addr(llc_mem_req_data_conv_addr);
        cosim.llc_mem_req_data_line(llc_mem_req_data_conv_line);
        cosim.llc_mem_req_ready(llc_mem_req.ready);
        cosim.llc_rst_tb_done_valid(llc_rst_tb_done.valid);
        cosim.llc_rst_tb_done_data(llc_rst_tb_done_data_conv);
        cosim.llc_rst_tb_done_ready(llc_rst_tb_done.ready);
#ifdef STATS_ENABLE
        cosim.llc_stats_valid (llc_stats.valid);
        cosim.llc_stats_data(llc_stats_data_conv);
        cosim.llc_stats_ready(llc_stats.ready);
#endif

    }

    //llc req in
    sc_signal<mix_msg_t> llc_req_in_data_conv_coh_msg;
    sc_signal<hprot_t> llc_req_in_data_conv_hprot;
    sc_signal<line_addr_t> llc_req_in_data_conv_addr;
    sc_signal<line_t> llc_req_in_data_conv_line;
    sc_signal<cache_id_t> llc_req_in_data_conv_req_id;
    sc_signal<word_offset_t> llc_req_in_data_conv_word_offset;
    sc_signal<word_offset_t> llc_req_in_data_conv_valid_words;

    //llc dma req in 
    sc_signal<mix_msg_t> llc_dma_req_in_data_conv_coh_msg;
    sc_signal<hprot_t> llc_dma_req_in_data_conv_hprot;
    sc_signal<line_addr_t> llc_dma_req_in_data_conv_addr;
    sc_signal<line_t> llc_dma_req_in_data_conv_line;
    sc_signal<llc_coh_dev_id_t> llc_dma_req_in_data_conv_req_id;
    sc_signal<word_offset_t> llc_dma_req_in_data_conv_word_offset;
    sc_signal<word_offset_t> llc_dma_req_in_data_conv_valid_words;
    
    //llc rsp
    sc_signal<coh_msg_t> llc_rsp_in_data_conv_coh_msg;
    sc_signal<line_addr_t> llc_rsp_in_data_conv_addr;
    sc_signal<line_t> llc_rsp_in_data_conv_line;
    sc_signal<cache_id_t> llc_rsp_in_data_conv_req_id;

    //llc mem rsp
    sc_signal<line_t> llc_mem_rsp_data_conv_line;

    //llc rst tb
    sc_signal<bool> llc_rst_tb_data_conv;

    //llc rsp put
    sc_signal<coh_msg_t> llc_rsp_out_data_conv_coh_msg;
    sc_signal<line_addr_t> llc_rsp_out_data_conv_addr;
    sc_signal<line_t> llc_rsp_out_data_conv_line;
    sc_signal<invack_cnt_t> llc_rsp_out_data_conv_invack_cnt;
    sc_signal<cache_id_t> llc_rsp_out_data_conv_req_id;
    sc_signal<cache_id_t> llc_rsp_out_data_conv_dest_id;
    sc_signal<word_offset_t> llc_rsp_out_data_conv_word_offset;

    //llc dma rsp out
    sc_signal<coh_msg_t> llc_dma_rsp_out_data_conv_coh_msg;
    sc_signal<line_addr_t > llc_dma_rsp_out_data_conv_addr;
    sc_signal<line_t> llc_dma_rsp_out_data_conv_line;
    sc_signal<invack_cnt_t> llc_dma_rsp_out_data_conv_invack_cnt;
    sc_signal<llc_coh_dev_id_t> llc_dma_rsp_out_data_conv_req_id;
    sc_signal<cache_id_t> llc_dma_rsp_out_data_conv_dest_id;
    sc_signal<word_offset_t> llc_dma_rsp_out_data_conv_word_offset;

    //llc fwd out
    sc_signal<mix_msg_t> llc_fwd_out_data_conv_coh_msg;
    sc_signal<line_addr_t> llc_fwd_out_data_conv_addr;
    sc_signal<cache_id_t> llc_fwd_out_data_conv_req_id;
    sc_signal<cache_id_t> llc_fwd_out_data_conv_dest_id;

    //llc mem req
    sc_signal<bool> llc_mem_req_data_conv_hwrite;
    sc_signal<hsize_t> llc_mem_req_data_conv_hsize;
    sc_signal<hprot_t> llc_mem_req_data_conv_hprot;
    sc_signal<line_addr_t> llc_mem_req_data_conv_addr;
    sc_signal<line_t> llc_mem_req_data_conv_line;

    //llc rst tb done
    sc_signal<bool> llc_rst_tb_done_data_conv;

#ifdef STATS_ENABLE
    sc_signal<bool> llc_stats_data_conv;
#endif


    void thread_llc_req_in_data_conv();
    void thread_llc_dma_req_in_data_conv();
    void thread_llc_rsp_in_data_conv(); 
    void thread_llc_mem_rsp_data_conv(); 
    void thread_llc_rst_tb_data_conv(); 

    void thread_llc_rsp_out_data_conv();
    void thread_llc_dma_rsp_out_data_conv();
    void thread_llc_fwd_out_data_conv();
    void thread_llc_mem_req_data_conv(); 
    void thread_llc_rst_tb_done_data_conv(); 
#ifdef STATS_ENABLE
    void thread_llc_stats_data_conv();
#endif


protected:
    llc_rtl_top cosim;

};

#endif
