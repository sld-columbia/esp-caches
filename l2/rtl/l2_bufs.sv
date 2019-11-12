`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_bufs(clk, rst, rd_mem_en, look, incr_evict_way_buf, way, evict_way_buf, tags_buf, hprots_buf, states_buf, lines_buf, wr_en_lines_buf, wr_en_tags_buf, wr_en_states_buf, wr_en_hprots_buf, lines_buf_wr_data, states_buf_wr_data, tags_buf_wr_data, hprots_buf_wr_data, rd_data_line, rd_data_tag, rd_data_hprot, rd_data_evict_way, rd_data_state);

    input logic clk, rst; 
    input logic rd_mem_en, look, incr_evict_way_buf;
    input llc_way_t way;
    input logic wr_en_lines_buf, wr_en_tags_buf, wr_en_states_buf, wr_en_hprots_buf; 
    input line_t lines_buf_wr_data; 
    input llc_state_t states_buf_wr_data;
    input llc_tag_t tags_buf_wr_data;
    input hprot_t hprots_buf_wr_data;
    
    input line_t rd_data_line[`LLC_WAYS];
    input llc_tag_t rd_data_tag[`LLC_WAYS];
    input hprot_t rd_data_hprot[`LLC_WAYS];
    input llc_way_t rd_data_evict_way; 
    input llc_state_t rd_data_state[`LLC_WAYS];

    output llc_way_t evict_way_buf; 
    output line_t lines_buf[`LLC_WAYS];
    output llc_tag_t tags_buf[`LLC_WAYS];
    output hprot_t hprots_buf[`LLC_WAYS];
    output llc_state_t states_buf[`LLC_WAYS];

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            evict_way_buf <= 0; 
        end else if (rd_mem_en & look) begin 
            evict_way_buf <= rd_data_evict_way;
        end else if (incr_evict_way_buf) begin 
            evict_way_buf <= evict_way_buf + 1; 
        end
        for (int i = 0; i < `LLC_WAYS; i++) begin 
            if (!rst) begin
                lines_buf[i] <= 0; 
            end else if (rd_mem_en & look) begin 
                lines_buf[i] <= rd_data_line[i];
            end else if (wr_en_lines_buf && (way == i)) begin 
                lines_buf[i] <= lines_buf_wr_data;
            end
   
            if (!rst) begin 
                tags_buf[i] <= 0;
            end else if (rd_mem_en & look) begin  
                tags_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_tags_buf && (way == i)) begin 
                tags_buf[i] <= tags_buf_wr_data;
            end
    
            if (!rst) begin 
                hprots_buf[i] <= 0;
            end else if (rd_mem_en & look) begin
                hprots_buf[i] <= rd_data_hprot[i]; 
            end else if (wr_en_hprots_buf && (way == i)) begin 
                hprots_buf[i] <= hprots_buf_wr_data;
            end
                        
            if (!rst) begin 
                states_buf[i] <= 0;
            end else if (rd_mem_en & look) begin
                states_buf[i] <= rd_data_state[i]; 
            end else if (wr_en_states_buf && (way == i)) begin 
                states_buf[i] <= states_buf_wr_data;
            end
        end
    end

endmodule
