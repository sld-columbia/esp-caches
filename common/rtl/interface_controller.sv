// Copyright (c) 2011-2023 Columbia University, System Level Design Group
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

    localparam NOT_READY = 1'b0; 
    localparam READY = 1'b1; 

    logic ready_next; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin
            ready_out <= READY;
        end else begin 
            ready_out <= ready_next; 
        end
    end

    always_comb begin 
        ready_next = ready_out;
        case (ready_out)
            NOT_READY : begin 
                if (ready_in) begin 
                    ready_next = READY; 
                end
            end
            READY : begin 
                if (valid_in && !ready_in) begin 
                    ready_next = NOT_READY;
                end
            end
        endcase
    end

    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            valid_tmp <= NOT_READY;
        end else if (ready_out && !ready_in) begin 
            valid_tmp <= valid_in; 
        end else if (valid_tmp && ready_in) begin 
            valid_tmp <= valid_in; 
        end
    end
    
    assign valid_out = valid_in | valid_tmp; 

endmodule
