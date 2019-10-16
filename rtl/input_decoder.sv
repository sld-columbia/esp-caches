`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

// input_decoder.sv 
// Author: Joseph Zuckerman
// processes available incoming signals with priority 

module input_decoder (clk, rst, llc_rst_tb_valid, llc_rsp_in_valid, llc_req_in_valid, llc_dma_req_in_valid, recall_pending, recall_valid, dma_read_pending, dma_write_pending, flush_stall, rst_stall, req_stall, req_in_stalled_valid, decode_en, is_dma_read_to_resume, is_dma_write_to_resume, update_req_in_from_stalled, clr_req_in_stalled_valid, look, is_rst_to_resume, is_flush_to_resume, set_is_dma_read_to_resume_decoder, set_is_dma_write_to_resume_decoder, clr_is_dma_read_to_resume, clr_is_dma_write_to_resume, is_rst_to_get, is_rsp_to_get, is_req_to_get, is_dma_req_to_get, is_rst_to_get_next, is_rsp_to_get_next, do_get_req,  do_get_dma_req); 
   
    input logic clk, rst; 
    input logic llc_rst_tb_valid, llc_rsp_in_valid, llc_req_in_valid, llc_dma_req_in_valid; 
    input logic recall_pending, recall_valid;
    input logic dma_read_pending, dma_write_pending; 
    input logic flush_stall, rst_stall, req_stall; 
    input logic req_in_stalled_valid;
    input logic decode_en; 
    input logic is_dma_read_to_resume, is_dma_write_to_resume; 

    output logic update_req_in_from_stalled, clr_req_in_stalled_valid;  
    output logic look;
    output logic is_rst_to_resume, is_flush_to_resume, set_is_dma_read_to_resume_decoder, set_is_dma_write_to_resume_decoder, clr_is_dma_read_to_resume, clr_is_dma_write_to_resume;
    output logic is_rst_to_get, is_rsp_to_get, is_req_to_get, is_dma_req_to_get; 
    output logic is_rst_to_get_next, is_rsp_to_get_next;
    output logic do_get_req, do_get_dma_req; 

    //STATE LOGI

    logic can_get_rst_tb, can_get_rsp_in, can_get_req_in, can_get_dma_req_in; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
           can_get_rst_tb <= 1'b0;
           can_get_rsp_in <= 1'b0; 
           can_get_req_in <= 1'b0; 
           can_get_dma_req_in <= 1'b0; 
        end else begin 
           can_get_rst_tb <= llc_rst_tb_valid; 
           can_get_rsp_in <= llc_rsp_in_valid; 
           can_get_req_in <= llc_req_in_valid; 
           can_get_dma_req_in <= llc_dma_req_in_valid;
        end
    end
   
    
    logic is_rst_to_resume_next, is_flush_to_resume_next, is_dma_read_to_resume_decoder_next, is_dma_write_to_resume_decoder_next;
    logic is_req_to_get_next, is_dma_req_to_get_next; 
    
    
    always_comb begin  
        is_rst_to_resume_next =  1'b0; 
        is_flush_to_resume_next = 1'b0; 
        is_rst_to_get_next = 1'b0; 
        is_rsp_to_get_next = 1'b0;  
        is_req_to_get_next = 1'b0;  
        is_dma_req_to_get_next =  1'b0;  
        set_is_dma_read_to_resume_decoder = 1'b0; 
        set_is_dma_write_to_resume_decoder = 1'b0; 
        clr_is_dma_read_to_resume = 1'b0; 
        clr_is_dma_write_to_resume = 1'b0; 
        do_get_req = 1'b0; 
        do_get_dma_req = 1'b0;  
        update_req_in_from_stalled = 1'b0;
        clr_req_in_stalled_valid = 1'b0;
        if (decode_en) begin 
            clr_is_dma_read_to_resume = 1'b1; 
            clr_is_dma_write_to_resume = 1'b1;        //decoder logic
            if (recall_pending) begin 
                if(!recall_valid) begin 
                    if(can_get_rsp_in) begin 
                        is_rsp_to_get_next = 1'b1; 
                    end 
                end else begin 
                    if (dma_read_pending) begin 
                        is_dma_read_to_resume_decoder_next = 1'b1; 
                    end else if (dma_write_pending) begin 
                        is_dma_write_to_resume_decoder_next = 1'b1; 
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
                    clr_req_in_stalled_valid = 1'b1;
                    update_req_in_from_stalled = 1'b1;   
                end else begin
                    do_get_req = 1'b1;
                end
                is_req_to_get_next = 1'b1;
            end else if (dma_read_pending) begin 
                set_is_dma_read_to_resume_decoder = 1'b1;
                clr_is_dma_read_to_resume = 1'b0;
            end else if (dma_write_pending) begin 
                if (can_get_dma_req_in) begin 
                    set_is_dma_write_to_resume_decoder = 1'b1;
                    clr_is_dma_write_to_resume = 1'b0; 
                    do_get_dma_req = 1'b1;
                end
            end else if (can_get_dma_req_in && !req_stall) begin 
                is_dma_req_to_get_next = 1'b1; 
                do_get_dma_req = 1'b1;
            end
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
        end else if (decode_en) begin 
            is_rst_to_resume <= is_rst_to_resume_next; 
            is_flush_to_resume <= is_flush_to_resume_next; 
            is_rst_to_get <= is_rst_to_get_next; 
            is_req_to_get <= is_req_to_get_next;
            is_rsp_to_get <= is_rsp_to_get_next;
            is_dma_req_to_get <= is_dma_req_to_get_next;
        end
    end
    
    assign look =  is_flush_to_resume | is_rsp_to_get | 
                   is_req_to_get | is_dma_req_to_get | 
                   (is_dma_read_to_resume & ~recall_pending) | 
                   (is_dma_write_to_resume & ~recall_pending); 
endmodule
