`timescale 1ps / 1ps 
`include "cache_consts.svh" 
`include "cache_types.svh" 

module l2_regs (clk, rst, set_ongoing_flush, clr_ongoing_flush, ongoing_flush, incr_flush_set, clr_flush_set, flush_set, incr_flush_way, clr_flush_way, flush_way, set_set_conflict, clr_set_conflict, set_conflict, set_fwd_stall, clr_fwd_stall, fwd_stall, set_fwd_stall_i, fwd_stall_i_wr_data, fwd_stall_i, fill_reqs, fill_reqs_flush, incr_reqs_cnt, reqs_cnt, clr_fwd_stall_ended, wr_en_put_reqs, reqs_i, fwd_stall_ended, clr_ongoing_atomic, set_ongoing_atomic, ongoing_atomic, clr_evict_stall, set_evict_stall, evict_stall); 
    
    input logic clk, rst;

    input logic set_ongoing_flush, clr_ongoing_flush; 
    output logic ongoing_flush;
    
    input logic incr_flush_set, clr_flush_set; 
    output logic [`L2_SET_BITS:0] flush_set; 

    input logic incr_flush_way, clr_flush_way; 
    output logic [`L2_WAY_BITS:0] flush_way;

    input logic set_set_conflict, clr_set_conflict; 
    output logic set_conflict;

    input logic set_fwd_stall, clr_fwd_stall;
    output logic fwd_stall; 

    input logic set_fwd_stall_i; 
    input logic [`REQS_BITS-1:0] fwd_stall_i_wr_data;
    output logic [`REQS_BITS-1:0] fwd_stall_i; 
   
    input logic fill_reqs, incr_reqs_cnt, fill_reqs_flush; 
    output logic [`REQS_BITS_P1-1:0] reqs_cnt; 

    input logic clr_fwd_stall_ended, wr_en_put_reqs; 
    input logic [`REQS_BITS-1:0] reqs_i; 
    output logic fwd_stall_ended; 

    input logic clr_ongoing_atomic, set_ongoing_atomic; 
    output logic ongoing_atomic; 

    input logic clr_evict_stall, set_evict_stall; 
    output logic evict_stall; 

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
        end else if (wr_en_put_reqs && fwd_stall && fwd_stall_i == reqs_i) begin 
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

endmodule

