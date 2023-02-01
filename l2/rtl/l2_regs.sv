// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_regs (
    input logic clk,
    input logic rst,
    input logic set_ongoing_flush,
    input logic clr_ongoing_flush,
    input logic incr_flush_set,
    input logic clr_flush_set,
    input logic incr_flush_way,
    input logic clr_flush_way,
    input logic set_set_conflict,
    input logic clr_set_conflict,
    input logic set_fwd_stall,
    input logic clr_fwd_stall,
    input logic set_fwd_stall_i,
    input logic fill_reqs,
    input logic incr_reqs_cnt,
    input logic fill_reqs_flush,
    input logic clr_fwd_stall_ended,
    input logic wr_en_put_reqs,
    input logic put_reqs_atomic,
    input logic clr_ongoing_atomic,
    input logic set_ongoing_atomic,
    input logic clr_evict_stall,
    input logic set_evict_stall,
    input logic lr_to_xmw,
    input logic [`REQS_BITS-1:0] reqs_atomic_i,
    input logic [`REQS_BITS-1:0] reqs_i,
    input logic [`REQS_BITS-1:0] fwd_stall_i_wr_data,

    output logic ongoing_flush,
    output logic set_conflict,
    output logic fwd_stall,
    output logic fwd_stall_ended,
    output logic ongoing_atomic,
    output logic evict_stall,
    output logic [`L2_SET_BITS:0] flush_set,
    output logic [`L2_WAY_BITS:0] flush_way,
    output logic [`REQS_BITS-1:0] fwd_stall_i,
    output logic [`REQS_BITS_P1-1:0] reqs_cnt

`ifdef LLSC
    , input logic clr_ongoing_atomic_set_conflict_instr,
    input logic set_ongoing_atomic_set_conflict_instr,
    output logic ongoing_atomic_set_conflict_instr
`endif
    );

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            ongoing_flush <= 1'b0;
        end else if (clr_ongoing_flush) begin
            ongoing_flush <= 1'b0;
        end else if (set_ongoing_flush) begin
            ongoing_flush <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            flush_set <= 0;
        end else if (clr_flush_set) begin
            flush_set <= 0;
        end else if (incr_flush_set) begin
            flush_set <= flush_set + 1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            flush_way <= 0;
        end else if (clr_flush_way) begin
            flush_way <= 0;
        end else if (incr_flush_way) begin
            flush_way <= flush_way + 1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            set_conflict <= 1'b0;
        end else if (clr_set_conflict) begin
            set_conflict <= 1'b0;
        end else if (set_set_conflict) begin
            set_conflict <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            fwd_stall <= 1'b0;
        end else if (clr_fwd_stall) begin
            fwd_stall <= 1'b0;
        end else if (set_fwd_stall) begin
            fwd_stall <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            fwd_stall_i <= 0;
        end else if (set_fwd_stall_i) begin
            fwd_stall_i <= fwd_stall_i_wr_data;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            reqs_cnt <= `N_REQS;
        end else if (fill_reqs || fill_reqs_flush) begin
            reqs_cnt <= reqs_cnt - 1;
        end else if (incr_reqs_cnt) begin
            reqs_cnt <= reqs_cnt + 1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            fwd_stall_ended <= 1'b0;
        end else if (clr_fwd_stall_ended) begin
            fwd_stall_ended <= 1'b0;
        end else if ((wr_en_put_reqs && fwd_stall && (fwd_stall_i == reqs_i
                    || (put_reqs_atomic  && fwd_stall_i == reqs_atomic_i)))
`ifdef LLSC
                    || (fwd_stall && lr_to_xmw && (fwd_stall_i == reqs_i))
`endif
        ) begin
            fwd_stall_ended <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            ongoing_atomic <= 1'b0;
        end else if (clr_ongoing_atomic) begin
            ongoing_atomic <= 1'b0;
        end else if (set_ongoing_atomic) begin
            ongoing_atomic <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            evict_stall <= 1'b0;
        end else if (clr_evict_stall) begin
            evict_stall <= 1'b0;
        end else if (set_evict_stall) begin
            evict_stall <= 1'b1;
        end
    end

`ifdef LLSC
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            ongoing_atomic_set_conflict_instr <= 1'b0;
        end else if (clr_ongoing_atomic_set_conflict_instr) begin
            ongoing_atomic_set_conflict_instr <= 1'b0;
        end else if (set_ongoing_atomic_set_conflict_instr) begin
            ongoing_atomic_set_conflict_instr <= 1'b1;
        end
    end
`endif

endmodule

