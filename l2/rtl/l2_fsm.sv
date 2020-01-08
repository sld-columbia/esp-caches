`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

module l2_fsm(clk, rst, do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next, reqs, reqs_i, reqs_i_next, line_br, addr_br, l2_rd_rsp_ready_int, l2_rsp_in, l2_fwd_in, l2_cpu_req, decode_en, lookup_en, wr_rst, wr_data_state, state_wr_data_req, wr_data_line, wr_data_hprot, wr_data_tag, wr_req_state, wr_req_state_atomic, wr_en_put_reqs, reqs_op_code, l2_rd_rsp_valid_int, set_in, way, l2_rd_rsp_o, l2_rsp_out_o, l2_req_out_o, incr_reqs_cnt, set_ongoing_atomic, line_wr_data_req, invack_cnt_wr_data_req, wr_req_invack_cnt, wr_req_line, line_br_next, addr_br_next, addr_br_reqs, flush_set, flush_way, rd_data_state, rd_data_hprot, is_flush_all, incr_flush_way, l2_req_out_ready_int, l2_req_out_valid_int, states_buf, tags_buf, lines_buf, hprot_wr_data_req, tag_estall_wr_data_req, way_wr_data_req, rd_mem_en, wr_en_state, fill_reqs, cpu_msg_wr_data_req, hsize_wr_data_req, word_wr_data_req, clr_evict_stall, lookup_mode, evict_stall, fwd_stall, wr_en_evict_way, wr_data_evict_way, set_fwd_in_stalled, wr_req_tag, tag_wr_data_req, clr_fwd_stall_ended, l2_rsp_out_ready_int, l2_rsp_out_valid_int, reqs_hit, reqs_hit_next, l2_inval_ready_int, l2_inval_valid_int, l2_inval_o, ongoing_flush, way_hit, set_conflict, ongoing_atomic, line_out, set_set_conflict_fsm, clr_set_conflict_fsm, set_set_conflict_reqs, set_cpu_req_conflict, clr_ongoing_atomic, word_in, w_off_in, b_off_in, hsize_in, line_in, tag_hit_next, empty_way, empty_way_found_next, evict_way_buf, set_evict_stall, wr_en_line, incr_flush_set, fill_reqs_flush, reqs_atomic_i, clr_set_conflict_reqs, set_fwd_stall, clr_fwd_stall, way_hit_next, put_reqs_atomic); 
   
    input logic clk, rst;
    input logic do_flush_next, do_rsp_next, do_fwd_next, do_ongoing_flush_next, do_cpu_req_next, is_flush_all;
    input reqs_buf_t reqs[`N_REQS];
    input logic [`REQS_BITS-1:0] reqs_i, reqs_i_next; 
    input logic [`L2_SET_BITS:0] flush_set;
    input logic [`L2_WAY_BITS:0] flush_way; 
    line_breakdown_l2_t.in line_br, line_br_next; 
    addr_breakdown_t.in addr_br, addr_br_next;
    input logic l2_rd_rsp_ready_int, l2_req_out_ready_int, l2_rsp_out_ready_int, l2_inval_ready_int; 
    l2_rsp_in_t.in l2_rsp_in;
    l2_fwd_in_t.in l2_fwd_in; 
    l2_cpu_req_t.in l2_cpu_req; 
    input state_t states_buf[`L2_WAYS], rd_data_state[`L2_NUM_PORTS];
    input hprot_t rd_data_hprot[`L2_NUM_PORTS];
    input line_t lines_buf[`L2_WAYS];
    input l2_tag_t tags_buf[`L2_WAYS];
    input logic fwd_stall, evict_stall, ongoing_flush, set_fwd_stall, clr_fwd_stall; 
    input logic reqs_hit, reqs_hit_next, set_conflict, set_set_conflict_reqs, ongoing_atomic, clr_set_conflict_reqs; 
    input l2_way_t way_hit, empty_way, evict_way_buf, way_hit_next;
    input line_t line_out; 
    input logic tag_hit_next, empty_way_found_next; 
    input logic incr_flush_set; 

    output logic decode_en, lookup_en, rd_mem_en, lookup_mode; 
    output logic wr_rst, wr_en_state, fill_reqs, wr_en_line; 
    output state_t wr_data_state;
    output unstable_state_t state_wr_data_req;
    output line_t wr_data_line, line_wr_data_req;
    output hprot_t wr_data_hprot, hprot_wr_data_req; 
    output l2_tag_t wr_data_tag, tag_estall_wr_data_req, tag_wr_data_req;
    output invack_cnt_calc_t invack_cnt_wr_data_req;
    output hsize_t hsize_wr_data_req;
    output word_t word_wr_data_req;
    output cpu_msg_t cpu_msg_wr_data_req; 
    output logic wr_req_state, wr_req_state_atomic, wr_req_invack_cnt, wr_req_line, wr_en_put_reqs, wr_req_tag, put_reqs_atomic;
    output logic wr_en_evict_way;
    output logic [2:0] reqs_op_code;
    output logic l2_rd_rsp_valid_int, l2_req_out_valid_int, l2_rsp_out_valid_int, l2_inval_valid_int; 
    output l2_set_t set_in;
    output l2_way_t way, way_wr_data_req, wr_data_evict_way;
    output logic incr_reqs_cnt, set_ongoing_atomic, incr_flush_way, clr_evict_stall; 
    output logic set_fwd_in_stalled, clr_fwd_stall_ended;
    output line_addr_t l2_inval_o;
    output logic set_set_conflict_fsm, clr_set_conflict_fsm, set_cpu_req_conflict, clr_ongoing_atomic, set_evict_stall; 
    output word_t word_in; 
    output word_offset_t w_off_in; 
    output byte_offset_t b_off_in; 
    output hsize_t hsize_in; 
    output line_t line_in;
    output logic fill_reqs_flush; 
    addr_breakdown_t.out addr_br_reqs;

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
    localparam FWD_LOOKUP = 5'b00111;
    localparam FWD_RD_MEM = 5'b01000;
    localparam FWD_PUTACK = 5'b01001;
    localparam FWD_STALL = 5'b01010; 
    localparam FWD_HIT = 5'b01011; 
    localparam FWD_HIT_2 = 5'b01100;
    localparam FWD_NO_HIT_INVAL = 5'b01101; 
    localparam FWD_NO_HIT_RSP = 5'b01110; 
    localparam FWD_NO_HIT_RSP_2 = 5'b01111; 
    localparam ONGOING_FLUSH_RD_MEM = 5'b10000; 
    localparam ONGOING_FLUSH_LOOKUP = 5'b10001; 
    localparam ONGOING_FLUSH_PROCESS = 5'b10010;
    localparam CPU_REQ_REQS_LOOKUP = 5'b10011;
    localparam CPU_REQ_ATOMIC_OVERRIDE = 5'b10100;
    localparam CPU_REQ_ATOMIC_CONTINUE_READ = 5'b10101;
    localparam CPU_REQ_ATOMIC_CONTINUE_WRITE = 5'b10110;
    localparam CPU_REQ_SET_CONFLICT = 5'b10111; 
    localparam CPU_REQ_TAG_LOOKUP = 5'b11000;
    localparam CPU_REQ_READ_READ_ATOMIC_EM  =  5'b11001;
    localparam CPU_REQ_READ_ATOMIC_WRITE_S = 5'b11010; 
    localparam CPU_REQ_WRITE_EM = 5'b11011; 
    localparam CPU_REQ_EMPTY_WAY = 5'b11100; 
    localparam CPU_REQ_EVICT = 5'b11101; 

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
    
    logic update_atomic;
    line_addr_t atomic_line_addr;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            atomic_line_addr <= 0; 
        end else if (update_atomic) begin 
            atomic_line_addr <= addr_br.line_addr; 
        end
    end
    
    output logic[`REQS_BITS-1:0]  reqs_atomic_i;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            reqs_atomic_i <= 0; 
        end else if (update_atomic) begin 
            reqs_atomic_i <= reqs_i; 
        end
    end

    logic[1:0] ready_bits; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            ready_bits <= 0; 
        end else if (state == DECODE) begin 
            ready_bits <= 0; 
        end else if (state == CPU_REQ_EVICT && l2_inval_ready_int) begin 
            ready_bits[0] <= 1'b1; 
        end else if (state == CPU_REQ_EVICT && l2_req_out_ready_int) begin 
            ready_bits[1] <= 1'b1; 
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
                    next_state = FWD_RD_MEM;
                end else if (do_ongoing_flush_next) begin 
                    next_state = ONGOING_FLUSH_RD_MEM;
                end else if (do_cpu_req_next) begin 
                    next_state = CPU_REQ_REQS_LOOKUP; 
                end
            end
            RSP_LOOKUP : begin 
                case(l2_rsp_in.coh_msg) 
                    `RSP_EDATA : begin 
                        next_state = RSP_E_DATA_ISD; 
                    end
                    `RSP_DATA : begin 
                        case(reqs[reqs_i_next].state) 
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
            RSP_DATA_XMAD : begin 
                next_state = DECODE; 
            end
            RSP_DATA_XMADW : begin 
                if (l2_rd_rsp_ready_int) begin 
                    next_state = DECODE;
                end
            end
            RSP_INVACK : begin 
                next_state = DECODE;
            end
            FWD_RD_MEM : begin 
                next_state = FWD_LOOKUP;
            end
            FWD_LOOKUP : begin 
                if (l2_fwd_in.coh_msg == `FWD_PUTACK) begin 
                    next_state = FWD_PUTACK;
                end else if ((fwd_stall || set_fwd_stall) & !clr_fwd_stall) begin 
                    next_state = FWD_STALL;
                end else if (reqs_hit_next) begin 
                    next_state = FWD_HIT;
                end else begin 
                    if (l2_fwd_in.coh_msg == `FWD_GETS) begin 
                        next_state = FWD_NO_HIT_RSP;
                    end else if (!ongoing_flush || l2_fwd_in.coh_msg == `FWD_INV_LLC) begin 
                        next_state = FWD_NO_HIT_INVAL; 
                    end else begin 
                        next_state = FWD_NO_HIT_RSP; 
                    end
                end
            end
            FWD_PUTACK : begin 
                if (l2_req_out_ready_int) begin 
                    next_state  = DECODE;
                end
            end
            FWD_STALL : begin 
                next_state = DECODE; 
            end
            FWD_HIT : begin 
                if (reqs[reqs_i].state == `SMAD || reqs[reqs_i].state == `SMADW) begin 
                    if (l2_fwd_in.coh_msg == `FWD_INV && l2_rsp_out_ready_int) begin 
                        next_state = DECODE;
                    end else if (l2_fwd_in.coh_msg != `FWD_INV) begin 
                        next_state = DECODE;
                    end 
                end else if (reqs[reqs_i].state == `MIA) begin 
                    if (l2_fwd_in.coh_msg == `FWD_GETS && l2_rsp_out_ready_int) begin 
                        next_state = FWD_HIT_2; 
                    end else if (l2_rsp_out_ready_int) begin 
                        next_state = DECODE;
                    end 
                end else if (reqs[reqs_i].state == `SIA) begin 
                    if (l2_fwd_in.coh_msg == `FWD_INV && l2_rsp_out_ready_int) begin 
                        next_state = DECODE;
                    end else if (l2_fwd_in.coh_msg != `FWD_INV) begin 
                        next_state = DECODE;
                    end
                end else begin 
                    next_state = DECODE; 
                end
            end
            FWD_HIT_2 : begin 
                if (l2_rsp_out_ready_int) begin 
                    next_state = DECODE; 
                end
            end
            FWD_NO_HIT_INVAL : begin 
                if (l2_inval_ready_int) begin 
                    if (l2_fwd_in.coh_msg == `FWD_INV_LLC) begin 
                        next_state = DECODE;
                    end else begin 
                        next_state = FWD_NO_HIT_RSP; 
                    end
                end
            end
            FWD_NO_HIT_RSP : begin 
                if (l2_rsp_out_ready_int) begin 
                    if (l2_fwd_in.coh_msg == `FWD_GETS) begin 
                        next_state = FWD_NO_HIT_RSP_2;
                    end else begin 
                        next_state = DECODE;
                    end
                end
            end 
            FWD_NO_HIT_RSP_2 : begin 
                if (l2_rsp_out_ready_int) begin 
                    next_state = DECODE; 
                end
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
            CPU_REQ_REQS_LOOKUP : begin 
                if (ongoing_atomic) begin 
                    if (atomic_line_addr != addr_br.line_addr) begin 
                        next_state = CPU_REQ_ATOMIC_OVERRIDE;
                    end else begin 
                        if (l2_cpu_req.cpu_msg == `READ || l2_cpu_req.cpu_msg == `READ_ATOMIC) begin 
                            next_state = CPU_REQ_ATOMIC_CONTINUE_READ;
                        end else begin 
                            next_state = CPU_REQ_ATOMIC_CONTINUE_WRITE;
                        end
                    end    
                end else if ((set_conflict | set_set_conflict_reqs) & !clr_set_conflict_reqs) begin 
                    next_state = CPU_REQ_SET_CONFLICT; 
                end else begin 
                    next_state = CPU_REQ_TAG_LOOKUP;
                end
            end
            CPU_REQ_ATOMIC_OVERRIDE : begin 
                next_state = DECODE;
            end 
            CPU_REQ_ATOMIC_CONTINUE_READ : begin 
                if (l2_rd_rsp_ready_int) begin 
                    next_state = DECODE;
                end
            end
            CPU_REQ_ATOMIC_CONTINUE_WRITE : begin 
                next_state = DECODE;
            end
            CPU_REQ_SET_CONFLICT : begin 
                next_state = DECODE; 
            end
            CPU_REQ_TAG_LOOKUP : begin 
                if (tag_hit_next) begin 
                    if (l2_cpu_req.cpu_msg == `READ || (l2_cpu_req.cpu_msg == `READ_ATOMIC && (states_buf[way_hit_next] == `EXCLUSIVE || states_buf[way_hit_next] == `MODIFIED)))  begin
                        next_state = CPU_REQ_READ_READ_ATOMIC_EM; 
                    end else if ((l2_cpu_req.cpu_msg == `READ_ATOMIC && states_buf[way_hit_next] == `SHARED) || (l2_cpu_req.cpu_msg == `WRITE && states_buf[way_hit_next] == `SHARED)) begin 
                        next_state = CPU_REQ_READ_ATOMIC_WRITE_S;
                    end else if (l2_cpu_req.cpu_msg == `WRITE && (states_buf[way_hit_next] == `EXCLUSIVE || states_buf[way_hit_next] == `MODIFIED)) begin  
                        next_state = CPU_REQ_WRITE_EM; 
                    end
                end else if (empty_way_found_next) begin 
                    next_state = CPU_REQ_EMPTY_WAY;
                end else begin 
                    next_state = CPU_REQ_EVICT;
                end
            end
            CPU_REQ_READ_READ_ATOMIC_EM : begin 
                if (l2_rd_rsp_ready_int) begin 
                    next_state = DECODE;
                end
            end
            CPU_REQ_READ_ATOMIC_WRITE_S : begin 
                if (l2_req_out_ready_int) begin 
                    next_state = DECODE;
                end
            end
            CPU_REQ_WRITE_EM : begin 
                next_state = DECODE; 
            end
            CPU_REQ_EMPTY_WAY : begin 
                if (l2_req_out_ready_int) begin 
                    next_state = DECODE; 
                end
            end
            CPU_REQ_EVICT : begin 
                if (l2_inval_ready_int && l2_req_out_ready_int) begin 
                    next_state = DECODE; 
                end else if (ready_bits[0] && l2_req_out_ready_int) begin 
                    next_state = DECODE;
                end else if (l2_inval_ready_int && ready_bits[1]) begin 
                    next_state = DECODE;
                end
            end
        endcase
    end

    addr_t addr_tmp;
    line_addr_t line_addr_tmp;
    unstable_state_t state_tmp;
    coh_msg_t coh_msg_tmp;

    always_comb begin 
        wr_rst = 1'b0; 
        wr_data_state = 0; 
        reqs_op_code = `L2_REQS_IDLE; 
        lookup_en = 1'b0; 
        lookup_mode = 1'b0; 
        wr_req_state = 1'b0;
        wr_req_state_atomic = 1'b0; 
        wr_req_line = 1'b0;
        wr_req_invack_cnt = 0;
        wr_req_tag = 1'b0; 
        wr_en_put_reqs = 1'b0;
        wr_en_state = 1'b0; 
        wr_en_line = 1'b0; 
        wr_en_evict_way = 1'b0; 
        set_in = 0; 
        way = 0; 
        way_wr_data_req = 0;
        wr_data_tag = 0;
        wr_data_hprot = 0; 
        wr_data_line = 0; 
        wr_data_state = 0; 
        wr_data_evict_way = 0; 
        incr_reqs_cnt = 1'b0;
        set_ongoing_atomic = 1'b0; 
        rd_mem_en = 1'b0; 
        incr_flush_way = 1'b0;
        addr_tmp = 0; 
        line_addr_tmp = 0; 
        state_tmp = 0; 
        coh_msg_tmp = 0; 
        fill_reqs = 1'b0;
        fill_reqs_flush = 1'b0; 
            
        set_fwd_in_stalled = 1'b0; 
        clr_fwd_stall_ended = 1'b0;
        set_set_conflict_fsm = 1'b0;
        clr_set_conflict_fsm = 1'b0; 
        set_cpu_req_conflict = 1'b0; 
        clr_ongoing_atomic  = 1'b0; 
        update_atomic = 1'b0;
        clr_evict_stall = 1'b0;
        set_evict_stall = 1'b0;
        put_reqs_atomic = 1'b0; 

        l2_rd_rsp_o.line = 0; 
        l2_rd_rsp_valid_int = 1'b0;
        l2_inval_o = 0; 
        l2_inval_valid_int = 1'b0; 

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
        tag_wr_data_req = 0; 

        l2_req_out_valid_int = 1'b0;
        l2_req_out_o.coh_msg = 0;
        l2_req_out_o.hprot = 0;
        l2_req_out_o.addr = 0; 
        l2_req_out_o.line = 0;
                   
        l2_rsp_out_valid_int = 1'b0;
        l2_rsp_out_o.coh_msg = 0; 
        l2_rsp_out_o.req_id = 0; 
        l2_rsp_out_o.to_req = 1'b0; 
        l2_rsp_out_o.addr = 0; 
        l2_rsp_out_o.line = 0; 

        word_in = 0; 
        w_off_in = 0; 
        b_off_in = 0; 
        hsize_in = 0; 
        line_in = 0;

        case (state)
            RESET : begin 
                wr_rst = 1'b1;
                wr_data_state = `INVALID;
            end
            DECODE : begin 
                if (do_ongoing_flush_next) begin 
                    if (incr_flush_set) begin 
                        set_in = flush_set + 1;
                    end else begin 
                        set_in = flush_set;
                    end
                end else if (do_fwd_next) begin 
                    set_in = line_br_next.set;
                end else if (do_cpu_req_next) begin 
                    set_in = addr_br_next.set;
                end
            end
            RSP_LOOKUP : begin 
                reqs_op_code = `L2_REQS_LOOKUP;
            end
            RSP_E_DATA_ISD : begin 
                l2_rd_rsp_valid_int = 1'b1;
                l2_rd_rsp_o.line = l2_rsp_in.line;
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
                if (invack_cnt_wr_data_req == `MAX_N_L2) begin 
                    wr_en_put_reqs = 1'b1;
                    set_in = line_br.set; 
                    way = reqs[reqs_i].way; 
                    wr_data_tag = line_br.tag;
                    wr_data_line = line_out;
                    wr_data_hprot = reqs[reqs_i].hprot;
                    wr_data_state = `MODIFIED; 
                    wr_req_state = 1'b1;
                    state_wr_data_req = `INVALID;
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
            FWD_RD_MEM : begin 
                rd_mem_en = 1'b1; 
                set_in = line_br.set; 
            end
            FWD_LOOKUP : begin 
                reqs_op_code = `L2_REQS_PEEK_FWD;
                lookup_en = 1'b1; 
                lookup_mode = `L2_LOOKUP_FWD;
                clr_fwd_stall_ended = 1'b1;
            end
            FWD_PUTACK : begin 
                if (evict_stall) begin 
                    clr_evict_stall = 1'b1; 
                    case (reqs[reqs_i].cpu_msg) 
                        `READ : begin 
                            state_wr_data_req = `ISD;
                            l2_req_out_o.coh_msg = `REQ_GETS;
                        end
                        `READ_ATOMIC : begin  
                            state_wr_data_req = `IMADW;
                            l2_req_out_o.coh_msg = `REQ_GETM;
                        end
                        `WRITE : begin 
                            state_wr_data_req = `IMAD;
                            l2_req_out_o.coh_msg = `REQ_GETM; 
                        end
                    endcase
                    wr_req_state = 1'b1;
                    wr_req_tag = 1'b1; 
                    tag_wr_data_req = reqs[reqs_i].tag_estall; 
                    
                    wr_en_evict_way = 1'b1; 
                    wr_data_evict_way = reqs[reqs_i].way + 1; 
                    set_in = reqs[reqs_i].set; 

                    l2_req_out_o.hprot = reqs[reqs_i].hprot; 
                    l2_req_out_o.addr = (reqs[reqs_i].tag_estall << `L2_SET_BITS) | line_br.set; 
                    l2_req_out_valid_int = 1'b1; 
                end else begin 
                    wr_req_state = 1'b1; 
                    state_wr_data_req = `INVALID;
                    incr_reqs_cnt = 1'b1; 
                end
            end
            FWD_STALL : begin 
                set_fwd_in_stalled = 1'b1; 
            end
            FWD_HIT : begin 
                if (reqs[reqs_i].state == `SMAD || reqs[reqs_i].state == `SMADW || reqs[reqs_i].state == `SIA) begin  
                    if (l2_fwd_in.coh_msg == `FWD_INV) begin 
                        l2_rsp_out_valid_int = 1'b1;
                        l2_rsp_out_o.coh_msg = `RSP_INVACK; 
                        l2_rsp_out_o.req_id = l2_fwd_in.req_id; 
                        l2_rsp_out_o.to_req = 1'b1; 
                        l2_rsp_out_o.addr = l2_fwd_in.addr;
                        l2_rsp_out_o.line = 0; 
                    end
                    wr_req_state = 1'b1;
                    if (reqs[reqs_i].state == `SIA) begin 
                        state_wr_data_req  = `IIA; 
                    end else begin     
                        state_wr_data_req  = reqs[reqs_i].state - 4;
                    end
                end else if (reqs[reqs_i].state == `MIA) begin 
                    l2_rsp_out_valid_int = 1'b1;
                    l2_rsp_out_o.coh_msg = `RSP_DATA; 
                    l2_rsp_out_o.addr = l2_fwd_in.addr;
                    l2_rsp_out_o.line = reqs[reqs_i].line;
                    if (l2_fwd_in.coh_msg == `FWD_GETS || l2_fwd_in.coh_msg == `FWD_GETM) begin
                        l2_rsp_out_o.req_id = l2_fwd_in.req_id; 
                        l2_rsp_out_o.to_req = 1'b1; 
                    end else begin 
                        l2_rsp_out_o.req_id = 0; 
                        l2_rsp_out_o.to_req = 1'b0; 
                    end
                    
                    wr_req_state = 1'b1; 
                    if (l2_fwd_in.coh_msg == `FWD_GETS) begin 
                        state_wr_data_req = `SIA;
                    end else begin 
                        state_wr_data_req = `IIA;
                    end
                end
            end 
            FWD_HIT_2 : begin 
                l2_rsp_out_valid_int = 1'b1;
                l2_rsp_out_o.coh_msg = `RSP_DATA; 
                l2_rsp_out_o.req_id = l2_fwd_in.req_id; 
                l2_rsp_out_o.to_req = 1'b0;
                l2_rsp_out_o.addr = l2_fwd_in.addr; 
                l2_rsp_out_o.line = reqs[reqs_i].line; 
            end
            FWD_NO_HIT_INVAL : begin 
                if (!ongoing_flush) begin 
                    l2_inval_valid_int = 1'b1; 
                    l2_inval_o = l2_fwd_in.addr;
                end
                wr_en_state = 1'b1; 
                wr_data_state = `INVALID; 
                way = way_hit;
                set_in = line_br.set; 
            end
            FWD_NO_HIT_RSP : begin 
                l2_rsp_out_valid_int = 1'b1;
                if (l2_fwd_in.coh_msg == `FWD_GETS || l2_fwd_in.coh_msg == `FWD_GETM) begin 
                    l2_rsp_out_o.coh_msg = `RSP_DATA;
                    l2_rsp_out_o.req_id = l2_fwd_in.req_id; 
                    l2_rsp_out_o.to_req = 1'b1; 
                    l2_rsp_out_o.addr = l2_fwd_in.addr; 
                    l2_rsp_out_o.line = lines_buf[way_hit]; 
                end else if (l2_fwd_in.coh_msg == `FWD_INV) begin 
                    l2_rsp_out_o.coh_msg = `RSP_INVACK;
                    l2_rsp_out_o.req_id = l2_fwd_in.req_id; 
                    l2_rsp_out_o.to_req = 1'b1; 
                    l2_rsp_out_o.addr = l2_fwd_in.addr; 
                    l2_rsp_out_o.line = 0;
                end else if (l2_fwd_in.coh_msg == `FWD_GETM_LLC) begin 
                    l2_rsp_out_o.req_id = l2_fwd_in.req_id; 
                    l2_rsp_out_o.to_req = 1'b1; 
                    l2_rsp_out_o.addr = l2_fwd_in.addr; 
                    if (states_buf[way_hit] == `EXCLUSIVE) begin 
                        l2_rsp_out_o.coh_msg = `RSP_INVACK;
                        l2_rsp_out_o.line = 0;
                    end else begin 
                        l2_rsp_out_o.coh_msg = `RSP_DATA;
                        l2_rsp_out_o.line = lines_buf[way_hit];
                    end
                end
                
                if (l2_fwd_in.coh_msg != `FWD_GETS) begin    
                    wr_en_state = 1'b1; 
                    wr_data_state = `INVALID; 
                    way = way_hit;
                    set_in = line_br.set; 
                end
            end
            FWD_NO_HIT_RSP_2 : begin 
                l2_rsp_out_valid_int = 1'b1;
                l2_rsp_out_o.coh_msg = `RSP_DATA;
                l2_rsp_out_o.req_id = l2_fwd_in.req_id; 
                l2_rsp_out_o.to_req = 1'b0; 
                l2_rsp_out_o.addr = l2_fwd_in.addr; 
                l2_rsp_out_o.line = lines_buf[way_hit]; 
                wr_en_state = 1'b1; 
                wr_data_state = `SHARED;
                set_in = line_br.set; 
                way = way_hit; 
             end
            ONGOING_FLUSH_RD_MEM : begin 
                rd_mem_en = 1'b1;
                if ((rd_data_state[flush_way] == `INVALID) || (~is_flush_all && ~rd_data_hprot[flush_way])) begin 
                    incr_flush_way = 1'b1;
                end
            end 
            ONGOING_FLUSH_LOOKUP : begin 
                reqs_op_code = `L2_REQS_PEEK_FLUSH;
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
                fill_reqs_flush = 1'b1;
                cpu_msg_wr_data_req = 0;
                tag_estall_wr_data_req = 0;
                way_wr_data_req = flush_way;
                hsize_wr_data_req = 0;
                state_wr_data_req = state_tmp;
                hprot_wr_data_req = 0; 
                word_wr_data_req = 0;
                line_wr_data_req = lines_buf[flush_way];

                l2_req_out_valid_int = 1'b1;
                l2_req_out_o.coh_msg = coh_msg_tmp;
                l2_req_out_o.hprot = 0;
                l2_req_out_o.addr = line_addr_tmp; 
                l2_req_out_o.line = lines_buf[flush_way];

                if (l2_req_out_ready_int) begin 
                    incr_flush_way = 1'b1;
                end
            end
            CPU_REQ_REQS_LOOKUP : begin 
                reqs_op_code = `L2_REQS_PEEK_REQ;
                rd_mem_en = 1'b1;
                set_in = addr_br.set; 
            end
            CPU_REQ_ATOMIC_OVERRIDE : begin 
                set_set_conflict_fsm = 1'b1;
                set_cpu_req_conflict = 1'b1; 
                state_wr_data_req = `INVALID;
                wr_req_state_atomic = 1'b1; 
                incr_reqs_cnt = 1'b1; 
                clr_ongoing_atomic  = 1'b1;

                set_in = reqs[reqs_atomic_i].set; 
                way = reqs[reqs_atomic_i].way;

                wr_en_put_reqs = 1'b1; 
                wr_data_tag = reqs[reqs_atomic_i].tag;
                wr_data_line =  reqs[reqs_atomic_i].line;
                wr_data_hprot = reqs[reqs_atomic_i].hprot;
                wr_data_state = `MODIFIED; 
            end 
            CPU_REQ_ATOMIC_CONTINUE_READ :  begin 
                clr_set_conflict_fsm = 1'b1;
                l2_rd_rsp_valid_int = 1'b1; 
                l2_rd_rsp_o.line = reqs[reqs_atomic_i].line;
                if (l2_cpu_req.cpu_msg == `READ) begin 
                    wr_req_state_atomic = 1'b1; 
                    state_wr_data_req = `INVALID;
                    incr_reqs_cnt = 1'b1; 
                    
                    set_in = reqs[reqs_atomic_i].set; 
                    way = reqs[reqs_atomic_i].way;
                    clr_ongoing_atomic = 1'b1;

                    wr_en_put_reqs = 1'b1; 
                    wr_data_tag = reqs[reqs_atomic_i].tag;
                    wr_data_line =  reqs[reqs_atomic_i].line;
                    wr_data_hprot = reqs[reqs_atomic_i].hprot;
                    wr_data_state = `MODIFIED; 
                end
            end 
            CPU_REQ_ATOMIC_CONTINUE_WRITE : begin 
                clr_set_conflict_fsm = 1'b1; 
                word_in = l2_cpu_req.word;
                w_off_in = addr_br.w_off; 
                b_off_in = addr_br.b_off; 
                hsize_in = l2_cpu_req.hsize; 
                line_in = reqs[reqs_atomic_i].line;
                    
                wr_req_state_atomic = 1'b1; 
                state_wr_data_req = `INVALID;
                incr_reqs_cnt = 1'b1;

                set_in = reqs[reqs_atomic_i].set; 
                way = reqs[reqs_atomic_i].way;
                
                put_reqs_atomic = 1'b1; 
                wr_en_put_reqs = 1'b1; 
                wr_data_tag = reqs[reqs_atomic_i].tag;
                wr_data_line =  line_out;
                wr_data_hprot = reqs[reqs_atomic_i].hprot;
                wr_data_state = `MODIFIED; 
                clr_ongoing_atomic = 1'b1;
            end
            CPU_REQ_SET_CONFLICT : begin 
                set_cpu_req_conflict = 1'b1; 
            end
            CPU_REQ_TAG_LOOKUP : begin 
                if (l2_cpu_req.cpu_msg == `READ_ATOMIC) begin 
                    update_atomic = 1'b1; 
                end
                lookup_en = 1'b1; 
                lookup_mode = `L2_LOOKUP;
            end
            CPU_REQ_READ_READ_ATOMIC_EM : begin 
                if (l2_cpu_req.cpu_msg == `READ_ATOMIC) begin 
                    fill_reqs = 1'b1; 
                    cpu_msg_wr_data_req = l2_cpu_req.cpu_msg;
                    tag_estall_wr_data_req = 0; 
                    tag_wr_data_req = addr_br.tag; 
                    way_wr_data_req = way_hit; 
                    hsize_wr_data_req = l2_cpu_req.hsize;
                    state_wr_data_req = `XMW;
                    hprot_wr_data_req = l2_cpu_req.hprot;
                    word_wr_data_req = l2_cpu_req.word;
                    line_wr_data_req = lines_buf[way_hit];
                    set_ongoing_atomic = 1'b1;
                end
                l2_rd_rsp_valid_int = 1'b1; 
                l2_rd_rsp_o.line = lines_buf[way_hit];
            end
            CPU_REQ_READ_ATOMIC_WRITE_S : begin 
                if (l2_cpu_req.cpu_msg == `READ_ATOMIC) begin 
                    state_wr_data_req = `SMADW;
                end else if (l2_cpu_req.cpu_msg == `WRITE) begin 
                    state_wr_data_req = `SMAD;
                end
                
                fill_reqs = 1'b1; 
                cpu_msg_wr_data_req = l2_cpu_req.cpu_msg;
                tag_estall_wr_data_req = 0; 
                tag_wr_data_req = addr_br.tag; 
                way_wr_data_req = way_hit; 
                hsize_wr_data_req = l2_cpu_req.hsize;
                hprot_wr_data_req = l2_cpu_req.hprot;
                word_wr_data_req = l2_cpu_req.word;
                line_wr_data_req = lines_buf[way_hit];
 
                l2_req_out_valid_int = 1'b1;
                l2_req_out_o.coh_msg = `REQ_GETM;
                l2_req_out_o.hprot = l2_cpu_req.hprot;
                l2_req_out_o.addr = addr_br.line_addr;
                l2_req_out_o.line = 0; 
            end
            CPU_REQ_WRITE_EM : begin 
                set_in = addr_br.set;
                way = way_hit; 
               
                if (states_buf[way_hit] == `EXCLUSIVE) begin 
                    wr_data_state = `MODIFIED; 
                    wr_en_state = 1'b1; 
                end
                
                line_in = lines_buf[way_hit];
                word_in = l2_cpu_req.word;
                w_off_in = addr_br.w_off; 
                b_off_in = addr_br.b_off;
                hsize_in = l2_cpu_req.hsize;
                wr_data_line = line_out; 
                wr_en_line = 1'b1;
            end
            CPU_REQ_EMPTY_WAY : begin 
                l2_req_out_valid_int = 1'b1; 
                l2_req_out_o.hprot = l2_cpu_req.hprot;
                l2_req_out_o.addr = addr_br.line_addr;
                l2_req_out_o.line = 0;
                case (l2_cpu_req.cpu_msg) 
                    `READ : begin 
                        l2_req_out_o.coh_msg = `REQ_GETS;
                        state_wr_data_req = `ISD;
                    end
                    `READ_ATOMIC : begin 
                        l2_req_out_o.coh_msg = `REQ_GETM;
                        state_wr_data_req = `IMADW;
                    end
                    `WRITE : begin 
                        l2_req_out_o.coh_msg = `REQ_GETM;
                        state_wr_data_req = `IMAD;
                    end
                endcase
                fill_reqs = 1'b1; 
                cpu_msg_wr_data_req = l2_cpu_req.cpu_msg;
                tag_estall_wr_data_req = 0; 
                tag_wr_data_req = addr_br.tag; 
                way_wr_data_req = empty_way; 
                hsize_wr_data_req = l2_cpu_req.hsize;
                hprot_wr_data_req = l2_cpu_req.hprot;
                word_wr_data_req = l2_cpu_req.word;
                line_wr_data_req = 0;
            end
            CPU_REQ_EVICT : begin 
                set_evict_stall = 1'b1;
                if (!ready_bits[0]) begin 
                    l2_inval_valid_int = 1'b1;
                end
                l2_inval_o = (tags_buf[evict_way_buf] << `L2_SET_BITS) | addr_br.set;
                if (!ready_bits[1]) begin 
                l2_req_out_valid_int = 1'b1;
                end
                case (states_buf[evict_way_buf]) 
                    `SHARED : begin 
                        l2_req_out_o.coh_msg = `REQ_PUTS;
                        state_wr_data_req = `SIA;
                    end
                    `EXCLUSIVE : begin 
                        l2_req_out_o.coh_msg = `REQ_PUTS;
                        state_wr_data_req = `MIA;
                    end
                    `MODIFIED : begin 
                        l2_req_out_o.coh_msg = `REQ_PUTM;
                        state_wr_data_req = `MIA;
                    end
                endcase    
                
                l2_req_out_o.hprot = 0;
                l2_req_out_o.addr = (tags_buf[evict_way_buf] << `L2_SET_BITS) | addr_br.set; 
                l2_req_out_o.line = lines_buf[evict_way_buf]; 
               
                fill_reqs = 1'b1;
                cpu_msg_wr_data_req = l2_cpu_req.cpu_msg;
                tag_estall_wr_data_req = addr_br.tag;
                tag_wr_data_req = tags_buf[evict_way_buf];
                way_wr_data_req = evict_way_buf; 
                hsize_wr_data_req = l2_cpu_req.hsize;
                hprot_wr_data_req = l2_cpu_req.hprot;
                word_wr_data_req = l2_cpu_req.word;
                line_wr_data_req = lines_buf[evict_way_buf];
            end
            default : begin 
                reqs_op_code = `L2_REQS_IDLE;
            end
        endcase
    end 

endmodule
