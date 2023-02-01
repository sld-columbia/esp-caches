// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

//llc_process_request.sv
//Author: Joseph Zuckerman
//takes action for next pending request 

module llc_process_request(    
    input logic clk,
    input logic rst, 
    input logic process_en, 
    input logic rst_in,
    input logic is_flush_to_resume,
    input logic is_rst_to_resume,
    input logic is_rst_to_get,
    input logic is_rsp_to_get,
    input logic is_req_to_get, 
    input logic is_dma_req_to_get,
    input logic is_dma_read_to_resume,
    input logic is_dma_write_to_resume,
    input logic is_req_to_resume, 
    input logic recall_pending,
    input logic recall_valid, 
    input logic req_stall, 
    input logic llc_mem_req_ready_int,
    input logic llc_fwd_out_ready_int, 
    input logic llc_rsp_out_ready_int, 
    input logic evict, 
    input logic evict_next, 
    input logic llc_mem_rsp_valid_int, 
    input logic llc_dma_rsp_out_ready_int, 
    input var logic dirty_bits_buf[`LLC_WAYS],
    input var line_t lines_buf[`LLC_WAYS],
    input var llc_tag_t tags_buf[`LLC_WAYS],
    input var sharers_t sharers_buf[`LLC_WAYS],
    input var owner_t owners_buf[`LLC_WAYS],
    input var hprot_t hprots_buf[`LLC_WAYS],
    input var llc_state_t states_buf[`LLC_WAYS],
    input llc_way_t evict_way_buf,
    input llc_tag_t req_in_stalled_tag, 
    input llc_set_t req_in_stalled_set, 
    input llc_set_t set,  
    input llc_way_t way,
    input llc_way_t way_next, 
    input line_addr_t addr_evict, 
    input line_addr_t recall_evict_addr,
    input addr_t dma_addr,
        
    llc_req_in_t.in llc_req_in,     
    llc_dma_req_in_t.in llc_dma_req_in,
    llc_rsp_in_t.in llc_rsp_in,
    llc_mem_rsp_t.in llc_mem_rsp, 
    line_breakdown_llc_t.in line_br, 
  
    output logic llc_mem_req_valid_int, 
    output logic llc_fwd_out_valid_int,
    output logic llc_rsp_out_valid_int,
    output logic llc_mem_rsp_ready_int, 
    output logic llc_dma_rsp_out_valid_int, 
    output logic rst_state, 
    output logic clr_req_stall_process,
    output logic clr_rst_flush_stalled_set, 
    output logic set_recall_valid, 
    output logic set_recall_pending, 
    output logic set_flush_stall,
    output logic wr_en_lines_buf,
    output logic wr_en_tags_buf,
    output logic wr_en_sharers_buf, 
    output logic wr_en_owners_buf, 
    output logic wr_en_hprots_buf, 
    output logic wr_en_dirty_bits_buf, 
    output logic wr_en_states_buf,
    output logic dirty_bits_buf_wr_data, 
    output logic process_done, 
    output logic set_req_stall, 
    output logic set_req_in_stalled_valid, 
    output logic set_req_in_stalled,
    output logic update_req_in_stalled,
    output logic incr_evict_way_buf, 
    output logic set_update_evict_way,
    output logic set_dma_read_pending, 
    output logic set_is_dma_read_to_resume_process, 
    output logic set_dma_write_pending, 
    output logic set_is_dma_write_to_resume_process,
    output logic clr_recall_pending, 
    output logic clr_recall_valid, 
    output logic clr_dma_read_pending, 
    output logic clr_dma_write_pending, 
    output logic incr_dma_addr, 
    output logic set_req_pending, 
    output logic clr_req_pending, 
    output logic set_recall_evict_addr,
    output line_t lines_buf_wr_data, 
    output llc_tag_t tags_buf_wr_data, 
    output sharers_t sharers_buf_wr_data, 
    output owner_t owners_buf_wr_data, 
    output hprot_t hprots_buf_wr_data, 
    output llc_state_t states_buf_wr_data,
        
    llc_mem_req_t.out llc_mem_req_o, 
    llc_fwd_out_t.out llc_fwd_out_o, 
    llc_rsp_out_t.out llc_rsp_out_o, 
    llc_dma_rsp_out_t.out llc_dma_rsp_out_o 

`ifdef STATS_ENABLE
    , input logic llc_stats_ready_int,
    output logic llc_stats_valid_int,
    output logic llc_stats_o
`endif 
    ); 

    //STATE ENCODING 
    localparam IDLE = 5'b00000; 
    localparam PROCESS_FLUSH_RESUME = 5'b00001; 
    localparam PROCESS_RST = 5'b00010;
    localparam PROCESS_RSP = 5'b00011;
    localparam REQ_RECALL_EM = 5'b00100; 
    localparam REQ_RECALL_SSD = 5'b00101; 
    localparam EVICT = 5'b00110; 
    localparam REQ_GET_S_M_IV_MEM_REQ = 5'b00111;
    localparam REQ_GET_S_M_IV_MEM_RSP = 5'b01000;
    localparam REQ_GET_S_M_IV_SEND_RSP = 5'b01001;
    localparam REQ_GETS_S = 5'b01010; 
    localparam REQ_GET_S_M_EM = 5'b01011; 
    localparam REQ_GET_S_M_SD = 5'b01100;
    localparam REQ_GETM_S_FWD = 5'b01101;
    localparam REQ_GETM_S_RSP = 5'b01110;
    localparam REQ_PUTS = 5'b01111;
    localparam REQ_PUTM = 5'b10000;
    localparam DMA_REQ_TO_GET = 5'b10001;
    localparam DMA_RECALL_EM = 5'b10010;
    localparam DMA_RECALL_SSD = 5'b10011; 
    localparam DMA_EVICT = 5'b10100; 
    localparam DMA_READ_RESUME_MEM_REQ = 5'b10101; 
    localparam DMA_READ_RESUME_MEM_RSP = 5'b10110;
    localparam DMA_READ_RESUME_DMA_RSP = 5'b10111;
    localparam DMA_WRITE_RESUME_MEM_REQ = 5'b11000;
    localparam DMA_WRITE_RESUME_MEM_RSP = 5'b11001; 
    localparam DMA_WRITE_RESUME_WRITE = 5'b11010;
    
    logic [4:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= IDLE;
        end else begin 
            state <= next_state; 
        end
    end 

    logic [(`MAX_N_L2_BITS - 1):0] l2_cnt, invack_cnt;
    logic incr_invack_cnt, skip;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            l2_cnt <= 0;
        end else if (state == IDLE) begin 
            l2_cnt <= 0;
        end else if ((state == REQ_RECALL_SSD || state == DMA_RECALL_SSD || state == REQ_GETM_S_FWD) 
                    && (llc_fwd_out_ready_int || skip) && l2_cnt < `MAX_N_L2) begin 
            l2_cnt <= l2_cnt + 1; 
        end
    end

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            invack_cnt <= 0;
        end else if (state == IDLE) begin 
            invack_cnt <= 0;
        end else if (incr_invack_cnt) begin 
            invack_cnt <= invack_cnt + 1; 
        end
    end

`ifdef STATS_ENABLE
    logic stats_new; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            stats_new <= 1'b1;
        end else if (state == IDLE) begin 
            stats_new <= 1'b1;
        end else if (llc_stats_valid_int) begin 
            stats_new <= 1'b0; 
        end
    end 
`endif

    line_addr_t line_addr;
    dma_length_t valid_words;
    word_offset_t dma_read_woffset; 
    word_offset_t dma_write_woffset; 
    invack_cnt_t dma_info; 
    llc_way_t cur_way;
    logic misaligned_next, misaligned; 
    
    always_comb begin 
        next_state = state;
        process_done = 1'b0; 
        if (process_en) begin 
            case (state) 
                IDLE: begin  
                    if (is_flush_to_resume) begin 
                        next_state = PROCESS_FLUSH_RESUME;
                    end else if (is_rst_to_get) begin 
                        next_state = PROCESS_RST;
                    end else if (is_rsp_to_get) begin 
                        next_state = PROCESS_RSP; 
                    end else if (is_req_to_get || is_req_to_resume) begin 
                        if (evict_next && !recall_pending && !recall_valid && states_buf[way_next] != `VALID) begin 
                            case (states_buf[way_next]) 
                                `EXCLUSIVE : next_state = REQ_RECALL_EM;
                                `MODIFIED : next_state = REQ_RECALL_EM;
                                `SD : next_state = REQ_RECALL_SSD;
                                `SHARED : next_state = REQ_RECALL_SSD; 
                                default : next_state = IDLE; 
                            endcase
                        end else if (!recall_pending || recall_valid) begin 
                            if (evict_next) begin 
                                next_state = EVICT; 
                            end else begin 
                                case(llc_req_in.coh_msg) 
                                    `REQ_GETS : begin 
                                        case(states_buf[way_next]) 
                                            `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                            `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                            `SHARED : next_state = REQ_GETS_S;
                                            `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                            `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                            `SD : next_state = REQ_GET_S_M_SD;
                                            default : next_state = IDLE;
                                        endcase
                                    end
                                    `REQ_GETM : begin 
                                        case(states_buf[way_next]) 
                                            `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                            `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                            `SHARED : next_state = REQ_GETM_S_FWD;
                                            `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                            `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                            `SD : next_state = REQ_GET_S_M_SD;
                                            default : next_state = IDLE;
                                        endcase
                                end
                                    `REQ_PUTS : next_state = REQ_PUTS;
                                    `REQ_PUTM : next_state = REQ_PUTM;
                                    default : next_state = IDLE; 
                                endcase
                            end
                        end
                    end else if (is_dma_req_to_get || is_dma_read_to_resume || is_dma_write_to_resume) begin 
                        if (is_dma_req_to_get) begin 
                            next_state = DMA_REQ_TO_GET; 
                        end else if (!recall_valid && !recall_pending && states_buf[way_next] != `INVALID 
                                    && states_buf[way_next] != `VALID) begin 
                            case (states_buf[way_next])
                                `EXCLUSIVE : next_state = DMA_RECALL_EM;
                                `MODIFIED : next_state = DMA_RECALL_EM;
                                `SD : next_state = DMA_RECALL_SSD; 
                                `SHARED : next_state = DMA_RECALL_SSD;
                                default : next_state = IDLE; 
                            endcase
                        end else if (!recall_pending || recall_valid) begin 
                            if (evict_next || recall_valid) begin 
                                next_state = DMA_EVICT;
                            end else if (is_dma_read_to_resume) begin 
                                if (states_buf[way_next] == `INVALID) begin 
                                    next_state = DMA_READ_RESUME_MEM_REQ;
                                end else begin 
                                    next_state = DMA_READ_RESUME_DMA_RSP;
                                end
                            end else begin 
                                if (states_buf[way_next] == `INVALID && misaligned_next) begin 
                                    next_state = DMA_WRITE_RESUME_MEM_REQ;
                                end else begin 
                                    next_state = DMA_WRITE_RESUME_WRITE;
                                end
                            end
                        end 
                    end else begin 
                        process_done = 1'b1; 
                    end
                end 
                PROCESS_FLUSH_RESUME : begin 
                    if (cur_way == `LLC_WAYS - 1 && (llc_mem_req_ready_int || skip)) begin 
                        next_state = IDLE;
                        process_done = 1'b1; 
                    end
                end
                PROCESS_RST : begin 
                     next_state = IDLE;
                     process_done = 1'b1;
                end
                PROCESS_RSP : begin 
                    next_state = IDLE; 
                    process_done = 1'b1; 
                end
                REQ_RECALL_EM : begin 
                    if (llc_fwd_out_ready_int || states_buf[way] == `SD) begin
                        if (recall_valid) begin 
                            if (evict) begin 
                                next_state = EVICT; 
                            end else begin 
                                case(llc_req_in.coh_msg) 
                                    `REQ_GETS : begin 
                                        case(states_buf[way]) 
                                            `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                            `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                            `SHARED : next_state = REQ_GETS_S;
                                            `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                            `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                            `SD : next_state = REQ_GET_S_M_SD;
                                            default : next_state = IDLE;
                                        endcase
                                    end
                                    `REQ_GETM : begin 
                                        case(states_buf[way]) 
                                            `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                            `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                            `SHARED : next_state = REQ_GETM_S_FWD;
                                            `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                            `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                            `SD : next_state = REQ_GET_S_M_SD;
                                            default : next_state = IDLE;
                                        endcase
                                end
                                    `REQ_PUTS : next_state = REQ_PUTS;
                                    `REQ_PUTM : next_state = REQ_PUTM;
                                    default : next_state = IDLE; 
                                endcase
                            end
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                REQ_RECALL_SSD : begin 
                    if (l2_cnt == `MAX_N_L2 - 1 && (llc_fwd_out_ready_int || skip)) begin 
                        if (!recall_pending || recall_valid) begin 
                            if (evict) begin 
                                next_state = EVICT; 
                            end else begin 
                                case(llc_req_in.coh_msg) 
                                    `REQ_GETS : begin 
                                        case(states_buf[way]) 
                                            `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                            `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                            `SHARED : next_state = REQ_GETS_S;
                                            `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                            `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                            `SD : next_state = REQ_GET_S_M_SD;
                                            default : next_state = IDLE;
                                        endcase
                                    end
                                    `REQ_GETM : begin 
                                        case(states_buf[way]) 
                                            `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                            `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                            `SHARED : next_state = REQ_GETM_S_FWD;
                                            `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                            `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                            `SD : next_state = REQ_GET_S_M_SD;
                                            default : next_state = IDLE;
                                        endcase
                                end
                                    `REQ_PUTS : next_state = REQ_PUTS;
                                    `REQ_PUTM : next_state = REQ_PUTM;
                                    default : next_state = IDLE; 
                                endcase
                            end
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end 
                end
                EVICT : begin
                    if ((states_buf[way] == `VALID && dirty_bits_buf[way] && llc_mem_req_ready_int) 
                        || (states_buf[way] != `VALID || !dirty_bits_buf[way])) begin
                        case(llc_req_in.coh_msg) 
                            `REQ_GETS : begin 
                                case(states_buf_wr_data) 
                                    `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                    `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                    `SHARED : next_state = REQ_GETS_S;
                                    `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                    `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                    `SD : next_state = REQ_GET_S_M_SD;
                                    default : next_state = IDLE; 
                                endcase
                            end
                           `REQ_GETM : begin 
                                case(states_buf_wr_data) 
                                    `INVALID : next_state = REQ_GET_S_M_IV_MEM_REQ;
                                    `VALID : next_state = REQ_GET_S_M_IV_SEND_RSP;
                                    `SHARED : next_state = REQ_GETM_S_FWD;
                                    `EXCLUSIVE : next_state = REQ_GET_S_M_EM; 
                                    `MODIFIED : next_state = REQ_GET_S_M_EM; 
                                    `SD : next_state = REQ_GET_S_M_SD;
                                    default : next_state = IDLE; 
                                endcase
                            end
                           `REQ_PUTS : next_state = REQ_PUTS;
                           `REQ_PUTM : next_state = REQ_PUTM;
                           default : next_state = IDLE; 
                        endcase
                    end
                end
                REQ_GET_S_M_IV_MEM_REQ : begin 
                    if (llc_mem_req_ready_int) begin 
                        next_state = REQ_GET_S_M_IV_MEM_RSP; 
                    end 
                end
                REQ_GET_S_M_IV_MEM_RSP : begin 
                    if (llc_mem_rsp_valid_int) begin 
                        next_state = REQ_GET_S_M_IV_SEND_RSP;
                    end
                end
                REQ_GET_S_M_IV_SEND_RSP : begin 
                    if (llc_rsp_out_ready_int) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                REQ_GETS_S:  begin 
                    if (llc_rsp_out_ready_int) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                REQ_GET_S_M_EM: begin 
                    if (llc_fwd_out_ready_int) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                REQ_GET_S_M_SD : begin 
                    next_state = IDLE;
                    process_done = 1'b1;
                end
                REQ_GETM_S_FWD : begin 
                    if (l2_cnt == `MAX_N_L2 - 1 && (llc_fwd_out_ready_int || skip)) begin 
                        next_state = REQ_GETM_S_RSP;
                    end
                end
                REQ_GETM_S_RSP : begin 
                    if (llc_rsp_out_ready_int) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                REQ_PUTS : begin 
                    if (llc_fwd_out_ready_int) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                REQ_PUTM : begin 
                    if (llc_fwd_out_ready_int) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                DMA_REQ_TO_GET : begin 
                    if (!recall_valid && !recall_pending && states_buf[way] != `INVALID && states_buf[way] != `VALID) begin 
                        case (states_buf[way])
                            `EXCLUSIVE : next_state = DMA_RECALL_EM;
                            `MODIFIED : next_state = DMA_RECALL_EM;
                            `SD : next_state = DMA_RECALL_SSD; 
                            `SHARED : next_state = DMA_RECALL_SSD;
                            default : next_state = IDLE; 
                        endcase
                    end else if (!recall_pending || recall_valid) begin 
                        if (evict || recall_valid) begin 
                            next_state = DMA_EVICT;
                        end else if (llc_dma_req_in.coh_msg == `REQ_DMA_READ_BURST) begin 
                            if (states_buf[way] == `INVALID) begin 
                                next_state = DMA_READ_RESUME_MEM_REQ;
                            end else begin 
                                next_state = DMA_READ_RESUME_DMA_RSP;
                            end
                        end else begin 
                            if (states_buf[way] == `INVALID && misaligned_next) begin 
                                next_state = DMA_WRITE_RESUME_MEM_REQ;
                            end else begin 
                                next_state = DMA_WRITE_RESUME_WRITE;
                            end
                        end
                    end else begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                DMA_RECALL_EM : begin 
                    if (llc_fwd_out_ready_int || states_buf[way] == `SD) begin
                        if (recall_valid) begin 
                            if (evict || recall_valid) begin 
                                next_state = DMA_EVICT;
                            end else if (is_dma_read_to_resume) begin 
                                if (states_buf[way] == `INVALID) begin 
                                    next_state = DMA_READ_RESUME_MEM_REQ;
                                end else begin 
                                    next_state = DMA_READ_RESUME_DMA_RSP;
                                end
                            end else begin 
                                if (states_buf[way] == `INVALID && misaligned_next) begin 
                                    next_state = DMA_WRITE_RESUME_MEM_REQ;
                                end else begin 
                                    next_state = DMA_WRITE_RESUME_WRITE;
                                end
                            end
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end 
                end
                DMA_RECALL_SSD : begin 
                    if (l2_cnt == `MAX_N_L2 - 1 && (llc_fwd_out_ready_int || skip)) begin 
                        if (states_buf[way] == `SHARED) begin 
                            next_state = DMA_EVICT;
                        end else if (!recall_pending || recall_valid) begin 
                            if (evict || recall_valid) begin 
                                next_state = DMA_EVICT;
                            end else if (is_dma_read_to_resume) begin 
                                if (states_buf[way] == `INVALID) begin 
                                    next_state = DMA_READ_RESUME_MEM_REQ;
                                end else begin 
                                    next_state = DMA_READ_RESUME_DMA_RSP;
                                end
                            end else begin 
                                if (states_buf[way] == `INVALID && misaligned_next) begin 
                                    next_state = DMA_WRITE_RESUME_MEM_REQ;
                                end else begin 
                                    next_state = DMA_WRITE_RESUME_WRITE;
                                end
                            end
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                DMA_EVICT : begin 
                    if ((evict && ((dirty_bits_buf[way] && llc_mem_req_ready_int) || !dirty_bits_buf[way])) || (!evict)) begin  
                        if (is_dma_read_to_resume) begin 
                            if (states_buf_wr_data == `INVALID) begin 
                                next_state = DMA_READ_RESUME_MEM_REQ;
                            end else begin 
                                next_state = DMA_READ_RESUME_DMA_RSP;
                            end
                        end else begin 
                            if (states_buf_wr_data == `INVALID && misaligned_next) begin 
                                next_state = DMA_WRITE_RESUME_MEM_REQ;
                            end else begin 
                                next_state = DMA_WRITE_RESUME_WRITE;
                            end
                        end
                    end
                end
                DMA_READ_RESUME_MEM_REQ : begin 
                    if (llc_mem_req_ready_int) begin 
                        next_state = DMA_READ_RESUME_MEM_RSP; 
                    end 
                end
                DMA_READ_RESUME_MEM_RSP : begin 
                    if (llc_mem_rsp_valid_int) begin 
                        next_state = DMA_READ_RESUME_DMA_RSP; 
                    end
                end
                DMA_READ_RESUME_DMA_RSP: begin 
                    if (llc_dma_rsp_out_ready_int) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
                DMA_WRITE_RESUME_MEM_REQ : begin 
                    if (llc_mem_req_ready_int) begin 
                        next_state = DMA_WRITE_RESUME_MEM_RSP; 
                    end 
                end
                DMA_WRITE_RESUME_MEM_RSP : begin 
                    if (llc_mem_rsp_valid_int) begin 
                        next_state = DMA_WRITE_RESUME_WRITE; 
                    end
                end
                DMA_WRITE_RESUME_WRITE : begin 
                    next_state = IDLE;
                    process_done = 1'b1;
                end
                default : next_state = IDLE; 
            endcase
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            cur_way <= 0;
        end else if (state == IDLE) begin 
            cur_way <= 0; 
        end else if ((state == PROCESS_FLUSH_RESUME) && (llc_mem_req_ready_int || skip)) begin 
            cur_way <= cur_way + 1; 
        end
    end
    
    logic dma_start, dma_done; 
    dma_length_t dma_length, dma_read_length; 
    
    logic dma_start_next; 
    dma_length_t dma_length_next; 

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            dma_start <= 1'b0; 
            dma_length <= 0; 
            dma_read_length <= 0; 
        end else if (state == DMA_REQ_TO_GET) begin 
            dma_start <= 1'b1; 
            dma_length <= 0; 
            dma_read_length <= llc_dma_req_in.line[(`BITS_PER_LINE - 1) : (`BITS_PER_LINE - `ADDR_BITS)];
        end else if (state == DMA_READ_RESUME_DMA_RSP || state == DMA_WRITE_RESUME_WRITE) begin 
            dma_start <= dma_start_next; 
            dma_length <= dma_length_next; 
        end 
    end
 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            misaligned <= 1'b0; 
        end else begin 
            misaligned <= misaligned_next;
        end
    end

    logic [`WORDS_PER_LINE-1:0] words_to_write;
    logic [`WORD_BITS-1:0] words_to_write_sum; 
    always_comb begin 
        //imterfaces
        llc_mem_req_o.hwrite = 0; 
        llc_mem_req_o.hsize = 0; 
        llc_mem_req_o.hprot = 0;
        llc_mem_req_o.addr = 0;
        llc_mem_req_o.line = 0;
        llc_mem_req_valid_int = 1'b0; 
        
        llc_rsp_out_o.coh_msg = 0;
        llc_rsp_out_o.addr = 0; 
        llc_rsp_out_o.line = 0; 
        llc_rsp_out_o.req_id = 0;
        llc_rsp_out_o.dest_id = 0; 
        llc_rsp_out_o.invack_cnt = 0; 
        llc_rsp_out_o.word_offset = 0;
        llc_rsp_out_valid_int = 1'b0; 
        
        llc_fwd_out_o.coh_msg = 0; 
        llc_fwd_out_o.addr = 0; 
        llc_fwd_out_o.req_id = 0; 
        llc_fwd_out_o.dest_id = 0;
        llc_fwd_out_valid_int = 1'b0;
        
        llc_dma_rsp_out_o.coh_msg = 0;
        llc_dma_rsp_out_o.addr = 0; 
        llc_dma_rsp_out_o.line = 0; 
        llc_dma_rsp_out_o.req_id = 0;
        llc_dma_rsp_out_o.dest_id = 0; 
        llc_dma_rsp_out_o.invack_cnt = 0; 
        llc_dma_rsp_out_o.word_offset = 0;
        llc_dma_rsp_out_valid_int = 1'b0;

        llc_mem_rsp_ready_int = 1'b0; 
              
        //write to buffers 
        lines_buf_wr_data = 0; 
        wr_en_lines_buf = 1'b0;
        dirty_bits_buf_wr_data = 1'b0;
        wr_en_dirty_bits_buf = 1'b0;
        states_buf_wr_data = 0;
        wr_en_states_buf = 1'b0; 
        sharers_buf_wr_data = 0;
        wr_en_sharers_buf = 1'b0;
        owners_buf_wr_data = 0; 
        wr_en_owners_buf = 1'b0; 
        wr_en_hprots_buf = 1'b0; 
        hprots_buf_wr_data = 0; 
        wr_en_tags_buf = 1'b0; 
        tags_buf_wr_data = 0;
        incr_evict_way_buf = 1'b0;
        set_update_evict_way = 1'b0;  

        //stalls/recalls
        set_flush_stall = 1'b0; 
        clr_rst_flush_stalled_set = 1'b0;  
        clr_req_stall_process = 1'b0; 
        set_req_stall = 1'b0; 
        set_req_in_stalled_valid = 1'b0; 
        set_req_in_stalled = 1'b0; 
        update_req_in_stalled = 1'b0;
        set_recall_pending = 1'b0; 
        clr_recall_pending = 1'b0;
        clr_recall_valid = 1'b0; 
        set_req_pending = 1'b0;
        clr_req_pending = 1'b0; 
        set_recall_evict_addr = 1'b0;
        set_recall_valid = 1'b0; 
        
        //DMA
        set_dma_read_pending = 1'b0; 
        set_is_dma_read_to_resume_process = 1'b0;
        set_dma_write_pending = 1'b0; 
        set_is_dma_write_to_resume_process = 1'b0;
        valid_words = `WORDS_PER_LINE;
        dma_read_woffset = 0;
        dma_write_woffset = 0; 
        dma_info = 0; 
        dma_done = 1'b0;
        dma_length_next = 0; 
        dma_start_next = 1'b0; 
        incr_dma_addr = 1'b0; 
        clr_dma_read_pending = 1'b0; 
        clr_dma_write_pending = 1'b0; 
        words_to_write = 0;
        words_to_write_sum = 0;
        misaligned_next = 1'b0;
        
        //misc 
        line_addr = 0; 
        skip = 1'b0;
        incr_invack_cnt = 1'b0; 
        rst_state = 1'b0;  

`ifdef STATS_ENABLE
        llc_stats_o = 1'b0; 
        llc_stats_valid_int = 1'b0; 
`endif

        case (state)
            IDLE : begin  
                dma_write_woffset = llc_dma_req_in.word_offset;
                valid_words = llc_dma_req_in.valid_words + 1; 
                misaligned_next = ((dma_write_woffset != 0) || (valid_words != `WORDS_PER_LINE));
            end
            PROCESS_FLUSH_RESUME :  begin 
                line_addr = (tags_buf[cur_way] << `LLC_SET_BITS) | set; 
                if (states_buf[cur_way] == `VALID && dirty_bits_buf[cur_way]) begin 
                    llc_mem_req_o.hwrite = `LLC_WRITE;
                    llc_mem_req_o.addr = line_addr; 
                    llc_mem_req_o.hsize = `WORD;
                    llc_mem_req_o.hprot = hprots_buf[cur_way]; 
                    llc_mem_req_o.line = lines_buf[cur_way];
                    llc_mem_req_valid_int = 1'b1; 
                end else begin  
                    skip = 1'b1; 
                end
            end  
            PROCESS_RST : begin 
                //FLUSH
                if (rst_in) begin 
                    set_flush_stall = 1'b1; 
                    clr_rst_flush_stalled_set = 1'b1;
                end else begin
                    rst_state = 1'b1; 
                end
            end 
            PROCESS_RSP : begin 
                if (recall_pending && (llc_rsp_in.addr == recall_evict_addr)) begin 
                    if (llc_rsp_in.coh_msg == `RSP_DATA) begin 
                        wr_en_lines_buf = 1'b1;
                        lines_buf_wr_data = llc_rsp_in.line;
                        wr_en_dirty_bits_buf = 1'b1; 
                        dirty_bits_buf_wr_data = 1'b1;
                    end
                    set_recall_valid = 1'b1;
                end else begin 
                    wr_en_lines_buf = 1'b1;
                    lines_buf_wr_data = llc_rsp_in.line;
                    wr_en_dirty_bits_buf = 1'b1; 
                    dirty_bits_buf_wr_data = 1'b1;
                end 
                
                if (req_stall && (line_br.tag == req_in_stalled_tag) && (line_br.set == req_in_stalled_set)) begin 
                    clr_req_stall_process = 1'b1;
                end
                
                if (states_buf[way] == `SD && set_recall_valid) begin 
                    wr_en_states_buf = 1'b1; 
                    states_buf_wr_data = `VALID;
                end else if (sharers_buf[way] != 0) begin 
                    wr_en_states_buf = 1'b1;
                    states_buf_wr_data = `SHARED;
                end else begin 
                    wr_en_states_buf = 1'b1; 
                    states_buf_wr_data = `VALID;
                end
            end
            REQ_RECALL_EM : begin 
                set_req_pending = 1'b1;
                set_recall_pending = 1'b1;
                set_recall_evict_addr = 1'b1;
                llc_fwd_out_o.coh_msg = `FWD_GETM_LLC; 
                llc_fwd_out_o.addr = addr_evict; 
                llc_fwd_out_o.req_id = owners_buf[way]; 
                llc_fwd_out_o.dest_id = owners_buf[way];;
                llc_fwd_out_valid_int = 1'b1; 
            end
            REQ_RECALL_SSD : begin 
                set_recall_evict_addr = 1'b1;
                if (states_buf[way] == `SD) begin 
                    set_recall_pending = 1'b1; 
                    set_req_pending = 1'b1; 
                end
                if (sharers_buf[way] & (1 << l2_cnt)) begin 
                    llc_fwd_out_o.coh_msg = `FWD_INV_LLC; 
                    llc_fwd_out_o.addr = addr_evict; 
                    llc_fwd_out_o.req_id = l2_cnt; 
                    llc_fwd_out_o.dest_id = l2_cnt;
                    llc_fwd_out_valid_int = 1'b1; 
                end else begin 
                    skip = 1'b1;
                end
            end
            EVICT : begin 
                clr_recall_pending = 1'b1;
                clr_recall_valid = 1'b1;
                clr_req_pending = 1'b1; 

                if (way == evict_way_buf) begin 
                    set_update_evict_way = 1'b1;  
                    incr_evict_way_buf = 1'b1;
                end 
                if (dirty_bits_buf[way]) begin 
                    llc_mem_req_valid_int = 1'b1; 
                    llc_mem_req_o.hwrite = `LLC_WRITE;
                    llc_mem_req_o.addr = addr_evict; 
                    llc_mem_req_o.hsize = `WORD; 
                    llc_mem_req_o.hprot = hprots_buf[way]; 
                    llc_mem_req_o.line = lines_buf[way];  
                end
                wr_en_states_buf = 1'b1; 
                states_buf_wr_data = `INVALID;
                wr_en_sharers_buf = 1'b1; 
                sharers_buf_wr_data = 0; 
                wr_en_owners_buf = 1'b1; 
                owners_buf_wr_data = 0; 
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_GET_S_M_IV_MEM_REQ : begin 
                llc_mem_req_valid_int = 1'b1; 
                llc_mem_req_o.hwrite = `READ;
                llc_mem_req_o.addr = llc_req_in.addr; 
                llc_mem_req_o.hsize = `WORD; 
                llc_mem_req_o.hprot = llc_req_in.hprot; 
                llc_mem_req_o.line = 0; 
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_GET_S_M_IV_MEM_RSP : begin 
                wr_en_hprots_buf = 1'b1; 
                hprots_buf_wr_data = llc_req_in.hprot; 
                wr_en_tags_buf = 1'b1; 
                tags_buf_wr_data = line_br.tag; 
                wr_en_dirty_bits_buf = 1'b1; 
                dirty_bits_buf_wr_data = 1'b0;
                llc_mem_rsp_ready_int = 1'b1; 
            end
            REQ_GET_S_M_IV_SEND_RSP : begin 
                if (llc_req_in.coh_msg == `REQ_GETS && llc_req_in.hprot == 1'b0)  begin 
                    llc_rsp_out_o.coh_msg = `RSP_DATA;
                    wr_en_sharers_buf = 1'b1; 
                    sharers_buf_wr_data = 1 << llc_req_in.req_id; 
                    states_buf_wr_data = `SHARED;
                end else begin 
                    if (llc_req_in.coh_msg == `REQ_GETS) begin 
                        llc_rsp_out_o.coh_msg = `RSP_EDATA; 
                        states_buf_wr_data = `EXCLUSIVE;
                    end else if (llc_req_in.coh_msg == `REQ_GETM) begin 
                        llc_rsp_out_o.coh_msg = `RSP_DATA;
                        states_buf_wr_data = `MODIFIED;
                    end
                    wr_en_owners_buf = 1'b1; 
                    owners_buf_wr_data = llc_req_in.req_id;
                end
                wr_en_states_buf = 1'b1; 
                llc_rsp_out_o.addr = llc_req_in.addr; 
                llc_rsp_out_o.line = lines_buf[way]; 
                llc_rsp_out_o.req_id = llc_req_in.req_id;
                llc_rsp_out_o.dest_id = 0; 
                llc_rsp_out_o.invack_cnt = 0; 
                llc_rsp_out_o.word_offset = 0;
                llc_rsp_out_valid_int = 1'b1; 
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_GETS_S : begin 
                wr_en_sharers_buf = 1'b1; 
                sharers_buf_wr_data = sharers_buf[way] | (1 << llc_req_in.req_id); 

                llc_rsp_out_o.coh_msg = `RSP_DATA;
                llc_rsp_out_o.addr = llc_req_in.addr; 
                llc_rsp_out_o.line = lines_buf[way]; 
                llc_rsp_out_o.req_id = llc_req_in.req_id;
                llc_rsp_out_o.dest_id = 0; 
                llc_rsp_out_o.invack_cnt = 0; 
                llc_rsp_out_o.word_offset = 0;
                llc_rsp_out_valid_int = 1'b1; 
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_GET_S_M_EM : begin 
                if (llc_req_in.coh_msg == `REQ_GETS) begin 
                    states_buf_wr_data = `SD;    
                    llc_fwd_out_o.coh_msg = `FWD_GETS; 
                    wr_en_sharers_buf = 1'b1; 
                    sharers_buf_wr_data = (1 << llc_req_in.req_id) | (1 << owners_buf[way]); 
                    wr_en_states_buf = 1'b1; 
                end else if (llc_req_in.coh_msg == `REQ_GETM) begin 
                    llc_fwd_out_o.coh_msg = `FWD_GETM;
                    if (states_buf[way] == `EXCLUSIVE) begin 
                        wr_en_states_buf = 1'b1; 
                        states_buf_wr_data = `MODIFIED;
                    end
                    wr_en_owners_buf = 1'b1; 
                    owners_buf_wr_data = llc_req_in.req_id; 
                end
                llc_fwd_out_o.addr = llc_req_in.addr; 
                llc_fwd_out_o.req_id = llc_req_in.req_id; 
                llc_fwd_out_o.dest_id = owners_buf[way];
                llc_fwd_out_valid_int = 1'b1;
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_GET_S_M_SD : begin 
                set_req_stall = 1'b1; 
                set_req_in_stalled_valid = 1'b1; 
                set_req_in_stalled = 1'b1; 
                update_req_in_stalled = 1'b1;
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_GETM_S_FWD : begin 
                if (((sharers_buf[way] & (1 << l2_cnt)) != 0) && (l2_cnt != llc_req_in.req_id)) begin 
                    if (llc_fwd_out_ready_int) begin 
                        incr_invack_cnt = 1'b1; 
                    end
                    llc_fwd_out_o.coh_msg = `FWD_INV; 
                    llc_fwd_out_o.addr = llc_req_in.addr; 
                    llc_fwd_out_o.req_id = llc_req_in.req_id; 
                    llc_fwd_out_o.dest_id = l2_cnt; 
                    llc_fwd_out_valid_int = 1'b1;
                end else begin 
                    skip = 1'b1;
                end
`ifdef STATS_ENABLE
                if (stats_new) begin 
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_GETM_S_RSP : begin 
                llc_rsp_out_o.coh_msg = `RSP_DATA;
                llc_rsp_out_o.addr = llc_req_in.addr; 
                llc_rsp_out_o.line = lines_buf[way]; 
                llc_rsp_out_o.req_id = llc_req_in.req_id;
                llc_rsp_out_o.dest_id = 0; 
                llc_rsp_out_o.invack_cnt = invack_cnt; 
                llc_rsp_out_o.word_offset = 0;
                llc_rsp_out_valid_int = 1'b1;

                wr_en_states_buf = 1'b1; 
                states_buf_wr_data = `MODIFIED; 
                wr_en_owners_buf = 1'b1; 
                owners_buf_wr_data = llc_req_in.req_id; 
                wr_en_sharers_buf = 1'b1; 
                sharers_buf_wr_data = 0; 
            end
            REQ_PUTS : begin 
                llc_rsp_out_o.coh_msg = `RSP_PUTACK;
                llc_rsp_out_o.addr = llc_req_in.addr; 
                llc_rsp_out_o.req_id = llc_req_in.req_id; 
                llc_rsp_out_o.dest_id = llc_req_in.req_id;
                llc_rsp_out_valid_int = 1'b1; 
                if (states_buf[way] == `SHARED || states_buf[way] == `SD) begin 
                    wr_en_sharers_buf = 1'b1; 
                    sharers_buf_wr_data = sharers_buf[way] & ~(1 << llc_req_in.req_id);
                    if (states_buf[way] == `SHARED && sharers_buf_wr_data == 0) begin 
                        states_buf_wr_data = `VALID;
                        wr_en_states_buf = 1'b1; 
                    end
                end else if (states_buf[way] == `EXCLUSIVE && owners_buf[way] == llc_req_in.req_id) begin 
                    wr_en_states_buf = 1'b1; 
                    states_buf_wr_data = `VALID; 
                end 
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            REQ_PUTM : begin 
                llc_rsp_out_o.coh_msg = `RSP_PUTACK; 
                llc_rsp_out_o.addr = llc_req_in.addr; 
                llc_rsp_out_o.req_id = llc_req_in.req_id; 
                llc_rsp_out_o.dest_id = llc_req_in.req_id;
                llc_rsp_out_valid_int = 1'b1; 
                if (states_buf[way] == `SHARED || states_buf[way] == `SD) begin 
                    sharers_buf_wr_data = sharers_buf[way] & ~(1 << llc_req_in.req_id);
                    wr_en_sharers_buf = 1'b1;
                    if (states_buf[way] == `SHARED && sharers_buf_wr_data == 0) begin 
                        states_buf_wr_data = `VALID;
                        wr_en_states_buf = 1'b1; 
                    end
                end else if (states_buf[way] == `EXCLUSIVE || states_buf[way] == `MODIFIED) begin 
                    if (owners_buf[way] == llc_req_in.req_id) begin 
                        wr_en_states_buf = 1'b1; 
                        states_buf_wr_data = `VALID;
                        wr_en_lines_buf = 1'b1; 
                        lines_buf_wr_data = llc_req_in.line;
                        wr_en_dirty_bits_buf = 1'b1;
                        dirty_bits_buf_wr_data = 1'b1;
                    end
                end
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            DMA_REQ_TO_GET : begin 
                dma_write_woffset = llc_dma_req_in.word_offset;
                valid_words = llc_dma_req_in.valid_words + 1; 
                misaligned_next = ((dma_write_woffset != 0) || (valid_words != `WORDS_PER_LINE));
                if (llc_dma_req_in.coh_msg == `REQ_DMA_READ_BURST) begin 
                    set_dma_read_pending = 1'b1; 
                    set_is_dma_read_to_resume_process = 1'b1; 
                end else begin 
                    set_dma_write_pending = 1'b1; 
                    set_is_dma_write_to_resume_process = 1'b1;
                end
            end
            DMA_RECALL_EM : begin 
                dma_write_woffset = llc_dma_req_in.word_offset;
                valid_words = llc_dma_req_in.valid_words + 1; 
                misaligned_next = ((dma_write_woffset != 0) || (valid_words != `WORDS_PER_LINE));
                set_recall_evict_addr = 1'b1;
                set_recall_pending = 1'b1;
                llc_fwd_out_o.coh_msg = `FWD_GETM_LLC; 
                llc_fwd_out_o.addr = addr_evict; 
                llc_fwd_out_o.req_id = owners_buf[way]; 
                llc_fwd_out_o.dest_id = owners_buf[way];;
                llc_fwd_out_valid_int = 1'b1; 
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            DMA_RECALL_SSD : begin 
                dma_write_woffset = llc_dma_req_in.word_offset;
                valid_words = llc_dma_req_in.valid_words + 1; 
                misaligned_next = ((dma_write_woffset != 0) || (valid_words != `WORDS_PER_LINE));
                set_recall_evict_addr = 1'b1;
                if (states_buf[way] == `SHARED) begin 
                    set_recall_valid = 1'b1;
                end
                if (states_buf[way] == `SD) begin 
                    set_recall_pending = 1'b1;
                end
                if (sharers_buf[way] & (1 << l2_cnt)) begin 
                    llc_fwd_out_o.coh_msg = `FWD_INV_LLC; 
                    llc_fwd_out_o.addr = addr_evict; 
                    llc_fwd_out_o.req_id = l2_cnt; 
                    llc_fwd_out_o.dest_id = l2_cnt;
                    llc_fwd_out_valid_int = 1'b1; 
                end else begin 
                    skip = 1'b1;
                end
`ifdef STATS_ENABLE
                if (stats_new) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            DMA_EVICT : begin 
                clr_recall_pending = 1'b1;
                clr_recall_valid = 1'b1; 
                
                wr_en_owners_buf = 1'b1;
                owners_buf_wr_data = 0;
                wr_en_sharers_buf = 1'b1;
                sharers_buf_wr_data = 0; 
                dma_write_woffset = llc_dma_req_in.word_offset;
                valid_words = llc_dma_req_in.valid_words + 1; 
                misaligned_next = ((dma_write_woffset != 0) || (valid_words != `WORDS_PER_LINE));
 
                if (evict) begin 
                    if (way == evict_way_buf) begin 
                        set_update_evict_way = 1'b1; 
                        incr_evict_way_buf = 1'b1;
                    end
                    if (dirty_bits_buf[way]) begin 
                        llc_mem_req_o.hwrite = `LLC_WRITE;
                        llc_mem_req_o.addr = addr_evict; 
                        llc_mem_req_o.hsize = `WORD;
                        llc_mem_req_o.hprot = hprots_buf[way]; 
                        llc_mem_req_o.line = lines_buf[way];
                        llc_mem_req_valid_int = 1'b1;
                    end 
                    states_buf_wr_data = `INVALID;
                    wr_en_states_buf = 1'b1;
                end else if (recall_valid) begin 
                    states_buf_wr_data = `VALID;
                    wr_en_states_buf = 1'b1;
                end
`ifdef STATS_ENABLE
                if (stats_new && !recall_valid && !recall_pending) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            DMA_READ_RESUME_MEM_REQ : begin 
                llc_mem_req_o.hwrite = `READ;
                llc_mem_req_o.addr = dma_addr; 
                llc_mem_req_o.hsize = `WORD;
                llc_mem_req_o.hprot = llc_dma_req_in.hprot; 
                llc_mem_req_o.line = 0;
                llc_mem_req_valid_int = 1'b1;
`ifdef STATS_ENABLE
                if (stats_new && !recall_valid && !recall_pending) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            DMA_READ_RESUME_MEM_RSP : begin 
                llc_mem_rsp_ready_int = 1'b1; 
            end
            DMA_READ_RESUME_DMA_RSP : begin 
                if (states_buf[way] == `INVALID) begin 
                    wr_en_hprots_buf = 1'b1; 
                    hprots_buf_wr_data = `DATA; 
                    wr_en_tags_buf = 1'b1; 
                    tags_buf_wr_data = line_br.tag;
                    wr_en_states_buf = 1'b1; 
                    states_buf_wr_data = `VALID; 
                    wr_en_dirty_bits_buf = 1'b1; 
                    dirty_bits_buf_wr_data = 1'b0;
                end

                if (dma_start) begin 
                    dma_read_woffset = llc_dma_req_in.word_offset;
                end else begin 
                    dma_read_woffset = 0;
                end

                //only increment once
                if (llc_dma_rsp_out_ready_int) begin 
                    dma_length_next = dma_length + (`WORDS_PER_LINE - dma_read_woffset); 
                end else begin 
                    dma_length_next = dma_length;
                end

               
                if (dma_length_next >= dma_read_length) begin 
                    dma_done = 1'b1; 
                end

                if (dma_start & dma_done) begin 
                    valid_words = dma_read_length; 
                end else if (dma_start) begin 
                    valid_words = dma_length_next;
                end else if (dma_length_next > dma_read_length) begin 
                    valid_words = `WORDS_PER_LINE - (dma_length_next - dma_read_length);
                end else begin 
                    valid_words = `WORDS_PER_LINE;
                end 

                dma_info[0] = dma_done; 
                dma_info[`WORD_BITS:1] = valid_words - 1; 
                
                llc_dma_rsp_out_o.coh_msg = `RSP_DATA_DMA;
                llc_dma_rsp_out_o.addr = dma_addr; 
                llc_dma_rsp_out_o.line = lines_buf[way]; 
                llc_dma_rsp_out_o.req_id = llc_dma_req_in.req_id;
                llc_dma_rsp_out_o.dest_id = 0; 
                llc_dma_rsp_out_o.invack_cnt = dma_info; 
                llc_dma_rsp_out_o.word_offset = dma_read_woffset;
                llc_dma_rsp_out_valid_int = 1'b1;

                if (llc_dma_rsp_out_ready_int) begin 
                    incr_dma_addr = 1'b1; 
                    dma_start_next = 1'b0; 
                    if (dma_done) begin 
                        clr_dma_read_pending = 1'b1; 
                        clr_dma_write_pending = 1'b1;
                    end 
                end
`ifdef STATS_ENABLE
                if (stats_new && !recall_valid && !recall_pending) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            DMA_WRITE_RESUME_MEM_REQ : begin 
                llc_mem_req_o.hwrite = `READ;
                llc_mem_req_o.addr = dma_addr; 
                llc_mem_req_o.hsize = `WORD;
                llc_mem_req_o.hprot = llc_dma_req_in.hprot; 
                llc_mem_req_o.line = 0;
                llc_mem_req_valid_int = 1'b1;
`ifdef STATS_ENABLE
                if (stats_new && !recall_valid && !recall_pending) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end
            DMA_WRITE_RESUME_MEM_RSP : begin 
                dma_write_woffset = llc_dma_req_in.word_offset;
                valid_words = llc_dma_req_in.valid_words + 1; 
                misaligned_next = ((dma_write_woffset != 0) || (valid_words != `WORDS_PER_LINE));
                llc_mem_rsp_ready_int = 1'b1;  
            end
            DMA_WRITE_RESUME_WRITE : begin 
                dma_write_woffset = llc_dma_req_in.word_offset;
                valid_words = llc_dma_req_in.valid_words + 1; 
                if (misaligned) begin 
                    lines_buf_wr_data = lines_buf[way]; 
                    
                    for (int i = 0; i < `WORDS_PER_LINE; i++) begin 
                        if (i >= dma_write_woffset) begin
                            words_to_write[i] = 1'b1; 
                        end
                    end
                   
                    for (int i = 0; i < `WORDS_PER_LINE; i++) begin 
                        words_to_write_sum = 0; 
                        for (int j = 0; j < i; j++) begin 
                            words_to_write_sum = words_to_write_sum + words_to_write[j];
                        end 
                        if (words_to_write[i] && (valid_words > words_to_write_sum)) begin 
                            lines_buf_wr_data[(`BITS_PER_WORD*i + `BITS_PER_WORD -1) -: (`BITS_PER_WORD)] 
                                = llc_dma_req_in.line[(`BITS_PER_WORD*i + `BITS_PER_WORD - 1) -: (`BITS_PER_WORD)];
                        end
                    end

                    wr_en_lines_buf = 1'b1; 
                end else begin 
                    wr_en_lines_buf = 1'b1; 
                    lines_buf_wr_data = llc_dma_req_in.line; 
                end
    
                wr_en_dirty_bits_buf = 1'b1; 
                dirty_bits_buf_wr_data = 1'b1; 
                
                if (states_buf[way] == `INVALID) begin 
                    wr_en_states_buf = 1'b1;
                    states_buf_wr_data = `VALID;
                    wr_en_hprots_buf = 1'b1; 
                    hprots_buf_wr_data = `DATA; 
                    wr_en_tags_buf = 1'b1;
                    tags_buf_wr_data = line_br.tag; 
                end

                if (llc_dma_req_in.hprot) begin 
                    dma_done = 1'b1; 
                end
                    
                incr_dma_addr = 1'b1; 
                dma_start_next = 1'b0;
                if (dma_done) begin 
                    clr_dma_read_pending = 1'b1; 
                    clr_dma_write_pending = 1'b1;
                end  
`ifdef STATS_ENABLE
                if (stats_new && !recall_valid && !recall_pending) begin
                    llc_stats_o = ~((states_buf[way] == `INVALID) || evict);
                    llc_stats_valid_int = 1'b1; 
                end
`endif
            end 
            default : skip = 1'b0;  
        endcase
    end
endmodule
