// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

#ifndef __RTL_WRAPPER__
#define __RTL_WRAPPER__

#include "systemc.h"
#include <cynw_flex_channels.h>
#include "cache_types.hpp"
#include "cache_consts.hpp"

class l2_rtl_top : public ncsc_foreign_module 
{
public:
    sc_in<bool> clk;
    sc_in<bool> rst;
      
    sc_in<bool> l2_cpu_req_valid;
    sc_in<cpu_msg_t> l2_cpu_req_data_cpu_msg;
    sc_in<hsize_t> l2_cpu_req_data_hsize;
    sc_in<hprot_t> l2_cpu_req_data_hprot;
    sc_in<addr_t> l2_cpu_req_data_addr;
    sc_in<word_t> l2_cpu_req_data_word;
    sc_in<amo_t> l2_cpu_req_data_amo;
    sc_out<bool> l2_cpu_req_ready;
    
    sc_in<bool> l2_fwd_in_valid;
    sc_in<mix_msg_t> l2_fwd_in_data_coh_msg;
    sc_in<line_addr_t> l2_fwd_in_data_addr;
    sc_in<cache_id_t> l2_fwd_in_data_req_id;
    sc_out<bool> l2_fwd_in_ready;

    sc_in<bool> l2_rsp_in_valid;
    sc_in<coh_msg_t> l2_rsp_in_data_coh_msg;
    sc_in<line_addr_t> l2_rsp_in_data_addr;
    sc_in<line_t> l2_rsp_in_data_line;
    sc_in<invack_cnt_t> l2_rsp_in_data_invack_cnt;
    sc_out<bool> l2_rsp_in_ready;

    sc_in<bool> l2_req_out_ready;
    sc_out<bool> l2_req_out_valid;
    sc_out<coh_msg_t> l2_req_out_data_coh_msg;
    sc_out<hprot_t> l2_req_out_data_hprot;
    sc_out<line_addr_t> l2_req_out_data_addr;
    sc_out<line_t> l2_req_out_data_line;
    
    sc_in<bool> l2_rsp_out_ready;
    sc_out<bool> l2_rsp_out_valid;
    sc_out<coh_msg_t> l2_rsp_out_data_coh_msg;
    sc_out<cache_id_t> l2_rsp_out_data_req_id;
    sc_out<sc_uint<2> > l2_rsp_out_data_to_req;
    sc_out<line_addr_t> l2_rsp_out_data_addr;
    sc_out<line_t> l2_rsp_out_data_line;
   
    sc_in<bool> l2_rd_rsp_ready;
    sc_out<bool> l2_rd_rsp_valid;
    sc_out<line_t> l2_rd_rsp_data_line;

    sc_in<bool> l2_flush_valid;
    sc_in<bool> l2_flush_data;
    sc_out<bool> l2_flush_ready;
   
    sc_in<bool> l2_inval_ready;
    sc_out<bool> l2_inval_valid;
    sc_out<l2_inval_addr_t> l2_inval_data_addr;
    sc_out<hprot_t> l2_inval_data_hprot;
    
    sc_in<bool> l2_bresp_ready;
    sc_out<bool> l2_bresp_valid;
    sc_out<bresp_t> l2_bresp_data;
 
    sc_out<bool> flush_done;

#ifdef STATS_ENABLE
    sc_in<bool> l2_stats_ready;
    sc_out<bool> l2_stats_valid;
    sc_out<bool> l2_stats_data;
#endif
     
