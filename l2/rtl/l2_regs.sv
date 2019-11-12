`timescale 1ps / 1ps 
`include "cache_consts.svh" 
`include "cache_types.svh" 

module l2_regs(clk, rst, set_ongoing_flush, clr_ongoing_flush, ongoing_flush, incr_flush_set, clr_flush_set, flush_set, incr_flush_way, clr_flush_way, flush_way); 
    
    input logic clk, rst;

    input logic set_ongoing_flush, clr_ongoing_flush; 
    output logic ongoing_flush;
    
    input logic incr_flush_set, clr_flush_set; 
    output l2_set_t flush_set; 

    input logic incr_flush_way, clr_flush_way; 
    output l2_way_t flush_way;

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            ongoing_flush <= 1'b0;
        end else if (clr_ongoing_flush) begin 
            ongoing_flush <= 1'b0; 
        end else if (set_ongoing_flush) begin 
            ongoing_flush <= 1'b1; 
        end 
    end

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            flush_set <= 0; 
        end else if (clr_flush_set) begin 
            flush_set <= 0; 
        end else if (incr_flush_set) begin 
            flush_set <= flush_set + 1; 
        end
    end 

   always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            flush_way <= 0; 
        end else if (clr_flush_way) begin 
            flush_way <= 0; 
        end else if (incr_flush_way) begin 
            flush_way <= flush_way + 1; 
        end
    end 

endmodule
