// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_bufs(
    input logic clk,
    input logic rst, 
    input logic rd_mem_en,
    input l2_way_t way,
    input var line_t rd_data_line[`L2_WAYS],
    input var l2_tag_t rd_data_tag[`L2_WAYS],
    input var hprot_t rd_data_hprot[`L2_WAYS],
    input l2_way_t rd_data_evict_way, 
    input var state_t rd_data_state[`L2_WAYS],

    output l2_way_t evict_way_buf, 
    output line_t lines_buf[`L2_WAYS],
    output l2_tag_t tags_buf[`L2_WAYS],
    output hprot_t hprots_buf[`L2_WAYS],
    output state_t states_buf[`L2_WAYS]
    );
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            evict_way_buf <= 0; 
        end else if (rd_mem_en) begin 
            evict_way_buf <= rd_data_evict_way;
        end
    end

    genvar i;
    generate
        for (i = 0; i < `L2_WAYS; i++) begin 
            always_ff @(posedge clk or negedge rst) begin 
                if (!rst) begin
                    lines_buf[i] <= 0; 
                end else if (rd_mem_en) begin 
                    lines_buf[i] <= rd_data_line[i];
                end
            end

            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin 
                    tags_buf[i] <= 0;
                end else if (rd_mem_en) begin  
                    tags_buf[i] <= rd_data_tag[i]; 
                end
            end

            always_ff @(posedge clk or negedge rst) begin        
                if (!rst) begin 
                    hprots_buf[i] <= 0;
                end else if (rd_mem_en) begin
                    hprots_buf[i] <= rd_data_hprot[i]; 
                end
            end

            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin 
                    states_buf[i] <= 0;
                end else if (rd_mem_en) begin
                    states_buf[i] <= rd_data_state[i]; 
                end
            end
        end
    endgenerate

endmodule
