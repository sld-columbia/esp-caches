// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// l2_core.sv
// Author: Joseph Zuckerman
// top level l2 cache module

module l2_core(
    input logic clk,
    input logic rst,
    input logic l2_cpu_req_valid,
    input logic l2_fwd_in_valid,
    input logic l2_rsp_in_valid,
    input logic l2_req_out_ready,
    input logic l2_rsp_out_ready,
    input logic l2_rd_rsp_ready,
    input logic l2_flush_valid,
    input logic l2_flush_i,
    input logic l2_inval_ready,
    input logic l2_bresp_ready,

    l2_cpu_req_t.in l2_cpu_req_i,
    l2_fwd_in_t.in l2_fwd_in_i,
    l2_rsp_in_t.in l2_rsp_in_i,

    output logic l2_cpu_req_ready,
    output logic l2_fwd_in_ready,
    output logic l2_rsp_in_ready,
    output logic l2_req_out_valid,
    output logic l2_rsp_out_valid,
    output logic l2_rd_rsp_valid,
    output logic l2_flush_ready,
    output logic l2_inval_valid,
    output logic flush_done,
    output logic l2_bresp_valid,
    output bresp_t l2_bresp,

    l2_req_out_t.out l2_req_out,
    l2_rsp_out_t.out l2_rsp_out,
    l2_rd_rsp_t.out l2_rd_rsp,
    l2_inval_t.out l2_inval

`ifdef STATS_ENABLE
    , input logic l2_stats_ready,
    output logic l2_stats_valid,
    output logic l2_stats
`endif
    );

    //interfaces
    l2_cpu_req_t l2_cpu_req();
    l2_fwd_in_t l2_fwd_in();
    l2_rsp_in_t l2_rsp_in();
    l2_rsp_out_t l2_rsp_out_o();
    l2_req_out_t l2_req_out_o();
    l2_rd_rsp_t l2_rd_rsp_o();
    l2_inval_t l2_inval_o();
    line_breakdown_l2_t line_br(), line_br_next();
    addr_breakdown_t addr_br(), addr_br_next(), addr_br_reqs();

    //wires
    logic l2_cpu_req_ready_int, l2_fwd_in_ready_int, l2_rsp_in_ready_int, l2_flush_ready_int;
    logic l2_rsp_out_ready_int, l2_req_out_ready_int, l2_inval_ready_int, l2_rd_rsp_ready_int;
    logic l2_cpu_req_valid_int, l2_fwd_in_valid_int, l2_rsp_in_valid_int, l2_flush_valid_int;
    logic l2_rsp_out_valid_int, l2_req_out_valid_int, l2_inval_valid_int, l2_rd_rsp_valid_int;
    logic l2_bresp_valid_int, l2_bresp_ready_int;
    logic decode_en, lookup_en, rd_mem_en;
    logic fwd_stall, fwd_stall_ended, ongoing_flush, set_conflict, evict_stall, ongoing_atomic, idle;
    logic set_cpu_req_conflict, set_fwd_in_stalled;
    logic do_flush, do_rsp, do_fwd, do_ongoing_flush, do_cpu_req;
    logic set_ongoing_flush, clr_ongoing_flush, set_cpu_req_from_conflict, set_fwd_in_from_stalled;
    logic set_ongoing_atomic, clr_ongoing_atomic, set_set_conflict, clr_set_confict;
    logic incr_flush_way, incr_flush_set, clr_flush_set, clr_flush_way;
    logic do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next;
    logic set_set_conflict_fsm, set_set_conflict_reqs, clr_set_conflict_fsm, clr_set_conflict_reqs;
    logic set_fwd_stall, clr_fwd_stall, set_fwd_stall_i, clr_reqs_cnt, incr_reqs_cnt, clr_fwd_stall_ended;
    logic clr_evict_stall, set_evict_stall, incr_evict_way_buf;
    logic clr_flush_stall_ended, set_flush_stall_ended, flush_stall_ended, is_flush_all;
    logic lookup_mode, tag_hit, empty_way_found, tag_hit_next, empty_way_found_next;
    logic fill_reqs, fill_reqs_flush, reqs_hit, reqs_hit_next, wr_req_state, wr_req_line;
    logic wr_req_invack_cnt, wr_req_tag, wr_en_put_reqs, wr_req_state_atomic, put_reqs_atomic;
    logic wr_en_lines_buf, wr_en_tags_buf, wr_en_states_buf, wr_en_hprots_buf;
    logic wr_rst, wr_en_state, wr_en_line, wr_en_evict_way, rd_en;
    logic ongoing_atomic_set_conflict_instr, set_ongoing_atomic_set_conflict_instr, clr_ongoing_atomic_set_conflict_instr;
    logic [2:0] reqs_op_code;
    logic [`L2_SET_BITS:0] flush_set;
    logic [`L2_WAY_BITS:0] flush_way;
    logic [`REQS_BITS-1:0] reqs_i, fwd_stall_i_wr_data, fwd_stall_i, reqs_i_next, reqs_atomic_i;
    logic [`REQS_BITS_P1-1:0] reqs_cnt;
    logic lr_to_xmw;  //allow forwards to be served between RISC-V LR/SC

    addr_t cpu_req_addr;
    mix_msg_t fwd_in_coh_msg;
    bresp_t l2_bresp_o;
    l2_set_t set;
    l2_set_t set_in;
    l2_way_t empty_way, way_hit, way_hit_next, way;
    l2_way_t wr_data_evict_way, rd_data_evict_way, evict_way_buf;
    line_addr_t rsp_in_addr, fwd_in_addr;
    reqs_buf_t reqs[`N_REQS];

    byte_offset_t b_off_in;
    hsize_t hsize_in;
    line_t line_in, line_out;
    word_t word_in;
    word_offset_t w_off_in;

    line_t lines_buf[`L2_WAYS];
    l2_tag_t tags_buf[`L2_WAYS];
    hprot_t hprots_buf[`L2_WAYS];
    state_t states_buf[`L2_WAYS];

    state_t wr_data_state, rd_data_state[`L2_WAYS];
    line_t wr_data_line, rd_data_line[`L2_WAYS];
    hprot_t wr_data_hprot, rd_data_hprot[`L2_WAYS];
    l2_tag_t wr_data_tag, rd_data_tag[`L2_WAYS];

    cpu_msg_t cpu_msg_wr_data_req;
    l2_tag_t tag_estall_wr_data_req, tag_wr_data_req;
    hsize_t hsize_wr_data_req;
    unstable_state_t state_wr_data_req;
    l2_way_t way_wr_data_req;
    hprot_t hprot_wr_data_req;
    word_t word_wr_data_req;
    line_t line_wr_data_req;
    invack_cnt_calc_t invack_cnt_wr_data_req;
    amo_t amo_wr_data_req;

`ifdef STATS_ENABLE
    logic l2_stats_ready_int, l2_stats_valid_int, l2_stats_o;
`endif

    assign set_set_conflict = set_set_conflict_fsm | set_set_conflict_reqs;
    assign clr_set_conflict = clr_set_conflict_fsm | clr_set_conflict_reqs;
    assign fwd_in_coh_msg = l2_fwd_in.coh_msg;
    assign rd_en = 1'b1;

    //instances
    l2_bufs bufs_u(.*);
    l2_fsm fsm_u(.*);
    l2_interfaces interfaces_u(.*);
    l2_input_decoder decode_u (.*);
`ifdef XILINX_FPGA
    l2_localmem localmem_u (.*);
`endif
`ifdef ASIC
    l2_localmem_asic localmem_u(.*);
`endif
    l2_lookup lookup_u(.*);
    l2_regs regs_u (.*);
    l2_reqs reqs_u (.*);
    l2_write_word write_word_u(.*);

endmodule
