`timescale 1ps / 1ps
`include "cache_consts.svh" 
`include "cache_types.svh" 

// input_decoder.sv 
// Author: Joseph Zuckerman
// processes available incoming signals with priority 
module read_set (clk, rst, rd_set_en,  rst_flush_stalled_set, req_in_stalled_set, req_in_stalled_tag, rsp_in_addr, req_in_addr, dma_req_in_addr, dma_addr, rd_set, set,  incr_rst_flush_stalled_set, clr_rst_stall, clr_flush_stall, clr_req_stall, update_dma_addr_from_req, line_br, is_rsp_to_get, is_req_to_get, is_dma_req_to_get, is_dma_read_to_resume, is_dma_write_to_resume, is_flush_to_resume, is_rst_to_resume, req_stall); 

    input logic clk, rst;
    input logic rd_set_en;
    input line_addr_t rsp_in_addr, req_in_addr, dma_req_in_addr;
    input addr_t dma_addr; 
    input llc_set_t rst_flush_stalled_set, req_in_stalled_set;
    input llc_tag_t req_in_stalled_tag; 
    input logic is_rsp_to_get, is_req_to_get, is_dma_req_to_get, is_dma_read_to_resume, is_dma_write_to_resume, is_flush_to_resume, is_rst_to_resume, req_stall;    

    output llc_set_t rd_set, set;
    output logic incr_rst_flush_stalled_set; 
    output logic clr_rst_stall, clr_flush_stall, clr_req_stall;
    output logic update_dma_addr_from_req; 
    line_breakdown_llc_t line_br; 
    
    line_addr_t addr_for_set; 
    line_breakdown_llc_t line_br_next(); 

    always_comb begin 
        //multiplex addr bits
        addr_for_set = {`LLC_ADDR_BITS{1'b0}};
        update_dma_addr_from_req = 1'b0;
        if (is_rsp_to_get) begin 
            addr_for_set = rsp_in_addr; 
        end else if (is_req_to_get) begin 
            addr_for_set = req_in_addr;
        end else if (is_dma_req_to_get  || is_dma_read_to_resume || is_dma_write_to_resume) begin 
            addr_for_set = is_dma_req_to_get ? dma_req_in_addr : dma_addr; 
            update_dma_addr_from_req = 1'b1;
        end
        
        line_br_next.tag = addr_for_set[(`ADDR_BITS - `OFFSET_BITS -1): `LLC_SET_BITS];
        line_br_next.set = addr_for_set[(`LLC_SET_BITS - 1):0]; 

        //set stall signals
        incr_rst_flush_stalled_set = 1'b0;
        clr_rst_stall = 1'b0;
        clr_flush_stall = 1'b0; 
        clr_req_stall = 1'b0;
        if (is_flush_to_resume || is_rst_to_resume) begin 
            incr_rst_flush_stalled_set = 1'b1;
            if (rst_flush_stalled_set == {`LLC_SET_BITS{1'b1}}) begin 
                clr_rst_stall  =  1'b1; 
                clr_flush_stall = 1'b1; 
            end    
        end else if (is_rsp_to_get) begin 
            if ((req_stall == 1'b1) 
                && (line_br_next.tag  == req_in_stalled_tag) 
                && (line_br_next.set == req_in_stalled_set)) begin 
                clr_req_stall = 1'b1;
            end
        end
    end 
    
    always_ff@(posedge clk or negedge rst) begin 
        if (!rst) begin 
            line_br.tag <= 0; 
            line_br.set <= 0;
        end else if (rd_set_en) begin 
            line_br.tag <= line_br_next.tag;
            line_br.set <= line_br_next.set;
        end
    end

    assign rd_set = line_br_next.set;  
    assign set = (is_flush_to_resume | is_rst_to_resume) ? rst_flush_stalled_set : line_br.set; 

endmodule
