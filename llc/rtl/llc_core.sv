// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc.sv
// Author: Joseph Zuckerman
// Top level LLC module 

module llc_core(
    input logic clk,
    input logic rst, 
    input logic llc_req_in_valid,
    input logic llc_dma_req_in_valid,
    input logic llc_rsp_in_valid,
    input logic llc_mem_rsp_valid,
    input logic llc_rst_tb_i,
    input logic llc_rst_tb_valid,
    input logic llc_rsp_out_ready,
    input logic llc_dma_rsp_out_ready,
    input logic llc_fwd_out_ready, 
    input logic llc_mem_req_ready,
    input logic llc_rst_tb_done_ready,
    
    llc_req_in_t.in llc_req_in_i,
    llc_dma_req_in_t.in llc_dma_req_in_i,
    llc_rsp_in_t.in llc_rsp_in_i, 
    llc_mem_rsp_t.in llc_mem_rsp_i,
    
    output logic llc_dma_req_in_ready, 
    output logic llc_req_in_ready,
    output logic llc_rsp_in_ready,
    output logic llc_mem_rsp_ready,
    output logic llc_rst_tb_ready,
    output logic llc_rsp_out_valid,
    output logic llc_dma_rsp_out_valid,
    output logic llc_fwd_out_valid,
    output logic llc_mem_req_valid,
    output logic llc_rst_tb_done_valid,
    output logic llc_rst_tb_done,
 
    llc_dma_rsp_out_t.out llc_dma_rsp_out,
    llc_rsp_out_t.out  llc_rsp_out,
    llc_fwd_out_t.out llc_fwd_out,   
    llc_mem_req_t.out llc_mem_req
    
`ifdef STATS_ENABLE
    , input  logic llc_stats_ready,
    output logic llc_stats_valid,
    output logic llc_stats
`endif
    );

    llc_req_in_t llc_req_in(); 
    llc_dma_req_in_t llc_dma_req_in(); 
    llc_rsp_in_t llc_rsp_in(); 
    llc_mem_rsp_t llc_mem_rsp();
    logic llc_rst_tb; 

    //STATE MACHINE
    
    localparam DECODE = 3'b000;
    localparam READ_SET = 3'b001;
    localparam READ_MEM = 3'b010;
    localparam LOOKUP = 3'b011; 
    localparam PROCESS = 3'b100; 
    localparam UPDATE = 3'b101; 

    logic[2:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= DECODE; 
        end else begin 
            state <= next_state; 
        end
    end 
    
    //wires 
    logic process_done, idle, idle_next; 
    logic rst_stall, clr_rst_stall;
    logic flush_stall, clr_flush_stall, set_flush_stall; 
    logic do_get_dma_req, is_flush_to_resume, is_rst_to_resume, is_rst_to_get_next, is_rsp_to_get_next, look; 
    logic llc_rsp_out_ready_int, llc_dma_rsp_out_ready_int, llc_fwd_out_ready_int, llc_mem_req_ready_int, llc_rst_tb_done_ready_int; 
    
    always_comb begin 
        next_state = state; 
        case(state) 
            DECODE : 
                if (!idle_next) begin 
                    next_state = READ_SET;
                end 
            READ_SET : 
                next_state = READ_MEM; 
            READ_MEM : 
                next_state = LOOKUP; 
            LOOKUP : 
                next_state = PROCESS;
            PROCESS :   
                if (process_done) begin 
                    next_state = UPDATE; 
                end
            UPDATE :   
                if ((is_flush_to_resume || is_rst_to_resume) && !flush_stall && !rst_stall) begin 
                    if (llc_rst_tb_done_ready_int) begin 
                        next_state = DECODE;
                    end
                end else begin 
                    next_state = DECODE;
                end
            default : 
                next_state = DECODE;
       endcase
    end

    logic decode_en, rd_set_en, rd_mem_en, update_en, process_en, lookup_en; 
    assign decode_en = (state == DECODE);
    assign rd_set_en = (state == READ_SET);
    assign rd_mem_en = (state == READ_MEM);
    assign lookup_en = (state == LOOKUP); 
    assign process_en = (state == PROCESS) | (state == LOOKUP); 
    assign update_en = (state == UPDATE); 
    
    //wires
    logic req_stall, clr_req_stall_decoder, clr_req_stall_process, set_req_stall; 
    logic req_in_stalled_valid, clr_req_in_stalled_valid, set_req_in_stalled_valid;  
    logic clr_rst_flush_stalled_set, incr_rst_flush_stalled_set;
    logic update_dma_addr_from_req, incr_dma_addr; 
    logic recall_pending, clr_recall_pending, set_recall_pending; 
    logic req_pending, set_req_pending, clr_req_pending; 
    logic dma_read_pending, clr_dma_read_pending, set_dma_read_pending;    
    logic dma_write_pending, clr_dma_write_pending, set_dma_write_pending;    
    logic recall_valid, clr_recall_valid, set_recall_valid, set_recall_evict_addr;    
    logic is_dma_read_to_resume, clr_is_dma_read_to_resume; 
    logic set_is_dma_read_to_resume_decoder, set_is_dma_read_to_resume_process; 
    logic is_dma_write_to_resume, clr_is_dma_write_to_resume; 
    logic set_is_dma_write_to_resume_decoder, set_is_dma_write_to_resume_process; 
    logic update_evict_way, set_update_evict_way, incr_evict_way_buf;
    logic is_rst_to_get, is_req_to_get, is_req_to_resume, is_dma_req_to_get, is_rsp_to_get, do_get_req; 
    logic llc_req_in_ready_int, llc_dma_req_in_ready_int, llc_rsp_in_ready_int, llc_rst_tb_ready_int, llc_mem_rsp_ready_int;
    logic llc_req_in_valid_int, llc_dma_req_in_valid_int, llc_rsp_in_valid_int, llc_rst_tb_valid_int, llc_mem_rsp_valid_int;  
    logic llc_rst_tb_done_o, rst_in, rst_state;
    logic llc_rsp_out_valid_int, llc_dma_rsp_out_valid_int, llc_fwd_out_valid_int, llc_mem_req_valid_int, llc_rst_tb_done_valid_int; 
    logic wr_en_lines_buf, wr_en_tags_buf, wr_en_sharers_buf, wr_en_owners_buf, wr_en_hprots_buf, wr_en_dirty_bits_buf, wr_en_states_buf;
    logic update_req_in_stalled, update_req_in_from_stalled, set_req_in_stalled; 
    logic rd_en, wr_en, wr_en_evict_way, evict, evict_next;
    logic [(`LLC_NUM_PORTS-1):0] wr_rst_flush;
  
    addr_t dma_addr;
    line_addr_t addr_evict, recall_evict_addr;
    line_addr_t req_in_addr, rsp_in_addr, dma_req_in_addr, req_in_stalled_addr, req_in_recall_addr; 
    llc_set_t rst_flush_stalled_set;
    llc_set_t req_in_stalled_set; 
    llc_set_t set, set_next, set_in;     
    llc_tag_t req_in_stalled_tag, tag;
    llc_way_t way, way_next;
    
    logic wr_data_dirty_bit;
    hprot_t wr_data_hprot;
    line_t wr_data_line; 
    llc_state_t wr_data_state;
    llc_tag_t wr_data_tag;
    llc_way_t wr_data_evict_way;
    sharers_t wr_data_sharers;
    owner_t wr_data_owner; 
 
    logic rd_data_dirty_bit[`LLC_WAYS];
    hprot_t rd_data_hprot[`LLC_WAYS];
    line_t rd_data_line[`LLC_WAYS];
    llc_state_t rd_data_state[`LLC_WAYS];
    llc_tag_t rd_data_tag[`LLC_WAYS];
    llc_way_t rd_data_evict_way; 
    sharers_t rd_data_sharers[`LLC_WAYS];
    owner_t rd_data_owner[`LLC_WAYS];
    
    logic dirty_bits_buf[`LLC_WAYS];
    hprot_t hprots_buf[`LLC_WAYS];
    line_t lines_buf[`LLC_WAYS];
    llc_state_t states_buf[`LLC_WAYS];
    llc_tag_t tags_buf[`LLC_WAYS];
    llc_way_t evict_way_buf; 
    sharers_t sharers_buf[`LLC_WAYS];
    owner_t owners_buf[`LLC_WAYS];

    logic dirty_bits_buf_wr_data;
    hprot_t hprots_buf_wr_data;
    line_t lines_buf_wr_data;
    llc_state_t states_buf_wr_data;
    llc_tag_t tags_buf_wr_data;
    sharers_t sharers_buf_wr_data;
    owner_t owners_buf_wr_data;
    
    assign set_in = rd_set_en ? set_next : set; 
    assign llc_rsp_in_ready_int = decode_en & is_rsp_to_get_next; 
    assign llc_rst_tb_ready_int = decode_en & is_rst_to_get_next; 
    assign llc_req_in_ready_int = decode_en & do_get_req; 
    assign llc_dma_req_in_ready_int = decode_en & do_get_dma_req;
    assign rd_en = !idle; 
    assign tag = line_br.tag;
 
    //interfaces
    line_breakdown_llc_t line_br();
    llc_dma_req_in_t llc_dma_req_in_next(); 
    llc_rsp_out_t llc_rsp_out_o();
    llc_dma_rsp_out_t llc_dma_rsp_out_o(); 
    llc_fwd_out_t llc_fwd_out_o(); 
    llc_mem_req_t llc_mem_req_o();
    llc_mem_rsp_t llc_mem_rsp_next();
 
`ifdef STATS_ENABLE
    logic llc_stats_ready_int, llc_stats_valid_int, llc_stats_o;
`endif

    //instances
    llc_regs regs_u(.*); 
    llc_input_decoder input_decoder_u(.*);
    llc_interfaces interfaces_u (.*); 
`ifdef XILINX_FPGA
    llc_localmem localmem_u(.*);
`endif
`ifdef ASIC
    llc_localmem_asic localmem_u(.*);
`endif
    llc_update update_u (.*);
    llc_bufs bufs_u(.*);
    llc_lookup_way lookup_way_u(.*); 
    llc_process_request process_request_u(.*);
    
endmodule
