`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

//process_request.sv
//Author: Joseph Zuckerman
//takes action for next pending request 

module process_request(clk, rst, rst_in,  process_en, way, is_flush_to_resume, is_rst_to_resume, is_rst_to_get, is_rsp_to_get, is_req_to_get, is_dma_req_to_get, set, llc_rsp_in, recall_pending, line_br, req_in_stalled_tag, req_in_stalled_set, flush_stall, rst_stall, req_stall, llc_mem_req_ready, llc_rst_tb_done_ready, addr_evict, lines_buf, tags_buf, sharers_buf, owners_buf, hprots_buf, dirty_bits_buf, evict_way_buf, states_buf, llc_mem_req, llc_mem_req_valid, llc_rst_tb_done_valid, llc_rst_tb_done, clr_flush_stall, clr_req_stall, clr_rst_flush_stalled_set, set_recall_valid, wr_en_lines_buf, wr_en_tags_buf, wr_en_sharers_buf, wr_en_owners_buf, wr_en_hprots_buf, wr_en_dirty_bits_buf, wr_en_states_buf, wr_en_evict_way_buf, lines_buf_wr_data, tags_buf_wr_data, sharers_buf_wr_data, owners_buf_wr_data, hprots_buf_wr_data, dirty_bits_buf_wr_data, states_buf_wr_data, evict_way_buf_wr_data, process_done); 
    
    input logic clk, rst; 
    input logic process_en; 

    input logic rst_in; 
    input llc_way_t way;
    input logic is_flush_to_resume, is_rst_to_resume, is_rst_to_get, is_rsp_to_get, is_req_to_get, is_dma_req_to_get; 
    input llc_set_t set;  

    llc_rsp_in_t llc_rsp_in;
    input logic recall_pending; 
    
    line_breakdown_llc_t line_br; 
    input llc_tag_t req_in_stalled_tag; 
    input llc_set_t req_in_stalled_set; 
    input flush_stall, rst_stall, req_stall; 
    input logic llc_mem_req_ready;
    input logic llc_rst_tb_done_ready;
    input llc_addr_t addr_evict; 

    input line_t lines_buf[`LLC_WAYS];
    input llc_tag_t tags_buf[`LLC_WAYS];
    input sharers_t sharers_buf[`LLC_WAYS];
    input owner_t owners_buf[`LLC_WAYS];
    input hprot_t hprots_buf[`LLC_WAYS];
    input logic dirty_bits_buf[`LLC_WAYS];
    input llc_way_t evict_way_buf;
    input llc_state_t states_buf[`LLC_WAYS];
    
    llc_mem_req_t llc_mem_req; 
    
    output logic llc_mem_req_valid; 
    output logic llc_rst_tb_done_valid;
    output logic llc_rst_tb_done; 
    
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
    output state_t states_buf_wr_data;
    output llc_way_t evict_way_buf_wr_data;
    output logic process_done; 

    //STATE LOGIC
    localparam IDLE = 3'b000; 
    localparam PROCESS_FLUSH_RESUME = 3'b001; 
    localparam PROCESS_NEXT= 3'b011; 
    localparam FINISH_RST_FLUSH = 3'b100;

    logic [2:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= IDLE;
        end else begin 
            state <= next_state; 
        end
    end 
    
    llc_way_t cur_way;
    always_comb begin 
        next_state = state;
        process_done = 1'b0; 
        case (state) 
            IDLE: begin  
                if (is_flush_to_resume) begin 
                    next_state = PROCESS_FLUSH_RESUME;
                end else if (is_rst_to_resume && !flush_stall && !rst_stall) begin 
                    next_state = FINISH_RST_FLUSH;
                end else begin 
                    next_state = PROCESS_NEXT;
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
            PROCESS_NEXT : begin 
                next_state = IDLE; 
                process_done = 1'b1;
            end
            FINISH_RST_FLUSH : begin  
                if (llc_rst_tb_done_ready) begin 
                    next_state = IDLE;
                    process_done = 1'b1; 
                end
            end

        endcase
    end

    logic idle, flush_resume, process_next, finish_rst_flush;
    assign idle = (state == IDLE); 
    assign flush_resume = (state == PROCESS_FLUSH_RESUME); 
    assign process_next = (state == PROCESS_NEXT);
    assign finish_rst_flush = (state == FINISH_RST_FLUSH);

    always @(posedge clk or negedge rst) begin 
        if (!rst || idle) begin 
            cur_way <= 0; 
        end else if (flush_resume && llc_mem_req_ready) begin 
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
        llc_mem_req.valid = 1'b0; 
        line_addr = 0; 
        
        lines_buf_wr_data = 0; 
        wr_en_lines_buf = 1'b0;
        dirty_bits_buf_wr_data = 1'b0;
        wr_en_dirty_bits_buf = 1'b0;
        states_buf_wr_data = 0;
        wr_en_states_buf = 1'b0; 
       
        set_recall_valid = 1'b0; 
        clr_req_stall = 1'b0; 
        llc_rst_tb_done_valid = 1'b0; 

        if (flush_resume) begin 
            line_addr = (tags_buf[cur_way] << `LLC_SET_BITS) | set; 
            if (states_buf[cur_way] == `VALID && dirty_bits_buf[cur_way]) begin 
                llc_mem_req.hwrite = `WRITE;
                llc_mem_req.addr = line_addr; 
                llc_mem_req.hsize = `WORD;
                llc_mem_req.hprot = hprots_buf[cur_way]; 
                llc_mem_req.line = lines_buf[way];
                if (llc_mem_req_ready) begin 
                    llc_mem_req_valid = 1'b1; 
                end 
            end 
        end else if (process_next) begin 
            if (is_rst_to_get) begin 
                //FLUSH
                if (rst_in) begin 
                    clr_flush_stall = 1'b1; 
                    clr_rst_flush_stalled_set = 1'b1;
                end
            end else if (is_rsp_to_get) begin 
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
            end else if (is_req_to_get) begin 
                
            end
        end else if (finish_rst_flush) begin 
            llc_rst_tb_done_valid = 1'b1; 
            llc_rst_tb_done = 1'b1;
        end 
    end 
endmodule
