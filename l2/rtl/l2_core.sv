`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh"

// l2_core.sv
// Author: Joseph Zuckerman
// top level l2 cache module

module l2_core(clk, rst, l2_cpu_req_valid, l2_cpu_req_i, l2_cpu_req_ready, l2_fwd_in_valid, l2_fwd_in_i, l2_fwd_in_ready, l2_rsp_in_valid, l2_rsp_in_i, l2_rsp_in_ready, l2_req_out_ready, l2_req_out_valid, l2_req_out, l2_rsp_out_ready, l2_rsp_out_valid, l2_rsp_out, l2_rd_rsp_ready, l2_rd_rsp_valid, l2_rd_rsp, l2_flush_valid, l2_flush_i, l2_flush_ready, l2_inval_ready, l2_inval_valid, l2_inval, flush_done
`ifdef STATS_ENABLE
    , l2_stats_ready, l2_stats_valid, l2_stats
`endif
);

    input clk, rst; 

    input logic l2_cpu_req_valid; 
    output logic l2_cpu_req_ready;
    l2_cpu_req_t.in l2_cpu_req_i;

    input logic l2_fwd_in_valid;
    output logic l2_fwd_in_ready; 
    l2_fwd_in_t.in l2_fwd_in_i; 

    input logic l2_rsp_in_valid;
    output logic l2_rsp_in_ready; 
    l2_rsp_in_t.in l2_rsp_in_i; 
    
    input logic l2_req_out_ready; 
    output logic l2_req_out_valid;
    l2_req_out_t.out l2_req_out;

    input logic l2_rsp_out_ready; 
    output logic l2_rsp_out_valid; 
    l2_rsp_out_t.out l2_rsp_out;

    input logic l2_rd_rsp_ready;
    output logic l2_rd_rsp_valid; 
    l2_rd_rsp_t.out l2_rd_rsp; 

    input logic l2_flush_valid;
    input logic l2_flush_i;
    output logic l2_flush_ready;

    input logic l2_inval_ready;
    output logic l2_inval_valid;
    output l2_inval_t l2_inval;

    output logic flush_done; 

`ifdef STATS_ENABLE
    input logic l2_stats_ready;
    output logic l2_stats_valid;
    output logic l2_stats; 
`endif 
    // STATE LOGIC 

    localparam RESET = 3'b000; 
    localparam DECODE = 3'b001; 
    logic [2:0] state, next_state;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= RESET; 
        end else begin 
            state <= next_state; 
        end 
    end

    logic decode_en; 
    assign decode_en = (state == DECODE); 
    
    //DECODE

    //input wires
    logic fwd_stall, fwd_stall_ended, ongoing_flush, set_conflict, evict_stall, ongoing_atomic;
    logic [`REQS_BITS_P1-1:0] reqs_cnt;  
    //output wires
    logic do_flush, do_rsp, do_fwd, do_ongoing_flush, do_cpu_req; 
    logic set_ongoing_flush, clr_ongoing_flush, set_cpu_req_from_conflict, set_fwd_in_from_stalled; 
    logic incr_flush_set, clr_flush_set, clr_flush_way; 
    l2_set_t flush_set; 
    l2_way_t flush_way; 
        
    //instance
    l2_input_decoder decode_u (.*);

    //INTERFACES
    
    //interfaces
    l2_cpu_req_t l2_cpu_req(); 
    l2_fwd_in_t l2_fwd_in();
    l2_rsp_in_t l2_rsp_in(); 
    logic l2_flush;

    l2_rsp_out_t l2_rsp_out_o(); 
    l2_req_out_t l2_req_out_o(); 
    l2_rd_rsp_t l2_rd_rsp_o(); 
    l2_inval_t l2_inval_o;
    
    //wires
    logic l2_cpu_req_ready_int, l2_fwd_in_ready_int, l2_rsp_in_ready_int, l2_flush_ready_int, l2_rsp_out_ready_int, l2_req_out_ready_int, l2_inval_ready_int, l2_rd_rsp_ready_int;
    logic l2_cpu_req_valid_int, l2_fwd_in_valid_int, l2_rsp_in_valid_int, l2_flush_valid_int, l2_rsp_out_valid_int, l2_req_out_valid_int, l2_inval_valid_int, l2_rd_rsp_valid_int; 
`ifdef STATS_ENABLE
    logic l2_stats_ready_int, l2_stats_valid_int, l2_stats_o; 
`endif
    logic set_cpu_req_conflict, set_fwd_in_stalled;

    //instance 
    l2_interfaces interfaces_u(.*); 
endmodule
