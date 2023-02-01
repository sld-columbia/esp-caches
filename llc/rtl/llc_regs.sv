// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc_regs.sv
// Author: Joseph Zuckerman
// llc registers 

module llc_regs(   
    input logic clk, 
    input logic rst, 
    input logic rst_state, 
    input logic decode_en, 
    input logic rd_set_en, 
    input logic lookup_en, 
    input logic update_en, 
    input logic clr_rst_stall,
    input logic clr_flush_stall, 
    input logic set_flush_stall, 
    input logic clr_req_stall_decoder, 
    input logic clr_req_stall_process, 
    input logic set_req_stall, 
    input logic clr_req_in_stalled_valid,
    input logic set_req_in_stalled_valid,  
    input logic clr_rst_flush_stalled_set, 
    input logic incr_rst_flush_stalled_set,
    input logic update_dma_addr_from_req, 
    input logic incr_dma_addr, 
    input logic clr_recall_pending, 
    input logic set_recall_pending,    
    input logic clr_dma_read_pending, 
    input logic set_dma_read_pending,    
    input logic clr_dma_write_pending, 
    input logic set_dma_write_pending,    
    input logic clr_recall_valid, 
    input logic set_recall_valid,    
    input logic clr_is_dma_read_to_resume, 
    input logic set_is_dma_read_to_resume_decoder, 
    input logic set_is_dma_read_to_resume_process, 
    input logic clr_is_dma_write_to_resume, 
    input logic set_is_dma_write_to_resume_decoder, 
    input logic set_is_dma_write_to_resume_process, 
    input logic update_req_in_stalled, 
    input logic set_update_evict_way,
    input logic set_req_pending, clr_req_pending, 
    input logic set_recall_evict_addr,
    input llc_way_t way_next,
    input llc_set_t set, 
    input var llc_tag_t tags_buf[`LLC_WAYS], 
        
    line_breakdown_llc_t.in line_br, 
    llc_dma_req_in_t.in llc_dma_req_in,
    
    output logic rst_stall,
    output logic flush_stall,
    output logic req_stall,
    output logic req_in_stalled_valid,      
    output logic recall_pending,   
    output logic dma_read_pending,
    output logic dma_write_pending, 
    output logic recall_valid, 
    output logic is_dma_read_to_resume,
    output logic is_dma_write_to_resume, 
    output logic update_evict_way,
    output logic req_pending, 
    output llc_set_t rst_flush_stalled_set,
    output addr_t dma_addr,  
    output llc_set_t req_in_stalled_set, 
    output llc_tag_t req_in_stalled_tag,
    output line_addr_t addr_evict,
    output line_addr_t recall_evict_addr
    );
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            rst_stall <= 1'b1;
        end else if (rst_state) begin 
            rst_stall <= 1'b1;
        end else if (clr_rst_stall) begin 
            rst_stall <= 1'b0;
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            flush_stall <= 1'b0; 
        end else if (rst_state || clr_flush_stall) begin 
            flush_stall <= 1'b0;
        end else if (set_flush_stall) begin 
            flush_stall <= 1'b1; 
        end
    end

    logic clr_req_stall; 
    assign clr_req_stall = clr_req_stall_decoder | clr_req_stall_process; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            req_stall <= 1'b0; 
        end else if (rst_state || clr_req_stall) begin 
            req_stall <= 1'b0;
        end else if (set_req_stall) begin 
            req_stall <= 1'b1; 
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            req_in_stalled_valid <= 1'b0; 
        end else if (rst_state || clr_req_in_stalled_valid) begin 
            req_in_stalled_valid <= 1'b0;
        end else if (set_req_in_stalled_valid) begin 
            req_in_stalled_valid <= 1'b1; 
        end
    end
   
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            rst_flush_stalled_set <= 0;
        end else if (rst_state || clr_rst_flush_stalled_set) begin 
            rst_flush_stalled_set <= 0; 
        end else if (incr_rst_flush_stalled_set) begin 
            rst_flush_stalled_set <= rst_flush_stalled_set + 1; 
        end
    end
   
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            dma_addr <= 0;
        end else if (rst_state) begin 
            dma_addr <= 0; 
        end else if (update_dma_addr_from_req && rd_set_en) begin 
            dma_addr <= llc_dma_req_in.addr;
        end else if (incr_dma_addr) begin 
            dma_addr <= dma_addr + 1; 
        end 
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            recall_pending <= 1'b0;
        end else if (rst_state || clr_recall_pending) begin 
            recall_pending <= 1'b0; 
        end else if (set_recall_pending) begin 
            recall_pending <= 1'b1;
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            dma_read_pending <= 1'b0;
        end else if (rst_state || clr_dma_read_pending) begin 
            dma_read_pending <= 1'b0; 
        end else if (set_dma_read_pending) begin 
            dma_read_pending <= 1'b1;
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            dma_write_pending <= 1'b0;
        end else if (rst_state || clr_dma_write_pending) begin 
            dma_write_pending <= 1'b0;
        end else if (set_dma_write_pending) begin 
            dma_write_pending <= 1'b1;
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            recall_valid <= 1'b0;
        end else if (rst_state || clr_recall_valid) begin 
            recall_valid <= 1'b0;
        end else if (set_recall_valid) begin 
            recall_valid <= 1'b1;
        end
    end
    
    logic set_is_dma_read_to_resume;
    assign set_is_dma_read_to_resume = set_is_dma_read_to_resume_decoder | set_is_dma_read_to_resume_process;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            is_dma_read_to_resume <= 1'b0;
        end else if (rst_state || clr_is_dma_read_to_resume) begin 
            is_dma_read_to_resume <=  1'b0;
        end else if (set_is_dma_read_to_resume) begin
            is_dma_read_to_resume <= 1'b1;
        end
    end 

    logic set_is_dma_write_to_resume;
    assign set_is_dma_write_to_resume = set_is_dma_write_to_resume_decoder | set_is_dma_write_to_resume_process;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            is_dma_write_to_resume <= 1'b0;
        end else  if (rst_state || clr_is_dma_write_to_resume) begin 
            is_dma_write_to_resume <= 1'b0; 
        end else if (set_is_dma_write_to_resume) begin
            is_dma_write_to_resume <= 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            req_in_stalled_set <= 0; 
            req_in_stalled_tag <= 0; 
        end else if (rst_state) begin 
            req_in_stalled_set <=  0;  
            req_in_stalled_tag <= 0; 
        end else if (update_req_in_stalled) begin 
            req_in_stalled_set <= line_br.set; 
            req_in_stalled_tag <= line_br.tag;
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            update_evict_way <= 1'b0;
        end else if (rst_state || decode_en) begin
            update_evict_way <=  1'b0; 
        end else if (set_update_evict_way) begin 
            update_evict_way <= 1'b1; 
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            addr_evict <= 0;
        end else if (lookup_en) begin 
            addr_evict <= {tags_buf[way_next], set}; 
        end
    end 

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            req_pending <= 1'b0;
        end else if (rst_state || clr_req_pending) begin 
            req_pending <= 1'b0;
        end else if (set_req_pending) begin 
            req_pending <= 1'b1; 
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            recall_evict_addr <= 0;
        end else if (set_recall_evict_addr) begin 
            recall_evict_addr <= addr_evict; 
        end
    end

endmodule
