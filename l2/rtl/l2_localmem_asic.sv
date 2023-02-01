// Copyright (c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// l2_localmem_asic.sv
// l2 memory for asic processes
// author: Joseph Zuckerman

module l2_localmem_asic (
    input logic clk,
    input logic rst,
    input logic rd_en,
    input logic wr_en_line,
    input logic wr_en_state,
    input logic wr_en_evict_way,
    input logic wr_rst,
    input logic wr_en_put_reqs,
    input l2_set_t set_in,
    input l2_way_t way,
    input line_t wr_data_line,
    input l2_tag_t wr_data_tag,
    input hprot_t wr_data_hprot,
    input l2_way_t wr_data_evict_way,
    input state_t wr_data_state,

    output line_t rd_data_line[`L2_NUM_PORTS],
    output l2_tag_t rd_data_tag[`L2_NUM_PORTS],
    output hprot_t rd_data_hprot[`L2_NUM_PORTS],
    output l2_way_t rd_data_evict_way,
    output state_t rd_data_state[`L2_NUM_PORTS]
    );

    logic [23:0] rd_data_mixed_tmp[`L2_NUM_PORTS][`L2_ASIC_SRAMS_PER_WAY];
    line_t rd_data_line_tmp[`L2_NUM_PORTS][`L2_ASIC_SRAMS_PER_WAY];

    //write enable decoder for ways
    logic wr_en_port[0:(`L2_NUM_PORTS-1)];
    always_comb begin
        for (int i = 0; i < `L2_NUM_PORTS; i++) begin
            wr_en_port[i] = 1'b0;
            if (wr_rst) begin
                wr_en_port[i] = 1'b1;
            end else if (way == i) begin
                wr_en_port[i] = 1'b1;
            end
        end
    end

    logic wr_en_mixed_bank[`L2_ASIC_SRAMS_PER_WAY];
    logic wr_en_line_bank[`L2_ASIC_SRAMS_PER_WAY];

    logic [23:0] wr_data_mixed, wr_mixed_mask;
    assign wr_data_mixed = {wr_data_hprot, wr_data_state, {(24 - 1 - `STABLE_STATE_BITS - `L2_TAG_BITS){1'b0}}, wr_data_tag};

    l2_way_t evict_way_arr [`L2_SETS];

    //determine mask for writing to shared SRAM
    always_comb begin
        wr_mixed_mask = 24'b0;

        if (wr_en_put_reqs) begin
            wr_mixed_mask[`L2_ASIC_MIXED_SRAM_HPROT_INDEX] = 1'b1;
            wr_mixed_mask[`L2_ASIC_MIXED_SRAM_TAG_INDEX_HI:`L2_ASIC_MIXED_SRAM_TAG_INDEX_LO] = {`L2_TAG_BITS{1'b1}};
        end

        if (wr_en_put_reqs | wr_en_state | wr_rst) begin
            wr_mixed_mask[`L2_ASIC_MIXED_SRAM_STATE_INDEX_HI:`L2_ASIC_MIXED_SRAM_STATE_INDEX_LO] = {`STABLE_STATE_BITS{1'b1}};
        end

    end

    generate
        if (`L2_ASIC_SRAMS_PER_WAY == 1) begin
            always_comb begin
                wr_en_mixed_bank[0] = wr_en_put_reqs | wr_rst | wr_en_state;
            end
        end else begin
            always_comb begin
                for (int j = 0; j < `L2_ASIC_SRAMS_PER_WAY; j++) begin
                    wr_en_mixed_bank[j] = 1'b0;
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS)]) begin
                        wr_en_mixed_bank[j] = wr_en_put_reqs | wr_rst | wr_en_state;
                    end
                end
            end
        end

        if (`L2_ASIC_SRAMS_PER_WAY == 1) begin
            always_comb begin
                wr_en_line_bank[0] = wr_en_line | wr_en_put_reqs;
            end
        end else begin
            always_comb begin
                for (int j = 0; j < `L2_ASIC_SRAMS_PER_WAY; j++) begin
                    wr_en_line_bank[j] = 1'b0;
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS)]) begin
                        wr_en_line_bank[j] = wr_en_line | wr_en_put_reqs;
                    end
                end
            end
        end
    endgenerate

    genvar i, j, k;
    generate
        for (i = 0; i < `L2_NUM_PORTS; i++) begin
            //shared memory for tag, state, hprot
            for (j = 0; j < `L2_ASIC_SRAMS_PER_WAY; j++) begin
                if (`ASIC_SRAM_ADDR_WIDTH > (`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS) + 1) begin
