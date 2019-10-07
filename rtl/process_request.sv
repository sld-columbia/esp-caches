`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

//process_request.sv
//Author: Joseph Zuckerman
//takes action for next pending request 

module process_request(); 
    input logic clk, rst; 
    input llc_tag_t tag;
    input llc_way_t evict_ways_buf;
    input logic process_en; 

    input llc_way_t way
    input logic is_flush_to_resume, is_rst_to_get, is_rsp_to_get, is_req_to_get, is_dma_req_to_get; 
    input llc_set_t set;  

    input llc_rsp_in_t llc_rsp_in;
    input logic recall_pending; 
    
    input line_breakdown_llc_t line_br; 
    input llc_tag_t req_in_stalled_tag; 
    input llc_set_t req_in_stalled_set; 

    input logic llc_mem_req_ready; 
    output llc_mem_req_t llc_mem_req; 
    output logic llc_mem_req_valid; 
   
    
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

    //STATE LOGIC
    localparam IDLE = 2'b00; 
    localparam PROCESS_FLUSH_RESUME = 2'b11; 
    localparam PROCESS_RST = 2'b01;
    localparam PROCESS_RSP 

    logic [2:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= IDLE
        end else begin 
            state <= next_state; 
        end
    end 

    always_comb begin 
        next_state = state; 
        case (state) begin 
            IDLE: 
                if (is_flush_to_resume) begin 
                    next_state = PROCESS_FLUSH_RESUME;
                end else begin 
                    next_state = PROCESS_NEXT; 
            PROCESS_FLUSH_RESUME :
                if (cur_way == `LLC_WAYS - 1) begin 
                    next_state = //@TODO;
                end
            PROCESS_NEXT : 

        endcase
    end

    logic lookup_en, idle, flush_resume, process_next;
    assign lookup_en = (state == LOOKUP); 
    assign idle = (state == IDLE); 
    assign flush_resume = (state == PROCESS_FLUSH_RESUME); 
    assign process_next = (state == PROCESS_NEXT);

    lookup_way lookup_way_u(.*);
    llc_way_t cur_way;

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

        if (flush_resume) begin 
            line_addr = (tags_buf[cur_way] << `LLC_SET_BITS) | set; 
            if (states_buf[cur_way] == VALID && dirty_bits_buf[cur_way]) begin 
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
                    clr_rst_flush_stall = 1'b1;
                end
            end else if (is_rsp_to_get) begin 
                if (recall_pending && (llc_rsp_in.addr == addr_evict) begin 
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
                
                if (req_stall && (line_br.tag == req_in_stalled_tag) && (line_br.set == req_in_stalled_set) begin 
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
        end  
    end 

endmodule