    l2_rtl_top(sc_module_name name) 
        : ncsc_foreign_module(name)
    , clk("clk")
    , rst("rst")
    , l2_cpu_req_valid("l2_cpu_req_valid")
    , l2_cpu_req_data_cpu_msg("l2_cpu_req_data_cpu_msg")
    , l2_cpu_req_data_hsize("l2_cpu_req_data_hsize")
    , l2_cpu_req_data_hprot("l2_cpu_req_data_hprot")
    , l2_cpu_req_data_addr("l2_cpu_req_data_addr")
    , l2_cpu_req_data_word("l2_cpu_req_data_word")
    , l2_cpu_req_data_amo("l2_cpu_req_data_amo")
    , l2_cpu_req_ready("l2_cpu_req_ready")
    , l2_fwd_in_valid("l2_fwd_in_valid")
    , l2_fwd_in_data_coh_msg("l2_fwd_in_data_coh_msg")
    , l2_fwd_in_data_addr("l2_fwd_in_data_addr")
    , l2_fwd_in_data_req_id("l2_fwd_in_data_req_id")
    , l2_fwd_in_ready("l2_fwd_in_ready")
    , l2_rsp_in_valid("l2_rsp_in_valid")
    , l2_rsp_in_data_coh_msg("l2_rsp_in_data_coh_msg")
    , l2_rsp_in_data_addr("l2_rsp_in_data_addr")
    , l2_rsp_in_data_line("l2_rsp_in_data_line")
    , l2_rsp_in_data_invack_cnt("l2_rsp_in_data_invack_cnt")
    , l2_rsp_in_ready("l2_rsp_in_ready")
    , l2_req_out_ready("l2_req_out_ready")
    , l2_req_out_valid("l2_req_out_valid")
    , l2_req_out_data_coh_msg("l2_req_out_data_coh_msg")
    , l2_req_out_data_hprot("l2_req_out_data_hprot")
    , l2_req_out_data_addr("l2_req_out_data_addr")
    , l2_req_out_data_line("l2_req_out_data_line")
    , l2_rsp_out_ready("l2_rsp_out_ready")
    , l2_rsp_out_valid("l2_rsp_out_valid")
    , l2_rsp_out_data_coh_msg("l2_rsp_out_data_coh_msg")
    , l2_rsp_out_data_req_id("l2_rsp_out_data_req_id")
    , l2_rsp_out_data_to_req("l2_rsp_out_data_to_req")
    , l2_rsp_out_data_addr("l2_rsp_out_data_addr")
    , l2_rsp_out_data_line("l2_rsp_out_data_line")
    , l2_rd_rsp_ready("l2_rd_rsp_ready")
    , l2_rd_rsp_valid("l2_rd_rsp_valid")
    , l2_rd_rsp_data_line("l2_rd_rsp_data_line")
    , l2_flush_valid("l2_flush_valid")
    , l2_flush_data("l2_flush_data")
    , l2_flush_ready("l2_flush_ready")
    , l2_inval_ready("l2_inval_ready")
    , l2_inval_valid("l2_inval_valid")
    , l2_inval_data_addr("l2_inval_data_addr")
    , l2_inval_data_hprot("l2_inval_data_hprot")
    , l2_bresp_ready("l2_bresp_ready")
    , l2_bresp_valid("l2_bresp_valid")
    , l2_bresp_data("l2_bresp_data")
, flush_done("flush_done")
#ifdef STATS_ENABLE
        , l2_stats_valid ("l2_stats_valid")
        , l2_stats_data("l2_stats_data")
        , l2_stats_ready("l2_stats_ready")
#endif
{}

        const char* hdl_name() const { return "l2_rtl_top"; }
};

class l2_wrapper_conv : public sc_module 
{
public: 
    sc_in<bool> clk;
    sc_in<bool> rst;
    sc_out<bool> flush_done; 
    cynw::cynw_get_port_base<l2_cpu_req_t> l2_cpu_req;
    cynw::cynw_get_port_base<l2_fwd_in_t> l2_fwd_in;
    cynw::cynw_get_port_base<l2_rsp_in_t> l2_rsp_in;
    cynw::cynw_get_port_base<bool> l2_flush;
    
    cynw::cynw_put_port_base<l2_req_out_t> l2_req_out;
    cynw::cynw_put_port_base<l2_rsp_out_t> l2_rsp_out;
    cynw::cynw_put_port_base<l2_rd_rsp_t> l2_rd_rsp;
    cynw::cynw_put_port_base<l2_inval_t> l2_inval;
    cynw::cynw_put_port_base<bresp_t> l2_bresp;

#ifdef STATS_ENABLE
    cynw::cynw_put_port_base<bool> l2_stats;
#endif
   
