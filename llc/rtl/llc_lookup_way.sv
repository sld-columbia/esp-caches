// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps 
`include "cache_consts.svh"
`include "cache_types.svh"

//llc_lookup_way.sv 
//Author: Joseph Zuckerman
//looks up way for eviction/replacement 

module llc_lookup_way (
    input logic clk, 
    input logic rst, 
    input logic lookup_en, 
    input llc_tag_t tag, 
    input var llc_tag_t tags_buf[`LLC_WAYS],
    input var llc_state_t states_buf[`LLC_WAYS],
    input llc_way_t evict_way_buf,

    output logic evict, 
    output logic evict_next,
    output llc_way_t way, 
    output llc_way_t way_next
    ); 
    
    //LOOKUP
    logic [`LLC_WAYS - 1:0] tag_hits_tmp, empty_ways_tmp, evict_valid_tmp, evict_not_sd_tmp; 
    llc_way_t way_tmp;
    always_comb begin 
        for (int i = 0; i < `LLC_WAYS; i++) begin
            tag_hits_tmp[i] = (tags_buf[i] == tag && states_buf[i] != `INVALID);
            empty_ways_tmp[i] = (states_buf[i] == `INVALID); 
            
            way_tmp = (i + evict_way_buf) & {`LLC_WAY_BITS{1'b1}};
            evict_valid_tmp[i] = (states_buf[way_tmp] == `VALID);
            evict_not_sd_tmp[i] = (states_buf[way_tmp] != `SD); 
        end
    end 

    //way priority encoder
    llc_way_t hit_way, empty_way, evict_way_valid, evict_way_not_sd;
    logic tag_hit, empty_way_found, evict_valid, evict_not_sd; 
    
    pri_enc #(`LLC_WAYS, `LLC_WAY_BITS) hit_way_enc (
        .in(tag_hits_tmp), 
        .out(hit_way), 
        .out_valid(tag_hit)
    );
    
    pri_enc #(`LLC_WAYS, `LLC_WAY_BITS) empty_way_enc (
        .in(empty_ways_tmp), 
        .out(empty_way), 
        .out_valid(empty_way_found)
    );
    
    pri_enc #(`LLC_WAYS, `LLC_WAY_BITS) evict_valid_enc (
        .in(evict_valid_tmp), 
        .out(evict_way_valid), 
        .out_valid(evict_valid)
    );
    
    pri_enc #(`LLC_WAYS, `LLC_WAY_BITS) evict_not_sd_enc (
        .in(evict_not_sd_tmp), 
        .out(evict_way_not_sd), 
        .out_valid(evict_not_sd)
    ); 
    
    always_comb begin 
        if (tag_hit) begin 
            way_next = hit_way;
            evict_next = 1'b0;
        end else if (empty_way_found) begin 
            way_next = empty_way;
            evict_next = 1'b0; 
        end else if (evict_valid) begin 
            way_next = evict_way_valid  + evict_way_buf;
            evict_next = 1'b1;
        end else if (evict_not_sd) begin 
            way_next = evict_way_not_sd + evict_way_buf;
            evict_next = 1'b1;
        end else begin 
            way_next = evict_way_buf;
            evict_next = 1'b1; 
        end 
    end

    //flop outputs
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            way <= 0; 
            evict <= 1'b0; 
        end else if (lookup_en) begin
            way <= way_next;
            evict <= evict_next;
        end 
    end
endmodule
