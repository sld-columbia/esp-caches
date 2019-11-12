`timescale 1ps / 1ps 
`include "cache_consts.svh"
`include "cache_types.svh"

// l2_localmem.sv 
// llc memory 
// author: Joseph Zuckerman

module l2_localmem (clk, rst, set_in, way, rd_en, wr_data_line, wr_data_tag, wr_data_hprot, wr_data_evict_way, wr_data_state, wr_en_state, wr_en_line, wr_en_tag, wr_en_hprot, wr_rst, wr_en_evict_way,rd_data_line, rd_data_tag, rd_data_hprot, rd_data_evict_way, rd_data_state);  
    
    input logic clk, rst; 
    input logic rd_en;
    input l2_set_t set_in;
    input l2_way_t way;
    input line_t wr_data_line;
    input l2_tag_t wr_data_tag;
    input hprot_t wr_data_hprot; 
    input l2_way_t wr_data_evict_way;  
    input state_t wr_data_state;
    input logic wr_en_line, wr_en_state, wr_en_tag, wr_en_hprot, wr_en_evict_way;
    input logic wr_rst;

    output line_t rd_data_line[`L2_NUM_PORTS];
    output l2_tag_t rd_data_tag[`L2_NUM_PORTS];
    output hprot_t rd_data_hprot[`L2_NUM_PORTS];
    output l2_way_t rd_data_evict_way;
    output state_t rd_data_state[`L2_NUM_PORTS];

    
    //for following 2 use BRAM data width to aviod warnings, only copy relevant bits to output data 
    state_t rd_data_state_tmp[`L2_NUM_PORTS][`L2_STATE_BRAMS_PER_WAY]; 
    logic [31:0] rd_data_tag_tmp[`L2_NUM_PORTS][`L2_TAG_BRAMS_PER_WAY]; 
    l2_way_t rd_data_evict_way_tmp[`L2_EVICT_WAY_BRAMS]; 
    line_t rd_data_line_tmp[`L2_NUM_PORTS][`L2_LINE_BRAMS_PER_WAY]; 
    hprot_t rd_data_hprot_tmp[`L2_NUM_PORTS][`L2_HPROT_BRAMS_PER_WAY]; 
    
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

    logic wr_en_hprot_bank[`L2_HPROT_BRAMS_PER_WAY];
    logic wr_en_state_bank[`L2_STATE_BRAMS_PER_WAY];
    logic wr_en_tag_bank[`L2_TAG_BRAMS_PER_WAY];
    logic wr_en_evict_way_bank[`L2_EVICT_WAY_BRAMS];
    logic wr_en_line_bank[`L2_LINE_BRAMS_PER_WAY];

    //extend to the appropriate BRAM width 
    logic [3:0] wr_data_state_extended;
    assign wr_data_state_extended = {{(4-`STABLE_STATE_BITS){1'b0}}, wr_data_state};
    logic [31:0] wr_data_tag_extended;
    assign wr_data_tag_extended = {{(4-`STABLE_STATE_BITS){1'b0}}, wr_data_tag};

    generate 
        if (`L2_HPROT_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_hprot_bank[0] = wr_en_hprot;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `L2_HPROT_BRAMS_PER_WAY; j++) begin 
                    wr_en_hprot_bank[j] = 1'b0;
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS)]) begin 
                        wr_en_hprot_bank[j] = wr_en_hprot;
                    end
                end
            end
        end
        
        if (`L2_STATE_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_state_bank[0] = wr_en_state  | wr_rst;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `L2_STATE_BRAMS_PER_WAY; j++) begin 
                    wr_en_state_bank[j] = 1'b0;
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS)]) begin 
                        wr_en_state_bank[j] = wr_en_state  | wr_rst;
                    end
                end
            end
        end

        if (`L2_TAG_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_tag_bank[0] = wr_en_tag;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `L2_TAG_BRAMS_PER_WAY; j++) begin 
                    wr_en_tag_bank[j] = 1'b0;
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS)]) begin 
                        wr_en_tag_bank[j] = wr_en_tag;
                    end
                end
            end
        end

        if (`L2_EVICT_WAY_BRAMS == 1) begin 
            always_comb begin 
                wr_en_evict_way_bank[0] = wr_en_evict_way;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `L2_EVICT_WAY_BRAMS; j++) begin 
                    wr_en_evict_way_bank[j] = 1'b0;
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_EVICT_WAY_BRAM_INDEX_BITS)]) begin 
                        wr_en_evict_way_bank[j] = wr_en_evict_way;
                    end
                end
            end
        end

        if (`L2_LINE_BRAMS_PER_WAY == 1) begin 
            always_comb begin 
                wr_en_line_bank[0] = wr_en_line;
            end
        end else begin 
            always_comb begin 
                for (int j = 0; j < `L2_LINE_BRAMS_PER_WAY; j++) begin 
                    wr_en_line_bank[j] = 1'b0;
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS)]) begin 
                        wr_en_line_bank[j] = wr_en_line;
                    end
                end
            end
        end
    endgenerate

    genvar i, j, k; 
    generate 
        for (i = 0; i < (`L2_NUM_PORTS / 2); i++) begin
            //hprot memory 
            //need 1 bit for hprot - 16384x1 BRAM
            for (j = 0; j < `L2_HPROT_BRAMS_PER_WAY; j++) begin
                if (`BRAM_16384_ADDR_WIDTH > (`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_16384x1 hprot_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_16384_ADDR_WIDTH - (`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_hprot), 
                        .Q0(rd_data_hprot_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_16384_ADDR_WIDTH - (`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_hprot), 
                        .Q1(rd_data_hprot_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE1(rd_en),
                        .WEM0(), 
                        .WEM1());
                end else begin 
                    BRAM_16384x1 hprot_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_hprot), 
                        .Q0(rd_data_hprot_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_hprot_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_hprot), 
                        .Q1(rd_data_hprot_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_hprot_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end
            end
            //state memory 
            //need 3 bits for state - 4096x4 BRAM
            for (j = 0; j < `L2_STATE_BRAMS_PER_WAY; j++) begin
                 if (`BRAM_8192_ADDR_WIDTH > (`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_8192x2 state_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_8192_ADDR_WIDTH - (`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_8192_ADDR_WIDTH - (`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_state_extended), 
                        .Q1(rd_data_state_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_state_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end else begin 
                    BRAM_8192x4 state_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_state_extended), 
                        .Q0(rd_data_state_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_state_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS - 1):0]}),
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
            for (j = 0; j < `L2_TAG_BRAMS_PER_WAY; j++) begin
                if (`BRAM_512_ADDR_WIDTH > (`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS) + 1) begin 
                    BRAM_512x32 tag_bram( 
                        .CLK(clk), 
                        .A0({{(`BRAM_512_ADDR_WIDTH - (`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_tag_extended), 
                        .Q0(rd_data_tag_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                        .CE0(rd_en),
                        .A1({{(`BRAM_512_ADDR_WIDTH - (`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS - 1):0]}),
                        .D1(wr_data_tag_extended), 
                        .Q1(rd_data_tag_tmp[2*i+1][j]), 
                        .WE1(wr_en_port[2*i+1] & wr_en_tag_bank[j]),
                        .CE1(rd_en),
						.WEM0(),
						.WEM1());
                end else begin 
                    BRAM_512x32 tag_bram( 
                        .CLK(clk), 
                        .A0({1'b0, set_in[(`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS - 1):0]}),
                        .D0(wr_data_tag_extended), 
                        .Q0(rd_data_tag_tmp[2*i][j]),
                        .WE0(wr_en_port[2*i] & wr_en_tag_bank[j]),
                        .CE0(rd_en),
                        .A1({1'b1, set_in[(`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS - 1):0]}),
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
            for (j = 0; j < `L2_LINE_BRAMS_PER_WAY; j++) begin 
                for (k = 0; k < `L2_BRAMS_PER_LINE; k++) begin 
                    if (`BRAM_512_ADDR_WIDTH > (`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS) + 1) begin 
                        BRAM_512x32 line_bram( 
                            .CLK(clk), 
                            .A0({{(`BRAM_512_ADDR_WIDTH - (`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b0, set_in[(`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(32*(k+1)-1):(32*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(32*(k+1)-1):(32*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .A1({{(`BRAM_512_ADDR_WIDTH - (`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS) - 1){1'b0}} , 1'b1, set_in[(`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D1(wr_data_line[(32*(k+1)-1):(32*k)]), 
                            .Q1(rd_data_line_tmp[2*i+1][j][(32*(k+1)-1):(32*k)]),
                            .WE1(wr_en_port[2*i+1] & wr_en_line_bank[j]),
                            .CE1(rd_en),
						    .WEM0(),
						    .WEM1());
                    end else begin 
                        BRAM_512x32 line_bram( 
                            .CLK(clk), 
                            .A0({1'b0, set_in[(`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS - 1):0]}),
                            .D0(wr_data_line[(32*(k+1)-1):(32*k)]), 
                            .Q0(rd_data_line_tmp[2*i][j][(32*(k+1)-1):(32*k)]),
                            .WE0(wr_en_port[2*i] & wr_en_line_bank[j]),
                            .CE0(rd_en),
                            .A1({1'b1, set_in[(`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS - 1):0]}),
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
        for (j = 0; j < `L2_EVICT_WAY_BRAMS; j++) begin
            if (`BRAM_4096_ADDR_WIDTH > (`L2_SET_BITS - `L2_EVICT_WAY_BRAM_INDEX_BITS)) begin 
                BRAM_4096x4 evict_way_bram( 
                    .CLK(clk), 
                    .A0({{(`BRAM_4096_ADDR_WIDTH - (`L2_SET_BITS - `L2_EVICT_WAY_BRAM_INDEX_BITS)){1'b0}}, set_in[(`L2_SET_BITS - `L2_EVICT_WAY_BRAM_INDEX_BITS - 1):0]}),
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
                    .A0({1'b0, set_in[(`L2_SET_BITS - `L2_EVICT_WAY_BRAM_INDEX_BITS - 1):0]}),
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
        
        if (`L2_HPROT_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    rd_data_hprot[i] = rd_data_hprot_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `L2_HPROT_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_HPROT_BRAM_INDEX_BITS)]) begin 
                            rd_data_hprot[i] = rd_data_hprot_tmp[i][j];
                        end
                    end 
                end
            end
        end 
               
        if (`L2_STATE_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    rd_data_state[i] = rd_data_state_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `L2_STATE_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_STATE_BRAM_INDEX_BITS)]) begin 
                            rd_data_state[i] = rd_data_state_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`L2_TAG_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    rd_data_tag[i] = rd_data_tag_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `L2_TAG_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_TAG_BRAM_INDEX_BITS)]) begin 
                            rd_data_tag[i] = rd_data_tag_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`L2_LINE_BRAMS_PER_WAY == 1) begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    rd_data_line[i] = rd_data_line_tmp[i][0]; 
                end
            end
        end else begin 
            always_comb begin
                for (int i = 0; i < `L2_NUM_PORTS; i++) begin 
                    for (int j = 0; j < `L2_LINE_BRAMS_PER_WAY; j++) begin 
                        if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_LINE_BRAM_INDEX_BITS)]) begin 
                            rd_data_line[i] = rd_data_line_tmp[i][j];
                        end
                    end 
                end
            end
        end 
        
        if (`L2_EVICT_WAY_BRAMS == 1) begin 
            always_comb begin
                rd_data_evict_way = rd_data_evict_way_tmp[0]; 
            end
        end else begin 
            always_comb begin
                for (int j = 0; j < `L2_EVICT_WAY_BRAMS; j++) begin 
                    if (j == set_in[(`L2_SET_BITS-1):(`L2_SET_BITS - `L2_EVICT_WAY_BRAM_INDEX_BITS)]) begin 
                        rd_data_evict_way = rd_data_evict_way_tmp[j];
                    end
                end 
            end
        end 
    endgenerate

endmodule
