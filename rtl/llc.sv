`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc.sv
// Author: Joseph Zuckerman
// Top level LLC module 

module llc(clk, rst, llc_req_in_i, llc_req_in_valid, llc_req_in_ready, llc_dma_req_in_i, llc_dma_req_in_valid, llc_dma_req_in_ready, llc_rsp_in_i, llc_rsp_in_valid, llc_rsp_in_ready, llc_mem_rsp_i, llc_mem_rsp_valid, llc_mem_rsp_ready, llc_rst_tb_i, llc_rst_tb_valid, llc_rst_tb_ready, llc_rsp_out_ready, llc_rsp_out_valid, llc_rsp_out, llc_dma_rsp_out_ready, llc_dma_rsp_out_valid, llc_dma_rsp_out, llc_fwd_out_ready, llc_fwd_out_valid, llc_fwd_out, llc_mem_req_ready,  llc_mem_req_valid, llc_mem_req, llc_rst_tb_done_ready, llc_rst_tb_done_valid, llc_rst_tb_done
`ifdef STATS_ENABLE
	, llc_stats_ready, llc_stats_valid, llc_stats
`endif
);

	input logic clk;
	input logic rst; 

	llc_req_in_t llc_req_in_i;
	input logic llc_req_in_valid;
	output logic llc_req_in_ready;

	llc_req_in_t llc_dma_req_in_i;
	input logic llc_dma_req_in_valid;
	output logic llc_dma_req_in_ready; 
	
	llc_rsp_in_t llc_rsp_in_i; 
	input logic llc_rsp_in_valid;
	output logic llc_rsp_in_ready;

	llc_mem_rsp_t llc_mem_rsp_i;
	input logic  llc_mem_rsp_valid;
	output logic llc_mem_rsp_ready;

    input logic llc_rst_tb_i;
	input logic llc_rst_tb_valid;
	output logic llc_rst_tb_ready;

	input logic llc_rsp_out_ready;
	output logic llc_rsp_out_valid;
	llc_rsp_out_t  llc_rsp_out;

	input logic llc_dma_rsp_out_ready;
	output logic llc_dma_rsp_out_valid;
	llc_rsp_out_t llc_dma_rsp_out;

	input logic llc_fwd_out_ready; 
	output logic llc_fwd_out_valid;
	llc_fwd_out_t llc_fwd_out;   

	input logic llc_mem_req_ready;
	output logic llc_mem_req_valid;
	llc_mem_req_t llc_mem_req;

	input logic llc_rst_tb_done_ready;
	output logic llc_rst_tb_done_valid;
    output logic llc_rst_tb_done;

`ifdef STATS_ENABLE
	input  logic llc_stats_ready;
	output logic llc_stats_valid;
	output logic llc_stats;