    SC_CTOR(l2_wrapper_conv)
    : clk("clk")
    , rst("rst")
    , flush_done("flush_done")
    , l2_cpu_req("l2_cpu_req")
    , l2_fwd_in("l2_fwd_in")
    , l2_rsp_in("l2_rsp_in")
    , l2_flush("l2_flush")
    , l2_req_out("l2_req_out")
    , l2_rsp_out("l2_rsp_out")
    , l2_rd_rsp("l2_rd_rsp")
    , l2_inval ("l2_inval")
    , l2_bresp ("l2_bresp")
#ifdef STATS_ENABLE
        ,  l2_stats("l2_stats")
#endif          
    , l2_cpu_req_data_conv_cpu_msg("l2_cpu_req_data_conv_cpu_msg")
    , l2_cpu_req_data_conv_hsize("l2_cpu_req_data_conv_hsize")
    , l2_cpu_req_data_conv_hprot("l2_cpu_req_data_conv_hprot")
    , l2_cpu_req_data_conv_addr("l2_cpu_req_data_conv_addr")
    , l2_cpu_req_data_conv_word("l2_cpu_req_data_conv_word")
    , l2_cpu_req_data_conv_amo("l2_cpu_req_data_conv_amo")
    , l2_fwd_in_data_conv_coh_msg("l2_fwd_in_data_conv_coh_msg")
    , l2_fwd_in_data_conv_addr("l2_fwd_in_data_conv_addr")
    , l2_fwd_in_data_conv_req_id("l2_fwd_in_data_conv_req_id")
    , l2_rsp_in_data_conv_coh_msg("l2_rsp_in_data_conv_coh_msg")
    , l2_rsp_in_data_conv_addr("l2_rsp_in_data_conv_addr")
    , l2_rsp_in_data_conv_line("l2_rsp_in_data_conv_line")
    , l2_rsp_in_data_conv_invack_cnt("l2_rsp_in_data_conv_invack_cnt")
    , l2_req_out_data_conv_coh_msg("l2_req_out_data_conv_coh_msg")
    , l2_req_out_data_conv_hprot("l2_req_out_data_conv_hprot")
    , l2_req_out_data_conv_addr("l2_req_out_data_conv_addr")
    , l2_req_out_data_conv_line("l2_req_out_data_conv_line")
    , l2_rsp_out_data_conv_coh_msg("l2_rsp_out_data_conv_coh_msg")
    , l2_rsp_out_data_conv_req_id("l2_rsp_out_data_conv_req_id")
    , l2_rsp_out_data_conv_to_req("l2_rsp_out_data_conv_to_req")
    , l2_rsp_out_data_conv_addr("l2_rsp_out_data_conv_addr")
    , l2_rsp_out_data_conv_line("l2_rsp_out_data_conv_line")
    , l2_rd_rsp_data_conv_line("l2_rd_rsp_data_conv_line")
    , l2_flush_data_conv("l2_flush_data_conv")
    , l2_inval_data_conv_addr("l2_inval_data_conv_addr")
    , l2_inval_data_conv_hprot("l2_inval_data_conv_hprot")
    , l2_bresp_data_conv("l2_bresp_data_conv")
#ifdef STATS_ENABLE
        , l2_stats_data_conv("l2_stats_data_conv")
#endif
        , cosim("cosim") 
    {
        SC_METHOD(thread_l2_cpu_req_data_conv);
        sensitive << l2_cpu_req.data;
        SC_METHOD(thread_l2_fwd_in_data_conv);
        sensitive << l2_fwd_in.data;
        SC_METHOD(thread_l2_rsp_in_data_conv);
        sensitive << l2_rsp_in.data;
        SC_METHOD(thread_l2_flush_data_conv);
        sensitive << l2_flush.data;

        SC_METHOD(thread_l2_req_out_data_conv);
        sensitive << l2_req_out_data_conv_coh_msg << l2_req_out_data_conv_addr << l2_req_out_data_conv_line << l2_req_out_data_conv_hprot; 
        SC_METHOD(thread_l2_rsp_out_data_conv);
        sensitive << l2_rsp_out_data_conv_coh_msg << l2_rsp_out_data_conv_addr << l2_rsp_out_data_conv_line << l2_rsp_out_data_conv_req_id << l2_rsp_out_data_conv_to_req;
        SC_METHOD(thread_l2_rd_rsp_data_conv);
        sensitive << l2_rd_rsp_data_conv_line;
        SC_METHOD(thread_l2_inval_data_conv);
        sensitive << l2_inval_data_conv_addr << l2_inval_data_conv_hprot; 
        SC_METHOD(thread_l2_bresp_data_conv);
        sensitive << l2_bresp_data_conv; 
#ifdef STATS_ENABLE
        SC_METHOD(thread_l2_stats_data_conv);
        sensitive << l2_stats_data_conv;
#endif

    cosim.clk(clk);
    cosim.rst(rst);
    cosim.l2_cpu_req_valid(l2_cpu_req.valid);
    cosim.l2_cpu_req_data_cpu_msg(l2_cpu_req_data_conv_cpu_msg);
    cosim.l2_cpu_req_data_hsize(l2_cpu_req_data_conv_hsize);
    cosim.l2_cpu_req_data_hprot(l2_cpu_req_data_conv_hprot);
    cosim.l2_cpu_req_data_addr(l2_cpu_req_data_conv_addr);
    cosim.l2_cpu_req_data_word(l2_cpu_req_data_conv_word);
    cosim.l2_cpu_req_data_amo(l2_cpu_req_data_conv_amo);
    cosim.l2_cpu_req_ready(l2_cpu_req.ready);
    cosim.l2_fwd_in_valid(l2_fwd_in.valid);
    cosim.l2_fwd_in_data_coh_msg(l2_fwd_in_data_conv_coh_msg);
    cosim.l2_fwd_in_data_addr(l2_fwd_in_data_conv_addr);
    cosim.l2_fwd_in_data_req_id(l2_fwd_in_data_conv_req_id);
    cosim.l2_fwd_in_ready(l2_fwd_in.ready);
    cosim.l2_rsp_in_valid(l2_rsp_in.valid);
    cosim.l2_rsp_in_data_coh_msg(l2_rsp_in_data_conv_coh_msg);
    cosim.l2_rsp_in_data_addr(l2_rsp_in_data_conv_addr);
    cosim.l2_rsp_in_data_line(l2_rsp_in_data_conv_line);
    cosim.l2_rsp_in_data_invack_cnt(l2_rsp_in_data_conv_invack_cnt);
    cosim.l2_rsp_in_ready(l2_rsp_in.ready);
    cosim.l2_req_out_ready(l2_req_out.ready);
    cosim.l2_req_out_valid(l2_req_out.valid);
    cosim.l2_req_out_data_coh_msg(l2_req_out_data_conv_coh_msg);
    cosim.l2_req_out_data_hprot(l2_req_out_data_conv_hprot);
    cosim.l2_req_out_data_addr(l2_req_out_data_conv_addr);
    cosim.l2_req_out_data_line(l2_req_out_data_conv_line);
    cosim.l2_rsp_out_ready(l2_rsp_out.ready);
    cosim.l2_rsp_out_valid(l2_rsp_out.valid);
    cosim.l2_rsp_out_data_coh_msg(l2_rsp_out_data_conv_coh_msg);
    cosim.l2_rsp_out_data_req_id(l2_rsp_out_data_conv_req_id);
    cosim.l2_rsp_out_data_to_req(l2_rsp_out_data_conv_to_req);;
    cosim.l2_rsp_out_data_addr(l2_rsp_out_data_conv_addr);
    cosim.l2_rsp_out_data_line(l2_rsp_out_data_conv_line);
    cosim.l2_rd_rsp_ready(l2_rd_rsp.ready);
    cosim.l2_rd_rsp_valid(l2_rd_rsp.valid);
    cosim.l2_rd_rsp_data_line(l2_rd_rsp_data_conv_line);
    cosim.l2_flush_valid(l2_flush.valid);
    cosim.l2_flush_data(l2_flush_data_conv);
    cosim.l2_flush_ready(l2_flush.ready);
    cosim.l2_inval_ready(l2_inval.ready);
    cosim.l2_inval_valid(l2_inval.valid);
    cosim.l2_inval_data_addr(l2_inval_data_conv_addr);
    cosim.l2_inval_data_hprot(l2_inval_data_conv_hprot);
    cosim.l2_bresp_ready(l2_bresp.ready);
    cosim.l2_bresp_valid(l2_bresp.valid);
    cosim.l2_bresp_data(l2_bresp_data_conv);
    cosim.flush_done(flush_done);
#ifdef STATS_ENABLE
        cosim.l2_stats_valid (l2_stats.valid);
        cosim.l2_stats_data(l2_stats_data_conv);
        cosim.l2_stats_ready(l2_stats.ready);
#endif

    }

