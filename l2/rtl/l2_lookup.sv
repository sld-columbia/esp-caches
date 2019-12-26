`timescale 1ps / 1ps
`include "cache_consts.svh"
`include "cache_types.svh" 

// l2_lookup.sv

module l2_lookup(clk, rst, lookup_mode, lookup_en, tags_buf, states_buf, line_br, addr_br, lookup_en, evict_way_buf, way_hit, empty_way, tag_hit, empty_way_found, tag_hit_next, empty_way_found_next);

    input logic clk, rst; 
    input logic lookup_mode; 
    input l2_tag_t tags_buf[`L2_WAYS];
    input state_t states_buf[`L2_WAYS];
    line_breakdown_l2_t.in line_br; 
    addr_breakdown_t addr_br; 
    input logic lookup_en; 
    input l2_way_t evict_way_buf; 

    output l2_way_t way_hit, empty_way;
    output logic tag_hit, empty_way_found; 
    output logic tag_hit_next, empty_way_found_next; 

    l2_way_t way_hit_next, empty_way_next; 

    always_comb begin 
        way_hit_next = 0;
        tag_hit_next = 1'b0; 
        empty_way_next = 0; 
        empty_way_found_next = 1'b0; 
        if (lookup_en) begin 
            case(lookup_mode) 
                `L2_LOOKUP : begin 
                    for (int i = `L2_WAYS-1; i >= 0; i--) begin
                        if (tags_buf[i] == addr_br.tag && states_buf[i] != `INVALID) begin 
                            tag_hit_next = 1'b1; 
                            way_hit_next = i; 
                        end
                        if (states_buf[i] == `INVALID) begin 
                            empty_way_found_next = 1'b1; 
                            empty_way_next = i; 
                        end
                    end
                end
                `L2_LOOKUP_FWD : begin 
                    for (int i = `L2_WAYS-1; i >= 0; i--) begin 
                        if (tags_buf[i] == line_br.tag && states_buf[i]  != `INVALID) begin 
                            tag_hit_next = 1'b1; 
                            way_hit_next = i;
                        end
                    end
                end
            endcase
        end
    end 
    
    always_ff @(posedge clk or negedge rst) begin 
        if (!rst) begin 
            way_hit <= 0;
            tag_hit <= 1'b0; 
            empty_way <= 0; 
            empty_way_found <= 1'b0; 
        end else if (lookup_en) begin 
            way_hit <= way_hit_next;
            tag_hit <= tag_hit_next; 
            empty_way <= empty_way_next; 
            empty_way_found <= empty_way_found_next;  
        end
    end

endmodule