`endif

    llc_req_in_t llc_req_in(); 
    llc_req_in_t llc_dma_req_in(); 
    llc_rsp_in_t llc_rsp_in(); 
    llc_mem_rsp_t llc_mem_rsp();
    logic llc_rst_tb; 

    //STATE MACHINE
    localparam DECODE = 3'b000;
    localparam READ = 3'b001;
    localparam LOOKUP = 3'b011; 
    localparam PROCESS = 3'b010; 
    localparam UPDATE = 3'b110; 

    logic[2:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= DECODE; 
        end else begin 
            state <= next_state; 
        end
    end 

    logic process_done; 
    always_comb begin 
        next_state = state; 
        case(state) 
            DECODE :  
                next_state = READ;
            READ :   
                next_state = LOOKUP;
            LOOKUP : 
                next_state = PROCESS;
            PROCESS :   
                if (process_done) begin 
                    next_state = UPDATE; 
                end
            UPDATE :   
                next_state = DECODE; 
        endcase
    end


    logic decode_en, rd_set_en, update_en, process_en, lookup_en; 
    assign decode_en = (state == DECODE);
    assign rd_set_en = (state == READ); 
    assign lookup_en = (state == LOOKUP);  
    assign process_en = (state == PROCESS); 
    assign update_en = (state == UPDATE); 

    logic is_rst_to_get, is_req_to_get, is_dma_req_to_get, is_rsp_to_get, do_get_req, do_get_dma_req, is_flush_to_resume, is_rst_to_resume, is_dma_read_to_resume, is_dma_write_to_resume, is_rst_to_get_next, is_rsp_to_get_next; 
    
    line_breakdown_llc_t line_br();
    
    logic look, rd_en;
    assign rd_en = look;
    input_decoder input_decoder_u(.*);
   
    assign llc_rsp_in_ready = decode_en & is_rsp_to_get_next; 
    assign llc_rst_tb_ready = decode_en & is_rst_to_get_next; 
    assign llc_req_in_ready = decode_en & do_get_req; 
    assign llc_dma_req_in_ready = decode_en & do_get_dma_req;

    line_t rd_data_line[`LLC_WAYS];
    llc_tag_t rd_data_tag[`LLC_WAYS];
    sharers_t rd_data_sharers[`LLC_WAYS];
    owner_t rd_data_owner[`LLC_WAYS];
    hprot_t rd_data_hprot[`LLC_WAYS];
    logic rd_data_dirty_bit[`LLC_WAYS];
    llc_way_t rd_data_evict_way; 
    llc_state_t rd_data_state[`LLC_WAYS];

    line_t lines_buf[`LLC_WAYS];
    llc_tag_t tags_buf[`LLC_WAYS];
    sharers_t sharers_buf[`LLC_WAYS];
    owner_t owners_buf[`LLC_WAYS];
    hprot_t hprots_buf[`LLC_WAYS];
    logic dirty_bits_buf[`LLC_WAYS];
    llc_way_t evict_way_buf; 
    llc_state_t states_buf[`LLC_WAYS];

    
    llc_way_t way;
    logic wr_en_evict_way_buf, wr_en_lines_buf, wr_en_tags_buf, wr_en_sharers_buf, wr_en_owners_buf, wr_en_hprots_buf, wr_en_dirty_bits_buf, wr_en_states_buf;
    line_t lines_buf_wr_data;
    llc_way_t evict_way_buf_wr_data;
    llc_tag_t tags_buf_wr_data;
    sharers_t sharers_buf_wr_data;
    owner_t owners_buf_wr_data;
    hprot_t hprots_buf_wr_data;
    logic dirty_bits_buf_wr_data;
    llc_state_t states_buf_wr_data;
    //read into buffers
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            evict_way_buf <= 0; 
        end else if (rd_en) begin 
            evict_way_buf <= rd_data_evict_way;
        end else if (wr_en_evict_way_buf) begin 
            evict_way_buf <= evict_way_buf_wr_data; 
        end
        for (int i = 0; i < `LLC_WAYS; i++) begin 
            if (!rst) begin
                lines_buf[i] <= 0; 
            end else if (rd_en) begin 
                lines_buf[i] <= rd_data_line[i];
            end else if (wr_en_lines_buf && (way == i)) begin 
                lines_buf[i] <= lines_buf_wr_data;
            end
   
            if (!rst) begin 
                tags_buf[i] <= 0;
            end else if (rd_en) begin  
                tags_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_tags_buf && (way == i)) begin 
                tags_buf[i] <= tags_buf_wr_data;
            end
     
           if (!rst) begin 
                sharers_buf[i] <= 0;
            end else if (rd_en) begin 
                sharers_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_sharers_buf && (way == i)) begin 
                sharers_buf[i] <= sharers_buf_wr_data;
            end

           if (!rst) begin 
                owners_buf[i] <= 0;
            end else if (rd_en) begin 
                owners_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_owners_buf && (way == i)) begin 
                owners_buf[i] <= owners_buf_wr_data;
            end

            if (!rst) begin 
                hprots_buf[i] <= 0;
            end else if (rd_en) begin
                hprots_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_hprots_buf && (way == i)) begin 
                hprots_buf[i] <= hprots_buf_wr_data;
            end
            
            if (!rst) begin 
                dirty_bits_buf[i] <= 0;
            end else if (rd_en) begin
                dirty_bits_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_dirty_bits_buf && (way == i)) begin 
                dirty_bits_buf[i] <= dirty_bits_buf_wr_data;
            end
            
            if (!rst) begin 
                states_buf[i] <= 0;
            end else if (rd_en) begin
                states_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_states_buf && (way == i)) begin 
                states_buf[i] <= states_buf_wr_data;
            end
       end
    end
    
    llc_set_t set_in, rd_set, set;     
    assign set_in = rd_en ? rd_set : set;
   
    line_addr_t req_in_addr, rsp_in_addr, dma_req_in_addr; 
    assign req_in_addr = llc_req_in.addr;
    assign rsp_in_addr = llc_rsp_in.addr;
    assign dma_req_in_addr = llc_dma_req_in.addr; 
    read_set read_set_u(.*);
     
    localmem localmem_u(.*);

    logic evict;
    llc_tag_t tag; 
    assign tag = line_br.tag;
 
    lookup_way lookup_way_u(.*); 

    llc_addr_t addr_evict;
    logic rst_state;
    process_request process_request_u(.*);

    logic update_req_in_from_stalled;
    //@TODO update req_in_stalled
    llc_req_in_t req_in_stalled();
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_req_in.coh_msg <= 0; 
            llc_req_in.hprot <= 0; 
            llc_req_in.addr <= 0; 
            llc_req_in.line <= 0; 
            llc_req_in.req_id <= 0; 
            llc_req_in.word_offset <= 0; 
            llc_req_in.valid_words <= 0; 
       end else if (update_req_in_from_stalled) begin
            llc_req_in.coh_msg <= req_in_stalled.coh_msg; 
            llc_req_in.hprot <= req_in_stalled.hprot; 
            llc_req_in.addr <= req_in_stalled.addr; 
            llc_req_in.line <= req_in_stalled.line; 
            llc_req_in.req_id <= req_in_stalled.req_id; 
            llc_req_in.word_offset <= req_in_stalled.word_offset; 
            llc_req_in.valid_words <= req_in_stalled.valid_words; 
        end else if (llc_req_in_valid && llc_req_in_ready) begin
            llc_req_in.coh_msg <= llc_req_in_i.coh_msg; 
            llc_req_in.hprot <= llc_req_in_i.hprot; 
            llc_req_in.addr <= llc_req_in_i.addr; 
            llc_req_in.line <= llc_req_in_i.line; 
            llc_req_in.req_id <= llc_req_in_i.req_id; 
            llc_req_in.word_offset <= llc_req_in_i.word_offset; 
            llc_req_in.valid_words <= llc_req_in_i.valid_words; 
        end
    end

    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_dma_req_in.coh_msg <= 0; 
            llc_dma_req_in.hprot <= 0; 
            llc_dma_req_in.addr <= 0; 
            llc_dma_req_in.line <= 0; 
            llc_dma_req_in.req_id <= 0; 
            llc_dma_req_in.word_offset <= 0; 
            llc_dma_req_in.valid_words <= 0; 
        end else if (llc_dma_req_in_valid && llc_dma_req_in_ready) begin
            llc_dma_req_in.coh_msg <= llc_dma_req_in_i.coh_msg; 
            llc_dma_req_in.hprot <= llc_dma_req_in_i.hprot; 
            llc_dma_req_in.addr <= llc_dma_req_in_i.addr; 
            llc_dma_req_in.line <= llc_dma_req_in_i.line; 
            llc_dma_req_in.req_id <= llc_dma_req_in_i.req_id; 
            llc_dma_req_in.word_offset <= llc_dma_req_in_i.word_offset; 
            llc_dma_req_in.valid_words <= llc_dma_req_in_i.valid_words; 
        end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rsp_in.coh_msg <= 0; 
            llc_rsp_in.addr <= 0; 
            llc_rsp_in.line <= 0; 
            llc_rsp_in.req_id <= 0; 
        end else if (llc_rsp_in_valid && llc_rsp_in_ready) begin
            llc_rsp_in.coh_msg <= llc_rsp_in_i.coh_msg; 
            llc_rsp_in.addr <= llc_rsp_in_i.addr; 
            llc_rsp_in.line <= llc_rsp_in_i.line; 
            llc_rsp_in.req_id <= llc_rsp_in_i.req_id; 
         end
    end
    
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_mem_rsp.line <= 0; 
        end else if (llc_mem_rsp_valid && llc_mem_rsp_ready) begin
            llc_mem_rsp.line <= llc_mem_rsp_i.line; 
        end
    end

    logic rst_in;
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rst_tb <= 0; 
        end else if (llc_rst_tb_valid && llc_rst_tb_ready) begin
            llc_rst_tb <= llc_rst_tb_i; 
        end
    end
    assign rst_in = llc_rst_tb;
    
    logic rst_stall, clr_rst_stall, set_rst_stall;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state || set_rst_stall) begin 
            rst_stall <= 1'b1;
        end else if (clr_rst_stall) begin 
            rst_stall <= 1'b0;
        end
    end

    logic flush_stall, clr_flush_stall, set_flush_stall; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state || clr_flush_stall) begin 
            flush_stall <= 1'b0; 
        end else if (set_flush_stall) begin 
            flush_stall <= 1'b1; 
        end
    end

    logic req_stall, clr_req_stall, set_req_stall; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state ||clr_req_stall) begin 
            req_stall <= 1'b0; 
        end else if (set_req_stall) begin 
            req_stall <= 1'b1; 
        end
    end

    logic req_in_stalled_valid, clr_req_in_stalled_valid, set_req_in_stalled_valid;  
     always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state || clr_req_in_stalled_valid) begin 
            req_in_stalled_valid <= 1'b0; 
        end else if (set_req_in_stalled_valid) begin 
            req_in_stalled_valid <= 1'b1; 
        end
    end

    llc_set_t rst_flush_stalled_set;
    logic clr_rst_flush_stalled_set, incr_rst_flush_stalled_set;
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state || clr_rst_flush_stalled_set) begin 
            rst_flush_stalled_set <= 0; 
        end else if (incr_rst_flush_stalled_set && rd_set_en) begin 
            rst_flush_stalled_set <= rst_flush_stalled_set + 1; 
        end
    end
    
    line_addr_t dma_addr;
    logic update_dma_addr_from_req; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state) begin 
            dma_addr <= 0; 
        end else if (update_dma_addr_from_req) begin 
            dma_addr <= llc_dma_req_in.addr;
        end
    end

    logic recall_pending, clr_recall_pending, set_recall_pending;    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state || clr_recall_pending) begin 
            recall_pending <= 1'b0;
        end else if (set_recall_pending) begin 
            recall_pending <= 1'b1;
        end
    end

    logic dma_read_pending, clr_dma_read_pending, set_dma_read_pending;    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state || clr_dma_read_pending) begin 
            dma_read_pending <= 1'b0;
        end else if (set_dma_read_pending) begin 
            dma_read_pending <= 1'b1;
        end
    end

    logic dma_write_pending, clr_dma_write_pending, set_dma_write_pending;    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state ||clr_dma_write_pending) begin 
            dma_write_pending <= 1'b0;
        end else if (set_dma_write_pending) begin 
            dma_write_pending <= 1'b1;
        end
    end

    logic recall_valid, clr_recall_valid, set_recall_valid;    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state || clr_recall_valid) begin 
            recall_valid <= 1'b0;
        end else if (set_recall_valid) begin 
            recall_valid <= 1'b1;
        end
    end

    llc_set_t req_in_stalled_set; 
    llc_tag_t req_in_stalled_tag;
    logic update_req_in_stalled; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state) begin 
            req_in_stalled_set <= 0; 
            req_in_stalled_tag <= 0; 
        end else if (update_req_in_stalled) begin 
            req_in_stalled_set <= line_br.set; 
            req_in_stalled_tag <= line_br.tag;
        end
    end


    //update cache
    logic update_evict_way;

    logic wr_en, wr_data_dirty_bit, wr_en_evict_way;
    hprot_t wr_data_hprot;
    llc_state_t wr_data_state;
    sharers_t wr_data_sharers;
    llc_tag_t wr_data_tag;
    owner_t wr_data_owner; 
    llc_way_t wr_data_evict_way;
    line_t wr_data_line; 
    logic [(`NUM_PORTS-1):0] wr_rst_flush;
    always_comb begin 
        wr_rst_flush = {`NUM_PORTS{1'b0}};
        wr_data_state = 0;
        wr_data_dirty_bit = 1'b0; 
        wr_data_sharers = 0;
        wr_data_evict_way = 0;
        wr_data_tag = 0; 
        wr_data_line = 0;
        wr_data_hprot = 0; 
        wr_data_owner = 0; 
        wr_data_evict_way = 0; 
        wr_en = 1'b0; 
        wr_en_evict_way = 1'b0;
        if (update_en) begin 
            if (is_rst_to_resume) begin 
                wr_rst_flush  = {`NUM_PORTS{1'b1}};
                wr_data_state = `INVALID;
                wr_data_dirty_bit = 1'b0; 
                wr_data_sharers = 0; 
                wr_data_evict_way = 0; 
                wr_en_evict_way = 1'b1;
            end else if (is_flush_to_resume) begin 
                wr_data_state = `INVALID;
                wr_data_dirty_bit = 1'b0; 
                wr_data_sharers = 0; 
                wr_data_evict_way = 0; 
                for (int cur_way = 0; cur_way < `LLC_WAYS; cur_way++) begin 
                    if (states_buf[cur_way] == `VALID && hprots_buf[cur_way] == `DATA) begin 
                        wr_rst_flush[cur_way] = 1'b1; 
                    end
                end
            end else if (is_rsp_to_get || is_req_to_get || is_dma_req_to_get ||
                         is_dma_read_to_resume || is_dma_write_to_resume) begin 
                wr_en = 1'b1; 
                wr_data_tag = tags_buf[way]; 
                wr_data_state = states_buf[way];
                wr_data_line = lines_buf[way];  
                wr_data_hprot = hprots_buf[way]; 
                wr_data_owner = owners_buf[way]; 
                wr_data_sharers = sharers_buf[way]; 
                wr_data_dirty_bit = dirty_bits_buf[way];
                wr_data_evict_way = evict_way_buf;
                wr_en_evict_way = update_evict_way;
            end
        end
    end

endmodule
