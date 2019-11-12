`timescale 1ps / 1ps 
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_input_decoder (clk, rst, decode_en, l2_flush_valid_int, l2_rsp_in_valid_int, l2_fwd_in_valid_int, l2_cpu_req_valid_int, reqs_cnt, fwd_stall, fwd_stall_ended, ongoing_flush, flush_set, flush_way, set_conflict, evict_stall, ongoing_atomic, do_flush, do_rsp, do_fwd, do_ongoing_flush, do_cpu_req, l2_flush_ready_int, l2_rsp_in_ready_int, l2_fwd_in_ready_int, l2_cpu_req_ready_int, set_ongoing_flush, clr_ongoing_flush, set_cpu_req_from_conflict, set_fwd_in_from_stalled, incr_flush_set, clr_flush_set, clr_flush_way, flush_done, idle);
    
    input logic clk, rst; 
    input decode_en; 
    input logic l2_flush_valid_int, l2_rsp_in_valid_int, l2_fwd_in_valid_int, l2_cpu_req_valid_int; 
    input logic [`REQS_BITS_P1-1:0] reqs_cnt; 
    input logic fwd_stall, fwd_stall_ended;
    input logic ongoing_flush; 
    input l2_set_t flush_set; 
    input l2_way_t flush_way; 
    input logic set_conflict, evict_stall, ongoing_atomic; 

    output logic do_flush, do_rsp, do_fwd, do_ongoing_flush, do_cpu_req; 
    output logic l2_flush_ready_int, l2_rsp_in_ready_int, l2_fwd_in_ready_int, l2_cpu_req_ready_int;
    output logic set_ongoing_flush, clr_ongoing_flush;
    output logic set_cpu_req_from_conflict, set_fwd_in_from_stalled;
    output logic incr_flush_set, clr_flush_set, clr_flush_way;
    output logic flush_done; 
    output logic idle; 

    logic do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next;
    always_comb begin 
        do_flush_next = 1'b0; 
        do_rsp_next = 1'b0; 
        do_fwd_next = 1'b0; 
        do_ongoing_flush_next = 1'b0;
        do_cpu_req_next = 1'b0; 
        l2_flush_ready_int = 1'b0; 
        l2_rsp_in_ready_int = 1'b0; 
        l2_fwd_in_ready_int = 1'b0; 
        l2_cpu_req_ready_int = 1'b0; 
        set_ongoing_flush = 1'b0; 
        set_fwd_in_from_stalled = 1'b0; 
        incr_flush_set = 1'b0; 
        clr_flush_way = 1'b0; 
        clr_flush_set = 1'b0; 
        clr_ongoing_flush = 1'b0; 
        flush_done = 1'b0; 
        set_cpu_req_from_conflict = 1'b0;
        idle = 1'b0; 
        if (decode_en) begin 
            if (l2_flush_valid_int && reqs_cnt == `N_REQS) begin 
                do_flush_next = 1'b1;
                set_ongoing_flush = 1'b1; 
                l2_flush_ready_int = 1'b1; 
            end else if (l2_rsp_in_valid_int) begin 
                do_rsp_next = 1'b1; 
                l2_rsp_in_ready_int = 1'b1; 
            end else if ((l2_fwd_in_valid_int && !fwd_stall) || fwd_stall_ended) begin 
                do_fwd_next = 1'b1;
                if (!fwd_stall) begin 
                    l2_fwd_in_ready_int = 1'b1; 
                end else begin 
                    set_fwd_in_from_stalled = 1'b1; 
                end
            end else if (ongoing_flush) begin 
                if (flush_set < `L2_SETS) begin 
                    if (!l2_fwd_in_valid_int && reqs_cnt != 0) begin 
                        do_ongoing_flush_next = 1'b1; 
                    end
                    
                    if (flush_way == `L2_WAYS) begin 
                        incr_flush_set = 1'b1; 
                        clr_flush_way = 1'b1;
                    end
                end else begin 
                    clr_flush_set = 1'b1; 
                    clr_flush_way = 1'b1; 
                    clr_ongoing_flush = 1'b1;
                    flush_done = 1'b1; 
                end 
            end else if ((l2_cpu_req_valid_int || set_conflict) && !evict_stall && (reqs_cnt != 0 || ongoing_atomic)) begin 
                do_cpu_req_next = 1'b1;
                if (!set_conflict) begin 
                    l2_cpu_req_ready_int = 1'b1; 
                end else begin 
                    set_cpu_req_from_conflict = 1'b1; 
                end
            end else begin 
                idle = 1'b1; 
            end 
        end
    end    

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            do_flush <= 1'b0; 
            do_rsp <= 1'b0; 
            do_fwd <= 1'b0; 
            do_ongoing_flush <= 1'b0; 
            do_cpu_req <= 1'b0; 
        end else if (decode_en) begin 
            do_flush <= do_flush_next; 
            do_rsp <= do_rsp_next; 
            do_fwd <= do_fwd_next; 
            do_ongoing_flush <= do_ongoing_flush_next; 
            do_cpu_req <= do_cpu_req_next; 
        end
    end

endmodule
