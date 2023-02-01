// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc_bufs.sv 
// Author: Joseph Zuckerman
// stores one set of data from cache

module llc_bufs(    
    input logic clk,
    input logic rst,
    input logic rst_state, 
    input logic rd_mem_en, 
    input logic look, 
    input logic incr_evict_way_buf,
    input logic llc_mem_rsp_ready_int, 
    input logic llc_mem_rsp_valid_int,
    input logic wr_en_lines_buf, 
    input logic wr_en_tags_buf, 
    input logic wr_en_states_buf, 
    input logic wr_en_owners_buf, 
    input logic wr_en_sharers_buf, 
    input logic wr_en_hprots_buf, 
    input logic wr_en_dirty_bits_buf, 
    input logic dirty_bits_buf_wr_data,
    input var logic rd_data_dirty_bit[`LLC_WAYS],
    input llc_way_t way,
    input line_t lines_buf_wr_data,
    input llc_state_t states_buf_wr_data,
    input owner_t owners_buf_wr_data,
    input llc_tag_t tags_buf_wr_data,
    input hprot_t hprots_buf_wr_data,
    input sharers_t sharers_buf_wr_data,
    input var line_t rd_data_line[`LLC_WAYS],
    input var llc_tag_t rd_data_tag[`LLC_WAYS],
    input var sharers_t rd_data_sharers[`LLC_WAYS],
    input var owner_t rd_data_owner[`LLC_WAYS],
    input var hprot_t rd_data_hprot[`LLC_WAYS],
    input var llc_way_t rd_data_evict_way, 
    input var llc_state_t rd_data_state[`LLC_WAYS],
    
    llc_mem_rsp_t.in llc_mem_rsp_next,

    output logic dirty_bits_buf[`LLC_WAYS],
    output llc_way_t evict_way_buf, 
    output line_t lines_buf[`LLC_WAYS],
    output llc_tag_t tags_buf[`LLC_WAYS],
    output sharers_t sharers_buf[`LLC_WAYS],
    output owner_t owners_buf[`LLC_WAYS],
    output hprot_t hprots_buf[`LLC_WAYS],
    output llc_state_t states_buf[`LLC_WAYS]
    );

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            evict_way_buf <= 0; 
        end else if (rst_state) begin 
            evict_way_buf <= 0; 
        end else if (rd_mem_en & look) begin 
            evict_way_buf <= rd_data_evict_way;
        end else if (incr_evict_way_buf) begin 
            evict_way_buf <= evict_way_buf + 1; 
        end
    end

    genvar i;
    generate 
        for (i = 0; i < `LLC_WAYS; i++) begin 
            always_ff @(posedge clk or negedge rst) begin 
                if (!rst) begin
                    lines_buf[i] <= 0; 
                end else if (rst_state) begin 
                    lines_buf[i] <= 0; 
                end else if (rd_mem_en & look) begin 
                    lines_buf[i] <= rd_data_line[i];
                end else if (llc_mem_rsp_ready_int && llc_mem_rsp_valid_int && (way == i)) begin 
                    lines_buf[i] <= llc_mem_rsp_next.line;
                end else if (wr_en_lines_buf && (way == i)) begin 
                    lines_buf[i] <= lines_buf_wr_data;
                end
            end
             
            always_ff @(posedge clk or negedge rst) begin 
                if (!rst) begin 
                    tags_buf[i] <= 0;
                end else if (rst_state) begin 
                    tags_buf[i] <= 0; 
                end else if (rd_mem_en & look) begin  
                    tags_buf[i] <= rd_data_tag[i]; 
                end else if (wr_en_tags_buf && (way == i)) begin 
                    tags_buf[i] <= tags_buf_wr_data;
                end
            end
             
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin 
                    sharers_buf[i] <= 0;
                end else if (rst_state) begin 
                    sharers_buf[i] <= 0; 
                end else if (rd_mem_en & look) begin 
                    sharers_buf[i] <= rd_data_sharers[i]; 
                end else if (wr_en_sharers_buf && (way == i)) begin 
                    sharers_buf[i] <= sharers_buf_wr_data;
                end
            end
             
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin 
                    owners_buf[i] <= 0;
                end else if (rst_state) begin 
                    owners_buf[i] <= 0; 
                end else if (rd_mem_en & look) begin 
                    owners_buf[i] <= rd_data_owner[i]; 
                end else if (wr_en_owners_buf && (way == i)) begin 
                    owners_buf[i] <= owners_buf_wr_data;
                end
            end
             
            always_ff @(posedge clk or negedge rst) begin
                if (!rst) begin 
                    hprots_buf[i] <= 0;
                end else if (rst_state) begin 
                    hprots_buf[i] <= 0; 
                end else if (rd_mem_en & look) begin
                    hprots_buf[i] <= rd_data_hprot[i]; 
                end else if (wr_en_hprots_buf && (way == i)) begin 
                    hprots_buf[i] <= hprots_buf_wr_data;
                end
            end
             
            always_ff @(posedge clk or negedge rst) begin                
                if (!rst) begin 
                    dirty_bits_buf[i] <= 0;
                end else if (rst_state) begin 
                    dirty_bits_buf[i] <= 0; 
                end else if (rd_mem_en & look) begin
                    dirty_bits_buf[i] <= rd_data_dirty_bit[i];
                end else if (wr_en_dirty_bits_buf && (way == i)) begin 
                    dirty_bits_buf[i] <= dirty_bits_buf_wr_data;
                end
            end
             
            always_ff @(posedge clk or negedge rst) begin                
                if (!rst) begin 
                    states_buf[i] <= 0;
                end else if (rst_state) begin 
                    states_buf[i] <= 0; 
                end else if (rd_mem_en & look) begin
                    states_buf[i] <= rd_data_state[i]; 
                end else if (wr_en_states_buf && (way == i)) begin 
                    states_buf[i] <= states_buf_wr_data;
                end
            end
        end
    endgenerate
      
endmodule
