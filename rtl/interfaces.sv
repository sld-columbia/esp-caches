`timescale 1ps / 1ps 
`include "cache_consts.svh" 
`include "cache_types.svh" 

// interfaces.sv
// Author: Joseph Zuckerman
// bypassable-queue implementation for input channels

module interfaces(clk, rst, llc_req_in_valid, llc_req_in_ready_int, llc_req_in_ready, llc_req_in_valid_int, llc_req_in_i, llc_req_in_next, llc_dma_req_in_valid, llc_dma_req_in_ready_int, llc_dma_req_in_ready, llc_dma_req_in_valid_int, llc_dma_req_in_i, llc_dma_req_in_next, llc_rsp_in_valid, llc_rsp_in_ready_int, llc_rsp_in_ready, llc_rsp_in_valid_int, llc_rsp_in_i, llc_rsp_in_next, llc_mem_rsp_valid, llc_mem_rsp_ready_int, llc_mem_rsp_ready, llc_mem_rsp_valid_int, llc_mem_rsp_i, llc_mem_rsp_next, llc_rst_tb_valid, llc_rst_tb_ready_int, llc_rst_tb_ready, llc_rst_tb_valid_int, llc_rst_tb_i, llc_rst_tb_next); 
    
    input logic clk, rst;
    
    //REQ IN 
    input logic llc_req_in_valid, llc_req_in_ready_int; 
    output logic llc_req_in_ready, llc_req_in_valid_int;
    
    llc_req_in_t llc_req_in_i;
    llc_req_in_t llc_req_in_tmp(); 
    llc_req_in_t llc_req_in_next; 

    logic llc_req_in_ready_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_req_in_ready <= 1'b1;
        end else begin 
            llc_req_in_ready <= llc_req_in_ready_next; 
        end
    end 

    always_comb begin 
        llc_req_in_ready_next = llc_req_in_ready; 
        case (llc_req_in_ready) 
            1'b0 : begin 
                if (llc_req_in_ready_int) begin 
                    llc_req_in_ready_next = 1'b1; 
                end
            end
            1'b1 : begin 
                if (llc_req_in_valid && !llc_req_in_ready_int) begin 
                    llc_req_in_ready_next = 1'b0;
                end    
            end
        endcase
    end

    logic llc_req_in_valid_tmp;
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_req_in_valid_tmp <= 1'b0; 
        end else if (llc_req_in_ready && !llc_req_in_ready_int) begin 
            llc_req_in_valid_tmp <= llc_req_in_valid;
        end
    end 
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_req_in_tmp.coh_msg <= 0; 
            llc_req_in_tmp.hprot <= 0; 
            llc_req_in_tmp.addr <= 0; 
            llc_req_in_tmp.line <= 0; 
            llc_req_in_tmp.req_id <= 0; 
            llc_req_in_tmp.word_offset <= 0; 
            llc_req_in_tmp.valid_words <= 0; 
        end else if (llc_req_in_valid) begin
            llc_req_in_tmp.coh_msg <= llc_req_in_i.coh_msg; 
            llc_req_in_tmp.hprot <= llc_req_in_i.hprot; 
            llc_req_in_tmp.addr <= llc_req_in_i.addr; 
            llc_req_in_tmp.line <= llc_req_in_i.line; 
            llc_req_in_tmp.req_id <= llc_req_in_i.req_id; 
            llc_req_in_tmp.word_offset <= llc_req_in_i.word_offset; 
            llc_req_in_tmp.valid_words <= llc_req_in_i.valid_words; 
        end
    end

    assign llc_req_in_next.coh_msg = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_i.coh_msg : llc_req_in_tmp.coh_msg; 
    assign llc_req_in_next.hprot = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_i.hprot : llc_req_in_tmp.hprot; 
    assign llc_req_in_next.addr = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_i.addr : llc_req_in_tmp.addr; 
    assign llc_req_in_next.line = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_i.line : llc_req_in_tmp.line; 
    assign llc_req_in_next.req_id = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_i.req_id : llc_req_in_tmp.req_id; 
    assign llc_req_in_next.word_offset = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_i.word_offset : llc_req_in_tmp.word_offset; 
    assign llc_req_in_next.valid_words = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_i.valid_words : llc_req_in_tmp.valid_words; 
    assign llc_req_in_valid_int = (llc_req_in_ready && llc_req_in_ready_int) ? llc_req_in_valid : llc_req_in_valid_tmp;  

    //DMA REQ IN 
    input logic llc_dma_req_in_valid, llc_dma_req_in_ready_int; 
    output logic llc_dma_req_in_ready, llc_dma_req_in_valid_int;
    
    llc_req_in_t llc_dma_req_in_i;
    llc_req_in_t llc_dma_req_in_tmp(); 
    llc_req_in_t llc_dma_req_in_next; 

    logic llc_dma_req_in_ready_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_dma_req_in_ready <= 1'b1;
        end else begin 
            llc_dma_req_in_ready <= llc_dma_req_in_ready_next; 
        end
    end 

    always_comb begin 
        llc_dma_req_in_ready_next = llc_dma_req_in_ready; 
        case (llc_dma_req_in_ready) 
            1'b0 : begin 
                if (llc_dma_req_in_ready_int) begin 
                    llc_dma_req_in_ready_next = 1'b1; 
                end
            end
            1'b1 : begin 
                if (llc_dma_req_in_valid && !llc_dma_req_in_ready_int) begin 
                    llc_dma_req_in_ready_next = 1'b0;
                end    
            end
        endcase
    end

    logic llc_dma_req_in_valid_tmp;
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_dma_req_in_valid_tmp <= 1'b0; 
        end else if (llc_dma_req_in_ready && !llc_dma_req_in_ready_int) begin 
            llc_dma_req_in_valid_tmp <= llc_dma_req_in_valid;
        end
    end 
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_dma_req_in_tmp.coh_msg <= 0; 
            llc_dma_req_in_tmp.hprot <= 0; 
            llc_dma_req_in_tmp.addr <= 0; 
            llc_dma_req_in_tmp.line <= 0; 
            llc_dma_req_in_tmp.req_id <= 0; 
            llc_dma_req_in_tmp.word_offset <= 0; 
            llc_dma_req_in_tmp.valid_words <= 0; 
        end else if (llc_dma_req_in_valid) begin
            llc_dma_req_in_tmp.coh_msg <= llc_dma_req_in_i.coh_msg; 
            llc_dma_req_in_tmp.hprot <= llc_dma_req_in_i.hprot; 
            llc_dma_req_in_tmp.addr <= llc_dma_req_in_i.addr; 
            llc_dma_req_in_tmp.line <= llc_dma_req_in_i.line; 
            llc_dma_req_in_tmp.req_id <= llc_dma_req_in_i.req_id; 
            llc_dma_req_in_tmp.word_offset <= llc_dma_req_in_i.word_offset; 
            llc_dma_req_in_tmp.valid_words <= llc_dma_req_in_i.valid_words; 
        end
    end

    assign llc_dma_req_in_next.coh_msg = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_i.coh_msg : llc_dma_req_in_tmp.coh_msg; 
    assign llc_dma_req_in_next.hprot = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_i.hprot : llc_dma_req_in_tmp.hprot; 
    assign llc_dma_req_in_next.addr = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_i.addr : llc_dma_req_in_tmp.addr; 
    assign llc_dma_req_in_next.line = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_i.line : llc_dma_req_in_tmp.line; 
    assign llc_dma_req_in_next.req_id = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_i.req_id : llc_dma_req_in_tmp.req_id; 
    assign llc_dma_req_in_next.word_offset = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_i.word_offset : llc_dma_req_in_tmp.word_offset; 
    assign llc_dma_req_in_next.valid_words = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_i.valid_words : llc_dma_req_in_tmp.valid_words; 
    assign llc_dma_req_in_valid_int = (llc_dma_req_in_ready && llc_dma_req_in_ready_int) ? llc_dma_req_in_valid : llc_dma_req_in_valid_tmp;  
    //RSP IN 
    input logic llc_rsp_in_valid, llc_rsp_in_ready_int; 
    output logic llc_rsp_in_ready, llc_rsp_in_valid_int;
    
    llc_rsp_in_t llc_rsp_in_i;
    llc_rsp_in_t llc_rsp_in_tmp(); 
    llc_rsp_in_t llc_rsp_in_next; 

    logic llc_rsp_in_ready_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rsp_in_ready <= 1'b1;
        end else begin 
            llc_rsp_in_ready <= llc_rsp_in_ready_next; 
        end
    end 

    always_comb begin 
        llc_rsp_in_ready_next = llc_rsp_in_ready; 
        case (llc_rsp_in_ready) 
            1'b0 : begin 
                if (llc_rsp_in_ready_int) begin 
                    llc_rsp_in_ready_next = 1'b1; 
                end
            end
            1'b1 : begin 
                if (llc_rsp_in_valid && !llc_rsp_in_ready_int) begin 
                    llc_rsp_in_ready_next = 1'b0;
                end    
            end
        endcase
    end

    logic llc_rsp_in_valid_tmp;
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rsp_in_valid_tmp <= 1'b0; 
        end else if (llc_rsp_in_ready && !llc_rsp_in_ready_int) begin 
            llc_rsp_in_valid_tmp <= llc_rsp_in_valid;
        end
    end 
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rsp_in_tmp.coh_msg <= 0; 
            llc_rsp_in_tmp.addr <= 0; 
            llc_rsp_in_tmp.line <= 0; 
            llc_rsp_in_tmp.req_id <= 0; 
        end else if (llc_rsp_in_valid) begin
            llc_rsp_in_tmp.coh_msg <= llc_rsp_in_i.coh_msg; 
            llc_rsp_in_tmp.addr <= llc_rsp_in_i.addr; 
            llc_rsp_in_tmp.line <= llc_rsp_in_i.line; 
            llc_rsp_in_tmp.req_id <= llc_rsp_in_i.req_id; 
        end
    end

    assign llc_rsp_in_next.coh_msg = (llc_rsp_in_ready && llc_rsp_in_ready_int) ? llc_rsp_in_i.coh_msg : llc_rsp_in_tmp.coh_msg; 
    assign llc_rsp_in_next.addr = (llc_rsp_in_ready && llc_rsp_in_ready_int) ? llc_rsp_in_i.addr : llc_rsp_in_tmp.addr; 
    assign llc_rsp_in_next.line = (llc_rsp_in_ready && llc_rsp_in_ready_int) ? llc_rsp_in_i.line : llc_rsp_in_tmp.line; 
    assign llc_rsp_in_next.req_id = (llc_rsp_in_ready && llc_rsp_in_ready_int) ? llc_rsp_in_i.req_id : llc_rsp_in_tmp.req_id; 
    assign llc_rsp_in_valid_int = (llc_rsp_in_ready && llc_rsp_in_ready_int) ? llc_rsp_in_valid : llc_rsp_in_valid_tmp;  
    
    //MEM RSP IN 
    input logic llc_mem_rsp_valid, llc_mem_rsp_ready_int; 
    output logic llc_mem_rsp_ready, llc_mem_rsp_valid_int;
    
    llc_mem_rsp_t llc_mem_rsp_i;
    llc_mem_rsp_t llc_mem_rsp_tmp(); 
    llc_mem_rsp_t llc_mem_rsp_next; 

    logic llc_mem_rsp_ready_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_mem_rsp_ready <= 1'b1;
        end else begin 
            llc_mem_rsp_ready <= llc_mem_rsp_ready_next; 
        end
    end 

    always_comb begin 
        llc_mem_rsp_ready_next = llc_mem_rsp_ready; 
        case (llc_mem_rsp_ready) 
            1'b0 : begin 
                if (llc_mem_rsp_ready_int) begin 
                    llc_mem_rsp_ready_next = 1'b1; 
                end
            end
            1'b1 : begin 
                if (llc_mem_rsp_valid && !llc_mem_rsp_ready_int) begin 
                    llc_mem_rsp_ready_next = 1'b0;
                end    
            end
        endcase
    end

    logic llc_mem_rsp_valid_tmp;
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_mem_rsp_valid_tmp <= 1'b0; 
        end else if (llc_mem_rsp_ready && !llc_mem_rsp_ready_int) begin 
            llc_mem_rsp_valid_tmp <= llc_mem_rsp_valid;
        end
    end 
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_mem_rsp_tmp.line <= 0; 
        end else if (llc_mem_rsp_valid) begin
            llc_mem_rsp_tmp.line <= llc_mem_rsp_i.line; 
        end
    end

    assign llc_mem_rsp_next.line = (llc_mem_rsp_ready && llc_mem_rsp_ready_int) ? llc_mem_rsp_i.line : llc_mem_rsp_tmp.line; 
    assign llc_mem_rsp_valid_int = (llc_mem_rsp_ready && llc_mem_rsp_ready_int) ? llc_mem_rsp_valid : llc_mem_rsp_valid_tmp;  
    
    //RST TB IN 
    input logic llc_rst_tb_valid, llc_rst_tb_ready_int; 
    output logic llc_rst_tb_ready, llc_rst_tb_valid_int;
    
    input logic llc_rst_tb_i;
    logic llc_rst_tb_tmp; 
    output logic llc_rst_tb_next; 

    logic llc_rst_tb_ready_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rst_tb_ready <= 1'b1;
        end else begin 
            llc_rst_tb_ready <= llc_rst_tb_ready_next; 
        end
    end 

    always_comb begin 
        llc_rst_tb_ready_next = llc_rst_tb_ready; 
        case (llc_rst_tb_ready) 
            1'b0 : begin 
                if (llc_rst_tb_ready_int) begin 
                    llc_rst_tb_ready_next = 1'b1; 
                end
            end
            1'b1 : begin 
                if (llc_rst_tb_valid && !llc_rst_tb_ready_int) begin 
                    llc_rst_tb_ready_next = 1'b0;
                end    
            end
        endcase
    end

    logic llc_rst_tb_valid_tmp;
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rst_tb_valid_tmp <= 1'b0; 
        end else if (llc_rst_tb_ready && !llc_rst_tb_ready_int) begin 
            llc_rst_tb_valid_tmp <= llc_rst_tb_valid;
        end
    end 
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rst_tb_tmp <= 0; 
        end else if (llc_rst_tb_valid) begin
            llc_rst_tb_tmp <= llc_rst_tb_i; 
        end
    end

    assign llc_rst_tb_next = (llc_rst_tb_ready && llc_rst_tb_ready_int) ? llc_rst_tb_i : llc_rst_tb_tmp; 
    assign llc_rst_tb_valid_int = (llc_rst_tb_ready && llc_rst_tb_ready_int) ? llc_rst_tb_valid : llc_rst_tb_valid_tmp;  
    
endmodule
