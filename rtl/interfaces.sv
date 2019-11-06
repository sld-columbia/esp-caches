`timescale 1ps / 1ps 
`include "cache_consts.svh" 
`include "cache_types.svh" 

// interfaces.sv
// Author: Joseph Zuckerman
// bypassable-queue implementation for input channels

module interfaces(clk, rst, llc_req_in_valid, llc_req_in_ready_int, llc_req_in_ready, llc_req_in_valid_int, llc_req_in_i, llc_req_in_next, llc_dma_req_in_valid, llc_dma_req_in_ready_int, llc_dma_req_in_ready, llc_dma_req_in_valid_int, llc_dma_req_in_i, llc_dma_req_in_next, llc_rsp_in_valid, llc_rsp_in_ready_int, llc_rsp_in_ready, llc_rsp_in_valid_int, llc_rsp_in_i, llc_rsp_in_next, llc_mem_rsp_valid, llc_mem_rsp_ready_int, llc_mem_rsp_ready, llc_mem_rsp_valid_int, llc_mem_rsp_i, llc_mem_rsp_next, llc_rst_tb_valid, llc_rst_tb_ready_int, llc_rst_tb_ready, llc_rst_tb_valid_int, llc_rst_tb_i, llc_rst_tb_next, llc_req_in_valid_tmp, llc_req_in_tmp, llc_dma_req_in_valid_tmp, llc_dma_req_in_tmp, llc_rsp_in_valid_tmp, llc_rsp_in_tmp, llc_rsp_out_valid, llc_rsp_out_ready, llc_rsp_out_valid_int, llc_rsp_out_ready_int, llc_rsp_out, llc_rsp_out_o, llc_dma_rsp_out_valid, llc_dma_rsp_out_ready, llc_dma_rsp_out_valid_int, llc_dma_rsp_out_ready_int, llc_dma_rsp_out_o, llc_dma_rsp_out, llc_fwd_out_valid, llc_fwd_out_ready, llc_fwd_out_valid_int, llc_fwd_out_ready_int, llc_fwd_out_o, llc_fwd_out, llc_mem_req_valid, llc_mem_req_ready, llc_mem_req_valid_int, llc_mem_req_ready_int, llc_mem_req_o, llc_mem_req, llc_rst_tb_done_valid, llc_rst_tb_done_ready, llc_rst_tb_done_valid_int, llc_rst_tb_done_ready_int, llc_rst_tb_done_o, llc_rst_tb_done
`ifdef STATS_ENABLE
    ,llc_stats_valid, llc_stats_ready, llc_stats_valid_int, llc_stats_ready_int, llc_stats_o, llc_stats
