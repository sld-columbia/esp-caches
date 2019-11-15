`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_fsm(clk, rst, do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next, reqs, reqs_i, line_br, addr_br, l2_rd_rsp_ready_int, l2_rsp_in, l2_fwd_in, l2_cpu_req, decode_en, lookup_en, wr_rst, wr_data_state, state_wr_data_req, wr_data_line, wr_data_hprot, wr_data_tag, wr_req_state, wr_en_put_reqs, reqs_i_wr, reqs_op_code, l2_rd_rsp_valid_int, set_in, way, l2_rd_rsp_o, l2_rsp_out_o, l2_req_out_o, incr_reqs_cnt, set_ongoing_atomic, line_wr_data_req, invack_cnt_wr_data_req, wr_req_invack_cnt, wr_req_line, line_br_next, addr_br_next, flush_set, flush_way, rd_data_state, rd_data_hprot, is_flush_all, incr_flush_way, l2_req_out_ready_int, l2_req_out_valid_int, states_buf, tags_buf, lines_buf, hprot_wr_data_req, tag_estall_wr_data_req, way_hit, rd_mem_en, wr_en_state, fill_reqs, cpu_msg_wr_data_req, hsize_wr_data_req, word_wr_data_req); 
   
    input logic clk, rst;
    input logic do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next, is_flush_all;
    input reqs_buf_t reqs[`N_REQS];
    input logic [`REQS_BITS-1:0] reqs_i; 
    input l2_set_t flush_set;
    input l2_way_t flush_way; 
    line_breakdown_l2_t.in line_br, line_br_next; 
    addr_breakdown_t.in addr_br, addr_br_next;
    input logic l2_rd_rsp_ready_int;
    input logic l2_req_out_ready_int;
    l2_rsp_in_t.in l2_rsp_in;
    l2_fwd_in_t.in l2_fwd_in; 
    l2_cpu_req_t.in l2_cpu_req; 
    input state_t states_buf[`L2_WAYS], rd_data_state[`L2_NUM_PORTS];
    input hprot_t rd_data_hprot[`L2_NUM_PORTS];
    input line_t lines_buf[`L2_WAYS];
    input l2_tag_t tags_buf[`L2_WAYS];

    output logic decode_en, lookup_en, rd_mem_en; 
    output logic wr_rst, wr_en_state, fill_reqs; 
    output state_t wr_data_state;
    output unstable_state_t state_wr_data_req;
    output line_t wr_data_line, line_wr_data_req;
    output hprot_t wr_data_hprot, hprot_wr_data_req; 
    output l2_tag_t wr_data_tag, tag_estall_wr_data_req;
    output invack_cnt_calc_t invack_cnt_wr_data_req;
    output hsize_t hsize_wr_data_req;
    output word_t word_wr_data_req;
    output cpu_msg_t cpu_msg_wr_data_req; 
    output logic wr_req_state, wr_req_invack_cnt, wr_req_line, wr_en_put_reqs;
    output logic [`REQS_BITS-1:0] reqs_i_wr;
    output logic [2:0] reqs_op_code;
    output logic l2_rd_rsp_valid_int, l2_req_out_valid_int; 
    output l2_set_t set_in;
    output l2_way_t way, way_hit;
    output logic incr_reqs_cnt, set_ongoing_atomic, incr_flush_way; 
    l2_rd_rsp_t.out l2_rd_rsp_o; 
    l2_rsp_out_t.out l2_rsp_out_o; 
    l2_req_out_t.out l2_req_out_o; 

    localparam RESET = 5'b00000; 
    localparam DECODE = 5'b00001; 
    localparam RSP_LOOKUP = 5'b00010;
    localparam RSP_E_DATA_ISD = 5'b00011;
    localparam RSP_DATA_XMAD = 5'b00100;
    localparam RSP_DATA_XMADW = 5'b00101;
    localparam RSP_INVACK = 5'b00110; 
    localparam FWD = 5'b00100; 
    localparam ONGOING_FLUSH_RD_MEM = 5'b01000; 
    localparam ONGOING_FLUSH_LOOKUP = 5'b01001; 
    localparam ONGOING_FLUSH_PROCESS = 5'b01010;
    localparam CPU_REQ = 5'b11000;

    logic [4:0] state, next_state;
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
                    next_state = ONGOING_FLUSH_RD_MEM;
                end else if (do_cpu_req_next) begin 
                    next_state = CPU_REQ; 
                end
            end
            RSP_LOOKUP : begin 
                case(l2_rsp_in.coh_msg) 
                    `RSP_EDATA : begin 
                        next_state = RSP_E_DATA_ISD; 
                    end
                    `RSP_DATA : begin 
                        case(reqs[reqs_i].state) 
                            `ISD : begin
                                next_state = RSP_E_DATA_ISD; 
                            end
                            `IMAD : begin 
                                next_state = RSP_DATA_XMAD;
                            end
                            `SMAD : begin 
                                next_state = RSP_DATA_XMAD;
                            end
                            `IMADW : begin 
                                next_state = RSP_DATA_XMADW;
                            end
                            `SMADW : begin 
                                next_state = RSP_DATA_XMADW;
                            end
                            default : begin 
                                next_state = DECODE;
                            end
                        endcase
                    end
                    `RSP_INVACK : begin 
                        next_state = RSP_INVACK; 
                    end
                    default : begin 
                        next_state = DECODE;
                    end
                endcase    
            end
            RSP_E_DATA_ISD : begin 
                if (l2_rd_rsp_ready_int) begin 
                    next_state = DECODE;
                end
            end
            RSP_DATA_XMADW : begin 
                if (l2_rd_rsp_ready_int) begin 
                    next_state = DECODE;
                end
            end
            RSP_INVACK : begin 
                next_state = DECODE;
            end
            ONGOING_FLUSH_RD_MEM : begin 
                if ((rd_data_state[flush_way] != `INVALID) && (is_flush_all || rd_data_hprot[flush_way])) begin 
                    next_state = ONGOING_FLUSH_LOOKUP;
                end else begin 
                    next_state = DECODE; 
                end
            end
            ONGOING_FLUSH_LOOKUP : begin 
                next_state = ONGOING_FLUSH_PROCESS;
            end
            ONGOING_FLUSH_PROCESS : begin 
                if (l2_req_out_ready_int) begin
                    next_state = DECODE;
                end
            end
             
        endcase
    end

    addr_breakdown_t addr_br_reqs();
    addr_t addr_tmp;
    line_addr_t line_addr_tmp;
    unstable_state_t state_tmp;
    coh_msg_t coh_msg_tmp;

    word_t word_in; 
    word_offset_t w_off_in;
    byte_offset_t b_off_in;
    hsize_t hsize_in;
    line_t line_in, line_out; 

    always_comb begin 
        wr_rst = 1'b0; 
        wr_data_state = 0; 
        reqs_op_code = `L2_REQS_IDLE; 
        lookup_en = 1'b0;
        reqs_i_wr = 0; 
        wr_req_state = 1'b0;
        state_wr_data_req = 0; 
        wr_req_line = 1'b0;
        line_wr_data_req = 0; 
        wr_req_invack_cnt = 0;
        wr_en_put_reqs = 1'b0;
        wr_en_state = 1'b0; 
        set_in = 0; 
        way = 0; 
        way_hit = 0;
        wr_data_tag = 0;
        wr_data_hprot = 0; 
        wr_data_line = 0; 
        wr_data_state = 0; 
        incr_reqs_cnt = 1'b0;
        set_ongoing_atomic = 1'b0; 
        rd_mem_en = 1'b0; 
        incr_flush_way = 1'b0;
        addr_tmp = 0; 
        line_addr_tmp = 0; 
        state_tmp = 0; 
        coh_msg_tmp = 0; 
        fill_reqs = 1'b0;

        l2_rd_rsp_o.line = 0; 
        l2_rd_rsp_valid_int = 1'b0; 

        addr_br_reqs.line = 0;
        addr_br_reqs.line_addr = 0;
        addr_br_reqs.word = 0;
        addr_br_reqs.tag = 0;
        addr_br_reqs.set = 0;
        addr_br_reqs.w_off = 0;
        addr_br_reqs.b_off = 0; 
        
        cpu_msg_wr_data_req = 0;
        tag_estall_wr_data_req = 0;
        invack_cnt_wr_data_req = 0; 
        hsize_wr_data_req = 0;
        state_wr_data_req = 0;
        hprot_wr_data_req = 0; 
        word_wr_data_req = 0;
        line_wr_data_req = 0;

        l2_req_out_valid_int = 1'b1;
        l2_req_out_o.coh_msg = coh_msg_tmp;
        l2_req_out_o.hprot = 0;
        l2_req_out_o.addr = line_addr_tmp; 
        l2_req_out_o.line = lines_buf[flush_way];
        
        case (state)
            RESET : begin 
                wr_rst = 1'b1;
                wr_data_state = `INVALID;
            end
            DECODE : begin 
                if (do_ongoing_flush_next) begin 
                    set_in = flush_set;
                end
            end
            RSP_LOOKUP : begin 
                reqs_op_code = `L2_REQS_LOOKUP;
                lookup_en = 1'b1;
            end
            RSP_E_DATA_ISD : begin 
                l2_rd_rsp_valid_int = 1'b1;
                l2_rd_rsp_o.line = l2_rsp_in.line;
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
                //only increment once if not ready
                if (l2_rd_rsp_ready_int) begin 
                    incr_reqs_cnt = 1'b1;
                end
            end
            RSP_DATA_XMAD : begin 
                line_in = l2_rsp_in.line;
                word_in = reqs[reqs_i].word; 
                w_off_in = reqs[reqs_i].w_off; 
                b_off_in = reqs[reqs_i].b_off; 
                hsize_in = reqs[reqs_i].hsize;

                invack_cnt_wr_data_req = reqs[reqs_i].invack_cnt + l2_rsp_in.invack_cnt; 
                wr_req_invack_cnt = 1'b1; 
                if (reqs[reqs_i].invack_cnt == `MAX_N_L2) begin 
                    wr_en_put_reqs = 1'b1;
                    set_in = line_br.set; 
                    way = reqs[reqs_i].way; 
                    wr_data_tag = line_br.tag;
                    wr_data_line = line_out;
                    wr_data_hprot = reqs[reqs_i].hprot;
                    wr_data_state = `MODIFIED; 
                    wr_req_state = 1'b1;
                    incr_reqs_cnt = 1'b1; 
                end else begin 
                    wr_req_state = 1'b1;
                    state_wr_data_req = reqs[reqs_i].state + 2;
                    wr_req_line = 1'b1;
                    line_wr_data_req = line_out;
                end
            end
            RSP_DATA_XMADW : begin 
                l2_rd_rsp_valid_int = 1'b1;
                l2_rd_rsp_o.line = l2_rsp_in.line;
                reqs_i_wr = reqs_i;
                wr_req_line = 1'b1;
                line_wr_data_req = l2_rsp_in.line;
                wr_req_invack_cnt = 1'b1;
                invack_cnt_wr_data_req = reqs[reqs_i].invack_cnt + l2_rsp_in.invack_cnt; 
                if (invack_cnt_wr_data_req == `MAX_N_L2) begin 
                    set_ongoing_atomic = 1'b1; 
                    state_wr_data_req = `XMW;
                end else begin 
                    state_wr_data_req = reqs[reqs_i].state + 2;
                end
                wr_req_state = 1'b1;
            end
            RSP_INVACK : begin 
                invack_cnt_wr_data_req = reqs[reqs_i].invack_cnt - 1; 
                wr_req_invack_cnt = 1'b1;
                reqs_i_wr = reqs_i;
                if (invack_cnt_wr_data_req == `MAX_N_L2) begin 
                    if (reqs[reqs_i].state == `IMA || reqs[reqs_i].state == `SMA) begin 
                       wr_en_put_reqs = 1'b1;
                       set_in = line_br.set;
                       way = reqs[reqs_i].way;
                       wr_data_tag = line_br.tag;
                       wr_data_line = reqs[reqs_i].line;
                       wr_data_hprot = reqs[reqs_i].hprot;
                       wr_data_state = `MODIFIED;
                       wr_req_state = 1'b1;
                       state_wr_data_req = `INVALID;
                       incr_reqs_cnt = 1'b1;
                    end else if (reqs[reqs_i].state == `IMAW || reqs[reqs_i].state == `SMAW) begin 
                        set_ongoing_atomic = 1'b1;
                        wr_req_state = 1'b1;
                        state_wr_data_req = `XMW;
                    end
                end
            end
            ONGOING_FLUSH_RD_MEM : begin 
                rd_mem_en = 1'b1;
                if ((rd_data_state[flush_way] == `INVALID) || (~is_flush_all && ~rd_data_hprot[flush_way])) begin 
                    incr_flush_way = 1'b1;
                end
            end 
            ONGOING_FLUSH_LOOKUP : begin 
                reqs_op_code = `L2_REQS_PEEK_FLUSH;
                lookup_en = 1'b1;
            end
            ONGOING_FLUSH_PROCESS : begin 
                addr_tmp = (tags_buf[flush_way] << `L2_TAG_RANGE_LO) | (flush_set << `SET_RANGE_LO);
                addr_br_reqs.line = addr_tmp;
                addr_br_reqs.line_addr = addr_tmp[`TAG_RANGE_HI:`SET_RANGE_LO];
                addr_br_reqs.word = addr_tmp;
                addr_br_reqs.tag = addr_tmp[`TAG_RANGE_HI:`L2_TAG_RANGE_LO];
                addr_br_reqs.set = addr_tmp[`L2_SET_RANGE_HI:`SET_RANGE_LO];
                addr_br_reqs.w_off = addr_tmp[`W_OFF_RANGE_HI:`W_OFF_RANGE_LO];
                addr_br_reqs.b_off = addr_tmp[`B_OFF_RANGE_HI:`B_OFF_RANGE_LO];
                addr_br_reqs.line[`OFF_RANGE_HI:`OFF_RANGE_LO] = 0;
                addr_br_reqs.word[`B_OFF_RANGE_HI:`B_OFF_RANGE_LO] = 0; 

                line_addr_tmp = (tags_buf[flush_way] << `L2_SET_BITS) | (flush_set);
                set_in = flush_set; 
                way = flush_way;
                wr_data_state = `INVALID;
                wr_en_state = 1'b1;
                case (states_buf[flush_way])
                    `SHARED : begin 
                        coh_msg_tmp = `REQ_PUTS;
                        state_tmp = `SIA;
                    end
                    `EXCLUSIVE : begin 
                        coh_msg_tmp = `REQ_PUTS;
                        state_tmp = `MIA;
                    end
                    `MODIFIED : begin 
                        coh_msg_tmp = `REQ_PUTM;
                        state_tmp = `MIA;
                    end
                    default : begin 
                        state_tmp = 0;
                    end 
                endcase
                fill_reqs = 1'b1;
                cpu_msg_wr_data_req = 0;
                tag_estall_wr_data_req = 0;
                way_hit = flush_way;
                hsize_wr_data_req = 0;
                state_wr_data_req = state_tmp;
                hprot_wr_data_req = 0; 
                word_wr_data_req = 0;
                line_wr_data_req = lines_buf[flush_way];
                reqs_i_wr = reqs_i;

                l2_req_out_valid_int = 1'b1;
                l2_req_out_o.coh_msg = coh_msg_tmp;
                l2_req_out_o.hprot = 0;
                l2_req_out_o.addr = line_addr_tmp; 
                l2_req_out_o.line = lines_buf[flush_way];

                if (l2_req_out_ready_int) begin 
                    incr_flush_way = 1'b1;
                end
            end
            default : begin 
                reqs_op_code = `L2_REQS_IDLE;
            end
        endcase
    end 

    l2_write_word write_word_u(.*);

endmodule
