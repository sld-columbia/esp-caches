`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// l2_wrapper.sv
// Author: Joseph Zuckerman
// top level wrapper for l2 cache
      
module l2_wrapper(clk, rst, flush_done, l2_cpu_req_valid, l2_cpu_req_data_cpu_msg, l2_cpu_req_data_hsize, l2_cpu_req_data_hprot, l2_cpu_req_data_addr, l2_cpu_req_data_word, l2_cpu_req_ready, l2_fwd_in_valid, l2_fwd_in_data_coh_msg, l2_fwd_in_data_addr, l2_fwd_in_data_req_id, l2_fwd_in_ready, l2_rsp_in_valid, l2_rsp_in_data_coh_msg, l2_rsp_in_data_addr, l2_rsp_in_data_line, l2_rsp_in_data_invack_cnt, l2_rsp_in_ready, l2_flush_valid, l2_flush_data, l2_flush_ready, l2_rd_rsp_valid, l2_rd_rsp_data_line, l2_rd_rsp_ready, l2_inval_valid, l2_inval_data, l2_inval_ready, l2_req_out_valid, l2_req_out_data_coh_msg, l2_req_out_data_hprot, l2_req_out_data_addr, l2_req_out_data_line, l2_req_out_ready, l2_rsp_out_valid, l2_rsp_out_data_coh_msg, l2_rsp_out_data_req_id, l2_rsp_out_data_to_req, l2_rsp_out_data_addr, l2_rsp_out_data_line, l2_rsp_out_ready, 
`ifdef STATS_ENABLE
    l2_stats_valid, l2_stats_data, l2_stats_ready
`endif
);

    input logic clk;
    input logic rst;
      
    input logic l2_cpu_req_valid;
    input cpu_msg_t l2_cpu_req_data_cpu_msg;
    input hsize_t l2_cpu_req_data_hsize;
    input hprot_t l2_cpu_req_data_hprot;
    input addr_t l2_cpu_req_data_addr;
    input word_t l2_cpu_req_data_word;
    output logic l2_cpu_req_ready;
    
    l2_cpu_req_t l2_cpu_req();
    assign l2_cpu_req.cpu_msg = l2_cpu_req_data_cpu_msg;
    assign l2_cpu_req.hsize = l2_cpu_req_data_hsize;
    assign l2_cpu_req.hprot = l2_cpu_req_data_hprot;
    assign l2_cpu_req.addr = l2_cpu_req_data_addr;
    assign l2_cpu_req.word = l2_cpu_req_data_word;

    input logic l2_fwd_in_valid;
    input mix_msg_t l2_fwd_in_data_coh_msg;
    input line_addr_t l2_fwd_in_data_addr;
    input cache_id_t l2_fwd_in_data_req_id;
    output logic l2_fwd_in_ready;

    l2_fwd_in_t l2_fwd_in(); 
    assign l2_fwd_in.coh_msg = l2_fwd_in_data_coh_msg
    assign l2_fwd_in.addr = l2_fwd_in_data_addr
    assign l2_fwd_in.req_id = l2_fwd_in_data_req_id

    input logic l2_rsp_in_valid;
    input coh_msg_t l2_rsp_in_data_coh_msg;
    input line_addr_t l2_rsp_in_data_addr;
    input line_t l2_rsp_in_data_line;
    input invack_cnt_t l2_rsp_in_data_invack_cnt;
    output logic l2_rsp_in_ready;

    l2_rsp_in_t l2_rsp_in();
    assign l2_rsp_in.coh_msg = l2_rsp_in_data_coh_msg
    assign l2_rsp_in.addr = l2_rsp_in_data_addr
    assign l2_rsp_in.line = l2_rsp_in_data_line
    assign l2_rsp_in.invack_cnt = l2_rsp_in_data_invack_cnt

    input logic l2_req_out_ready;
    output logic l2_req_out_valid;
    output coh_msg_t l2_req_out_data_coh_msg;
    output hprot_t l2_req_out_data_hprot;
    output line_addr_t l2_req_out_data_addr;
    output line_t l2_req_out_data_line;
   
    l2_req_out_t l2_req_out();
    assign l2_req_out_data_coh_msg = l2_req_out.coh_msg
    assign l2_req_out_data_hprot = l2_req_out.hprot
    assign l2_req_out_data_addr = l2_req_out.addr
    assign l2_req_out_data_line = l2_req_out.line

    input logic l2_rsp_out_ready;
    output logic l2_rsp_out_valid;
    output coh_msg_t l2_rsp_out_data_coh_msg;
    output cache_id_t l2_rsp_out_data_req_id;
    output logic[1:0] l2_rsp_out_data_to_req;
    output line_addr_t l2_rsp_out_data_addr;
    output line_t l2_rsp_out_data_line;
   
    l2_rsp_out_t l2_rsp_out(); 
    assign l2_rsp_out_data_coh_msg = l2_rsp_out.coh_msg
    assign l2_rsp_out_data_req_id = l2_rsp_out.req_id
    assign l2_rsp_out_data_to_req = l2_rsp_out.to_req
    assign l2_rsp_out_data_addr = l2_rsp_out.addr
    assign l2_rsp_out_data_line = l2_rsp_out.line

    input logic l2_rd_rsp_ready;
    output logic l2_rd_rsp_valid;
    output line_t l2_rd_rsp_data_line;

    l2_rd_rsp_t l2_rd_rsp(); 
    assign l2_rd_rsp_data_line = l2_rd_rsp.line;

    input logic l2_flush_valid;
    input logic l2_flush_data;
    output logic l2_flush_ready;

    input logic l2_inval_ready;
    output logic l2_inval_valid;
    output l2_inval_t l2_inval_data;

`ifdef STATS_ENABLE
    input logic l2_stats_ready;
    output logic l2_stats_valid;
    output logic l2_stats_data;
`endif

    output logic flush_done;
     
    //l2_core l2_u(.*);
endmodule