`endif
); 
    
    input logic clk, rst;
    
    //REQ IN 
    input logic llc_req_in_valid, llc_req_in_ready_int; 
    output logic llc_req_in_ready, llc_req_in_valid_int;
    
    llc_req_in_t llc_req_in_i;
    llc_req_in_t llc_req_in_tmp; 
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

    output logic llc_req_in_valid_tmp;
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
        end else if (llc_req_in_valid && llc_req_in_ready && !llc_req_in_ready_int) begin
            llc_req_in_tmp.coh_msg <= llc_req_in_i.coh_msg; 
            llc_req_in_tmp.hprot <= llc_req_in_i.hprot; 
            llc_req_in_tmp.addr <= llc_req_in_i.addr; 
            llc_req_in_tmp.line <= llc_req_in_i.line; 
            llc_req_in_tmp.req_id <= llc_req_in_i.req_id; 
            llc_req_in_tmp.word_offset <= llc_req_in_i.word_offset; 
            llc_req_in_tmp.valid_words <= llc_req_in_i.valid_words; 
        end
    end

    assign llc_req_in_next.coh_msg = (!llc_req_in_valid_tmp) ? llc_req_in_i.coh_msg : llc_req_in_tmp.coh_msg; 
    assign llc_req_in_next.hprot = (!llc_req_in_valid_tmp) ? llc_req_in_i.hprot : llc_req_in_tmp.hprot; 
    assign llc_req_in_next.addr = (!llc_req_in_valid_tmp) ? llc_req_in_i.addr : llc_req_in_tmp.addr; 
    assign llc_req_in_next.line = (!llc_req_in_valid_tmp) ? llc_req_in_i.line : llc_req_in_tmp.line; 
    assign llc_req_in_next.req_id = (!llc_req_in_valid_tmp) ? llc_req_in_i.req_id : llc_req_in_tmp.req_id; 
    assign llc_req_in_next.word_offset = (!llc_req_in_valid_tmp) ? llc_req_in_i.word_offset : llc_req_in_tmp.word_offset; 
    assign llc_req_in_next.valid_words = (!llc_req_in_valid_tmp) ? llc_req_in_i.valid_words : llc_req_in_tmp.valid_words; 
    assign llc_req_in_valid_int = llc_req_in_valid | llc_req_in_valid_tmp; 

    //DMA REQ IN 
    input logic llc_dma_req_in_valid, llc_dma_req_in_ready_int; 
    output logic llc_dma_req_in_ready, llc_dma_req_in_valid_int;
    
    llc_req_in_t llc_dma_req_in_i;
    llc_req_in_t llc_dma_req_in_tmp; 
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

    output logic llc_dma_req_in_valid_tmp;
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
        end else if (llc_dma_req_in_valid && llc_dma_req_in_ready && !llc_dma_req_in_ready_int) begin
            llc_dma_req_in_tmp.coh_msg <= llc_dma_req_in_i.coh_msg; 
            llc_dma_req_in_tmp.hprot <= llc_dma_req_in_i.hprot; 
            llc_dma_req_in_tmp.addr <= llc_dma_req_in_i.addr; 
            llc_dma_req_in_tmp.line <= llc_dma_req_in_i.line; 
            llc_dma_req_in_tmp.req_id <= llc_dma_req_in_i.req_id; 
            llc_dma_req_in_tmp.word_offset <= llc_dma_req_in_i.word_offset; 
            llc_dma_req_in_tmp.valid_words <= llc_dma_req_in_i.valid_words; 
        end
    end

    assign llc_dma_req_in_next.coh_msg = (!llc_dma_req_in_valid_tmp) ? llc_dma_req_in_i.coh_msg : llc_dma_req_in_tmp.coh_msg; 
    assign llc_dma_req_in_next.hprot = (!llc_dma_req_in_valid_tmp) ? llc_dma_req_in_i.hprot : llc_dma_req_in_tmp.hprot; 
    assign llc_dma_req_in_next.addr = (!llc_dma_req_in_valid_tmp) ? llc_dma_req_in_i.addr : llc_dma_req_in_tmp.addr; 
    assign llc_dma_req_in_next.line = (!llc_dma_req_in_valid_tmp) ? llc_dma_req_in_i.line : llc_dma_req_in_tmp.line; 
    assign llc_dma_req_in_next.req_id = (!llc_dma_req_in_valid_tmp) ? llc_dma_req_in_i.req_id : llc_dma_req_in_tmp.req_id; 
    assign llc_dma_req_in_next.word_offset = (!llc_dma_req_in_valid_tmp) ? llc_dma_req_in_i.word_offset : llc_dma_req_in_tmp.word_offset; 
    assign llc_dma_req_in_next.valid_words = (!llc_dma_req_in_valid_tmp) ? llc_dma_req_in_i.valid_words : llc_dma_req_in_tmp.valid_words; 
    assign llc_dma_req_in_valid_int = llc_dma_req_in_valid | llc_dma_req_in_valid_tmp; 
    
    //RSP IN 
    input logic llc_rsp_in_valid, llc_rsp_in_ready_int; 
    output logic llc_rsp_in_ready, llc_rsp_in_valid_int;
    
    llc_rsp_in_t llc_rsp_in_i;
    llc_rsp_in_t llc_rsp_in_tmp; 
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

    output logic llc_rsp_in_valid_tmp;
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
        end else if (llc_rsp_in_valid && llc_rsp_in_ready && !llc_rsp_in_ready_int ) begin
            llc_rsp_in_tmp.coh_msg <= llc_rsp_in_i.coh_msg; 
            llc_rsp_in_tmp.addr <= llc_rsp_in_i.addr; 
            llc_rsp_in_tmp.line <= llc_rsp_in_i.line; 
            llc_rsp_in_tmp.req_id <= llc_rsp_in_i.req_id; 
        end
    end

    assign llc_rsp_in_next.coh_msg = (!llc_rsp_in_valid_tmp) ? llc_rsp_in_i.coh_msg : llc_rsp_in_tmp.coh_msg; 
    assign llc_rsp_in_next.addr = (!llc_rsp_in_valid_tmp) ? llc_rsp_in_i.addr : llc_rsp_in_tmp.addr; 
    assign llc_rsp_in_next.line = (!llc_rsp_in_valid_tmp) ? llc_rsp_in_i.line : llc_rsp_in_tmp.line; 
    assign llc_rsp_in_next.req_id = (!llc_rsp_in_valid_tmp) ? llc_rsp_in_i.req_id : llc_rsp_in_tmp.req_id; 
    assign llc_rsp_in_valid_int = llc_rsp_in_valid | llc_rsp_in_valid_tmp; 
    
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
        end else if (llc_mem_rsp_valid && llc_mem_rsp_ready && !llc_mem_rsp_ready_int) begin
            llc_mem_rsp_tmp.line <= llc_mem_rsp_i.line; 
        end
    end

    assign llc_mem_rsp_next.line = (!llc_mem_rsp_valid_tmp) ? llc_mem_rsp_i.line : llc_mem_rsp_tmp.line; 
    assign llc_mem_rsp_valid_int = llc_mem_rsp_valid | llc_mem_rsp_valid_tmp; 
    
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
        end else if (llc_rst_tb_valid && llc_rst_tb_ready && !llc_rst_tb_ready_int) begin
            llc_rst_tb_tmp <= llc_rst_tb_i; 
        end
    end

    assign llc_rst_tb_next = (!llc_rst_tb_valid_tmp) ? llc_rst_tb_i : llc_rst_tb_tmp; 
    assign llc_rst_tb_valid_int = llc_rst_tb_valid | llc_rst_tb_valid_tmp; 

    //LLC RSP OUT
    input logic llc_rsp_out_ready, llc_rsp_out_valid_int;
    output logic llc_rsp_out_valid, llc_rsp_out_ready_int;
    
    llc_rsp_out_t llc_rsp_out_o;
    llc_rsp_out_t llc_rsp_out_tmp(); 
    llc_rsp_out_t llc_rsp_out; 

    logic llc_rsp_out_ready_int_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rsp_out_ready_int <= 1'b1;
        end else begin 
            llc_rsp_out_ready_int <= llc_rsp_out_ready_int_next; 
        end
    end
    
    always_comb begin 
        llc_rsp_out_ready_int_next = llc_rsp_out_ready_int;
        case (llc_rsp_out_ready_int)
            1'b0 : begin 
                if (llc_rsp_out_ready) begin 
                    llc_rsp_out_ready_int_next = 1'b1; 
                end
            end 
            1'b1 : begin 
                if (llc_rsp_out_valid_int && !llc_rsp_out_ready) begin 
                    llc_rsp_out_ready_int_next = 1'b0; 
                end 
            end
        endcase
    end

    logic llc_rsp_out_valid_tmp; 
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rsp_out_valid_tmp <= 1'b0; 
        end else if (llc_rsp_out_ready_int && !llc_rsp_out_ready) begin 
            llc_rsp_out_valid_tmp <= llc_rsp_out_valid_int; 
        end 
    end
    
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rsp_out_tmp.coh_msg <= 0; 
            llc_rsp_out_tmp.addr <= 0; 
            llc_rsp_out_tmp.line <= 0; 
            llc_rsp_out_tmp.invack_cnt <= 0; 
            llc_rsp_out_tmp.req_id <= 0;
            llc_rsp_out_tmp.dest_id <= 0; 
            llc_rsp_out_tmp.word_offset <= 0; 
        end else if (llc_rsp_out_valid_int && llc_rsp_out_ready_int && !llc_rsp_out_ready) begin 
            llc_rsp_out_tmp.coh_msg <= llc_rsp_out_o.coh_msg; 
            llc_rsp_out_tmp.addr <= llc_rsp_out_o.addr; 
            llc_rsp_out_tmp.line <= llc_rsp_out_o.line; 
            llc_rsp_out_tmp.invack_cnt <= llc_rsp_out_o.invack_cnt; 
            llc_rsp_out_tmp.req_id <= llc_rsp_out_o.req_id;
            llc_rsp_out_tmp.dest_id <= llc_rsp_out_o.dest_id; 
            llc_rsp_out_tmp.word_offset <= llc_rsp_out_o.word_offset; 
        end 
    end

    assign llc_rsp_out.coh_msg = (!llc_rsp_out_valid_tmp) ? llc_rsp_out_o.coh_msg : llc_rsp_out_tmp.coh_msg; 
    assign llc_rsp_out.addr = (!llc_rsp_out_valid_tmp) ? llc_rsp_out_o.addr : llc_rsp_out_tmp.addr; 
    assign llc_rsp_out.line = (!llc_rsp_out_valid_tmp) ? llc_rsp_out_o.line : llc_rsp_out_tmp.line; 
    assign llc_rsp_out.invack_cnt = (!llc_rsp_out_valid_tmp) ? llc_rsp_out_o.invack_cnt : llc_rsp_out_tmp.invack_cnt; 
    assign llc_rsp_out.req_id = (!llc_rsp_out_valid_tmp) ? llc_rsp_out_o.req_id : llc_rsp_out_tmp.req_id; 
    assign llc_rsp_out.dest_id = (!llc_rsp_out_valid_tmp) ? llc_rsp_out_o.dest_id : llc_rsp_out_tmp.dest_id; 
    assign llc_rsp_out.word_offset = (!llc_rsp_out_valid_tmp) ? llc_rsp_out_o.word_offset : llc_rsp_out_tmp.word_offset; 
    assign llc_rsp_out_valid = llc_rsp_out_valid_int | llc_rsp_out_valid_tmp; 
    
    //LLC DMA RSP OUT
    input logic llc_dma_rsp_out_ready, llc_dma_rsp_out_valid_int;
    output logic llc_dma_rsp_out_valid, llc_dma_rsp_out_ready_int;
    
    llc_rsp_out_t llc_dma_rsp_out_o;
    llc_rsp_out_t llc_dma_rsp_out_tmp(); 
    llc_rsp_out_t llc_dma_rsp_out; 

    logic llc_dma_rsp_out_ready_int_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_dma_rsp_out_ready_int <= 1'b1;
        end else begin 
            llc_dma_rsp_out_ready_int <= llc_dma_rsp_out_ready_int_next; 
        end
    end
    
    always_comb begin 
        llc_dma_rsp_out_ready_int_next = llc_dma_rsp_out_ready_int;
        case (llc_dma_rsp_out_ready_int)
            1'b0 : begin 
                if (llc_dma_rsp_out_ready) begin 
                    llc_dma_rsp_out_ready_int_next = 1'b1; 
                end
            end 
            1'b1 : begin 
                if (llc_dma_rsp_out_valid_int && !llc_dma_rsp_out_ready) begin 
                    llc_dma_rsp_out_ready_int_next = 1'b0; 
                end 
            end
        endcase
    end

    logic llc_dma_rsp_out_valid_tmp; 
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_dma_rsp_out_valid_tmp <= 1'b0; 
        end else if (llc_dma_rsp_out_ready_int && !llc_dma_rsp_out_ready) begin 
            llc_dma_rsp_out_valid_tmp <= llc_dma_rsp_out_valid_int; 
        end 
    end
    
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_dma_rsp_out_tmp.coh_msg <= 0; 
            llc_dma_rsp_out_tmp.addr <= 0; 
            llc_dma_rsp_out_tmp.line <= 0; 
            llc_dma_rsp_out_tmp.invack_cnt <= 0; 
            llc_dma_rsp_out_tmp.req_id <= 0;
            llc_dma_rsp_out_tmp.dest_id <= 0; 
            llc_dma_rsp_out_tmp.word_offset <= 0; 
        end else if (llc_dma_rsp_out_valid_int && llc_dma_rsp_out_ready_int && !llc_dma_rsp_out_ready) begin 
            llc_dma_rsp_out_tmp.coh_msg <= llc_dma_rsp_out_o.coh_msg; 
            llc_dma_rsp_out_tmp.addr <= llc_dma_rsp_out_o.addr; 
            llc_dma_rsp_out_tmp.line <= llc_dma_rsp_out_o.line; 
            llc_dma_rsp_out_tmp.invack_cnt <= llc_dma_rsp_out_o.invack_cnt; 
            llc_dma_rsp_out_tmp.req_id <= llc_dma_rsp_out_o.req_id;
            llc_dma_rsp_out_tmp.dest_id <= llc_dma_rsp_out_o.dest_id; 
            llc_dma_rsp_out_tmp.word_offset <= llc_dma_rsp_out_o.word_offset; 
        end 
    end

    assign llc_dma_rsp_out.coh_msg = (!llc_dma_rsp_out_valid_tmp) ? llc_dma_rsp_out_o.coh_msg : llc_dma_rsp_out_tmp.coh_msg; 
    assign llc_dma_rsp_out.addr = (!llc_dma_rsp_out_valid_tmp) ? llc_dma_rsp_out_o.addr : llc_dma_rsp_out_tmp.addr; 
    assign llc_dma_rsp_out.line = (!llc_dma_rsp_out_valid_tmp) ? llc_dma_rsp_out_o.line : llc_dma_rsp_out_tmp.line; 
    assign llc_dma_rsp_out.invack_cnt = (!llc_dma_rsp_out_valid_tmp) ? llc_dma_rsp_out_o.invack_cnt : llc_dma_rsp_out_tmp.invack_cnt; 
    assign llc_dma_rsp_out.req_id = (!llc_dma_rsp_out_valid_tmp) ? llc_dma_rsp_out_o.req_id : llc_dma_rsp_out_tmp.req_id; 
    assign llc_dma_rsp_out.dest_id = (!llc_dma_rsp_out_valid_tmp) ? llc_dma_rsp_out_o.dest_id : llc_dma_rsp_out_tmp.dest_id; 
    assign llc_dma_rsp_out.word_offset = (!llc_dma_rsp_out_valid_tmp) ? llc_dma_rsp_out_o.word_offset : llc_dma_rsp_out_tmp.word_offset; 
    assign llc_dma_rsp_out_valid = llc_dma_rsp_out_valid_int | llc_dma_rsp_out_valid_tmp; 

    //LLC FWD OUT
    input logic llc_fwd_out_ready, llc_fwd_out_valid_int;
    output logic llc_fwd_out_valid, llc_fwd_out_ready_int;
    
    llc_fwd_out_t llc_fwd_out_o;
    llc_fwd_out_t llc_fwd_out_tmp(); 
    llc_fwd_out_t llc_fwd_out; 

    logic llc_fwd_out_ready_int_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_fwd_out_ready_int <= 1'b1;
        end else begin 
            llc_fwd_out_ready_int <= llc_fwd_out_ready_int_next; 
        end
    end
    
    always_comb begin 
        llc_fwd_out_ready_int_next = llc_fwd_out_ready_int;
        case (llc_fwd_out_ready_int)
            1'b0 : begin 
                if (llc_fwd_out_ready) begin 
                    llc_fwd_out_ready_int_next = 1'b1; 
                end
            end 
            1'b1 : begin 
                if (llc_fwd_out_valid_int && !llc_fwd_out_ready) begin 
                    llc_fwd_out_ready_int_next = 1'b0; 
                end 
            end
        endcase
    end

    logic llc_fwd_out_valid_tmp; 
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_fwd_out_valid_tmp <= 1'b0; 
        end else if (llc_fwd_out_ready_int && !llc_fwd_out_ready) begin 
            llc_fwd_out_valid_tmp <= llc_fwd_out_valid_int; 
        end 
    end
    
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_fwd_out_tmp.coh_msg <= 0; 
            llc_fwd_out_tmp.addr <= 0; 
            llc_fwd_out_tmp.req_id <= 0;
            llc_fwd_out_tmp.dest_id <= 0; 
        end else if (llc_fwd_out_valid_int && llc_fwd_out_ready_int && !llc_fwd_out_ready) begin 
            llc_fwd_out_tmp.coh_msg <= llc_fwd_out_o.coh_msg; 
            llc_fwd_out_tmp.addr <= llc_fwd_out_o.addr; 
            llc_fwd_out_tmp.req_id <= llc_fwd_out_o.req_id;
            llc_fwd_out_tmp.dest_id <= llc_fwd_out_o.dest_id; 
        end 
    end

    assign llc_fwd_out.coh_msg = (!llc_fwd_out_valid_tmp) ? llc_fwd_out_o.coh_msg : llc_fwd_out_tmp.coh_msg; 
    assign llc_fwd_out.addr = (!llc_fwd_out_valid_tmp) ? llc_fwd_out_o.addr : llc_fwd_out_tmp.addr; 
    assign llc_fwd_out.req_id = (!llc_fwd_out_valid_tmp) ? llc_fwd_out_o.req_id : llc_fwd_out_tmp.req_id; 
    assign llc_fwd_out.dest_id = (!llc_fwd_out_valid_tmp) ? llc_fwd_out_o.dest_id : llc_fwd_out_tmp.dest_id; 
    assign llc_fwd_out_valid = llc_fwd_out_valid_int | llc_fwd_out_valid_tmp; 
    
    //LLC MEM REQ
    input logic llc_mem_req_ready, llc_mem_req_valid_int;
    output logic llc_mem_req_valid, llc_mem_req_ready_int;
    
    llc_mem_req_t llc_mem_req_o;
    llc_mem_req_t llc_mem_req_tmp(); 
    llc_mem_req_t llc_mem_req; 

    logic llc_mem_req_ready_int_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_mem_req_ready_int <= 1'b1;
        end else begin 
            llc_mem_req_ready_int <= llc_mem_req_ready_int_next; 
        end
    end
    
    always_comb begin 
        llc_mem_req_ready_int_next = llc_mem_req_ready_int;
        case (llc_mem_req_ready_int)
            1'b0 : begin 
                if (llc_mem_req_ready) begin 
                    llc_mem_req_ready_int_next = 1'b1; 
                end
            end 
            1'b1 : begin 
                if (llc_mem_req_valid_int && !llc_mem_req_ready) begin 
                    llc_mem_req_ready_int_next = 1'b0; 
                end 
            end
        endcase
    end

    logic llc_mem_req_valid_tmp; 
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_mem_req_valid_tmp <= 1'b0; 
        end else if (llc_mem_req_ready_int && !llc_mem_req_ready) begin 
            llc_mem_req_valid_tmp <= llc_mem_req_valid_int; 
        end 
    end
    
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_mem_req_tmp.hwrite <= 0; 
            llc_mem_req_tmp.hsize <= 0; 
            llc_mem_req_tmp.hprot <= 0;
            llc_mem_req_tmp.addr <= 0; 
            llc_mem_req_tmp.line <= 0; 
        end else if (llc_mem_req_valid_int && llc_mem_req_ready_int && !llc_mem_req_ready) begin 
            llc_mem_req_tmp.hwrite <= llc_mem_req_o.hwrite; 
            llc_mem_req_tmp.hsize <= llc_mem_req_o.hsize; 
            llc_mem_req_tmp.hprot <= llc_mem_req_o.hprot;
            llc_mem_req_tmp.addr <= llc_mem_req_o.addr; 
            llc_mem_req_tmp.line <= llc_mem_req_o.line; 
        end 
    end

    assign llc_mem_req.hwrite = (!llc_mem_req_valid_tmp) ? llc_mem_req_o.hwrite : llc_mem_req_tmp.hwrite; 
    assign llc_mem_req.hsize = (!llc_mem_req_valid_tmp) ? llc_mem_req_o.hsize : llc_mem_req_tmp.hsize; 
    assign llc_mem_req.hprot = (!llc_mem_req_valid_tmp) ? llc_mem_req_o.hprot : llc_mem_req_tmp.hprot; 
    assign llc_mem_req.addr = (!llc_mem_req_valid_tmp) ? llc_mem_req_o.addr : llc_mem_req_tmp.addr; 
    assign llc_mem_req.line = (!llc_mem_req_valid_tmp) ? llc_mem_req_o.line : llc_mem_req_tmp.line; 
    assign llc_mem_req_valid = llc_mem_req_valid_int | llc_mem_req_valid_tmp; 
   
    //LLC RST TB DONE
    input logic llc_rst_tb_done_ready, llc_rst_tb_done_valid_int;
    output logic llc_rst_tb_done_valid, llc_rst_tb_done_ready_int;
    
    input logic llc_rst_tb_done_o;
    logic llc_rst_tb_done_tmp; 
    output logic llc_rst_tb_done; 

    logic llc_rst_tb_done_ready_int_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rst_tb_done_ready_int <= 1'b1;
        end else begin 
            llc_rst_tb_done_ready_int <= llc_rst_tb_done_ready_int_next; 
        end
    end
    
    always_comb begin 
        llc_rst_tb_done_ready_int_next = llc_rst_tb_done_ready_int;
        case (llc_rst_tb_done_ready_int)
            1'b0 : begin 
                if (llc_rst_tb_done_ready) begin 
                    llc_rst_tb_done_ready_int_next = 1'b1; 
                end
            end 
            1'b1 : begin 
                if (llc_rst_tb_done_valid_int && !llc_rst_tb_done_ready) begin 
                    llc_rst_tb_done_ready_int_next = 1'b0; 
                end 
            end
        endcase
    end

    logic llc_rst_tb_done_valid_tmp; 
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rst_tb_done_valid_tmp <= 1'b0; 
        end else if (llc_rst_tb_done_ready_int && !llc_rst_tb_done_ready) begin 
            llc_rst_tb_done_valid_tmp <= llc_rst_tb_done_valid_int; 
        end 
    end
    
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_rst_tb_done_tmp <= 0; 
        end else if (llc_rst_tb_done_valid_int && llc_rst_tb_done_ready_int && !llc_rst_tb_done_ready) begin 
            llc_rst_tb_done_tmp <= llc_rst_tb_done_o; 
        end 
    end

    assign llc_rst_tb_done = (!llc_rst_tb_done_valid_tmp) ? llc_rst_tb_done_o : llc_rst_tb_done_tmp; 
    assign llc_rst_tb_done_valid = llc_rst_tb_done_valid_int | llc_rst_tb_done_valid_tmp; 

    //LLC RST TB DONE
`ifdef STATS_ENABLE
    input logic llc_stats_ready, llc_stats_valid_int;
    output logic llc_stats_valid, llc_stats_ready_int;
    
    input logic llc_stats_o;
    logic llc_stats_tmp; 
    output logic llc_stats; 

    logic llc_stats_ready_int_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_stats_ready_int <= 1'b1;
        end else begin 
            llc_stats_ready_int <= llc_stats_ready_int_next; 
        end
    end
    
    always_comb begin 
        llc_stats_ready_int_next = llc_stats_ready_int;
        case (llc_stats_ready_int)
            1'b0 : begin 
                if (llc_stats_ready) begin 
                    llc_stats_ready_int_next = 1'b1; 
                end
            end 
            1'b1 : begin 
                if (llc_stats_valid_int && !llc_stats_ready) begin 
                    llc_stats_ready_int_next = 1'b0; 
                end 
            end
        endcase
    end

    logic llc_stats_valid_tmp; 
    always @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_stats_valid_tmp <= 1'b0; 
        end else if (llc_stats_ready_int && !llc_stats_ready) begin 
            llc_stats_valid_tmp <= llc_stats_valid_int; 
        end 
    end
    
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            llc_stats_tmp <= 0; 
        end else if (llc_stats_valid_int && llc_stats_ready_int && !llc_stats_ready) begin 
            llc_stats_tmp <= llc_stats_o; 
        end 
    end

    assign llc_stats = (!llc_stats_valid_tmp) ? llc_stats_o : llc_stats_tmp; 
    assign llc_stats_valid = llc_stats_valid_int | llc_stats_valid_tmp; 
`endif
endmodule
