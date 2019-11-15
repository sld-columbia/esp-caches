`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_bufs(clk, rst, rd_mem_en, incr_evict_way_buf, way, evict_way_buf, tags_buf, hprots_buf, states_buf, lines_buf, wr_en_lines_buf, wr_en_tags_buf, wr_en_states_buf, wr_en_hprots_buf, lines_buf_wr_data, states_buf_wr_data, tags_buf_wr_data, hprots_buf_wr_data, rd_data_line, rd_data_tag, rd_data_hprot, rd_data_evict_way, rd_data_state);

    input logic clk, rst; 
    input logic rd_mem_en, incr_evict_way_buf;
    input l2_way_t way;
    input logic wr_en_lines_buf, wr_en_tags_buf, wr_en_states_buf, wr_en_hprots_buf; 
    input line_t lines_buf_wr_data; 
    input state_t states_buf_wr_data;
    input l2_tag_t tags_buf_wr_data;
    input hprot_t hprots_buf_wr_data;
    
    input line_t rd_data_line[`L2_WAYS];
    input l2_tag_t rd_data_tag[`L2_WAYS];
    input hprot_t rd_data_hprot[`L2_WAYS];
    input l2_way_t rd_data_evict_way; 
    input state_t rd_data_state[`L2_WAYS];

    output l2_way_t evict_way_buf; 
    output line_t lines_buf[`L2_WAYS];
    output l2_tag_t tags_buf[`L2_WAYS];
    output hprot_t hprots_buf[`L2_WAYS];
    output state_t states_buf[`L2_WAYS];

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            evict_way_buf <= 0; 
        end else if (rd_mem_en) begin 
            evict_way_buf <= rd_data_evict_way;
        end else if (incr_evict_way_buf) begin 
            evict_way_buf <= evict_way_buf + 1; 
        end
        for (int i = 0; i < `L2_WAYS; i++) begin 
            if (!rst) begin
                lines_buf[i] <= 0; 
            end else if (rd_mem_en) begin 
                lines_buf[i] <= rd_data_line[i];
            end else if (wr_en_lines_buf && (way == i)) begin 
                lines_buf[i] <= lines_buf_wr_data;
            end
   
            if (!rst) begin 
                tags_buf[i] <= 0;
            end else if (rd_mem_en) begin  
                tags_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_tags_buf && (way == i)) begin 
                tags_buf[i] <= tags_buf_wr_data;
            end
    
            if (!rst) begin 
                hprots_buf[i] <= 0;
            end else if (rd_mem_en) begin
                hprots_buf[i] <= rd_data_hprot[i]; 
            end else if (wr_en_hprots_buf && (way == i)) begin 
                hprots_buf[i] <= hprots_buf_wr_data;
            end
                        
            if (!rst) begin 
                states_buf[i] <= 0;
            end else if (rd_mem_en) begin
                states_buf[i] <= rd_data_state[i]; 
            end else if (wr_en_states_buf && (way == i)) begin 
                states_buf[i] <= states_buf_wr_data;
            end
        end
    end

endmodule