    sc_signal<cpu_msg_t> l2_cpu_req_data_conv_cpu_msg;
    sc_signal<hsize_t> l2_cpu_req_data_conv_hsize;
    sc_signal<hprot_t> l2_cpu_req_data_conv_hprot;
    sc_signal<addr_t> l2_cpu_req_data_conv_addr;
    sc_signal<word_t> l2_cpu_req_data_conv_word;
    sc_signal<amo_t> l2_cpu_req_data_conv_amo;
    
    sc_signal<mix_msg_t> l2_fwd_in_data_conv_coh_msg;
    sc_signal<line_addr_t> l2_fwd_in_data_conv_addr;
    sc_signal<cache_id_t> l2_fwd_in_data_conv_req_id;

    sc_signal<coh_msg_t> l2_rsp_in_data_conv_coh_msg;
    sc_signal<line_addr_t> l2_rsp_in_data_conv_addr;
    sc_signal<line_t> l2_rsp_in_data_conv_line;
    sc_signal<invack_cnt_t> l2_rsp_in_data_conv_invack_cnt;

    sc_signal<coh_msg_t> l2_req_out_data_conv_coh_msg;
    sc_signal<hprot_t> l2_req_out_data_conv_hprot;
    sc_signal<line_addr_t> l2_req_out_data_conv_addr;
    sc_signal<line_t> l2_req_out_data_conv_line;
    
