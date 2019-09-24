`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc.sv
// Author: Joseph Zuckerman
// Top level LLC module 

module llc(clk, rst, llc_req_in_i, llc_req_in_valid, llc_req_in_ready, llc_dma_req_in_i, llc_dma_req_in_valid, llc_dma_reqin_ready, llc_rsp_in_i, llc_rsp_in_valid, llc_rsp_in_ready, llc_mem_rsp_i, llc_mem_rsp_valid, llc_mem_rsp_ready, llc_rst_tb_i, llc_rst_tb_valid, llc_rst_tb_ready, llc_rsp_out_ready, llc_rsp_out_valid, llc_rsp_out, llc_dma_rsp_out_ready, llc_dma_rsp_out_valid, llc_dma_rsp_out, llc_fwd_out_ready, llc_fwd_out_valud, llc_fwd_out, llc_mem_req_ready,  llc_mem_req_valid, llc_mem_req, llc_rst_tb_done_ready, llc_rst_tb_done_valid, llc_rst_tb_done
`ifdef STATS_ENABLE
	, llc_stats_ready, llc_stats_valud, llc_stats
`endif
);

	input logic clk;
	input logic rst; 

	input llc_req_in_t llc_req_in_i;
	input logic llc_req_in_valid;
	output logic llc_req_in_ready;

	input llc_req_in_t llc_dma_req_in_i;
	input logic llc_dma_req_in_valid;
	output logic llc_dma_req_in_ready; 
	
	input llc_rsp_in_t llc_rsp_in_i; 
	input logic llc_rsp_in_valid;
	output logic llc_rsp_in_ready;

	input llc_mem_rsp_t llc_mem_rsp_i;
	input logic  llc_mem_rsp_valid;
	output logic llc_mem_rsp_ready;

    input logic llc_rst_tb_i;
	input logic llc_rst_tb_valid;
	output logic llc_rst_tb_ready;

	input logic llc_rsp_out_ready;
	output logic llc_rsp_out_valid;
	output llc_rsp_out_t  llc_rsp_out;

	input logic llc_dma_rsp_out_ready;
	output logic llc_dma_rsp_out_valid;
	output llc_rsp_out_t llc_dma_rsp_out;

	input logic llc_fwd_out_ready; 
	output logic llc_fwd_out_valid;
	output llc_fwd_out_t llc_fwd_out;   

	input logic llc_mem_req_ready;
	output logic llc_mem_req_valid;
	output llc_mem_req_t llc_mem_req;

	input logic llc_rst_tb_done_ready;
	output logic llc_rst_tb_done_valid;
    output logic llc_rst_tb_done;

`ifdef STATS_ENABLE
	input  logic llc_stats_ready;
	output logic llc_stats_valid;
	output logic llc_stats;
`endif

    llc_req_in_t llc_req_in; 
    llc_req_in_t llc_dma_req_in; 
    llc_rsp_in_t llc_rsp_in; 
    llc_mem_rsp_t llc_mem_rsp_in;
    logic llc_rst_tb; 

    handle_incoming handle_incoming_u (.*); 

    always @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_req_in <= 0; 
        end else if (llc_req_in_valid && llc_req_in_ready) begin
            llc_req_in <= llc_req_in_i; 
        end
    end

    always @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_dma_req_in <= 0; 
        end else if (llc_dma_req_in_valid && llc_dma_req_in_ready) begin
            llc_dma_req_in <= llc_dma_req_in_i; 
        end
    end
    
    always @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rsp_in <= 0; 
        end else if (llc_rsp_in_valid && llc_rsp_in_ready) begin
            llc_rsp_in <= llc_rsp_in_i; 
        end
    end
    
    always @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_mem_rsp <= 0; 
        end else if (llc_mem_rsp_valid && llc_mem_rsp_ready) begin
            llc_mem_rsp <= llc_rst_tb_i; 
        end
    end

    always @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rst_tb <= 0; 
        end else if (llc_rst_tb_valid && llc_rst_tb_ready) begin
            llc_rst_tb <= llc_rst_tb_i; 
        end
    end
    
endmodule
