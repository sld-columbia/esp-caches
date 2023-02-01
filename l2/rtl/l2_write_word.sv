// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps 
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_write_word(
    input logic clk, 
    input logic rst,
    input word_t word_in,
    input word_offset_t w_off_in,
    input byte_offset_t b_off_in,
    input hsize_t hsize_in,
    input line_t line_in,
    
    output line_t line_out 
    );

    logic[6:0] size, b_off_tmp, w_off_bits, b_off_bits, off_bits, word_range_hi, line_range_hi;

    always_comb begin 
        size = `BITS_PER_WORD;
        b_off_tmp = 0; 
`ifdef BIG_ENDIAN
        if (hsize_in == `BYTE) begin 
            b_off_tmp = `BYTES_PER_WORD - 1 - b_off_in;
            size = 8;
        end else if (hsize_in == `HALFWORD) begin 
            b_off_tmp = `BYTES_PER_WORD - 2 - b_off_in;
            size = 16;
        end else if (`BYTE_BITS == 2) begin 
            size = 32;
        end else if (hsize_in == `WORD_32) begin 
            b_off_tmp = `BYTES_PER_WORD - 4 - b_off_in; 
            size = 32; 
        end else begin 
            size = 64;
        end
`else     
    b_off_tmp = b_off_in;
    if (hsize_in == `BYTE) begin 
        size = 8;
    end else if (hsize_in == `HALFWORD) begin 
        size = 16;
    end else if (hsize_in == `WORD_32) begin 
        size = 32;
    end else begin 
        size = 64; 
    end
`endif
        w_off_bits = `BITS_PER_WORD * w_off_in;
        b_off_bits = 8 * b_off_tmp;
        off_bits = w_off_bits + b_off_bits;

        word_range_hi = b_off_bits + size - 1;
        line_range_hi = off_bits + size - 1;
        line_out = line_in;
        
        if (hsize_in == `BYTE) begin 
            line_out[off_bits +: 8] = word_in[b_off_bits +: 8]; 
        end else if (hsize_in == `HALFWORD) begin 
            line_out[off_bits +: 16] = word_in[b_off_bits +: 16]; 
        end else if (hsize_in == `WORD_32) begin 
            line_out[off_bits +: 32] = word_in[b_off_bits +: 32]; 
        end else if (`BYTE_BITS != 2) begin 
            line_out[off_bits +: 64] = word_in[b_off_bits +: 64]; 
        end

end

endmodule
