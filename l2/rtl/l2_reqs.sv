// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// l2_reqs.sv
// Author: Joseph Zuckerman
// request buffer for l2

module l2_reqs(
    input logic clk,
    input logic rst,
    input logic fill_reqs,
    input logic fill_reqs_flush,
    input logic wr_req_state,
    input logic wr_req_state_atomic,
    input logic wr_req_line,
    input logic wr_req_invack_cnt,
    input logic wr_req_tag,
    input logic [2:0] reqs_op_code,
    input logic [`REQS_BITS-1:0] reqs_atomic_i,
    input cpu_msg_t cpu_msg_wr_data_req,
    input hprot_t hprot_wr_data_req,
    input hsize_t hsize_wr_data_req,
    input invack_cnt_calc_t invack_cnt_wr_data_req,
    input l2_tag_t tag_estall_wr_data_req,
    input l2_tag_t tag_wr_data_req,
    input l2_way_t way_wr_data_req,
    input line_t line_wr_data_req,
    input mix_msg_t fwd_in_coh_msg,
    input unstable_state_t state_wr_data_req,
    input word_t word_wr_data_req,
    input amo_t  amo_wr_data_req,

    addr_breakdown_t.in addr_br,
    addr_breakdown_t.in addr_br_reqs,
    line_breakdown_l2_t.in line_br,

    output logic set_set_conflict_reqs,
    output logic clr_set_conflict_reqs,
    output logic reqs_hit,
    output logic reqs_hit_next,
    output logic set_fwd_stall,
    output logic clr_fwd_stall,
    output logic set_fwd_stall_i,
    output logic [`REQS_BITS-1:0] reqs_i_next,
    output logic [`REQS_BITS-1:0] fwd_stall_i_wr_data,
    output logic [`REQS_BITS-1:0] reqs_i,
    output reqs_buf_t reqs[`N_REQS]
    );

    genvar i;
    generate
        for (i = 0; i < `N_REQS; i++) begin
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin
                    reqs[i].cpu_msg <= 0;
                    reqs[i].tag_estall <= 0;
                    reqs[i].set <= 0;
                    reqs[i].way <= 0;
                    reqs[i].hsize <= 0;
                    reqs[i].w_off <= 0;
                    reqs[i].b_off <= 0;
                    reqs[i].hprot <= 0;
                    reqs[i].word <= 0;
                    reqs[i].amo <= 0;
                end else if (fill_reqs) begin
                    if (reqs_i == i) begin
                        reqs[i].cpu_msg <= cpu_msg_wr_data_req;
                        reqs[i].tag_estall <= tag_estall_wr_data_req;
                        reqs[i].set <= addr_br.set;
                        reqs[i].way <= way_wr_data_req;
                        reqs[i].hsize <= hsize_wr_data_req;
                        reqs[i].w_off <= addr_br.w_off;
                        reqs[i].b_off <= addr_br.b_off;
                        reqs[i].hprot <= hprot_wr_data_req;
                        reqs[i].word <= word_wr_data_req;
                        reqs[i].amo <= amo_wr_data_req;
                    end
                end else if (fill_reqs_flush) begin
                    if (reqs_i == i) begin
                        reqs[i].cpu_msg <= cpu_msg_wr_data_req;
                        reqs[i].tag_estall <= tag_estall_wr_data_req;
                        reqs[i].set <= addr_br_reqs.set;
                        reqs[i].way <= way_wr_data_req;
                        reqs[i].hsize <= hsize_wr_data_req;
                        reqs[i].w_off <= addr_br_reqs.w_off;
                        reqs[i].b_off <= addr_br_reqs.b_off;
                        reqs[i].hprot <= hprot_wr_data_req;
                        reqs[i].word <= word_wr_data_req;
                        reqs[i].amo <= amo_wr_data_req;
                    end
                end
            end

            //state
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin
                    reqs[i].state <= 0;
                end else if (wr_req_state_atomic) begin
                    if (reqs_atomic_i == i) begin
                        reqs[i].state <= state_wr_data_req;
                    end
                end else if (wr_req_state || fill_reqs || fill_reqs_flush) begin
                    if (reqs_i == i) begin
                        reqs[i].state <= state_wr_data_req;
                    end
                end
            end

            //line
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin
                    reqs[i].line <= 0;
                end else if (wr_req_line || fill_reqs || fill_reqs_flush) begin
                    if (reqs_i == i) begin
                        reqs[i].line <= line_wr_data_req;
                    end
                end
            end

            //invack_cnt
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin
                    reqs[i].invack_cnt <= 0;
                end else if (fill_reqs || fill_reqs_flush) begin
                    if (reqs_i == i) begin
                        reqs[i].invack_cnt <= `MAX_N_L2;
                    end
                end else if (wr_req_invack_cnt) begin
                    if (reqs_i == i) begin
                        reqs[i].invack_cnt <= invack_cnt_wr_data_req;
                    end
                end
            end

            //tag
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin
                    reqs[i].tag <= 0;
                end else if (fill_reqs) begin
                    if (reqs_i == i) begin
                        reqs[i].tag <= tag_wr_data_req;
                    end
                end else if (fill_reqs_flush) begin
                    if (reqs_i == i) begin
                        reqs[i].tag <= addr_br_reqs.tag;
                    end
                end else if (wr_req_tag) begin
                    if (reqs_i == i) begin
                        reqs[i].tag <= tag_wr_data_req;
                    end
                end
            end
        end
    endgenerate

    always_comb begin
        clr_set_conflict_reqs = 1'b0;
        set_set_conflict_reqs = 1'b0;
        clr_fwd_stall = 1'b0;
        set_fwd_stall = 1'b0;
        reqs_i_next = 0;
        reqs_hit_next = 1'b0;
        fwd_stall_i_wr_data = 0;
        set_fwd_stall_i = 1'b0;
        case(reqs_op_code)
            `L2_REQS_LOOKUP : begin
                for (int i = 0; i < `N_REQS; i++) begin
                    if (reqs[i].tag == line_br.tag && reqs[i].set == line_br.set && reqs[i].state != `INVALID) begin
                        reqs_i_next = i;
                    end
                end
            end
            `L2_REQS_PEEK_REQ : begin
                clr_set_conflict_reqs = 1'b1;
                for (int i = 0; i < `N_REQS; i++) begin
                    if (reqs[i].state == `INVALID) begin
                        reqs_i_next = i;
                    end

                    if (reqs[i].set == addr_br.set && reqs[i].state != `INVALID) begin
                        set_set_conflict_reqs = 1'b1;
                        clr_set_conflict_reqs = 1'b0;
                    end
                end
            end
            `L2_REQS_PEEK_FLUSH : begin
                for (int i = 0; i <`N_REQS; i++) begin
                    if (reqs[i].state == `INVALID) begin
                        reqs_i_next = i;
                    end
                end
            end
            `L2_REQS_PEEK_FWD : begin
                clr_fwd_stall = 1'b1;
                for (int i = 0; i < `N_REQS; i++) begin
                    if (reqs[i].state != `INVALID && reqs[i].tag == line_br.tag && reqs[i].set == line_br.set) begin
                        reqs_hit_next = 1'b1;
                        reqs_i_next = i;

                        set_fwd_stall = 1'b1;
                        clr_fwd_stall = 1'b0;
                        if (fwd_in_coh_msg == `FWD_INV || fwd_in_coh_msg == `FWD_INV_LLC) begin
                            if (reqs[i].state != `ISD) begin
                                set_fwd_stall = 1'b0;
                                clr_fwd_stall = 1'b1;
                            end
                        end else begin
                            if (reqs[i].state == `MIA
`ifdef LLSC
                                || (reqs[i].state == `XMW && reqs[i].amo == 0)
`endif
                            ) begin
                                set_fwd_stall = 1'b0;
                                clr_fwd_stall = 1'b1;
                            end
                        end
                    end
                end
                set_fwd_stall_i = 1'b1;
                fwd_stall_i_wr_data = reqs_i_next;
            end
            default : begin
                reqs_hit_next = 1'b0;
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            reqs_i <= 0;
            reqs_hit <= 1'b0;
        end else if (reqs_op_code != `L2_REQS_IDLE) begin
            reqs_i <= reqs_i_next;
            reqs_hit <= reqs_hit_next;
        end
    end

endmodule
