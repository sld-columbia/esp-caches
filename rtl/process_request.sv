`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

//process_request.sv
//Author: Joseph Zuckerman
//takes action for next pending request 

module process_request(clk, rst, process_en, way, is_flush_to_resume, is_rst_to_resume, is_rst_to_get, is_rsp_to_get, is_req_to_get, is_dma_req_to_get, set, llc_rsp_in, recall_pending, line_br, req_in_stalled_tag, req_in_stalled_set, flush_stall, rst_stall, req_stall, llc_mem_req_ready, llc_rst_tb_done_ready, addr_evict, lines_buf, tags_buf, sharers_buf, owners_buf, hprots_buf, dirty_bits_buf, evict_way_buf, states_buf, llc_mem_req, llc_mem_req_valid, llc_rst_tb_done_valid, llc_rst_tb_done, clr_flush_stall, clr_req_stall, clr_rst_flush_stalled_set, set_recall_valid, wr_en_lines_buf, wr_en_tags_buf, wr_en_sharers_buf, wr_en_owners_buf, wr_en_hprots_buf, wr_en_dirty_bits_buf, wr_en_states_buf, wr_en_evict_way_buf, lines_buf_wr_data, tags_buf_wr_data, sharers_buf_wr_data, owners_buf_wr_data, hprots_buf_wr_data, dirty_bits_buf_wr_data, states_buf_wr_data, evict_way_buf_wr_data, process_done, llc_fwd_out, llc_fwd_out_ready, llc_fwd_out_valid,  llc_rsp_out, llc_rsp_out_ready, llc_rsp_out_valid, llc_mem_req, llc_mem_rsp, llc_mem_rsp_valid, llc_mem_rsp_ready, llc_req_in, rst_in, rst_state, set_req_stall, set_req_in_stalled_valid, set_req_in_stalled, update_req_in_stalled, incr_evict_way_buf, set_update_evict_way, evict); 
    
    input logic clk, rst; 
    input logic process_en; 
    input logic rst_in;

    input llc_way_t way;
    input logic is_flush_to_resume, is_rst_to_resume, is_rst_to_get, is_rsp_to_get, is_req_to_get, is_dma_req_to_get; 
    input llc_set_t set;  
    llc_req_in_t llc_req_in;     
    llc_rsp_in_t llc_rsp_in;
    llc_mem_rsp_t llc_mem_rsp; 
    input logic recall_pending; 
    
    line_breakdown_llc_t line_br; 
    input llc_tag_t req_in_stalled_tag; 
    input llc_set_t req_in_stalled_set; 
    input flush_stall, rst_stall, req_stall; 
    input logic llc_mem_req_ready;
    input logic llc_rst_tb_done_ready;
    input logic llc_fwd_out_ready; 
    input logic llc_rsp_out_ready; 
    input llc_addr_t addr_evict;
    input logic evict; 
    input llc_mem_rsp_valid; 

    input line_t lines_buf[`LLC_WAYS];
    input llc_tag_t tags_buf[`LLC_WAYS];
    input sharers_t sharers_buf[`LLC_WAYS];
    input owner_t owners_buf[`LLC_WAYS];
    input hprot_t hprots_buf[`LLC_WAYS];
    input logic dirty_bits_buf[`LLC_WAYS];
    input llc_way_t evict_way_buf;
    input llc_state_t states_buf[`LLC_WAYS];
    
    llc_mem_req_t llc_mem_req; 
    llc_fwd_out_t llc_fwd_out; 
    llc_rsp_out_t llc_rsp_out; 

    output logic llc_mem_req_valid; 
    output logic llc_rst_tb_done_valid;
    output logic llc_rst_tb_done; 
    output logic llc_fwd_out_valid;
    output logic llc_rsp_out_valid;
    output logic llc_mem_rsp_ready; 

    output logic rst_state; 
    output logic clr_flush_stall, clr_req_stall;
    output logic clr_rst_flush_stalled_set; 
    output logic set_recall_valid; 

    output logic wr_en_lines_buf, wr_en_tags_buf, wr_en_sharers_buf, wr_en_owners_buf, wr_en_hprots_buf, wr_en_dirty_bits_buf, wr_en_states_buf, wr_en_evict_way_buf;
    output line_t lines_buf_wr_data; 
    output llc_tag_t tags_buf_wr_data; 
    output sharers_t sharers_buf_wr_data; 
    output owner_t owners_buf_wr_data; 
    output hprot_t hprots_buf_wr_data; 
    output logic dirty_bits_buf_wr_data; 
    output llc_state_t states_buf_wr_data;
    output llc_way_t evict_way_buf_wr_data;
    output logic process_done; 
    output logic set_req_stall, set_req_in_stalled_valid, set_req_in_stalled, update_req_in_stalled;
    output logic incr_evict_way_buf, set_update_evict_way; 
    //STATE LOGIC
    localparam IDLE = 4'b0000; 
    localparam PROCESS_FLUSH_RESUME = 4'b0001; 
    localparam PROCESS_RST = 4'b0010;
    localparam PROCESS_RSP = 4'b0011;
    localparam EVICT = 4'b0100; 
    localparam PROCESS_REQ_GET_S_M_IV_MEM_REQ = 4'b0101;
    localparam PROCESS_REQ_GET_S_M_IV_MEM_RSP = 4'b0110;
    localparam PROCESS_REQ_GET_S_M_IV_SEND_RSP = 4'b0111;
    localparam PROCESS_REQ_GETS_S = 4'b1000; 
    localparam PROCESS_REQ_GET_S_M_EM = 4'b1001; 
    localparam PROCESS_REQ_GET_S_M_SD = 4'b1010;
    localparam PROCESS_REQ_GETM_S_FWD = 4'b1011;
    localparam PROCESS_REQ_GETM_S_RSP = 4'b1100;
    localparam PROCESS_REQ_PUTS = 4'b1101;
    localparam PROCESS_REQ_PUTM = 4'b1110;
    localparam FINISH_RST_FLUSH = 4'b1111;

    logic [3:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= IDLE;
        end else begin 
            state <= next_state; 
        end
    end 

    logic [(`MAX_N_L2_BITS - 1):0] l2_cnt, invack_cnt;
    logic incr_invack_cnt;
    always @(posedge clk or negedge rst) begin 
        if (!rst || (state == IDLE)) begin 
            l2_cnt <= 0;
        end else if (state == PROCESS_REQ_GETM_S_FWD && llc_fwd_out_ready) begin 
            l2_cnt <= l2_cnt + 1; 
        end

        if (!rst || (state == IDLE)) begin 
            invack_cnt <= 0;
        end else if (incr_invack_cnt) begin 
            invack_cnt <= invack_cnt + 1; 
        end
    end

    llc_way_t cur_way;
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
                    end else if (is_req_to_get) begin 
                        if (evict) begin 
                            next_state = EVICT; 
                        end else begin 
                            case(llc_req_in.coh_msg) 
                                `REQ_GETS : begin 
                                    case(states_buf[way]) 
                                        `INVALID : next_state = PROCESS_REQ_GET_S_M_IV_MEM_REQ;
                                        `VALID : next_state = PROCESS_REQ_GET_S_M_IV_SEND_RSP;
                                        `SHARED : next_state = PROCESS_REQ_GETS_S;
                                        `EXCLUSIVE : next_state = PROCESS_REQ_GET_S_M_EM; 
                                        `MODIFIED : next_state = PROCESS_REQ_GET_S_M_EM; 
                                        `SD : next_state = PROCESS_REQ_GET_S_M_SD;
                                    endcase
                                end
                                `REQ_GETM : begin 
                                    case(states_buf[way]) 
                                        `INVALID : next_state = PROCESS_REQ_GET_S_M_IV_MEM_REQ;
                                        `VALID : next_state = PROCESS_REQ_GET_S_M_IV_SEND_RSP;
                                        `SHARED : next_state = PROCESS_REQ_GETM_S_FWD;
                                        `EXCLUSIVE : next_state = PROCESS_REQ_GET_S_M_EM; 
                                        `MODIFIED : next_state = PROCESS_REQ_GET_S_M_EM; 
                                        `SD : next_state = PROCESS_REQ_GET_S_M_SD;
                                    endcase
                            end
                                `REQ_PUTS : next_state = PROCESS_REQ_PUTS;
                                `REQ_PUTM : next_state = PROCESS_REQ_PUTM;
                            endcase
                        end
                    end else if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                        next_state = FINISH_RST_FLUSH;
                    end else begin 
                        process_done = 1'b1; 
                    end
                end 
                PROCESS_FLUSH_RESUME : begin 
                    if (cur_way == `LLC_WAYS - 1) begin 
                        if (!flush_stall && !rst_stall) begin 
                            next_state = FINISH_RST_FLUSH;
                         end else begin 
                            next_state = IDLE;
                            process_done = 1'b1; 
                         end
                    end
                end
                PROCESS_RST : begin 
                    if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                         next_state = FINISH_RST_FLUSH;
                     end else begin 
                         next_state = IDLE;
                         process_done = 1'b1;
                     end
                end
                PROCESS_RSP : begin 
                    next_state = IDLE; 
                    process_done = 1'b1; 
                end
                EVICT : begin
                    if (llc_mem_req_ready) begin
                        case(llc_req_in.coh_msg) 
                            `REQ_GETS : begin 
                                case(states_buf[way]) 
                                    `INVALID : next_state = PROCESS_REQ_GET_S_M_IV_MEM_REQ;
                                    `VALID : next_state = PROCESS_REQ_GET_S_M_IV_SEND_RSP;
                                    `SHARED : next_state = PROCESS_REQ_GETS_S;
                                    `EXCLUSIVE : next_state = PROCESS_REQ_GET_S_M_EM; 
                                    `MODIFIED : next_state = PROCESS_REQ_GET_S_M_EM; 
                                    `SD : next_state = PROCESS_REQ_GET_S_M_SD;
                                endcase
                            end
                           `REQ_GETM : begin 
                                case(states_buf[way]) 
                                    `INVALID : next_state = PROCESS_REQ_GET_S_M_IV_MEM_REQ;
                                    `VALID : next_state = PROCESS_REQ_GET_S_M_IV_SEND_RSP;
                                    `SHARED : next_state = PROCESS_REQ_GETM_S_FWD;
                                    `EXCLUSIVE : next_state = PROCESS_REQ_GET_S_M_EM; 
                                    `MODIFIED : next_state = PROCESS_REQ_GET_S_M_EM; 
                                    `SD : next_state = PROCESS_REQ_GET_S_M_SD;
                                endcase
                            end
                           `REQ_PUTS : next_state = PROCESS_REQ_PUTS;
                           `REQ_PUTM : next_state = PROCESS_REQ_PUTM;
                        endcase
                    end
                end
                PROCESS_REQ_GET_S_M_IV_MEM_REQ : begin 
                    if (llc_mem_req_ready) begin 
                        next_state = PROCESS_REQ_GET_S_M_IV_MEM_RSP; 
                    end 
                end
                PROCESS_REQ_GET_S_M_IV_MEM_RSP : begin 
                    if (llc_mem_rsp_valid) begin 
                        next_state = PROCESS_REQ_GET_S_M_IV_SEND_RSP;
                    end
                end
                PROCESS_REQ_GET_S_M_IV_SEND_RSP : begin 
                    if (llc_rsp_out_ready) begin 
                        if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                            next_state = FINISH_RST_FLUSH;
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                PROCESS_REQ_GETS_S:  begin 
                    if (llc_rsp_out_ready) begin 
                        if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                            next_state = FINISH_RST_FLUSH;
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                PROCESS_REQ_GET_S_M_EM: begin 
                    if (llc_fwd_out_ready) begin 
                        if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                            next_state = FINISH_RST_FLUSH;
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                PROCESS_REQ_GET_S_M_SD : begin 
                    if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                        next_state = FINISH_RST_FLUSH;
                    end else begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
    
                end
                PROCESS_REQ_GETM_S_FWD : begin 
                    if (l2_cnt == `MAX_N_L2 - 1) begin 
                        next_state = PROCESS_REQ_GETM_S_RSP;
                    end
                end
                PROCESS_REQ_GETM_S_RSP : begin 
                    if (llc_rsp_out_ready) begin 
                        if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                            next_state = FINISH_RST_FLUSH;
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                PROCESS_REQ_PUTS : begin 
                    if (llc_fwd_out_ready) begin 
                        if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                            next_state = FINISH_RST_FLUSH;
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                PROCESS_REQ_PUTM : begin 
                    if (llc_fwd_out_ready) begin 
                        if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                            next_state = FINISH_RST_FLUSH;
                        end else begin 
                            next_state = IDLE;
                            process_done = 1'b1;
                        end
                    end
                end
                FINISH_RST_FLUSH : begin  
                    if (llc_rst_tb_done_ready) begin 
                        next_state = IDLE;
                        process_done = 1'b1;
                    end
                end
            endcase
        end
      end

    logic skip; 
    always @(posedge clk or negedge rst) begin 
        if (!rst || (state == IDLE)) begin 
            cur_way <= 0; 
        end else if ((state == PROCESS_FLUSH_RESUME) && (llc_mem_req_ready || skip)) begin 
            cur_way = cur_way + 1; 
        end
    end

    line_addr_t line_addr;
    logic hit;
    always_comb begin 
        llc_mem_req.hwrite = 0; 
        llc_mem_req.hsize = 0; 
        llc_mem_req.hprot = 0;
        llc_mem_req.addr = 0;
        llc_mem_req.line = 0;
        llc_mem_req_valid = 1'b0; 
        
        llc_rsp_out.addr = 0; 
        llc_rsp_out.line = 0; 
        llc_rsp_out.req_id = 0;
        llc_rsp_out.dest_id = 0; 
        llc_rsp_out.invack_cnt = 0; 
        llc_rsp_out.word_offset = 0;
        llc_rsp_out_valid = 1'b0; 

        llc_fwd_out.coh_msg = 0; 
        llc_fwd_out.addr = 0; 
        llc_fwd_out.req_id = 0; 
        llc_fwd_out.dest_id = 0;
        llc_fwd_out_valid = 1'b0;

        llc_mem_rsp_ready = 1'b0; 
        
        line_addr = 0; 
        skip = 1'b0;

        lines_buf_wr_data = 0; 
        wr_en_lines_buf = 1'b0;
        
        dirty_bits_buf_wr_data = 1'b0;
        wr_en_dirty_bits_buf = 1'b0;
        
        states_buf_wr_data = 0;
        wr_en_states_buf = 1'b0; 
        
        sharers_buf_wr_data = 0;
        wr_en_states_buf = 1'b0;

        owners_buf_wr_data = 0; 
        wr_en_owners_buf = 1'b0; 
        
        wr_en_hprots_buf = 1'b0; 
        hprots_buf_wr_data = 0; 
        
        wr_en_tags_buf = 1'b0; 
        tags_buf_wr_data = 0;

        clr_rst_flush_stalled_set = 1'b0;  
        set_recall_valid = 1'b0; 
        clr_req_stall = 1'b0; 
        llc_rst_tb_done_valid = 1'b0; 
        llc_rst_tb_done = 1'b0;
        rst_state = 1'b0; 
        
        set_req_stall = 1'b0; 
        set_req_in_stalled_valid = 1'b0; 
        set_req_in_stalled = 1'b0; 
        update_req_in_stalled = 1'b0;
        set_update_evict_way = 1'b0;  
        incr_evict_way_buf = 1'b0;
        incr_invack_cnt = 1'b0; 

        case (state)
            PROCESS_FLUSH_RESUME :  begin 
                line_addr = (tags_buf[cur_way] << `LLC_SET_BITS) | set; 
                if (states_buf[cur_way] == `VALID && dirty_bits_buf[cur_way]) begin 
                    llc_mem_req.hwrite = `WRITE;
                    llc_mem_req.addr = line_addr; 
                    llc_mem_req.hsize = `WORD;
                    llc_mem_req.hprot = hprots_buf[cur_way]; 
                    llc_mem_req.line = lines_buf[way];
                    llc_mem_req_valid = 1'b1; 
                end else begin  
                    skip = 1'b1; 
                end
            end  
            PROCESS_RST : begin 
                //FLUSH
                if (rst_in) begin 
                    clr_flush_stall = 1'b1; 
                    clr_rst_flush_stalled_set = 1'b1;
                end else begin
                    rst_state = 1'b1; 
                end
            end 
            PROCESS_RSP : begin 
                if (recall_pending && (llc_rsp_in.addr == addr_evict)) begin 
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
                    clr_req_stall = 1'b1;
                end

                if (sharers_buf[way] != 0) begin 
                    wr_en_states_buf = 1'b1;
                    states_buf_wr_data = `SHARED;
                end else begin 
                    wr_en_states_buf = 1'b1; 
                    states_buf_wr_data = `VALID;
                end
            end
            EVICT : begin 
                if (way == evict_way_buf) begin 
                    set_update_evict_way = 1'b1;  
                    incr_evict_way_buf = 1'b1;
                end 
                if (states_buf[way] == `VALID && dirty_bits_buf[way]) begin 
                    llc_mem_req_valid = 1'b1; 
                    llc_mem_req.hwrite = `WRITE;
                    llc_mem_req.addr = addr_evict; 
                    llc_mem_req.hsize = `WORD; 
                    llc_mem_req.hprot = hprots_buf[way]; 
                    llc_mem_req.line = lines_buf[way];  
                end
                wr_en_states_buf = 1'b1; 
                states_buf_wr_data = `INVALID;
            end
            PROCESS_REQ_GET_S_M_IV_MEM_REQ : begin 
                llc_mem_req_valid = 1'b1; 
                llc_mem_req.hwrite = `READ;
                llc_mem_req.addr = llc_req_in.addr; 
                llc_mem_req.hsize = `WORD; 
                llc_mem_req.hprot = llc_req_in.hprot; 
                llc_mem_req.line = 0; 
            end
            PROCESS_REQ_GET_S_M_IV_MEM_RSP : begin 
                wr_en_hprots_buf = 1'b1; 
                hprots_buf_wr_data = llc_req_in.hprot; 
                wr_en_tags_buf = 1'b1; 
                tags_buf_wr_data = line_br.tag; 
                wr_en_dirty_bits_buf = 1'b1; 
                dirty_bits_buf_wr_data = 1'b0;
                llc_mem_rsp_ready = 1'b1; 
            end
            PROCESS_REQ_GET_S_M_IV_SEND_RSP : begin 
                if (llc_req_in.coh_msg == `REQ_GETS && llc_req_in.hprot == 1'b0)  begin 
                    llc_rsp_out.coh_msg = `RSP_DATA;
                    wr_en_sharers_buf = 1'b1; 
                    sharers_buf_wr_data = 1 << llc_req_in.req_id; 
                    states_buf_wr_data = `SHARED;
                end else begin 
                    if (llc_req_in.coh_msg == `REQ_GETS) begin 
                        llc_rsp_out.coh_msg = `RSP_EDATA; 
                        states_buf_wr_data = `EXCLUSIVE;
                    end else if (llc_req_in.coh_msg == `REQ_GETM) begin 
                        llc_rsp_out.coh_msg = `RSP_DATA;
                        states_buf_wr_data = `MODIFIED;
                    end
                    wr_en_owners_buf = 1'b1; 
                    owners_buf_wr_data = llc_req_in.req_id;
                    states_buf_wr_data = `EXCLUSIVE;
                end
                wr_en_states_buf = 1'b1; 
                llc_rsp_out.addr = llc_req_in.addr; 
                llc_rsp_out.line = lines_buf[way]; 
                llc_rsp_out.req_id = llc_req_in.req_id;
                llc_rsp_out.dest_id = 0; 
                llc_rsp_out.invack_cnt = 0; 
                llc_rsp_out.word_offset = 0;
                llc_rsp_out_valid = 1'b1; 
            end
            PROCESS_REQ_GETS_S : begin 
                wr_en_sharers_buf = 1'b1; 
                sharers_buf_wr_data = sharers_buf[way] | (1 << llc_req_in.req_id); 

                llc_rsp_out.coh_msg = `RSP_DATA;
                llc_rsp_out.addr = llc_req_in.addr; 
                llc_rsp_out.line = lines_buf[way]; 
                llc_rsp_out.req_id = llc_req_in.req_id;
                llc_rsp_out.dest_id = 0; 
                llc_rsp_out.invack_cnt = 0; 
                llc_rsp_out.word_offset = 0;
                llc_rsp_out_valid = 1'b1; 
            end
            PROCESS_REQ_GET_S_M_EM : begin 
                if (llc_req_in.coh_msg == `REQ_GETS) begin 
                    states_buf_wr_data = `SD;    
                    llc_fwd_out.coh_msg = `FWD_GETS; 
                    wr_en_sharers_buf = 1'b1; 
                    sharers_buf_wr_data = (1 << llc_req_in.req_id) | (1 << owners_buf[way]); 
                    wr_en_states_buf = 1'b1; 
                end else if (llc_req_in.coh_msg == `REQ_GETM) begin 
                    llc_fwd_out.coh_msg = `REQ_GETM;
                    if (states_buf[way] == `EXCLUSIVE) begin 
                        wr_en_states_buf = 1'b1; 
                        states_buf_wr_data = `MODIFIED;
                    end
                    wr_en_owners_buf = 1'b1; 
                    owners_buf_wr_data = llc_req_in.req_id; 
                end
                llc_fwd_out.addr = llc_req_in.addr; 
                llc_fwd_out.req_id = llc_req_in.req_id; 
                llc_fwd_out.dest_id = owners_buf[way];
                llc_fwd_out_valid = 1'b1;
            end
            PROCESS_REQ_GET_S_M_SD : begin 
                set_req_stall = 1'b1; 
                set_req_in_stalled_valid = 1'b1; 
                set_req_in_stalled = 1'b1; 
                update_req_in_stalled = 1'b1;
            end
            PROCESS_REQ_GETM_S_FWD : begin 
                if (((sharers_buf[way] & (1 << l2_cnt)) != 0) && (l2_cnt != llc_req_in.req_id)) begin 
                    incr_invack_cnt = 1'b1; 
                    llc_fwd_out.coh_msg = `FWD_INV; 
                    llc_fwd_out.addr = llc_req_in.addr; 
                    llc_fwd_out.req_id = llc_req_in.req_id; 
                    llc_fwd_out.dest_id = l2_cnt; 
                    llc_fwd_out_valid = 1'b1;
                end
            end
            PROCESS_REQ_GETM_S_RSP : begin 
                llc_rsp_out.coh_msg = `RSP_DATA;
                llc_rsp_out.addr = llc_req_in.addr; 
                llc_rsp_out.line = lines_buf[way]; 
                llc_rsp_out.req_id = llc_req_in.req_id;
                llc_rsp_out.dest_id = 0; 
                llc_rsp_out.invack_cnt = invack_cnt; 
                llc_rsp_out.word_offset = 0;
                llc_rsp_out_valid = 1'b1;

                wr_en_states_buf = 1'b1; 
                states_buf_wr_data = `MODIFIED; 
                wr_en_owners_buf = 1'b1; 
                owners_buf_wr_data = llc_req_in.req_id; 
                wr_en_sharers_buf = 1'b1; 
                sharers_buf_wr_data = 0; 
            end
            PROCESS_REQ_PUTS : begin 
               llc_fwd_out.coh_msg = `FWD_PUTACK; 
               llc_fwd_out.addr = llc_req_in.addr; 
               llc_fwd_out.req_id = llc_req_in.req_id; 
               llc_fwd_out.dest_id = llc_req_in.req_id;
               llc_fwd_out_valid = 1'b1; 
               if (states_buf[way] == `SHARED || states_buf[way] == `SD) begin 
                    wr_en_sharers_buf = 1'b1; 
                    sharers_buf_wr_data = sharers_buf[way] & ~(1 << llc_req_in.req_id);
                    if (states_buf[way] == `SHARED && sharers_buf[way] == 0) begin 
                        states_buf_wr_data = `VALID;
                    end
               end else if (states_buf[way] == `EXCLUSIVE && owners_buf[way] == llc_req_in.req_id) begin 
                    wr_en_states_buf = 1'b1; 
                    states_buf_wr_data = `VALID; 
               end 
            end
            PROCESS_REQ_PUTM : begin 
               llc_fwd_out.coh_msg = `FWD_PUTACK; 
               llc_fwd_out.addr = llc_req_in.addr; 
               llc_fwd_out.req_id = llc_req_in.req_id; 
               llc_fwd_out.dest_id = llc_req_in.req_id;
               llc_fwd_out_valid = 1'b1; 
               if (states_buf[way] == `SHARED || states_buf[way] == `SD) begin 
                    sharers_buf_wr_data = sharers_buf[way] & ~(1 << llc_req_in.req_id);
                    wr_en_sharers_buf = 1'b1;
                    if (states_buf[way] == `SHARED && sharers_buf[way] == 0) begin 
                        states_buf_wr_data = `VALID;
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
            end
            FINISH_RST_FLUSH : begin 
                llc_rst_tb_done_valid = 1'b1; 
                llc_rst_tb_done = 1'b1;
            end
        endcase
    end 
endmodule
