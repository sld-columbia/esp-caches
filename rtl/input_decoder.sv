`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

// input_decoder.sv 
// Author: Joseph Zuckerman
// processes available incoming signals with priority 

module input_decoder (clk, rst, llc_rst_tb_valid, llc_rsp_in_vaild, llc_req_in_valid, llc_dma_req_in_valid, recall_pending, recall_valid, dma_read_pending, dma_write_pending, flush_stall, rst_stall, req_stall, req_in_stalled_valid, decode_en, rst_flush_stalled_set, req_in_stalled_set, req_in_stalled_tag, rsp_in_addr, req_in_addr, dma_req_in_addr, dma_addr, update_req_in_from_stalled, llc_rst_tb_ready, llc_rsp_in_ready, llc_req_in_ready, llc_dma_req_in_ready, look, set, incr_rst_flush_stalled_set, clr_rst_stall, clr_flush_stall, clr_req_stall); 
   
    input logic clk, rst; 
    input logic llc_rst_tb_valid, llc_rsp_in_vaild, llc_req_in_valid, llc_dma_req_in_valid; 
    input logic recall_pending, recall_valid;
    input logic dma_read_pending, dma_write_pending; 
    input logic flush_stall, rst_stall, req_stall; 
    input logic req_in_stalled_valid;
    input logic decode_en; 
    input llc_set_t rst_flush_stalled_set, req_in_stalled_set;
    input llc_tag_t req_in_stalled_tag; 
    input line_addr_t rsp_in_addr, req_in_addr, dma_req_in_addr;
    input addr_t dma_addr; 
    
    output logic update_req_in_from_stalled, clr_req_in_stalled_valid;  
    output logic llc_rst_tb_ready, llc_rsp_in_ready, llc_req_in_ready, llc_dma_req_in_ready; 
    output logic look;
    output llc_set_t set;
    output logic incr_rst_flush_stalled_set; 
    output logic clr_rst_stall, clr_flush_stall, clr_req_stall;
    output logic update_dma_addr_from_req; 

    //STATE LOGIC

    localparam IDLE = 2'b00; //waiting for start  
    localparam DECODE = 2'b01; //determining action
    localparam SET = 2'b11; //computing set
    localparam STALL = 2'b10; //clearing stalls  
    logic[1:0] state, next_state;
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= DECODE;
        else begin 
            state <= next_state;
        end 
    end

    always_comb begin 
        next_state = state;
        case(state) begin 
            IDLE: 
                if (decode_en) begin 
                    next_state = DECODE;
                end
            DECODE: 
                next_state = SET;
            SET:
                next_state = STALL;
            STALL:
                next_state = IDLE;
        endcase 
    end

    logic st_dec, st_set, st_stall; 
    assign st_dec = (state == DECODE); 
    assign st_set = (state == SET); 
    assign st_stall = (state == STALL);  

    logic can_get_rst_tb, can_get_rsp_in, can_get_req_in, can_get_dma_req_in; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
           can_get_rst_tb <= 1'b0;
           can_get_rsp_in <= 1'b0; 
           can_get_req_in <= 1'b0; 
           can_get_dma_req_in <= 1'b0; 
           req_in_stalled_valid <= 1'b0;
        end else if begin 
           can_get_rst_tb <= llc_rst_tb_valid; 
           can_get_rsp_in <= llc_rsp_in_valid; 
           can_get_req_in <= llc_req_in_valid; 
           can_get_dma_req_in <= llc_dma_req_in_valid;
           req_in_stalled_valid <= req_in_stalled_valid_next;
        end
    end
   
    //DECODE 

    logic is_rst_to_resume, is_flush_to_resume, is_dma_read_to_resume, is_dma_write_to_resume;
    logic is_rst_to_get, is_rsp_to_get,  is_req_to_get, is_dma_req_to_get; 
    logic do_get_req, do_get_dma_req; 

    logic is_rst_to_resume_next, is_flush_to_resume_next, is_dma_read_to_resume_next, is_dma_write_to_resume_next;
    logic is_rst_to_get_next, is_rsp_to_get_next,  is_req_to_get_next, is_dma_req_to_get_next; 
    logic do_get_req_next, do_get_dma_req_next; 
    logic update_req_in_from_stalled_next, clr_req_in_stalled_valid_next; 

    //decoder logic
    always_comb begin  
        is_rst_to_resume_next =  1'b0; 
        is_flush_to_resume_next = 1'b0; 
        is_rst_to_get_next = 1'b0; 
        is_rsp_to_get_next = 1'b0;  
        is_req_to_get_next = 1'b0;  
        is_dma_req_to_get_next =  1'b0;  
        is_dma_read_to_resume_next = 1'b0; 
        is_dma_write_to_resume_next = 1'b0; 
        do_get_req_next = 1'b0; 
        do_get_dma_req_next = 1'b0;  
        update_req_in_from_stalled_next = 1'b0;
        clr_req_in_stalled_valid_next = 1'b0;

        if (recall_pending) begin 
            if(!recall_valid) begin 
                if(can_get_rsp_in) begin 
                    is_rsp_to_get_next = 1'b1; 
                end 
            end else begin 
                if (dma_read_pending) begin 
                    is_dma_read_to_resume_next = 1'b1; 
                end else if (dma_write_pending) begin 
                    is_dma_write_to_resume_next = 1'b1; 
                end
            end
        end else if (rst_stall) begin 
            is_rst_to_resume_next = 1'b1; 
        end else if (flush_stall) begin
            is_flush_to_resume_next = 1'b1; 
        end else if (can_get_rst_tb && !dma_read_pending && !dma_write_pending) begin 
            is_rst_to_get_next = 1'b1;
        end else if (can_get_rsp_in) begin 
            is_rsp_to_get_next =  1'b1;
        end else if ((can_get_req_in &&  !req_stall)  ||  (!req_stall  && req_in_stalled_valid)) begin 
            if (req_in_stalled_valid) begin 
                clr_req_in_stalled_valid_next = 1'b1;
                update_req_in_from_stalled_next = 1'b1;   
            end else
                do_get_req_next = 1'b1;
            end
            is_req_to_get_next = 1'b1;
        end else if (dma_read_pending) begin 
            is_dma_read_to_resume_next = 1'b1; 
        end else if (dma_write_pending) begin 
            if (can_get_dma_req_in) begin 
                is_dma_write_to_resume_next = 1'b1; 
                do_get_dma_req_next = 1'b1;
            end
        end else if (can_get_dma_req_in && !req_stall) begin 
            is_dma_req_to_get_next = 1'b1; 
            do_get_dma_req_next = 1'b1;
        end
    end

    //flop outputs 
    always_ff@(posedge clk or negedge rst) begin 
        if (!rst) begin 
            is_rst_to_resume <= 1'b0; 
            is_flush_to_resume <= 1'b0; 
            is_rst_to_get <= 1'b0; 
            is_req_to_get <= 1'b0;
            is_rsp_to_get <= 1'b0; 
            is_dma_req_to_get <= 1'b0; 
            is_dma_read_to_resume <= 1'b0;
            is_dma_write_to_resume <= 1'b0;  
            do_get_req <= 1'b0;
            do_get_dma_req <= 1'b0;
            clr_req_in_stalled_valid <= 1'b0; 
            update_req_in_from_stalled <= 1'b0; 
        end else if (st_dec) begin 
            is_rst_to_resume <= is_rst_to_resume_next; 
            is_flush_to_resume <= is_flush_to_resume_next; 
            is_rst_to_get <= is_rst_to_get_next; 
            is_req_to_get <= is_req_to_get_next;
            is_rsp_to_get <= is_rsp_to_get_next;
            is_dma_req_to_get <= is_dma_req_to_get_next;
            is_dma_read_to_resume <= is_dma_read_to_resume_next;
            is_dma_write_to_resume <= is_dma_write_to_resume_next; 
            do_get_req <= do_get_req_next;
            do_get_dma_req <= do_get_dma_req_next;
            clr_req_in_stalled_valid <= clr_req_in_stalled_valid_next; 
            update_req_in_from_stalled <= update_req_in_from_stalled_next;  
        end
    end

    //assign ready bits for top level
    assign llc_rsp_in_ready = is_rsp_to_get; 
    assign llc_rst_tb_ready = is_rst_to_get; 
    assign llc_req_in_ready = do_get_req;
    assign llc_dma_req_in = do_get_dma_req; 

    assign look =  is_flush_to_resume | is_rsp_to_get | 
                   is_req_to_get | is_dma_req_to_get | 
                   (is_dma_read_to_resume & ~recall_pending) | 
                   (is_dma_write_to_resule & ~recall_pendind); 
    
    //SET
    
    llc_addr_t addr_for_set; 
    line_breakdown_llc_t line_br; 
    
    logic update_dma_addr_from_req_next; 
    //multiplex set bits
    always_comb begin  
        addr_for_set = {LLC_ADDR_BITS{1'b0}};
        update_dma_addr_from_req_next = 1'b0;
        if (is_rsp_to_get) begin 
            addr_for_set = rsp_in_addr; 
        end else if (is_req_to_get) begin 
            addr_for_set = req_in_addr;
        end else if (is_dma_req_to_get  || is_dma_read_to_resume || is_dma_write_to_resume) begin 
            addr_for_set = is_dma_req_to_get ? dma_req_in_addr : dma_addr; 
            update_dma_addr_from_req_next = 1'b0;
        end
    end
    
    //flop outputs
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            line_br.tag <= 0; 
            line_br.set <= 0;
            update_dma_addr_from_req <= 1'b0;
        end else if (st_decode) begin 
            line_br.tag <= addr_for_set[(ADDR_BIT - OFFSET_BITS -1): LLC_SET_BITS];
            line_br.set <= addr_for_set[(LLC_SET_BITS - 1):0]; 
            update_dma_addr_from_req <= update_dma_addr_from_req_next; 
        end
    end

    assign set = (is_flush_to_resume | is_rst_to_resume) ? rst_flush_stalled_set : line_br.set; 
    
    //STALL

    logic incr_rst_flush_stalled_set_next; 
    logic clr_rst_stall_next, clr_flush_stall_next, clr_req_stall_next;

    //set bits for clearing signals
    always_comb begin
        incr_rst_flush_stalled_set_next = 1'b0;
        clr_rst_stall_next = 1'b0;
        clr_flush_stall_next = 1'b0; 
        clr_req_stall_next = 1'b0;
        if (is_flush_to_resume || is_rst_to_resume) begin 
            incr_rst_flush_stalled_set_next = 1'b1;
            if (rst_flush_stalled_set == {LLC_SET_BITS{1'b1}}) begin 
                clr_rst_stall_next  =  1'b1; 
                clr_flush stall = 1'b1; 
            end    
        end else if (is_rsp_to_get) begin 
            if ((req_stall == 1'b1) 
                && (line_br.tag  == req_in_stalled_tag) 
                && (line_br.set == req_in_stalled_set)) begin 
                clr_req_stall_next = 1'b1;
            end
        end
    end 

    //flop outputs
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            incr_rst_flush_stalled_set <= 1'b0;
            clr_rst_stall <= 1'b0; 
            clr_flush_stall <= 1'b0; 
            clr_req_stall <= 1'b0; 
        end else if (st_stall) begin
            incr_rst_flush_stalled_set <= incr_rst_flush_stalled_set_next; 
            clr_rst_stall <= clr_rst_stall_next;
            clr_flush_stall <= clr_flush_stall_next;
            clr_req_stall <= clr_req_stall_next;
        end
    end
endmodule