    sc_signal<coh_msg_t> l2_rsp_out_data_conv_coh_msg;
    sc_signal<cache_id_t> l2_rsp_out_data_conv_req_id;
    sc_signal<sc_uint<2> > l2_rsp_out_data_conv_to_req;
    sc_signal<line_addr_t> l2_rsp_out_data_conv_addr;
    sc_signal<line_t> l2_rsp_out_data_conv_line;
   
    sc_signal<line_t> l2_rd_rsp_data_conv_line;

    sc_signal<bool> l2_flush_data_conv;
   
    sc_signal<l2_inval_addr_t> l2_inval_data_conv_addr;
    sc_signal<hprot_t> l2_inval_data_conv_hprot;
    
    sc_signal<bresp_t> l2_bresp_data_conv;
#ifdef STATS_ENABLE
    sc_signal<bool> l2_stats_data_conv;
#endif

    void thread_l2_cpu_req_data_conv();
    void thread_l2_fwd_in_data_conv();
    void thread_l2_rsp_in_data_conv(); 
    void thread_l2_flush_data_conv(); 

    void thread_l2_req_out_data_conv();
    void thread_l2_rsp_out_data_conv();
    void thread_l2_rd_rsp_data_conv();
    void thread_l2_inval_data_conv(); 
    void thread_l2_bresp_data_conv(); 
#ifdef STATS_ENABLE
    void thread_l2_stats_data_conv();
#endif


protected:
    l2_rtl_top cosim;

};

#endif