`ifdef GF12
                    GF12_SRAM_SP_512x24 mixed_sram(
                        .CLK(clk),
                        .A0({{(`ASIC_SRAM_ADDR_WIDTH - (`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_mixed),
                        .Q0(rd_data_mixed_tmp[i][j]),
                        .WE0(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .CE0(rd_en),
                        .WEM0(wr_mixed_mask));
`else
                    sram_behav #(.DATA_WIDTH(24), .NUM_WORDS(512)) mixed_sram(
                        .clk_i(clk),
                        .req_i(rd_en),
                        .we_i(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .addr_i({{(`ASIC_SRAM_ADDR_WIDTH - (`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]}),
                        .wdata_i(wr_data_mixed),
                        .be_i(wr_mixed_mask),
                        .rdata_o(rd_data_mixed_tmp[i][j]));
`endif
                end else begin
`ifdef GF12
                    GF12_SRAM_SP_512x24 mixed_sram(
                        .CLK(clk),
                        .A0(set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]),
                        .D0(wr_data_mixed),
                        .Q0(rd_data_mixed_tmp[i][j]),
                        .WE0(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .CE0(rd_en),
                        .WEM0(wr_mixed_mask));
`else
                    sram_behav #(.DATA_WIDTH(24), .NUM_WORDS(512)) mixed_sram(
                        .clk_i(clk),
                        .req_i(rd_en),
                        .we_i(wr_en_port[i] & wr_en_mixed_bank[j]),
                        .addr_i(set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]),
                        .wdata_i(wr_data_mixed),
                        .be_i(wr_mixed_mask),
                        .rdata_o(rd_data_mixed_tmp[i][j]));
`endif
                end

                //line memory
                //128 bits - using 512x64 SRAM, need 2 SRAMs per line
                for (k = 0; k < `L2_ASIC_SRAMS_PER_LINE; k++) begin
                    if (`ASIC_SRAM_ADDR_WIDTH > (`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS) + 1) begin
`ifdef GF12
                        GF12_SRAM_SP_512x64 line_sram(
                            .CLK(clk),
                            .A0({{(`ASIC_SRAM_ADDR_WIDTH - (`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                    set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]}),
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
                            .addr_i({{(`ASIC_SRAM_ADDR_WIDTH - (`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS) - 1){1'b0}},
                                    set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]}),
                            .wdata_i(wr_data_line[(64*(k+1)-1):(64*k)]),
                            .be_i({64{1'b1}}),
                            .rdata_o(rd_data_line_tmp[i][j][(64*(k+1)-1):(64*k)]));
`endif
                    end else begin
`ifdef GF12
                        GF12_SRAM_SP_512x64 line_sram(
                            .CLK(clk),
                            .A0(set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]),
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
                            .addr_i(set_in[(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS - 1):0]),
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
        if (`L2_ASIC_SRAMS_PER_WAY == 1) begin
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin
                    rd_data_hprot[i] = rd_data_mixed_tmp[i][0][`L2_ASIC_MIXED_SRAM_HPROT_INDEX];
                    rd_data_state[i] = rd_data_mixed_tmp[i][0][`L2_ASIC_MIXED_SRAM_STATE_INDEX_HI:`L2_ASIC_MIXED_SRAM_STATE_INDEX_LO];
                    rd_data_tag[i] = rd_data_mixed_tmp[i][0][`L2_ASIC_MIXED_SRAM_TAG_INDEX_HI:`L2_ASIC_MIXED_SRAM_TAG_INDEX_LO];
                    rd_data_line[i] = rd_data_line_tmp[i][0];
                end
            end
        end else begin
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin
                    rd_data_hprot[i] = rd_data_mixed_tmp[i][0][`L2_ASIC_MIXED_SRAM_HPROT_INDEX];
                    rd_data_state[i] = rd_data_mixed_tmp[i][0][`L2_ASIC_MIXED_SRAM_STATE_INDEX_HI:`L2_ASIC_MIXED_SRAM_STATE_INDEX_LO];
                    rd_data_tag[i] = rd_data_mixed_tmp[i][0][`L2_ASIC_MIXED_SRAM_TAG_INDEX_HI:`L2_ASIC_MIXED_SRAM_TAG_INDEX_LO];
                    rd_data_line[i] = rd_data_line_tmp[i][0];
                    for (int j = 1; j < `L2_ASIC_SRAMS_PER_WAY; j++) begin
                        if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_ASIC_SRAM_INDEX_BITS)]) begin
                            rd_data_hprot[i] = rd_data_mixed_tmp[i][j][`L2_ASIC_MIXED_SRAM_HPROT_INDEX];
                            rd_data_state[i] = rd_data_mixed_tmp[i][j][`L2_ASIC_MIXED_SRAM_STATE_INDEX_HI:`L2_ASIC_MIXED_SRAM_STATE_INDEX_LO];
                            rd_data_tag[i] = rd_data_mixed_tmp[i][j][`L2_ASIC_MIXED_SRAM_TAG_INDEX_HI:`L2_ASIC_MIXED_SRAM_TAG_INDEX_LO];
                            rd_data_line[i] = rd_data_line_tmp[i][j];
                        end
                    end
                end
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            for (int i = 0; i < `L2_SETS; i++) begin
                evict_way_arr[i] <= {`L2_WAY_BITS{1'b0}};
            end
        end else begin
            if (wr_en_evict_way) begin
                evict_way_arr[set_in] <= wr_data_evict_way;
            end
            rd_data_evict_way <= evict_way_arr[set_in];
        end
    end

endmodule
