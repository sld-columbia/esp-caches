`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc.sv
// Author: Joseph Zuckerman
// Top level LLC module 

module llc(clk, rst, llc_req_in_i, llc_req_in_valid, llc_req_in_ready, llc_dma_req_in_i, llc_dma_req_in_valid, llc_dma_reqin_ready, llc_rsp_in_i, llc_rsp_in_valid, llc_rsp_in_ready, llc_mem_rsp_i, llc_mem_rsp_valid, llc_mem_rsp_ready, llc_rst_tb_i, llc_rst_tb_valid, llc_rst_tb_ready, llc_rsp_out_ready, llc_rsp_out_valid, llc_rsp_out, llc_dma_rsp_out_ready, llc_dma_rsp_out_valid, llc_dma_rsp_out, llc_fwd_out_ready, llc_fwd_out_valud, llc_fwd_out, llc_mem_req_ready,  llc_mem_req_valid, llc_mem_req, llc_rst_tb_done_ready, llc_rst_tb_done_valid, llc_rst_tb_done
`ifdef STATS_ENABLE
	, llc_stats_ready, llc_stats_valid, llc_stats
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

    //STATE MACHINE
    localparam DECODE = 2'b00;
    localparam READ = 2'b01; 
    localparam PROCESS = 2'b11; 
    localparam UPDATE = 2'b10; 

    logic[1:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= DECODE; 
        end else begin 
            state <= next_state; 
    end 

    always_comb begin 
        next_state = state; 
        case(state) begin 
            DECODE :   
                if (decode_done && look) begin
                    next_state = READ;
                end else if (decode_done) begin 
                    next_state = PROCESS;
                end
            READ : 
                next_state = PROCESS; 
            PROCESS : 
                next_state = UPDATE; 
            UPDATE : 
                next_state = DECODE; 
        endcase
    end


    logic decode_en, rd_en, look; 
    assign decode_en = (state == DECODE); 
    assign rd_en = (state == READ); 
    
    input_decoder input_decoder_u(.*);
    
    line_t lines_buf[`LLC_WAYS];
    llc_tag_t tags_buf[`LLC_WAYS];
    sharers_t sharers_buf[`LLC_WAYS];
    owner_t owners_buf[`LLC_WAYS];
    hprot_t hprots_buf[`LLC_WAYS];
    logic dirty_bits_buf[`LLC_WAYS];
    llc_way_t evict_ways_buf; 
    llc_state_t states_buf[`LLC_WAYS];
    
    localmem localmem_u(.*, .rd_data_line(lines_buf), .rd_data_tag(tags_buf), .rd_data_sharers(sharers_buf), .rd_data_owner(owners_buf), .rd_data_hprot(hprot), .rd_data_dirty_bit(dirty_bits_buf), .rd_data_evicty_way(evict_ways_buf), .rd_data_state(states_buf));

    process_response process_response_u();

    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_req_in <= 0; 
        end else if (llc_req_in_valid && llc_req_in_ready) begin
            llc_req_in <= llc_req_in_i; 
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_dma_req_in <= 0; 
        end else if (llc_dma_req_in_valid && llc_dma_req_in_ready) begin
            llc_dma_req_in <= llc_dma_req_in_i; 
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rsp_in <= 0; 
        end else if (llc_rsp_in_valid && llc_rsp_in_ready) begin
            llc_rsp_in <= llc_rsp_in_i; 
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_mem_rsp <= 0; 
        end else if (llc_mem_rsp_valid && llc_mem_rsp_ready) begin
            llc_mem_rsp <= llc_rst_tb_i; 
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rst_tb <= 0; 
        end else if (llc_rst_tb_valid && llc_rst_tb_ready) begin
            llc_rst_tb <= llc_rst_tb_i; 
        end
    end
    
    logic rst_stall, clr_rst_stall, set_rst_stall;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || set_rst_stall) begin 
            rst_stall <= 1'b1;
        end else if (clr_rst_stall) begin 
            rst_stall <= 1'b0;
        end
    end

    logic flush_stall, clr_flush_stall, set_flush_stall; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || clr_flush_stall) begin 
            flush_stall <= 1'b0; 
        end else if (set_flush_stall) begin 
            flush_stall <= 1'b1; 
        end
    end

    logic req_stall, clr_req_stall, set_req_stall; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || clr_req_stall) begin 
            req_stall <= 1'b0; 
        end else if (set_req_stall) begin 
            req_stall <= 1'b1; 
        end
    end

    logic req_in_stalled_valid, clr_req_in_stalled_valid, set_req_in_stalled_valid;  
     always_ff @(posedge clk or negedge rst) begin 
        if (!rst || clr_req_in_stalled_valid) begin 
            req_in_stalled_valid <= 1'b0; 
        end else if (set_req_in_stalled_valid) begin 
            req_in_stalled_valid <= 1'b1; 
        end
    end

    llc_set_t rst_flush_stalled_set;
    logic clr_rst_flush_stalled_set, incr_rst_flush_stalled_set;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || clr_rst_flush_stalled_set) begin 
            rst_flush_stalled_set <= 0; 
        end else if (incr_rst_flush_stalled_set) begin 
            rst_flush_stalled_set <= rst_flush_stalled_set + 1; 
        end
    end
    
    line_addr_t dma_addr;
    logic update_dma_addr_from_req; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            dma_addr <= 0; 
        end else if (update_dma_addr_from_req) begin 
            dma_addr <= dma_req_in.addr;
        end
    end

    logic recall_pending, clr_recall_pending, set_recall_pending;    
    always_ff @(posedge_clk or negedge rst) begin 
        if (!rst || clr_recall_pending) begin 
            recall_pending <= 1'b0;
        end else if (set_recall_pending) begin 
            recall_pending <= 1'b1;
        end
    end

    logic dma_read_pending, clr_dma_read_pending, set_dma_read_pending;    
    always_ff @(posedge_clk or negedge rst) begin 
        if (!rst || clr_dma_read_pending) begin 
            dma_read_pending <= 1'b0;
        end else if (set_dma_read_pending) begin 
            dma_read_pending <= 1'b1;
        end
    end

    logic dma_write_pending, clr_dma_write_pending, set_dma_write_pending;    
    always_ff @(posedge_clk or negedge rst) begin 
        if (!rst || clr_dma_write_pending) begin 
            dma_write_pending <= 1'b0;
        end else if (set_dma_write_pending) begin 
            dma_write_pending <= 1'b1;
        end
    end

    logic recall_valid, clr_recall_valid, set_recall_valid;    
    always_ff @(posedge_clk or negedge rst) begin 
        if (!rst || clr_recall_valid) begin 
            recall_valid <= 1'b0;
        end else if (set_recall_valid) begin 
            recall_valid <= 1'b1;
        end
    end

    //@TODO
    llc_set_t req_in_stalled_set; 
    llc_tag_t req_in_stalled_tag; 

endmodule
