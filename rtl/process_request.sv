`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

//process_request.sv
//Author: Joseph Zuckerman
//takes action for next pending request 

module process_request(); 
    input logic clk, rst; 
    input llc_tag_t tag;
    input llc_tag_t states_buf[`LLC_WAYS];
    input llc_state_t states_buf[`LLC_WAYS];
    input llc_way_t evict_ways_buf;
    input logic process_en; 

    input logic is_flush_to_resume; 
    input llc_set_t set;  

    input logic llc_mem_req_ready; 
    output llc_mem_req_t llc_mem_req; 
    output logic llc_mem_req_valid; 
   
    output llc_way_t way
    output logic evict; 

    //STATE LOGIC
    localparam IDLE = 2'b00; 
    localparam LOOKUP = 2'b10;
    localparam PROCESS_FLUSH_RESUME = 2'b11; 
    localparam PROCESS_NEXT = 2'b01;

    logic [1:0] state, next_state; 
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
                if (process_en) begin 
                    next_state = LOOKUP;
                end
            LOOKUP: 
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
    
    line_addr_t line_addr; 
    always_comb begin 
        llc_mem_req.hwrite = 0; 
        llc_mem_req.hsize = 0; 
        llc_mem_req.hprot = 0;
        llc_mem_req.addr = 0;
        llc_mem_req.line = 0;
        llc_mem_req.valid = 1'b0; 
        line_addr = 0; 

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
            end 
        end 
    end 

endmodule
