// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh" 

// l2_lookup.sv

module l2_lookup(
    input logic clk,
    input logic rst, 
    input logic lookup_mode, 
    input logic lookup_en, 
    input l2_way_t evict_way_buf, 
    input var l2_tag_t tags_buf[`L2_WAYS],
    input var state_t states_buf[`L2_WAYS],
    line_breakdown_l2_t.in line_br, 
    addr_breakdown_t.in addr_br, 

    output logic tag_hit, 
    output logic empty_way_found, 
    output logic tag_hit_next, 
    output logic empty_way_found_next, 
    output l2_way_t way_hit,
    output l2_way_t empty_way, 
    output l2_way_t way_hit_next
    );

    l2_way_t empty_way_next; 

    always_comb begin 
        way_hit_next = 0;
        tag_hit_next = 1'b0; 
        empty_way_next = 0; 
        empty_way_found_next = 1'b0; 
        if (lookup_en) begin 
            case(lookup_mode) 
                `L2_LOOKUP : begin 
                    for (int i = `L2_WAYS-1; i >= 0; i--) begin
                        if (tags_buf[i] == addr_br.tag && states_buf[i] != `INVALID) begin 
                            tag_hit_next = 1'b1; 
                            way_hit_next = i; 
                        end
                        if (states_buf[i] == `INVALID) begin 
                            empty_way_found_next = 1'b1; 
                            empty_way_next = i; 
                        end
                    end
                end
                `L2_LOOKUP_FWD : begin 
                    for (int i = `L2_WAYS-1; i >= 0; i--) begin 
                        if (tags_buf[i] == line_br.tag && states_buf[i]  != `INVALID) begin 
                            tag_hit_next = 1'b1; 
                            way_hit_next = i;
                        end
                    end
                end
            endcase
        end
    end 
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            way_hit <= 0;
            tag_hit <= 1'b0; 
            empty_way <= 0; 
            empty_way_found <= 1'b0; 
        end else if (lookup_en) begin 
            way_hit <= way_hit_next;
            tag_hit <= tag_hit_next; 
            empty_way <= empty_way_next; 
            empty_way_found <= empty_way_found_next;  
        end
    end

endmodule
