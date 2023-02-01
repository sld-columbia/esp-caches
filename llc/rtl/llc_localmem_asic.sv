// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc_localmem_asic.sv
// llc memory for asic processes
// author: Joseph Zuckerman

module llc_localmem_asic (
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
    logic [27:0] rd_data_mixed_tmp[`LLC_NUM_PORTS][`LLC_ASIC_SRAMS_PER_WAY];
    sharers_t rd_data_sharers_tmp[`LLC_NUM_PORTS][`LLC_ASIC_SRAMS_PER_WAY];
    line_t rd_data_line_tmp[`LLC_NUM_PORTS][`LLC_ASIC_SRAMS_PER_WAY];

    //write enable decoder for ways
    logic wr_en_port[0:(`LLC_NUM_PORTS-1)];
    always_comb begin
        for (int i = 0; i < `LLC_NUM_PORTS; i++) begin
            wr_en_port[i] = 1'b0;
            if (wr_rst_flush[i]) begin
                wr_en_port[i] = 1'b1;
            end else if (way == i) begin
                wr_en_port[i] = 1'b1;
            end
        end
    end

    logic wr_en_mixed_bank[`LLC_ASIC_SRAMS_PER_WAY];
    logic wr_en_line_bank[`LLC_ASIC_SRAMS_PER_WAY];
    logic wr_en_sharers_bank[`LLC_ASIC_SRAMS_PER_WAY];

    logic [27:0] wr_data_mixed, wr_mixed_mask;

    generate
        if (`LLC_SET_BITS == 9) begin
            assign wr_data_mixed = {wr_data_hprot, wr_data_dirty_bit, wr_data_state, wr_data_owner, wr_data_tag};
        end else begin
            assign wr_data_mixed = {wr_data_hprot, wr_data_dirty_bit, wr_data_state, wr_data_owner, {(28 - 2 - `LLC_STATE_BITS - `MAX_N_L2_BITS -`LLC_TAG_BITS){1'b0}}, wr_data_tag};
        end
    endgenerate
    llc_way_t evict_way_arr[`LLC_SETS];

    logic wr_rst_flush_or;
    assign wr_rst_flush_or = |(wr_rst_flush);

    //determine mask for writing to shared SRAM
    always_comb begin
        wr_mixed_mask = 28'b0;

        if (wr_en) begin
            wr_mixed_mask[`LLC_ASIC_MIXED_SRAM_HPROT_INDEX] = 1'b1;
            wr_mixed_mask[`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_HI:`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_LO] = {`MAX_N_L2_BITS{1'b1}};
            wr_mixed_mask[`LLC_ASIC_MIXED_SRAM_TAG_INDEX_HI:`LLC_ASIC_MIXED_SRAM_TAG_INDEX_LO] = {`LLC_TAG_BITS{1'b1}};
        end

        if (wr_en | wr_rst_flush_or) begin
            wr_mixed_mask[`LLC_ASIC_MIXED_SRAM_DIRTY_BIT_INDEX] = 1'b1;
            wr_mixed_mask[`LLC_ASIC_MIXED_SRAM_STATE_INDEX_HI:`LLC_ASIC_MIXED_SRAM_STATE_INDEX_LO] = {`LLC_STATE_BITS{1'b1}};
        end

    end

    generate
        if (`LLC_ASIC_SRAMS_PER_WAY == 1) begin
            always_comb begin
                wr_en_mixed_bank[0] = wr_en | wr_rst_flush_or;
            end
        end else begin
            always_comb begin
                for (int j = 0; j < `LLC_ASIC_SRAMS_PER_WAY; j++) begin
                    wr_en_mixed_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS)]) begin
                        wr_en_mixed_bank[j] = wr_en | wr_rst_flush_or;
                    end
                end
            end
        end

        if (`LLC_ASIC_SRAMS_PER_WAY == 1) begin
            always_comb begin
                wr_en_line_bank[0] = wr_en;
            end
        end else begin
            always_comb begin
                for (int j = 0; j < `LLC_ASIC_SRAMS_PER_WAY; j++) begin
                    wr_en_line_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS)]) begin
                        wr_en_line_bank[j] = wr_en;
                    end
                end
            end
        end

        if (`LLC_ASIC_SRAMS_PER_WAY == 1) begin
            always_comb begin
                wr_en_sharers_bank[0] = wr_en | wr_rst_flush_or;
            end
        end else begin
            always_comb begin
                for (int j = 0; j < `LLC_ASIC_SRAMS_PER_WAY; j++) begin
                    wr_en_sharers_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS)]) begin
                        wr_en_sharers_bank[j] = wr_en | wr_rst_flush_or;
                    end
                end
            end
        end
    endgenerate

    genvar i, j, k;
    generate
        for (i = 0; i < `LLC_NUM_PORTS; i++) begin
            //shared memory for tag, state, hprot
            for (j = 0; j < `LLC_ASIC_SRAMS_PER_WAY; j++) begin
                if (`ASIC_SRAM_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) + 1) begin
`ifdef GF12
                    GF12_SRAM_SP_512x28 mixed_sram(
                        .CLK(clk),
                        .A0({{(`ASIC_SRAM_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_mixed),
                        .Q0(rd_data_mixed_tmp[i][j]),
                        .WE0(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .CE0(rd_en),
                        .WEM0(wr_mixed_mask));
`else
                    sram_behav #(.DATA_WIDTH(28), .NUM_WORDS(512)) mixed_sram(
                        .clk_i(clk),
                        .req_i(rd_en),
                        .we_i(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .addr_i({{(`ASIC_SRAM_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]}),
                        .wdata_i(wr_data_mixed),
                        .be_i(wr_mixed_mask),
                        .rdata_o(rd_data_mixed_tmp[i][j]));
