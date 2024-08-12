// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

`timescale 1ps / 1ps
`include "cache_types.svh"
`include "cache_consts.svh"

module interface_controller(

    input logic clk,
    input logic rst,
    input logic ready_in,
    input logic valid_in,
    output logic ready_out,
    output logic valid_out,
    output logic valid_tmp
    );

    localparam EMPTY = 1'b0;
    localparam FULL = 1'b1;

    logic state, state_next;
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= EMPTY;
        end else begin
            state <= state_next;
        end
    end

    always_comb begin
        state_next = state;
        case (state)
            EMPTY : begin
                ready_out = 1'b1;
                valid_tmp = 1'b0;
                if (valid_in && !ready_in) begin
                    state_next = FULL;
                end
            end
            FULL : begin
                ready_out = 1'b0;
                valid_tmp = 1'b1;
                if (ready_in) begin
                    state_next = EMPTY;
                end
            end
        endcase
    end

    assign valid_out = valid_in | valid_tmp;

endmodule
