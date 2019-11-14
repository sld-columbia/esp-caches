`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_fsm(clk, rst, do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next, reqs, reqs_i, line_br, addr_br, l2_rd_rsp_ready_int, l2_rsp_in, l2_fwd_in, l2_cpu_req, decode_en, lookup_en, wr_rst, wr_data_state, state_wr_data_req, wr_data_line, wr_data_hprot, wr_data_tag, wr_req_state, wr_en_put_reqs, reqs_i_wr, reqs_op_code, l2_rd_rsp_valid_int, set_in, way, l2_rd_rsp_o, l2_rsp_out_o, l2_req_out_o, incr_reqs_cnt); 
   
    input logic clk, rst;
    input logic do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next;
    input reqs_buf_t reqs[`N_REQS];
    input logic [`REQS_BITS-1:0] reqs_i; 
    line_breakdown_l2_t.in line_br; 
    addr_breakdown_t.in addr_br;
    input logic l2_rd_rsp_ready_int; 
    l2_rsp_in_t.in l2_rsp_in;
    l2_fwd_in_t.in l2_fwd_in; 
    l2_cpu_req_t.in l2_cpu_req; 

    output logic decode_en, lookup_en; 
    output logic wr_rst; 
    output state_t wr_data_state;
    output unstable_state_t state_wr_data_req;
    output line_t wr_data_line;
    output hprot_t wr_data_hprot; 
    output l2_tag_t wr_data_tag;
    output logic wr_req_state, wr_en_put_reqs;
    output logic [`REQS_BITS-1:0] reqs_i_wr;
    output logic [2:0] reqs_op_code;
    output logic l2_rd_rsp_valid_int; 
    output l2_set_t set_in;
    output l2_way_t way;
    output logic incr_reqs_cnt; 
    l2_rd_rsp_t.out l2_rd_rsp_o; 
    l2_rsp_out_t.out l2_rsp_out_o; 
    l2_req_out_t.out l2_req_out_o; 

    localparam RESET = 4'b0000; 
    localparam DECODE = 4'b0001; 
    localparam RSP_LOOKUP = 4'b0010;
    localparam RSP_SEND_RD_RSP = 4'b0011;
    localparam FWD = 4'b0100; 
    localparam FLUSH = 4'b0101; 
    localparam CPU_REQ = 4'b1000;

    logic [3:0] state, next_state;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= RESET; 
        end else begin 
            state <= next_state; 
        end 
    end

    logic rst_en;
    assign rst_en = (state == RESET); 
    assign decode_en = (state == DECODE); 

    l2_set_t rst_set; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            rst_set <= 0; 
        end else if (rst_en) begin 
            rst_set <= rst_set + 1; 
        end
    end 

    always_comb begin 
        next_state = state; 
        case (state)
            RESET : begin  
                if (rst_set == `L2_SETS - 1) begin 
                    next_state = DECODE;
                end
            end
            DECODE : begin 
                if (do_flush_next) begin 
                    next_state = DECODE;
                end else if (do_rsp_next) begin 
                    next_state = RSP_LOOKUP; 
                end else if (do_fwd_next) begin 
                    next_state = FWD;
                end else if (do_ongoing_flush_next) begin 
                    next_state = FLUSH;
                end else if (do_cpu_req_next) begin 
                    next_state = CPU_REQ; 
                end
            end
            RSP_LOOKUP : begin 
                case(l2_rsp_in.coh_msg) 
                    `RSP_EDATA : begin 
                        next_state = RSP_SEND_RD_RSP; 
                    end
                    `RSP_DATA : begin 
                        case(reqs[reqs_i].state) 
                            `ISD : begin
                                next_state = RSP_SEND_RD_RSP; 
                            end
                        endcase
                    end

                endcase    
            end
            RSP_SEND_RD_RSP : begin 
                if (l2_rd_rsp_ready_int) begin 
                    next_state = DECODE;
                end
            end
                
             
        endcase
    end

    always_comb begin 
        wr_rst = 1'b0; 
        wr_data_state = 0; 
        reqs_op_code = `L2_REQS_IDLE; 
        lookup_en = 1'b0;
        l2_rd_rsp_o.line = 0; 
        l2_rd_rsp_valid_int = 1'b0; 
        reqs_i_wr = 0; 
        wr_req_state = 1'b0;
        state_wr_data_req = 0; 
        wr_en_put_reqs = 1'b0;
        set_in = 0; 
        way = 0; 
        wr_data_tag = 0;
        wr_data_hprot = 0; 
        wr_data_line = 0; 
        wr_data_state = 0; 
        incr_reqs_cnt = 1'b0;
        case (state)
            RESET : begin 
                wr_rst = 1'b1;
                wr_data_state = `INVALID;
            end
            RSP_LOOKUP : begin 
                reqs_op_code = `L2_REQS_LOOKUP;
                lookup_en = 1'b1;
            end
            RSP_SEND_RD_RSP : begin 
                l2_rd_rsp_valid_int = 1'b1;
                l2_rd_rsp_o.line = l2_rsp_in.line;
                //only increment once if not ready
                if (l2_rd_rsp_ready_int) begin 
                    incr_reqs_cnt = 1'b1;
                end
                reqs_i_wr = reqs_i;
                wr_req_state = 1'b1; 
                state_wr_data_req = `INVALID;
                wr_en_put_reqs = 1'b1;
                set_in = line_br.set;
                way = reqs[reqs_i].way;
                wr_data_tag = line_br.tag;
                wr_data_line = l2_rsp_in.line;
                wr_data_hprot = reqs[reqs_i].hprot;
                wr_data_state = (l2_rsp_in.coh_msg == `RSP_EDATA) ? `EXCLUSIVE : `SHARED;

            end
            default : begin 
                reqs_op_code = `L2_REQS_IDLE;
            end
        endcase

    end 

endmodule 
