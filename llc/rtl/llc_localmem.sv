// Copyright (c) 2011-2019 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps 
`include "cache_consts.svh"
`include "cache_types.svh"

// llc_localmem.sv 
// llc memory 
// author: Joseph Zuckerman

module llc_localmem (    
    input logic clk, 
    input logic rst, 
    input logic rd_en,
    input logic wr_data_dirty_bit, 
    input logic wr_en,
    input logic wr_en_evict_way,
    input logic [(`LLC_NUM_PORTS-1):0] wr_rst_flush,
    input llc_set_t set_in,
    input llc_way_t way,
    input line_t wr_data_line,
    input llc_tag_t wr_data_tag,
    input sharers_t wr_data_sharers, 
    input owner_t wr_data_owner,
    input hprot_t wr_data_hprot, 
    input llc_way_t wr_data_evict_way,  
    input  llc_state_t wr_data_state,
    
    output logic rd_data_dirty_bit[`LLC_NUM_PORTS],
    output line_t rd_data_line[`LLC_NUM_PORTS],
    output llc_tag_t rd_data_tag[`LLC_NUM_PORTS],
    output sharers_t rd_data_sharers[`LLC_NUM_PORTS],
    output owner_t rd_data_owner[`LLC_NUM_PORTS],
    output hprot_t rd_data_hprot[`LLC_NUM_PORTS],
    output llc_state_t rd_data_state[`LLC_NUM_PORTS],
    output llc_way_t rd_data_evict_way
    );

    owner_t rd_data_owner_tmp[`LLC_NUM_PORTS][`LLC_OWNER_BRAMS_PER_WAY];
    sharers_t rd_data_sharers_tmp[`LLC_NUM_PORTS][`LLC_SHARERS_BRAMS_PER_WAY]; 
    hprot_t rd_data_hprot_tmp[`LLC_NUM_PORTS][`LLC_HPROT_BRAMS_PER_WAY]; 
    logic rd_data_dirty_bit_tmp[`LLC_NUM_PORTS][`LLC_DIRTY_BIT_BRAMS_PER_WAY]; 
    
    //for following 3 use BRAM data width to aviod warnings, only copy relevant bits to output data 
    logic [`LLC_STATE_BRAM_WIDTH-1:0] rd_data_state_tmp[`LLC_NUM_PORTS][`LLC_STATE_BRAMS_PER_WAY]; 
    logic [`LLC_TAG_BRAM_WIDTH-1:0] rd_data_tag_tmp[`LLC_NUM_PORTS][`LLC_TAG_BRAMS_PER_WAY]; 
    logic [`LLC_EVICT_WAY_BRAM_WIDTH-1:0] rd_data_evict_way_tmp[`LLC_EVICT_WAY_BRAMS]; 
    line_t rd_data_line_tmp[`LLC_NUM_PORTS][`LLC_LINE_BRAMS_PER_WAY]; 
    
    //write enable decoder for ways 
    logic wr_en_port[0:(`LLC_NUM_PORTS-1)];
    always_comb begin 
        for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
            wr_en_port[i] = 1'b0; 
            if (wr_rst_flush[i]) begin 
                wr_en_port[i] = 1'b1;
            end else if (way == i) begin 
                wr_en_port[i] = wr_en; 
            end
        end
    end

    logic wr_en_owner_bank[`LLC_OWNER_BRAMS_PER_WAY];
    logic wr_en_sharers_bank[`LLC_SHARERS_BRAMS_PER_WAY];
    logic wr_en_hprot_bank[`LLC_HPROT_BRAMS_PER_WAY];
    logic wr_en_dirty_bit_bank[`LLC_DIRTY_BIT_BRAMS_PER_WAY];
    logic wr_en_state_bank[`LLC_STATE_BRAMS_PER_WAY];
    logic wr_en_tag_bank[`LLC_TAG_BRAMS_PER_WAY];
    logic wr_en_evict_way_bank[`LLC_EVICT_WAY_BRAMS];
    logic wr_en_line_bank[`LLC_LINE_BRAMS_PER_WAY];

    logic wr_rst_flush_or; 
    assign wr_rst_flush_or = |(wr_rst_flush); 

    //extend to the appropriate BRAM width 
    logic [3:0] wr_data_state_extended;
    assign wr_data_state_extended = {{(4-`LLC_STATE_BITS){1'b0}}, wr_data_state};
    logic [23:0] wr_data_tag_extended;
    assign wr_data_tag_extended = {{(24-`LLC_TAG_BITS){1'b0}}, wr_data_tag};
    logic [3:0] wr_data_evict_way_extended; 

    always_comb begin 
        if (`LLC_WAYS == 16) begin 
            wr_data_evict_way_extended = wr_data_evict_way;
        end else begin 
            wr_data_evict_way_extended = {{(4-`LLC_WAY_BITS){1'b0}}, wr_data_evict_way};
        end 
    end
    generate 
        if (`LLC_OWNER_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_owner_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_OWNER_BRAMS_PER_WAY; j++) begin 
                    wr_en_owner_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS)]) begin 
                        wr_en_owner_bank[j] = wr_en;
                    end
                end
            end
        end
        
        if (`LLC_SHARERS_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_sharers_bank[0] = wr_en  | wr_rst_flush_or;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_SHARERS_BRAMS_PER_WAY; j++) begin 
                    wr_en_sharers_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS)]) begin 
                        wr_en_sharers_bank[j] = wr_en  | wr_rst_flush_or;
                    end
                end
            end
        end
        
        if (`LLC_HPROT_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_hprot_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_HPROT_BRAMS_PER_WAY; j++) begin 
                    wr_en_hprot_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS)]) begin 
                        wr_en_hprot_bank[j] = wr_en;
                    end
                end
            end
        end
        
        if (`LLC_DIRTY_BIT_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_dirty_bit_bank[0] = wr_en  | wr_rst_flush_or;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_DIRTY_BIT_BRAMS_PER_WAY; j++) begin 
                    wr_en_dirty_bit_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS)]) begin 
                        wr_en_dirty_bit_bank[j] = wr_en  | wr_rst_flush_or;
                    end
                end
            end
        end

        if (`LLC_STATE_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_state_bank[0] = wr_en  | wr_rst_flush_or;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_STATE_BRAMS_PER_WAY; j++) begin 
                    wr_en_state_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS)]) begin 
                        wr_en_state_bank[j] = wr_en  | wr_rst_flush_or;
                    end
                end
            end
        end

        if (`LLC_TAG_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_tag_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_TAG_BRAMS_PER_WAY; j++) begin 
                    wr_en_tag_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS)]) begin 
                        wr_en_tag_bank[j] = wr_en;
                    end
                end
            end
        end

        if (`LLC_EVICT_WAY_BRAMS == 1) begin 
            always_comb begin 
                wr_en_evict_way_bank[0] = wr_en_evict_way;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_EVICT_WAY_BRAMS; j++) begin 
                    wr_en_evict_way_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)]) begin 
                        wr_en_evict_way_bank[j] = wr_en_evict_way;
                    end
                end
            end
        end

        if (`LLC_LINE_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_line_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_LINE_BRAMS_PER_WAY; j++) begin 
                    wr_en_line_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS)]) begin 
                        wr_en_line_bank[j] = wr_en;
                    end
                end
            end
        end
    endgenerate

    genvar i, j, k; 
    generate 
        for (i = 0; i < (`LLC_NUM_PORTS / 2); i++) begin
            //owner memory
            //need 4 bits for owner - 4096x4 BRAM
            for (j = 0; j < `LLC_OWNER_BRAMS_PER_WAY; j++) begin
                if (`BRAM_4096_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) + 1) begin 
                    `ifdef XILINX_FPGA
                    BRAM_4096x4 owner_bram(
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b0, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_owner_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b1, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_owner), 
                        .Q1(rd_data_owner_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_owner_bank[j]), 
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                    `endif
                    
                    `ifdef GF12
                    GF12_SRAM_SP_2048x4 owner_sram_0(
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_owner_bank[j]),
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    GF12_SRAM_SP_2048x4 owner_sram_1(
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i+1][j]), 
                        .WE0(wr_en_port[2*i+1] & wr_en_owner_bank[j]), 
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    `endif
                end else begin 
                    `ifdef XILINX_FPGA
                    BRAM_4096x4 owner_bram(
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_owner_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_owner), 
                        .Q1(rd_data_owner_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_owner_bank[j]), 
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                    `endif    
                        
                    `ifdef GF12
                    GF12_SRAM_SP_2048x4 owner_sram_0(
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_owner_bank[j]),
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    GF12_SRAM_SP_2048x4 owner_sram_1(
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i+1][j]), 
                        .WE0(wr_en_port[2*i+1] & wr_en_owner_bank[j]), 
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    `endif
                end
            end
            //sharers memory 
            //need 16 bits for sharers - 1024x16 BRAM
            for (j = 0; j < `LLC_SHARERS_BRAMS_PER_WAY; j++) begin
                if (`BRAM_1024_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) + 1) begin 
                    `ifdef XILINX_FPGA
                    BRAM_1024x16 sharers_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b0, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b1, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_sharers), 
                        .Q1(rd_data_sharers_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_sharers_bank[j]),
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                    `endif
                    
                    `ifdef GF12
                    GF12_SRAM_SP_512x16 sharers_sram_0( 
                        .CLK(clk), 
                        .A0({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .WEM0({16{1'b1}}));
                    GF12_SRAM_SP_512x16 sharers_sram_1( 
                        .CLK(clk), 
                        .A0({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i+1][j]), 
                        .WE0(wr_en_port[2*i+1] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .WEM0({16{1'b1}}));
                    `endif
                end else begin 
                    `ifdef XILINX_FPGA 
                    BRAM_1024x16 sharers_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_sharers), 
                        .Q1(rd_data_sharers_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_sharers_bank[j]),
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                    `endif

                    `ifdef GF12
                    GF12_SRAM_SP_512x16 sharers_sram_0( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .WEM0({16{1'b1}}));
                    GF12_SRAM_SP_512x16 sharers_sram_1( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i+1][j]), 
                        .WE0(wr_en_port[2*i+1] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .WEM0({16{1'b1}}));
                    `endif
                end
            end
            //hprot memory 
            //need 1 bit for hport - 16384x1 BRAM
            for (j = 0; j < `LLC_HPROT_BRAMS_PER_WAY; j++) begin
                if (`BRAM_16384_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) + 1) begin 
                    `ifdef XILINX_FPGA
                    BRAM_16384x1 hprot_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b0, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_hprot), 
                        .Q0(rd_data_hprot_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b1, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_hprot), 
                        .Q1(rd_data_hprot_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                    `endif
                    
                    `ifdef GF12
                    logic[3:0] hprot_line_rd_data_0, hprot_line_rd_data_1, hprot_wr_mask, wr_data_hprot_extended;
                    assign wr_data_hprot_extended = {4{wr_data_hprot}};

                    always_comb begin 
                        hprot_wr_mask = 4'b0;
                        for (int b = 0; b < 4; b++) begin 
                            if (set_in[1:0] == b) begin 
                                hprot_wr_mask[b] = 1'b1;
                            end
                        end
                    end 

                    GF12_SRAM_SP_2048x4 hprot_sram_0( 
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):2]}),
                        .D0(wr_data_hprot_extended), 
                        .Q0(hprot_line_rd_data_0),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .WEM0(hprot_wr_mask));
                    
                    GF12_SRAM_SP_2048x4 hprot_sram_1(
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):2]}),
                        .D0(wr_data_hprot_extended), 
                        .Q0(hprot_line_rd_data_1), 
                        .WE0(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .WEM0(hprot_wr_mask));
                    
                    always_comb begin 
                        rd_data_hprot_tmp[2*i][j] = hprot_line_rd_data_0[0];
                        rd_data_hprot_tmp[2*i+1][j] = hprot_line_rd_data_1[0];
                        for (int b = 0; b < 4; b++) begin 
                            if (b == set_in[1:0]) begin 
                                rd_data_hprot_tmp[2*i][j] = hprot_line_rd_data_0[b];
                                rd_data_hprot_tmp[2*i+1][j] = hprot_line_rd_data_1[b];
                            end
                        end
                    end
                    
                    `endif
                end else begin 
                    `ifdef XILINX_FPGA
                    BRAM_16384x1 hprot_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_hprot), 
                        .Q0(rd_data_hprot_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_hprot), 
                        .Q1(rd_data_hprot_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE1(rd_en),
                        .WEM0(),
                        .WEM1());
                    `endif
                
                    `ifdef GF12
                    logic[3:0] hprot_line_rd_data_0, hprot_line_rd_data_1, hprot_wr_mask, wr_data_hprot_extended;
                    assign wr_data_hprot_extended = {4{wr_data_hprot}};

                    always_comb begin 
                        hprot_wr_mask = 4'b0;
                        for (int b = 0; b < 4; b++) begin
                            if (set_in[1:0] == b) begin 
                                hprot_wr_mask[b] = 1'b1;
                            end
                        end
                    end 
                    
                    GF12_SRAM_SP_2048x4 hprot_sram_0( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):2]),
                        .D0(wr_data_hprot_extended), 
                        .Q0(hprot_line_rd_data_0),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .WEM0(hprot_wr_mask));
                    
                    GF12_SRAM_SP_2048x4 hprot_sram_1( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):2]),
                        .D0(wr_data_hprot_extended), 
                        .Q0(hprot_line_rd_data_1), 
                        .WE0(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .WEM0(hprot_wr_mask));
                    
                    always_comb begin                       
                        rd_data_hprot_tmp[2*i][j] = hprot_line_rd_data_0[0];
                        rd_data_hprot_tmp[2*i+1][j] = hprot_line_rd_data_1[0];
                        for (int b = 0; b < 4; b++) begin 
                            if (b == set_in[1:0]) begin 
                                rd_data_hprot_tmp[2*i][j] = hprot_line_rd_data_0[b];
                                rd_data_hprot_tmp[2*i+1][j] = hprot_line_rd_data_1[b];
                            end
                        end
                    end
                    `endif
                end
            end
            //dirty bit memory 
            //need 1 dirty bit1 - 16384x1 BRAM
            for (j = 0; j < `LLC_DIRTY_BIT_BRAMS_PER_WAY; j++) begin
                if (`BRAM_16384_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) + 1) begin 
                    `ifdef XILINX_FPGA 
                    BRAM_16384x1 dirty_bit_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) - 1){1'b0}},
                                1'b0, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_dirty_bit), 
                        .Q0(rd_data_dirty_bit_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b1, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_dirty_bit), 
                        .Q1(rd_data_dirty_bit_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_dirty_bit_bank[j]),
                        .CE1(rd_en),
                        .WEM0(),
                        .WEM1());
                    `endif
                    
                    `ifdef GF12
                    logic[3:0] dirty_bit_line_rd_data_0, dirty_bit_line_rd_data_1, dirty_bit_wr_mask, wr_data_dirty_bit_extended;
                    assign wr_data_dirty_bit_extended = {4{wr_data_dirty_bit}};

                    always_comb begin 
                        dirty_bit_wr_mask = 4'b0;
                        for (int b = 0; b < 4; b++) begin 
                            if (set_in[1:0] == b) begin 
                                dirty_bit_wr_mask[b] = 1'b1;
                            end
                        end
                    end 

                    GF12_SRAM_SP_2048x4 dirty_bit_sram_0( 
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):2]}),
                        .D0(wr_data_dirty_bit_extended), 
                        .Q0(dirty_bit_line_rd_data_0),
                        .WE0(wr_en_port[2*i] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .WEM0(dirty_bit_wr_mask));
                    
                    GF12_SRAM_SP_2048x4 dirty_bit_sram_1(
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):2]}),
                        .D0(wr_data_dirty_bit_extended), 
                        .Q0(dirty_bit_line_rd_data_1), 
                        .WE0(wr_en_port[2*i+1] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .WEM0(dirty_bit_wr_mask));
                    
                    always_comb begin 
                        rd_data_dirty_bit_tmp[2*i][j] = dirty_bit_line_rd_data_0[0];
                        rd_data_dirty_bit_tmp[2*i+1][j] = dirty_bit_line_rd_data_1[0];
                        for (int b = 0; b < 4; b++) begin 
                            if (b == set_in[1:0]) begin 
                                rd_data_dirty_bit_tmp[2*i][j] = dirty_bit_line_rd_data_0[b];
                                rd_data_dirty_bit_tmp[2*i+1][j] = dirty_bit_line_rd_data_1[b];
                            end
                        end
                    end
                    
                    `endif
                end else begin 
                    `ifdef XILINX_FPGA
                    BRAM_16384x1 dirty_bit_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_dirty_bit), 
                        .Q0(rd_data_dirty_bit_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_dirty_bit), 
                        .Q1(rd_data_dirty_bit_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_dirty_bit_bank[j]),
                        .CE1(rd_en),
                        .WEM0(),
                        .WEM1());
                    `endif

                    `ifdef GF12
                    logic[3:0] dirty_bit_line_rd_data_0, dirty_bit_line_rd_data_1, dirty_bit_wr_mask, wr_data_dirty_bit_extended;
                    assign wr_data_dirty_bit_extended = {4{wr_data_dirty_bit}};

                    always_comb begin 
                        dirty_bit_wr_mask = 4'b0;
                        for (int b = 0; b < 4; b++) begin 
                            if (set_in[1:0] == b) begin 
                                dirty_bit_wr_mask[b] = 1'b1;
                            end
                        end
                    end 
                    
                    GF12_SRAM_SP_2048x4 dirty_bit_sram_0( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):2]),
                        .D0(wr_data_dirty_bit_extended), 
                        .Q0(dirty_bit_line_rd_data_0),
                        .WE0(wr_en_port[2*i] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .WEM0(dirty_bit_wr_mask));
                    
                    GF12_SRAM_SP_2048x4 dirty_bit_sram_1( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):2]),
                        .D0(wr_data_dirty_bit_extended), 
                        .Q0(dirty_bit_line_rd_data_1), 
                        .WE0(wr_en_port[2*i+1] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .WEM0(dirty_bit_wr_mask));
                    
                    always_comb begin                       
                        rd_data_dirty_bit_tmp[2*i][j] = dirty_bit_line_rd_data_0[0];
                        rd_data_dirty_bit_tmp[2*i+1][j] = dirty_bit_line_rd_data_1[0];
                        for (int b = 0; b < 4; b++) begin 
                            if (b == set_in[1:0]) begin 
                                rd_data_dirty_bit_tmp[2*i][j] = dirty_bit_line_rd_data_0[b];
                                rd_data_dirty_bit_tmp[2*i+1][j] = dirty_bit_line_rd_data_1[b];
                            end
                        end
                    end
                    `endif
                end     
            end
            //state memory 
            //need 3 bits for state - 4096x4 BRAM
            for (j = 0; j < `LLC_STATE_BRAMS_PER_WAY; j++) begin
                 if (`BRAM_4096_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) + 1) begin 
                    `ifdef XILINX_FPGA
                    BRAM_4096x4 state_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b0, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                1'b1, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_state_extended), 
                        .Q1(rd_data_state_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_state_bank[j]),
                        .CE1(rd_en),
                        .WEM0(),
                        .WEM1());
                    `endif
                    
                    `ifdef GF12
                    GF12_SRAM_SP_2048x4 state_sram_0( 
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    GF12_SRAM_SP_2048x4 state_sram_1( 
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i+1][j]), 
                        .WE0(wr_en_port[2*i+1] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    `endif               
                 end else begin 
                    `ifdef XILINX_FPGA
                    BRAM_4096x4 state_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_state_extended), 
                        .Q1(rd_data_state_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_state_bank[j]),
                        .CE1(rd_en),
                        .WEM0(),
                        .WEM1());
                    `endif

                    `ifdef GF12
                    GF12_SRAM_SP_2048x4 state_sram_0( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    GF12_SRAM_SP_2048x4 state_sram_1( 
                        .CLK(clk), 
                        .A0(set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i+1][j]), 
                        .WE0(wr_en_port[2*i+1] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .WEM0({4{1'b1}}));
                    `endif               
                end 
            end
            //tag memory 
            //need ~15-20 bits for tag - 2048x8 BRAM
            for (j = 0; j < `LLC_TAG_BRAMS_PER_WAY; j++) begin 
                for (k = 0; k < `LLC_BRAMS_PER_TAG; k++) begin 
                    if (`BRAM_2048_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) + 1) begin 
                        `ifdef XILINX_FPGA
                        BRAM_2048x8 tag_bram( 
                            .CLK(clk), 
                            .A0({{(`BRAM_2048_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    1'b0, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q0(rd_data_tag_tmp[2*i][j][(8*(k+1)-1):(8*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                            .CE0(rd_en),
                            .A1({{(`BRAM_2048_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    1'b1, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                            .D1(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q1(rd_data_tag_tmp[2*i+1][j][(8*(k+1)-1):(8*k)]),
                            .WE1(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                            .CE1(rd_en),
                            .WEM0(),
                            .WEM1());
                        `endif

                        `ifdef GF12
                        GF12_SRAM_SP_1024x8 tag_sram_0( 
                            .CLK(clk), 
                            .A0({{(`BRAM_2048_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q0(rd_data_tag_tmp[2*i][j][(8*(k+1)-1):(8*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                            .CE0(rd_en),
                            .WEM0({8{1'b1}}));
                        GF12_SRAM_SP_1024x8 tag_sram_1( 
                            .CLK(clk), 
                            .A0({{(`BRAM_2048_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q0(rd_data_tag_tmp[2*i+1][j][(8*(k+1)-1):(8*k)]),
                            .WE0(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                            .CE0(rd_en),
                            .WEM0({8{1'b1}}));
                        `endif
                    end else begin 
                        `ifdef XILINX_FPGA
                        BRAM_2048x8 tag_bram( 
                            .CLK(clk), 
                            .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q0(rd_data_tag_tmp[2*i][j][(8*(k+1)-1):(8*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                            .CE0(rd_en),
                            .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                            .D1(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q1(rd_data_tag_tmp[2*i+1][j][(8*(k+1)-1):(8*k)]),
                            .WE1(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                            .CE1(rd_en),
                            .WEM0(),
                            .WEM1());
                        `endif

                        `ifdef GF12
                        GF12_SRAM_SP_1024x8 tag_sram_0( 
                            .CLK(clk), 
                            .A0(set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]),
                            .D0(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q0(rd_data_tag_tmp[2*i][j][(8*(k+1)-1):(8*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                            .CE0(rd_en),
                            .WEM0({8{1'b1}}));
                        GF12_SRAM_SP_1024x8 tag_sram_1( 
                            .CLK(clk), 
                            .A0(set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]),
                            .D0(wr_data_tag_extended[(8*(k+1)-1):(8*k)]), 
                            .Q0(rd_data_tag_tmp[2*i+1][j][(8*(k+1)-1):(8*k)]),
                            .WE0(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                            .CE0(rd_en),
                            .WEM0({8{1'b1}}));
                        `endif
                    end
                end 
            end
            //line memory 
            //128 bits - using 1024x16 BRAM, need 4 BRAMs per line 
            for (j = 0; j < `LLC_LINE_BRAMS_PER_WAY; j++) begin 
                for (k = 0; k < `LLC_BRAMS_PER_LINE; k++) begin 
                    if (`BRAM_1024_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) + 1) begin 
                        `ifdef XILINX_FPGA
                        BRAM_1024x16 line_bram( 
                            .CLK(clk), 
                            .A0({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    1'b0, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(16*(k+1)-1):(16*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .A1({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    1'b1, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D1(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q1(rd_data_line_tmp[2*i+1][j][(16*(k+1)-1):(16*k)]),
                            .WE1(wr_en_port[2*i+1] & wr_en_line_bank[j]),
                            .CE1(rd_en),
                            .WEM0(),
                            .WEM1());
                        `endif
                        
                        `ifdef GF12
                        GF12_SRAM_SP_512x16 line_sram_0( 
                            .CLK(clk), 
                            .A0({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(16*(k+1)-1):(16*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .WEM0({16{1'b1}}));
                        GF12_SRAM_SP_512x16 line_sram_1( 
                            .CLK(clk), 
                            .A0({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) - 1){1'b0}}, 
                                    set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q0(rd_data_line_tmp[2*i+1][j][(16*(k+1)-1):(16*k)]),
                            .WE0(wr_en_port[2*i+1] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .WEM0());
                        `endif
                    end else begin 
                        `ifdef XILINX_FPGA
                        BRAM_1024x16 line_bram( 
                            .CLK(clk), 
                            .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(16*(k+1)-1):(16*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D1(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q1(rd_data_line_tmp[2*i+1][j][(16*(k+1)-1):(16*k)]),
                            .WE1(wr_en_port[2*i+1] & wr_en_line_bank[j]),
                            .CE1(rd_en),
                            .WEM0(),
                            .WEM1());
                        `endif

                        `ifdef GF12
                        GF12_SRAM_SP_512x16 line_sram_0( 
                            .CLK(clk), 
                            .A0(set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]),
                            .D0(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(16*(k+1)-1):(16*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .WEM0({16{1'b1}}));
                        GF12_SRAM_SP_512x16 line_sram_1( 
                            .CLK(clk), 
                            .A0(set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]),
                            .D0(wr_data_line[(16*(k+1)-1):(16*k)]), 
                            .Q0(rd_data_line_tmp[2*i+1][j][(16*(k+1)-1):(16*k)]),
                            .WE0(wr_en_port[2*i+1] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .WEM0({16{1'b1}}));
                        `endif
                    end
                end 
            end
        end
            //evict ways memory 
            //need 2-5 bits for eviction  - 4096x4 BRAM
        for (j = 0; j < `LLC_EVICT_WAY_BRAMS; j++) begin
            if (`BRAM_4096_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)) begin 
                `ifdef XILINX_FPGA
                BRAM_4096x4 evict_way_bram( 
                    .CLK(clk), 
                    .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)){1'b0}},
                            set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):0]}),
                    .D0(wr_data_evict_way_extended), 
                    .Q0(rd_data_evict_way_tmp[j]),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en),
                    .A1(12'b0),
                    .D1(4'b0), 
                    .Q1(), 
                    .WE1(1'b0),
                    .CE1(1'b0),
                    .WEM0(),
                    .WEM1());
                `endif
                
                `ifdef GF12
                logic [3:0] rd_data_evict_way_tmp_0;
                logic [3:0] rd_data_evict_way_tmp_1;
                
                GF12_SRAM_SP_2048x4 evict_way_sram_0( 
                    .CLK(clk), 
                    .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)){1'b0}},
                            set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):1]}),
                    .D0(wr_data_evict_way_extended), 
                    .Q0(rd_data_evict_way_tmp_0),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en & ~set_in[0]),
                    .WEM0({4{1'b1}}));

                GF12_SRAM_SP_2048x4 evict_way_sram_1( 
                    .CLK(clk), 
                    .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)){1'b0}},
                            set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):1]}),
                    .D0(wr_data_evict_way_extended), 
                    .Q0(rd_data_evict_way_tmp_1),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en & set_in[0]),
                    .WEM0({4{1'b1}}));
                   
                always_comb begin 
                    if (set_in[0] == 1'b0) begin
                        rd_data_evict_way_tmp[j] = rd_data_evict_way_tmp_0;
                    end else begin
                        rd_data_evict_way_tmp[j] = rd_data_evict_way_tmp_1;
                    end 
                end
                `endif
            end else begin 
                `ifdef XILINX_FPGA
                BRAM_4096x4 evict_way_bram( 
                    .CLK(clk), 
                    .A0({set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):0]}),
                    .D0(wr_data_evict_way_extended), 
                    .Q0(rd_data_evict_way_tmp[j]),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en),
                    .A1(12'b0),
                    .D1(4'b0), 
                    .Q1(), 
                    .WE1(1'b0),
                    .CE1(1'b0),
                    .WEM0(),
                    .WEM1());
                `endif
                
                `ifdef GF12
                logic [3:0] rd_data_evict_way_tmp_0;
                logic [3:0] rd_data_evict_way_tmp_1;
                
                GF12_SRAM_SP_2048x4 evict_way_sram_0( 
                    .CLK(clk), 
                    .A0(set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):1]),
                    .D0(wr_data_evict_way_extended), 
                    .Q0(rd_data_evict_way_tmp_0),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en & ~set_in[0]),
                    .WEM0({4{1'b1}}));

                GF12_SRAM_SP_2048x4 evict_way_sram_1( 
                    .CLK(clk), 
                    .A0(set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):1]),
                    .D0(wr_data_evict_way_extended), 
                    .Q0(rd_data_evict_way_tmp_1),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en & set_in[0]),
                    .WEM0({4{1'b1}}));
                   
                always_comb begin 
                    if (set_in[0] == 1'b0) begin
                        rd_data_evict_way_tmp[j] = rd_data_evict_way_tmp_0;
                    end else begin
                        rd_data_evict_way_tmp[j] = rd_data_evict_way_tmp_1;
                    end 
                end
                `endif
            end 
        end
    endgenerate

    generate
        if (`LLC_OWNER_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_owner[i] = rd_data_owner_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_owner[i] = rd_data_owner_tmp[i][0];
                    for (int j = 1; j < `LLC_OWNER_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS)]) begin 
                            rd_data_owner[i] = rd_data_owner_tmp[i][j]; 
                        end
                    end 
                end
            end
        end 
         
        if (`LLC_SHARERS_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_sharers[i] = rd_data_sharers_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_sharers[i] = rd_data_sharers_tmp[i][0]; 
                    for (int j = 1; j < `LLC_SHARERS_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS)]) begin 
                            rd_data_sharers[i] = rd_data_sharers_tmp[i][j]; 
                        end
                    end 
                end
            end
        end

        if (`LLC_HPROT_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_hprot[i] = rd_data_hprot_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_hprot[i] = rd_data_hprot_tmp[i][0];
                    for (int j = 1; j < `LLC_HPROT_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS)]) begin 
                            rd_data_hprot[i] = rd_data_hprot_tmp[i][j];
                        end
                    end 
                end
            end
        end 

       if (`LLC_DIRTY_BIT_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_dirty_bit[i] = rd_data_dirty_bit_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_dirty_bit[i] = rd_data_dirty_bit_tmp[i][0];
                    for (int j = 1; j < `LLC_DIRTY_BIT_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS)]) begin 
                            rd_data_dirty_bit[i] = rd_data_dirty_bit_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_STATE_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_state[i] = rd_data_state_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_state[i] = rd_data_state_tmp[i][0];
                    for (int j = 1; j < `LLC_STATE_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS)]) begin 
                            rd_data_state[i] = rd_data_state_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_TAG_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_tag[i] = rd_data_tag_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_tag[i] = rd_data_tag_tmp[i][0];
                    for (int j = 1; j < `LLC_TAG_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS)]) begin 
                            rd_data_tag[i] = rd_data_tag_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_LINE_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_line[i] = rd_data_line_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_line[i] = rd_data_line_tmp[i][0];
                    for (int j = 1; j < `LLC_LINE_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS)]) begin 
                            rd_data_line[i] = rd_data_line_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_EVICT_WAY_BRAMS == 1) begin 
            always_comb begin
                rd_data_evict_way = rd_data_evict_way_tmp[0]; 
            end
        end else begin 
            always_comb begin
                rd_data_evict_way = rd_data_evict_way_tmp[0];
                for (int j = 1; j < `LLC_EVICT_WAY_BRAMS; j++) begin 
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)]) begin 
                        rd_data_evict_way = rd_data_evict_way_tmp[j];
                    end
                end 
            end
        end 
    endgenerate

endmodule
