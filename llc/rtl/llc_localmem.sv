`timescale 1ps / 1ps 
`include "cache_consts.svh"
`include "cache_types.svh"

// llc_localmem.sv 
// llc memory 
// author: Joseph Zuckerman

module llc_localmem (clk, rst, set_in, way, rd_en,  wr_data_line, wr_data_tag, wr_data_sharers, wr_data_owner, wr_data_hprot, wr_data_dirty_bit, wr_data_evict_way, wr_data_state, wr_en, wr_rst_flush, wr_en_evict_way,rd_data_line, rd_data_tag, rd_data_sharers, rd_data_owner, rd_data_hprot, rd_data_dirty_bit, rd_data_evict_way, rd_data_state);  
    
    input logic clk, rst; 
    input logic rd_en;
    input llc_set_t set_in;
    input llc_way_t way;
    input line_t wr_data_line;
    input llc_tag_t wr_data_tag;
    input sharers_t wr_data_sharers; 
    input owner_t wr_data_owner; 
    input hprot_t wr_data_hprot; 
    input logic wr_data_dirty_bit;  
    input llc_way_t wr_data_evict_way;  
    input  llc_state_t wr_data_state;
    input logic wr_en;
    input logic [(`LLC_NUM_PORTS-1):0]wr_rst_flush;
    input logic wr_en_evict_way;

    output line_t rd_data_line[`LLC_NUM_PORTS];
    output llc_tag_t rd_data_tag[`LLC_NUM_PORTS];
    output sharers_t rd_data_sharers[`LLC_NUM_PORTS];
    output owner_t rd_data_owner[`LLC_NUM_PORTS];
    output hprot_t rd_data_hprot[`LLC_NUM_PORTS];
    output logic rd_data_dirty_bit[`LLC_NUM_PORTS];
    output llc_way_t rd_data_evict_way;
    output llc_state_t rd_data_state[`LLC_NUM_PORTS];

    owner_t rd_data_owner_tmp[`LLC_NUM_PORTS][`LLC_OWNER_BRAMS_PER_WAY];
    sharers_t rd_data_sharers_tmp[`LLC_NUM_PORTS][`LLC_SHARERS_BRAMS_PER_WAY]; 
    hprot_t rd_data_hprot_tmp[`LLC_NUM_PORTS][`LLC_HPROT_BRAMS_PER_WAY]; 
    logic rd_data_dirty_bit_tmp[`LLC_NUM_PORTS][`LLC_DIRTY_BIT_BRAMS_PER_WAY]; 
    
    //for following 2 use BRAM data width to aviod warnings, only copy relevant bits to output data 
    logic [3:0] rd_data_state_tmp[`LLC_NUM_PORTS][`LLC_STATE_BRAMS_PER_WAY]; 
    logic [31:0] rd_data_tag_tmp[`LLC_NUM_PORTS][`LLC_TAG_BRAMS_PER_WAY]; 
    llc_way_t rd_data_evict_way_tmp[`LLC_EVICT_WAY_BRAMS]; 
    line_t rd_data_line_tmp[`LLC_NUM_PORTS][`LLC_LINE_BRAMS_PER_WAY]; 
    
    //write enable decoder for ways 
    logic wr_en_port[0:(`LLC_NUM_PORTS-1)];
    always_comb begin 
        for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
            wr_en_port[i] = 1'b0; 
            if (wr_rst_flush[i]) begin 
                wr_en_port[i] = 1'b1;
            end else if (way == i) begin 
                wr_en_port[i] = wr_en; 
            end
        end
    end

    logic wr_en_owner_bank[`LLC_OWNER_BRAMS_PER_WAY];
    logic wr_en_sharers_bank[`LLC_SHARERS_BRAMS_PER_WAY];
    logic wr_en_hprot_bank[`LLC_HPROT_BRAMS_PER_WAY];
    logic wr_en_dirty_bit_bank[`LLC_DIRTY_BIT_BRAMS_PER_WAY];
    logic wr_en_state_bank[`LLC_STATE_BRAMS_PER_WAY];
    logic wr_en_tag_bank[`LLC_TAG_BRAMS_PER_WAY];
    logic wr_en_evict_way_bank[`LLC_EVICT_WAY_BRAMS];
    logic wr_en_line_bank[`LLC_LINE_BRAMS_PER_WAY];

    logic wr_rst_flush_or; 
    assign wr_rst_flush_or = |(wr_rst_flush); 

    //extend to the appropriate BRAM width 
    logic [3:0] wr_data_state_extended;
    assign wr_data_state_extended = {{(4-`LLC_STATE_BITS){1'b0}}, wr_data_state};
    logic [31:0] wr_data_tag_extended;
    assign wr_data_tag_extended = {{(4-`LLC_STATE_BITS){1'b0}}, wr_data_tag};

    generate 
        if (`LLC_OWNER_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_owner_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_OWNER_BRAMS_PER_WAY; j++) begin 
                    wr_en_owner_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS)]) begin 
                        wr_en_owner_bank[j] = wr_en;
                    end
                end
            end
        end
        
        if (`LLC_SHARERS_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_sharers_bank[0] = wr_en  | wr_rst_flush_or;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_SHARERS_BRAMS_PER_WAY; j++) begin 
                    wr_en_sharers_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS)]) begin 
                        wr_en_sharers_bank[j] = wr_en  | wr_rst_flush_or;
                    end
                end
            end
        end
        
        if (`LLC_HPROT_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_hprot_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_HPROT_BRAMS_PER_WAY; j++) begin 
                    wr_en_hprot_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS)]) begin 
                        wr_en_hprot_bank[j] = wr_en;
                    end
                end
            end
        end
        
        if (`LLC_DIRTY_BIT_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_dirty_bit_bank[0] = wr_en  | wr_rst_flush_or;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_DIRTY_BIT_BRAMS_PER_WAY; j++) begin 
                    wr_en_dirty_bit_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS)]) begin 
                        wr_en_dirty_bit_bank[j] = wr_en  | wr_rst_flush_or;
                    end
                end
            end
        end

        if (`LLC_STATE_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_state_bank[0] = wr_en  | wr_rst_flush_or;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_STATE_BRAMS_PER_WAY; j++) begin 
                    wr_en_state_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS)]) begin 
                        wr_en_state_bank[j] = wr_en  | wr_rst_flush_or;
                    end
                end
            end
        end

        if (`LLC_TAG_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_tag_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_TAG_BRAMS_PER_WAY; j++) begin 
                    wr_en_tag_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS)]) begin 
                        wr_en_tag_bank[j] = wr_en;
                    end
                end
            end
        end

        if (`LLC_EVICT_WAY_BRAMS == 1) begin 
            always_comb begin 
                wr_en_evict_way_bank[0] = wr_en_evict_way;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_EVICT_WAY_BRAMS; j++) begin 
                    wr_en_evict_way_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)]) begin 
                        wr_en_evict_way_bank[j] = wr_en_evict_way;
                    end
                end
            end
        end

        if (`LLC_LINE_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_line_bank[0] = wr_en;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `LLC_LINE_BRAMS_PER_WAY; j++) begin 
                    wr_en_line_bank[j] = 1'b0;
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS)]) begin 
                        wr_en_line_bank[j] = wr_en;
                    end
                end
            end
        end
    endgenerate

    genvar i, j, k; 
    generate 
        for (i = 0; i < (`LLC_NUM_PORTS / 2); i++) begin
            //owner memory
            //need 4 bits for owner - 4096x4 BRAM
            for (j = 0; j < `LLC_OWNER_BRAMS_PER_WAY; j++) begin
                if (`BRAM_4096_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_4096x4 owner_bram(
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_owner_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_owner), 
                        .Q1(rd_data_owner_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_owner_bank[j]), 
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                end else begin 
                    BRAM_4096x4 owner_bram(
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_owner), 
                        .Q0(rd_data_owner_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_owner_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_owner), 
                        .Q1(rd_data_owner_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_owner_bank[j]), 
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                end
            end
            //sharers memory 
            //need 16 bits for sharers - 1024x16 BRAM
            for (j = 0; j < `LLC_SHARERS_BRAMS_PER_WAY; j++) begin
                if (`BRAM_1024_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_1024x16 sharers_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_1024_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_sharers), 
                        .Q1(rd_data_sharers_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_sharers_bank[j]),
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                end else begin 
                    BRAM_1024x16 sharers_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_sharers), 
                        .Q0(rd_data_sharers_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_sharers_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_sharers), 
                        .Q1(rd_data_sharers_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_sharers_bank[j]),
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                end
            end
            //hprot memory 
            //need 1 bit for hport - 16384x1 BRAM
            for (j = 0; j < `LLC_HPROT_BRAMS_PER_WAY; j++) begin
                if (`BRAM_16384_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_16384x1 hprot_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_hprot), 
                        .Q0(rd_data_hprot_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_hprot), 
                        .Q1(rd_data_hprot_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                end else begin 
                    BRAM_16384x1 hprot_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_hprot), 
                        .Q0(rd_data_hprot_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_hprot), 
                        .Q1(rd_data_hprot_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end
            end
            //dirty bit memory 
            //need 1 dirty bit1 - 16384x1 BRAM
            for (j = 0; j < `LLC_DIRTY_BIT_BRAMS_PER_WAY; j++) begin
                if (`BRAM_16384_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_16384x1 dirty_bit_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_dirty_bit), 
                        .Q0(rd_data_dirty_bit_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_16384_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_dirty_bit), 
                        .Q1(rd_data_dirty_bit_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_dirty_bit_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end else begin 
                    BRAM_16384x1 dirty_bit_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_dirty_bit), 
                        .Q0(rd_data_dirty_bit_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_dirty_bit_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_dirty_bit), 
                        .Q1(rd_data_dirty_bit_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_dirty_bit_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end     
            end
            //state memory 
            //need 3 bits for state - 4096x4 BRAM
            for (j = 0; j < `LLC_STATE_BRAMS_PER_WAY; j++) begin
                 if (`BRAM_4096_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_4096x4 state_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_state_extended), 
                        .Q1(rd_data_state_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_state_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end else begin 
                    BRAM_4096x4 state_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_state_extended), 
                        .Q1(rd_data_state_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_state_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end 
            end
            //tag memory 
            //need ~15-20 bits for tag - 512x32 BRAM
            for (j = 0; j < `LLC_TAG_BRAMS_PER_WAY; j++) begin
                if (`BRAM_512_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_512x32 tag_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_512_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_tag_extended), 
                        .Q0(rd_data_tag_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_512_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_tag_extended), 
                        .Q1(rd_data_tag_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end else begin 
                    BRAM_512x32 tag_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_tag_extended), 
                        .Q0(rd_data_tag_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_tag_extended), 
                        .Q1(rd_data_tag_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end  
            end
            //line memory 
            //128 bits - using 512x32 BRAM, need 4 BRAMs per line 
            for (j = 0; j < `LLC_LINE_BRAMS_PER_WAY; j++) begin 
                for (k = 0; k < `LLC_BRAMS_PER_LINE; k++) begin 
                    if (`BRAM_512_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) + 1) begin 
                        BRAM_512x32 line_bram( 
                            .CLK(clk), 
                            .A0({{(`BRAM_512_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(32*(k+1)-1):(32*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(32*(k+1)-1):(32*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .A1({{(`BRAM_512_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D1(wr_data_line[(32*(k+1)-1):(32*k)]), 
                            .Q1(rd_data_line_tmp[2*i+1][j][(32*(k+1)-1):(32*k)]),
                            .WE1(wr_en_port[2*i+1] & wr_en_line_bank[j]),
                            .CE1(rd_en),
						    .WEM0(),
						    .WEM1());
                    end else begin 
                        BRAM_512x32 line_bram( 
                            .CLK(clk), 
                            .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(32*(k+1)-1):(32*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(32*(k+1)-1):(32*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .A1({1'b1, set_in[(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D1(wr_data_line[(32*(k+1)-1):(32*k)]), 
                            .Q1(rd_data_line_tmp[2*i+1][j][(32*(k+1)-1):(32*k)]),
                            .WE1(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                            .CE1(rd_en),
						    .WEM0(),
						    .WEM1());
                    end
                end 
            end
        end
            //evict ways memory 
            //need 2-5 bits for eviction  - 4096x4 BRAM
        for (j = 0; j < `LLC_EVICT_WAY_BRAMS; j++) begin
            if (`BRAM_4096_ADDR_WIDTH > (`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)) begin 
                BRAM_4096x4 evict_way_bram( 
                    .CLK(clk), 
                    .A0({{(`BRAM_4096_ADDR_WIDTH - (`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)){1'b0}}, set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):0]}),
                    .D0(wr_data_evict_way), 
                    .Q0(rd_data_evict_way_tmp[j]),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en),
                    .A1(12'b0),
                    .D1(4'b0), 
                    .Q1(), 
                    .WE1(1'b0),
                    .CE1(1'b0),
					.WEM0(),
					.WEM1());
            end else begin 
                BRAM_4096x4 evict_way_bram( 
                    .CLK(clk), 
                    .A0({1'b0, set_in[(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS - 1):0]}),
                    .D0(wr_data_evict_way), 
                    .Q0(rd_data_evict_way_tmp[j]),
                    .WE0(wr_en_evict_way_bank[j]),
                    .CE0(rd_en),
                    .A1(12'b0),
                    .D1(4'b0), 
                    .Q1(), 
                    .WE1(1'b0),
                    .CE1(1'b0),
					.WEM0(),
    				.WEM1());
            end 
        end
    endgenerate

    generate
        if (`LLC_OWNER_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_owner[i] = rd_data_owner_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `LLC_OWNER_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_OWNER_BRAM_INDEX_BITS)]) begin 
                            rd_data_owner[i] = rd_data_owner_tmp[i][j]; 
                        end
                    end 
                end
            end
        end 
         
        if (`LLC_SHARERS_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_sharers[i] = rd_data_sharers_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `LLC_SHARERS_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_SHARERS_BRAM_INDEX_BITS)]) begin 
                            rd_data_sharers[i] = rd_data_sharers_tmp[i][j]; 
                        end
                    end 
                end
            end
        end

        if (`LLC_HPROT_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_hprot[i] = rd_data_hprot_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `LLC_HPROT_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_HPROT_BRAM_INDEX_BITS)]) begin 
                            rd_data_hprot[i] = rd_data_hprot_tmp[i][j];
                        end
                    end 
                end
            end
        end 

       if (`LLC_DIRTY_BIT_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_dirty_bit[i] = rd_data_dirty_bit_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `LLC_DIRTY_BIT_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_DIRTY_BIT_BRAM_INDEX_BITS)]) begin 
                            rd_data_dirty_bit[i] = rd_data_dirty_bit_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_STATE_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_state[i] = rd_data_state_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `LLC_STATE_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_STATE_BRAM_INDEX_BITS)]) begin 
                            rd_data_state[i] = rd_data_state_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_TAG_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_tag[i] = rd_data_tag_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `LLC_TAG_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_TAG_BRAM_INDEX_BITS)]) begin 
                            rd_data_tag[i] = rd_data_tag_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_LINE_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    rd_data_line[i] = rd_data_line_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `LLC_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `LLC_LINE_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_LINE_BRAM_INDEX_BITS)]) begin 
                            rd_data_line[i] = rd_data_line_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`LLC_EVICT_WAY_BRAMS == 1) begin 
            always_comb begin
                rd_data_evict_way = rd_data_evict_way_tmp[0]; 
            end
        end else begin 
            always_comb begin
                for (int j = 0; j < `LLC_EVICT_WAY_BRAMS; j++) begin 
                    if (j == set_in[(`LLC_SET_BITS-1):(`LLC_SET_BITS - `LLC_EVICT_WAY_BRAM_INDEX_BITS)]) begin 
                        rd_data_evict_way = rd_data_evict_way_tmp[j];
                    end
                end 
            end
        end 
    endgenerate

endmodule
