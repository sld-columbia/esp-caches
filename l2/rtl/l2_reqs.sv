`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// l2_reqs.sv
// Author: Joseph Zuckerman
// request buffer for l2 

module l2_reqs(clk, rst, reqs, fill_reqs, cpu_msg_wr_data_req, addr_br, tag_estall_wr_data_req, way_hit, hsize_wr_data_req, state_wr_data_req, hprot_wr_data_req, word_wr_data_req, line_wr_data_req, invack_cnt_wr_data_req, reqs_i_wr, wr_req_state, wr_req_line, wr_req_invack_cnt, wr_req_tag, reqs_i, reqs_op_code, line_br, set, fwd_in_coh_msg, set_set_conflict, clr_set_conflict, reqs_hit, set_fwd_stall, clr_fwd_stall, fwd_stall_i_wr_data, set_fwd_stall_i, lookup_en);
    
    input clk, rst; 
    input logic fill_reqs; 
    input cpu_msg_t cpu_msg_wr_data_req;
    addr_breakdown_t.in addr_br;
    input l2_tag_t tag_estall_wr_data_req;
    input l2_way_t way_hit; 
    input hsize_t hsize_wr_data_req; 
    input unstable_state_t state_wr_data_req; 
    input hprot_t hprot_wr_data_req;
    input word_t word_wr_data_req; 
    input line_t line_wr_data_req;
    input invack_cnt_calc_t invack_cnt_wr_data_req; 
    input logic [2:0] reqs_op_code; 
    line_breakdown_l2_t.in line_br;
    input l2_set_t set; 
    input mix_msg_t fwd_in_coh_msg; 
    input logic lookup_en; 
    input logic wr_req_state, wr_req_line, wr_req_invack_cnt, wr_req_tag; 
    input [`REQS_BITS-1:0] reqs_i_wr; 

    logic [`REQS_BITS-1:0] reqs_i_next;
    logic reqs_hit_next; 

    output reqs_buf_t reqs[`N_REQS]; 
    output logic [`REQS_BITS-1:0] reqs_i, fwd_stall_i_wr_data; 
    output logic set_set_conflict, clr_set_conflict; 
    output logic reqs_hit; 
    output logic set_fwd_stall, clr_fwd_stall, set_fwd_stall_i; 

    always_ff @(posedge clk or negedge rst) begin 
        for (int i = 0; i < `N_REQS; i++) begin 
            if (!rst) begin 
                reqs[i].cpu_msg <= 0; 
                reqs[i].tag_estall <= 0;
                reqs[i].set <= 0; 
                reqs[i].way <= 0; 
                reqs[i].hsize <= 0; 
                reqs[i].w_off <= 0; 
                reqs[i].b_off <= 0; 
                reqs[i].hprot <= 0; 
                reqs[i].word <= 0; 
            end else if (fill_reqs) begin 
                if (reqs_i_wr == i) begin 
                    reqs[i].cpu_msg <= cpu_msg_wr_data_req; 
                    reqs[i].tag_estall <= tag_estall_wr_data_req;
                    reqs[i].set <= addr_br.set; 
                    reqs[i].way <= way_hit; 
                    reqs[i].hsize <= hsize_wr_data_req; 
                    reqs[i].w_off <= addr_br.w_off; 
                    reqs[i].b_off <= addr_br.b_off;
                    reqs[i].hprot <= hprot_wr_data_req; 
                    reqs[i].word <= word_wr_data_req; 
                end 
            end
            //state
            if (!rst) begin 
                reqs[i].state <= 0; 
            end else if (wr_req_state || fill_reqs) begin 
                if (reqs_i_wr == i) begin 
                    reqs[i].state <= state_wr_data_req;
                end
            end
            //line
            if (!rst) begin 
                reqs[i].line <= 0; 
            end else if (wr_req_line || fill_reqs) begin 
                if (reqs_i_wr == i) begin 
                    reqs[i].line <= line_wr_data_req;
                end
            end
            //invack_cnt
            if (!rst) begin 
                reqs[i].invack_cnt <= 0;
            end else if (fill_reqs) begin 
                if (reqs_i_wr == i) begin 
                    reqs[i].invack_cnt <= `MAX_N_L2;
                end
            end else if (wr_req_invack_cnt) begin 
                if (reqs_i_wr == i) begin 
                    reqs[i].invack_cnt <= invack_cnt_wr_data_req;
                end
            end
            //tag
            if (!rst) begin 
                reqs[i].tag <= 0; 
            end else if (wr_req_tag || fill_reqs) begin 
                if (reqs_i_wr == i) begin 
                    reqs[i].tag <= addr_br.tag;
                end
            end

        end 
    end

    always_comb begin 
        clr_set_conflict = 1'b0; 
        set_set_conflict = 1'b0; 
        clr_fwd_stall = 1'b0; 
        set_fwd_stall = 1'b0; 
        reqs_i_next = 0;
        reqs_hit_next = 1'b0; 
        fwd_stall_i_wr_data = 0; 
        set_fwd_stall_i = 1'b0; 
        case(reqs_op_code) 
            `L2_REQS_LOOKUP : begin 
                for (int i = 0; i < `N_REQS; i++) begin 
                    if (reqs[i].tag == line_br.tag && reqs[i].set == set && reqs[i].state != `INVALID) begin 
                        reqs_i_next = i; 
                    end
                end     
            end
            `L2_REQS_PEEK_REQ : begin 
                clr_set_conflict = 1'b1; 
                for (int i = 0; i < `N_REQS; i++) begin 
                    if (reqs[i].state == `INVALID) begin 
                        reqs_i_next = i; 
                    end

                    if (reqs[i].set == set && reqs[i].state != `INVALID) begin
                        set_set_conflict = 1'b1;
                        clr_set_conflict = 1'b0; 
                    end
                end
            end
            `L2_REQS_PEEK_FLUSH : begin 
                for (int i = 0; i <`N_REQS; i++) begin 
                    if (reqs[i].state == `INVALID) begin 
                        reqs_i_next = i; 
                    end
                end
            end
            `L2_REQS_PEEK_FWD : begin 
                for (int i = 0; i < `N_REQS; i++) begin 
                    if (reqs[i].state != `INVALID && reqs[i].tag == line_br.tag && reqs[i].set == line_br.set) begin 
                        reqs_hit_next = 1'b1; 
                        reqs_i_next = i; 
                        
                        set_fwd_stall = 1'b1; 
                        if (fwd_in_coh_msg == `FWD_PUTACK) begin 
                            set_fwd_stall = 1'b0; 
                            clr_fwd_stall = 1'b1; 
                        end else if (fwd_in_coh_msg == `FWD_INV || fwd_in_coh_msg == `FWD_INV_LLC) begin 
                            if (reqs[i].state != `ISD) begin 
                                set_fwd_stall = 1'b0; 
                                clr_fwd_stall = 1'b1; 
                            end 
                        end else begin 
                            if (reqs[i].state == `MIA) begin 
                                set_fwd_stall = 1'b0; 
                                clr_fwd_stall = 1'b1; 
                            end
                        end 
                    end
                end 
                set_fwd_stall_i = 1'b1; 
                fwd_stall_i_wr_data = reqs_i_next; 
            end
            default : begin 
                reqs_hit_next = 1'b0; 
            end 
        endcase
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            reqs_i <= 0; 
            reqs_hit <= 1'b0; 
        end else if (lookup_en) begin 
            reqs_i <= reqs_i_next; 
            reqs_hit <= reqs_hit_next;
        end
    end

endmodule