`endif
                end else begin
`ifdef GF12
                    GF12_SRAM_SP_512x28 mixed_sram(
                        .CLK(clk),
                        .A0(set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_mixed),
                        .Q0(rd_data_mixed_tmp[i][j]),
                        .WE0(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .CE0(rd_en),
                        .WEM0(wr_mixed_mask));
`else
                    sram_behav #(.DATA_WIDTH(28), .NUM_WORDS(512)) mixed_sram(
                        .clk_i(clk),
                        .req_i(rd_en),
                        .we_i(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .addr_i(set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]),
                        .wdata_i(wr_data_mixed),
                        .be_i(wr_mixed_mask),
                        .rdata_o(rd_data_mixed_tmp[i][j]));
`endif
                end
                //sharers memory
                if (`ASIC_SRAM_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) + 1) begin
`ifdef GF12
                    GF12_SRAM_SP_512x16 sharers_sram(
                        .CLK(clk),
                        .A0({{(`ASIC_SRAM_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_sharers),
                        .Q0(rd_data_sharers_tmp[i][j]),
                        .WE0(wr_en_port[i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .WEM0({16{1'b1}}));
`else
                    sram_behav #(.DATA_WIDTH(16), .NUM_WORDS(512)) sharers_sram(
                        .clk_i(clk),
                        .req_i(rd_en),
                        .we_i(wr_en_port[i] & wr_en_sharers_bank[j]),
                        .addr_i({{(`ASIC_SRAM_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]}),
                        .wdata_i(wr_data_sharers),
                        .be_i({16{1'b1}}),
                        .rdata_o(rd_data_sharers_tmp[i][j]));
`endif
                end else begin
`ifdef GF12
                    GF12_SRAM_SP_512x16 sharers_sram(
                        .CLK(clk),
                        .A0(set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_sharers),
                        .Q0(rd_data_sharers_tmp[i][j]),
                        .WE0(wr_en_port[i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .WEM0({16{1'b1}}));
`else
                     sram_behav #(.DATA_WIDTH(16), .NUM_WORDS(512)) sharers_sram(
                        .clk_i(clk),
                        .req_i(rd_en),
                        .we_i(wr_en_port[i] & wr_en_sharers_bank[j]),
                        .addr_i(set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]),
                        .wdata_i(wr_data_sharers),
                        .be_i({16{1'b1}}),
                        .rdata_o(rd_data_sharers_tmp[i][j]));
`endif
                end


                //line memory
                //128 bits - using 512x64 SRAM, need 2 SRAMs per line
                for (k = 0; k < `LLC_ASIC_SRAMS_PER_LINE; k++) begin
                    if (`ASIC_SRAM_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) + 1) begin
`ifdef GF12
                        GF12_SRAM_SP_512x64 line_sram(
                            .CLK(clk),
                            .A0({{(`ASIC_SRAM_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                    set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(64*(k+1)-1):(64*k)]),
                            .Q0(rd_data_line_tmp[i][j][(64*(k+1)-1):(64*k)]),
                            .WE0(wr_en_port[i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .WEM0({64{1'b1}}));
`else
                        sram_behav #(.DATA_WIDTH(64), .NUM_WORDS(512)) line_sram(
                            .clk_i(clk),
                            .req_i(rd_en),
                            .we_i(wr_en_port[i] & wr_en_line_bank[j]),
                            .addr_i({{(`ASIC_SRAM_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                    set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]}),
                            .wdata_i(wr_data_line[(64*(k+1)-1):(64*k)]),
                            .be_i({64{1'b1}}),
                            .rdata_o(rd_data_line_tmp[i][j][(64*(k+1)-1):(64*k)]));
`endif
                    end else begin
`ifdef GF12
                        GF12_SRAM_SP_512x64 line_sram(
                            .CLK(clk),
                            .A0(set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]),
                            .D0(wr_data_line[(64*(k+1)-1):(64*k)]),
                            .Q0(rd_data_line_tmp[i][j][(64*(k+1)-1):(64*k)]),
                            .WE0(wr_en_port[i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .WEM0({64{1'b1}}));
`else
                        sram_behav #(.DATA_WIDTH(64), .NUM_WORDS(512)) line_sram(
                            .clk_i(clk),
                            .req_i(rd_en),
                            .we_i(wr_en_port[i] & wr_en_line_bank[j]),
                            .addr_i(set_in[(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS - 1):0]),
                            .wdata_i(wr_data_line[(64*(k+1)-1):(64*k)]),
                            .be_i({64{1'b1}}),
                            .rdata_o(rd_data_line_tmp[i][j][(64*(k+1)-1):(64*k)]));

`endif
                    end
                end
            end
        end
    endgenerate

    generate
        if (`LLC_ASIC_SRAMS_PER_WAY == 1) begin
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin
                    rd_data_hprot[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_HPROT_INDEX];
                    rd_data_dirty_bit[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_DIRTY_BIT_INDEX];
                    rd_data_state[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_STATE_INDEX_HI:`LLC_ASIC_MIXED_SRAM_STATE_INDEX_LO];
                    rd_data_owner[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_HI:`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_LO];
                    rd_data_tag[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_TAG_INDEX_HI:`LLC_ASIC_MIXED_SRAM_TAG_INDEX_LO];
                    rd_data_line[i] = rd_data_line_tmp[i][0];
                    rd_data_sharers[i] = rd_data_sharers_tmp[i][0];
                end
            end
        end else begin
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin
                    rd_data_hprot[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_HPROT_INDEX];
                    rd_data_dirty_bit[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_DIRTY_BIT_INDEX];
                    rd_data_state[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_STATE_INDEX_HI:`LLC_ASIC_MIXED_SRAM_STATE_INDEX_LO];
                    rd_data_owner[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_HI:`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_LO];
                    rd_data_tag[i] = rd_data_mixed_tmp[i][0][`LLC_ASIC_MIXED_SRAM_TAG_INDEX_HI:`LLC_ASIC_MIXED_SRAM_TAG_INDEX_LO];
                    rd_data_line[i] = rd_data_line_tmp[i][0];
                    rd_data_sharers[i] = rd_data_sharers_tmp[i][0];
                    for (int j = 1; j < `LLC_ASIC_SRAMS_PER_WAY; j++) begin
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_ASIC_SRAM_INDEX_BITS)]) begin
                            rd_data_hprot[i] = rd_data_mixed_tmp[i][j][`LLC_ASIC_MIXED_SRAM_HPROT_INDEX];
                            rd_data_dirty_bit[i] = rd_data_mixed_tmp[i][j][`LLC_ASIC_MIXED_SRAM_DIRTY_BIT_INDEX];
                            rd_data_state[i] = rd_data_mixed_tmp[i][j][`LLC_ASIC_MIXED_SRAM_STATE_INDEX_HI:`LLC_ASIC_MIXED_SRAM_STATE_INDEX_LO];
                            rd_data_owner[i] = rd_data_mixed_tmp[i][j][`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_HI:`LLC_ASIC_MIXED_SRAM_OWNER_INDEX_LO];
                            rd_data_tag[i] = rd_data_mixed_tmp[i][j][`LLC_ASIC_MIXED_SRAM_TAG_INDEX_HI:`LLC_ASIC_MIXED_SRAM_TAG_INDEX_LO];
                            rd_data_line[i] = rd_data_line_tmp[i][j];
                            rd_data_sharers[i] = rd_data_sharers_tmp[i][j];
                        end
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (int i = 0; i < `LLC_SETS; i++) begin
                evict_way_arr[i] <= {`LLC_WAY_BITS{1'b0}};
            end
        end else begin
            if (wr_en_evict_way) begin
                evict_way_arr[set_in] <= wr_data_evict_way;
            end
            rd_data_evict_way <= evict_way_arr[set_in];
        end
    end

endmodule
