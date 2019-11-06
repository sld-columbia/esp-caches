`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh"

// llc.sv
// Author: Joseph Zuckerman
// Top level LLC module 

module llc_core(clk, rst, llc_req_in_i, llc_req_in_valid, llc_req_in_ready, llc_dma_req_in_i, llc_dma_req_in_valid, llc_dma_req_in_ready, llc_rsp_in_i, llc_rsp_in_valid, llc_rsp_in_ready, llc_mem_rsp_i, llc_mem_rsp_valid, llc_mem_rsp_ready, llc_rst_tb_i, llc_rst_tb_valid, llc_rst_tb_ready, llc_rsp_out_ready, llc_rsp_out_valid, llc_rsp_out, llc_dma_rsp_out_ready, llc_dma_rsp_out_valid, llc_dma_rsp_out, llc_fwd_out_ready, llc_fwd_out_valid, llc_fwd_out, llc_mem_req_ready,  llc_mem_req_valid, llc_mem_req, llc_rst_tb_done_ready, llc_rst_tb_done_valid, llc_rst_tb_done
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
    localparam READ_SET = 3'b001;
    localparam READ_MEM = 3'b011;
    localparam LOOKUP = 3'b010; 
    localparam PROCESS = 3'b110; 
    localparam UPDATE = 3'b100; 

    logic[2:0] state, next_state; 
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            state <= DECODE; 
        end else begin 
            state <= next_state; 
        end
    end 
    
    
    logic process_done, idle; 
    always_comb begin 
        next_state = state; 
        case(state) 
            DECODE : 
                if (!idle) begin 
                    next_state = READ_MEM;
                end 
            READ_MEM : 
                next_state = LOOKUP; 
            LOOKUP : 
                next_state = PROCESS;
            PROCESS :   
                if (process_done) begin 
                    next_state = UPDATE; 
                end
            UPDATE :   
                next_state = DECODE; 
            default : 
                next_state = DECODE;
       endcase
    end


    logic decode_en, rd_set_en, rd_mem_en, update_en, process_en, lookup_en; 
    assign decode_en = (state == DECODE);
    assign rd_set_en = decode_en;
    assign rd_mem_en = (state == READ_MEM);
    assign lookup_en = (state == LOOKUP); 
    assign process_en = (state == PROCESS); 
    assign update_en = (state == UPDATE); 
    
    line_breakdown_llc_t line_br();
    
    //INTERNAL REGS
    
    //wires
    logic rst_stall, clr_rst_stall;
    logic flush_stall, clr_flush_stall, set_flush_stall; 
    logic req_stall, clr_req_stall_decoder, clr_req_stall_process, set_req_stall; 
    logic req_in_stalled_valid, clr_req_in_stalled_valid, set_req_in_stalled_valid;  
    llc_set_t rst_flush_stalled_set;
    logic clr_rst_flush_stalled_set, incr_rst_flush_stalled_set;
    addr_t dma_addr;
    logic update_dma_addr_from_req, incr_dma_addr; 
    logic recall_pending, clr_recall_pending, set_recall_pending;    
    logic dma_read_pending, clr_dma_read_pending, set_dma_read_pending;    
    logic dma_write_pending, clr_dma_write_pending, set_dma_write_pending;    
    logic recall_valid, clr_recall_valid, set_recall_valid;    
    logic is_dma_read_to_resume, clr_is_dma_read_to_resume; 
    logic set_is_dma_read_to_resume_decoder, set_is_dma_read_to_resume_process; 
    logic is_dma_write_to_resume, clr_is_dma_write_to_resume; 
    logic set_is_dma_write_to_resume_decoder, set_is_dma_write_to_resume_process; 
    llc_set_t req_in_stalled_set; 
    llc_tag_t req_in_stalled_tag;
    logic update_req_in_stalled; 
    logic update_evict_way, set_update_evict_way;
    line_addr_t addr_evict;
    
    //instance
    regs regs_u(.*); 

    //DECODE

    //wires
    logic is_rst_to_get, is_req_to_get, is_dma_req_to_get, is_rsp_to_get, do_get_req, do_get_dma_req, is_flush_to_resume, is_rst_to_resume, is_rst_to_get_next, is_rsp_to_get_next, look; 
    line_addr_t req_in_addr, rsp_in_addr, dma_req_in_addr; 
    logic llc_req_in_valid_tmp, llc_dma_req_in_valid_tmp, llc_rsp_in_valid_tmp; 
    llc_req_in_t llc_req_in_tmp(); 
    llc_req_in_t llc_dma_req_in_tmp(); 
    llc_rsp_in_t llc_rsp_in_tmp(); 

    assign req_in_addr = llc_req_in_valid_tmp ? llc_req_in_tmp.addr : llc_req_in_i.addr;
    assign rsp_in_addr = llc_rsp_in_valid_tmp ? llc_rsp_in_tmp.addr : llc_rsp_in_i.addr;
    assign dma_req_in_addr = llc_dma_req_in_valid_tmp ? llc_dma_req_in_tmp.addr : llc_dma_req_in_i.addr; 
    llc_set_t set, set_next, set_in;     
 
    //instance
    input_decoder input_decoder_u(.*);
    
    logic llc_req_in_ready_int, llc_dma_req_in_ready_int, llc_rsp_in_ready_int, llc_rst_tb_ready_int, llc_mem_rsp_ready_int;
    logic llc_req_in_valid_int, llc_dma_req_in_valid_int, llc_rsp_in_valid_int, llc_rst_tb_valid_int, llc_mem_rsp_valid_int;  
    //assign outputs
    assign llc_rsp_in_ready_int = decode_en & is_rsp_to_get_next; 
    assign llc_rst_tb_ready_int = decode_en & is_rst_to_get_next; 
    assign llc_req_in_ready_int = decode_en & do_get_req; 
    assign llc_dma_req_in_ready_int = decode_en & do_get_dma_req;
    assign set_in = rd_set_en ? set_next : set; 
    
    llc_req_in_t llc_req_in_next();
    llc_req_in_t llc_dma_req_in_next(); 
    llc_rsp_in_t llc_rsp_in_next(); 
    llc_mem_rsp_t llc_mem_rsp_next(); 
    logic llc_rst_tb_next; 
    //READ INPUTS FROM INTERFACES
    interfaces interfaces_u (.*); 

    //llc req in
    logic update_req_in_from_stalled;
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
        end else if (llc_req_in_valid_int && llc_req_in_ready_int) begin
            llc_req_in.coh_msg <= llc_req_in_next.coh_msg; 
            llc_req_in.hprot <= llc_req_in_next.hprot; 
            llc_req_in.addr <= llc_req_in_next.addr; 
            llc_req_in.line <= llc_req_in_next.line; 
            llc_req_in.req_id <= llc_req_in_next.req_id; 
            llc_req_in.word_offset <= llc_req_in_next.word_offset; 
            llc_req_in.valid_words <= llc_req_in_next.valid_words; 
        end
    end

    //req in stalled
    logic set_req_in_stalled; 
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            req_in_stalled.coh_msg <= 0; 
            req_in_stalled.hprot <= 0; 
            req_in_stalled.addr <= 0; 
            req_in_stalled.line <= 0; 
            req_in_stalled.req_id <= 0; 
            req_in_stalled.word_offset <= 0; 
            req_in_stalled.valid_words <= 0; 
       end else if (set_req_in_stalled) begin
            req_in_stalled.coh_msg <= llc_req_in.coh_msg; 
            req_in_stalled.hprot <= llc_req_in.hprot; 
            req_in_stalled.addr <= llc_req_in.addr; 
            req_in_stalled.line <= llc_req_in.line; 
            req_in_stalled.req_id <= llc_req_in.req_id; 
            req_in_stalled.word_offset <= llc_req_in.word_offset; 
            req_in_stalled.valid_words <= llc_req_in.valid_words; 
        end 
    end

    //dma req in 
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_dma_req_in.coh_msg <= 0; 
            llc_dma_req_in.hprot <= 0; 
            llc_dma_req_in.addr <= 0; 
            llc_dma_req_in.line <= 0; 
            llc_dma_req_in.req_id <= 0; 
            llc_dma_req_in.word_offset <= 0; 
            llc_dma_req_in.valid_words <= 0; 
        end else if (llc_dma_req_in_valid_int && llc_dma_req_in_ready_int) begin
            llc_dma_req_in.coh_msg <= llc_dma_req_in_next.coh_msg; 
            llc_dma_req_in.hprot <= llc_dma_req_in_next.hprot; 
            llc_dma_req_in.addr <= llc_dma_req_in_next.addr; 
            llc_dma_req_in.line <= llc_dma_req_in_next.line; 
            llc_dma_req_in.req_id <= llc_dma_req_in_next.req_id; 
            llc_dma_req_in.word_offset <= llc_dma_req_in_next.word_offset; 
            llc_dma_req_in.valid_words <= llc_dma_req_in_next.valid_words; 
        end
    end
    
    //llc rsp in 
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rsp_in.coh_msg <= 0; 
            llc_rsp_in.addr <= 0; 
            llc_rsp_in.line <= 0; 
            llc_rsp_in.req_id <= 0; 
        end else if (llc_rsp_in_valid_int && llc_rsp_in_ready_int) begin
            llc_rsp_in.coh_msg <= llc_rsp_in_next.coh_msg; 
            llc_rsp_in.addr <= llc_rsp_in_next.addr; 
            llc_rsp_in.line <= llc_rsp_in_next.line; 
            llc_rsp_in.req_id <= llc_rsp_in_next.req_id; 
         end
    end
    
    //mem rsp
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_mem_rsp.line <= 0; 
        end else if (llc_mem_rsp_valid_int && llc_mem_rsp_ready_int) begin
            llc_mem_rsp.line <= llc_mem_rsp_next.line; 
        end
    end

    //rst tb 
    logic rst_in;
    always_ff @(posedge clk or negedge rst) begin 
        if(!rst) begin 
            llc_rst_tb <= 0; 
        end else if (llc_rst_tb_valid_int && llc_rst_tb_ready_int) begin
            llc_rst_tb <= llc_rst_tb_next; 
        end
    end
    assign rst_in = llc_rst_tb;
     
    //MEMORY
    
    //read data wires
    line_t rd_data_line[`LLC_WAYS];
    llc_tag_t rd_data_tag[`LLC_WAYS];
    sharers_t rd_data_sharers[`LLC_WAYS];
    owner_t rd_data_owner[`LLC_WAYS];
    hprot_t rd_data_hprot[`LLC_WAYS];
    logic rd_data_dirty_bit[`LLC_WAYS];
    llc_way_t rd_data_evict_way; 
    llc_state_t rd_data_state[`LLC_WAYS];
    
    //write enables
    logic wr_en_lines_buf, wr_en_tags_buf, wr_en_sharers_buf, wr_en_owners_buf, wr_en_hprots_buf, wr_en_dirty_bits_buf, wr_en_states_buf;

    //write data
    llc_way_t way, way_next;
    line_t lines_buf_wr_data;
    llc_tag_t tags_buf_wr_data;
    sharers_t sharers_buf_wr_data;
    owner_t owners_buf_wr_data;
    hprot_t hprots_buf_wr_data;
    logic dirty_bits_buf_wr_data;
    llc_state_t states_buf_wr_data;
    
    logic rd_en;
    assign rd_en = !idle; 
   
    //instance
    localmem localmem_u(.*);

    //BUFFERS
    llc_way_t evict_way_buf; 
    line_t lines_buf[`LLC_WAYS];
    llc_tag_t tags_buf[`LLC_WAYS];
    sharers_t sharers_buf[`LLC_WAYS];
    owner_t owners_buf[`LLC_WAYS];
    hprot_t hprots_buf[`LLC_WAYS];
    logic dirty_bits_buf[`LLC_WAYS];
    llc_state_t states_buf[`LLC_WAYS];
     
    //read into buffers
    logic incr_evict_way_buf; 
    logic rst_state;
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst || rst_state) begin 
            evict_way_buf <= 0; 
        end else if (rd_mem_en & look) begin 
            evict_way_buf <= rd_data_evict_way;
        end else if (incr_evict_way_buf) begin 
            evict_way_buf <= evict_way_buf + 1; 
        end
        for (int i = 0; i < `LLC_WAYS; i++) begin 
            if (!rst || rst_state) begin
                lines_buf[i] <= 0; 
            end else if (rd_mem_en & look) begin 
                lines_buf[i] <= rd_data_line[i];
            end else if (llc_mem_rsp_ready && llc_mem_rsp_valid && (way == i)) begin 
                lines_buf[i] <= llc_mem_rsp_i.line;
            end else if (wr_en_lines_buf && (way == i)) begin 
                lines_buf[i] <= lines_buf_wr_data;
            end
   
            if (!rst || rst_state) begin 
                tags_buf[i] <= 0;
            end else if (rd_mem_en & look) begin  
                tags_buf[i] <= rd_data_tag[i]; 
            end else if (wr_en_tags_buf && (way == i)) begin 
                tags_buf[i] <= tags_buf_wr_data;
            end
     
           if (!rst || rst_state) begin 
                sharers_buf[i] <= 0;
            end else if (rd_mem_en & look) begin 
                sharers_buf[i] <= rd_data_sharers[i]; 
            end else if (wr_en_sharers_buf && (way == i)) begin 
                sharers_buf[i] <= sharers_buf_wr_data;
            end

           if (!rst || rst_state) begin 
                owners_buf[i] <= 0;
            end else if (rd_mem_en & look) begin 
                owners_buf[i] <= rd_data_owner[i]; 
            end else if (wr_en_owners_buf && (way == i)) begin 
                owners_buf[i] <= owners_buf_wr_data;
            end

            if (!rst || rst_state) begin 
                hprots_buf[i] <= 0;
            end else if (rd_mem_en & look) begin
                hprots_buf[i] <= rd_data_hprot[i]; 
            end else if (wr_en_hprots_buf && (way == i)) begin 
                hprots_buf[i] <= hprots_buf_wr_data;
            end
            
            if (!rst || rst_state) begin 
                dirty_bits_buf[i] <= 0;
            end else if (rd_mem_en & look) begin
                dirty_bits_buf[i] <= rd_data_dirty_bit[i];
            end else if (wr_en_dirty_bits_buf && (way == i)) begin 
                dirty_bits_buf[i] <= dirty_bits_buf_wr_data;
            end
            
            if (!rst || rst_state) begin 
                states_buf[i] <= 0;
            end else if (rd_mem_en & look) begin
                states_buf[i] <= rd_data_state[i]; 
            end else if (wr_en_states_buf && (way == i)) begin 
                states_buf[i] <= states_buf_wr_data;
            end
       end
    end
    
    //LOOKUP 

    //wires
    logic evict;
    llc_tag_t tag; 
    assign tag = line_br.tag;
 
    //instance
    lookup_way lookup_way_u(.*); 
   
    //PROCESS 

    //instance
    process_request process_request_u(.*);
    
    //UPDATE 

    //wires
    logic wr_en, wr_data_dirty_bit, wr_en_evict_way;
    hprot_t wr_data_hprot;
    llc_state_t wr_data_state;
    sharers_t wr_data_sharers;
    llc_tag_t wr_data_tag;
    owner_t wr_data_owner; 
    llc_way_t wr_data_evict_way;
    line_t wr_data_line; 
    logic [(`NUM_PORTS-1):0] wr_rst_flush;
    
    //instance
    update update_u (.*);
    
endmodule
