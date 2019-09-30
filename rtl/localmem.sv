`timescale 1ps / 1ps 
`include "cache_consts.svh"
`include "cache_types.svh"

// localmem.sv 
// llc memory 
// author: Joseph Zuckerman

module localmem ();  

input logic clk, rst; 

input llc_addr_t rd_addr_0, rd_addr_1, rd_addr_2, rd_addr_3, rd_addr_4, rd_addr_5, rd_addr_6, rd_addr_7, rd_addr_8, rd_addr_9, rd_addr_10, rd_addr_11, rd_addr_12, rd_addr_13, rd_addr_14, rd_addr_15;

input llc_addr_t wr_addr;
input line_t wr_data_line;
input llc_tag_t wr_data_tag;
input sharers_t wr_data_sharers; 
input owner_t wr_data_owner; 
input hprot_t wr_data_hprot; 
input logic wr_data_dirty_bits;  
input llc_way_t wr_data_evict_ways;  
input  llc_state_t wr_data_state;
input logic wr_en;

output line_t rd_data_line_0, rd_data_line_1, rd_data_line_2, rd_data_line_3, rd_data_line_4, rd_data_line_5, rd_data_line_6, rd_data_line_7, rd_data_line_8, rd_data_line_9, rd_data_line_10, rd_data_line_11, rd_data_line_12, rd_data_line_13, rd_data_line_14, rd_data_line_15;
output llc_tag_t rd_data_tag_0, rd_data_tag_1, rd_data_tag_2, rd_data_tag_3, rd_data_tag_4, rd_data_tag_5, rd_data_tag_6, rd_data_tag_7, rd_data_tag_8, rd_data_tag_9, rd_data_tag_10, rd_data_tag_11, rd_data_tag_12, rd_data_tag_13, rd_data_tag_14, rd_data_tag_15;
output sharers_t rd_data_sharers_0, rd_data_sharers_1, rd_data_sharers_2, rd_data_sharers_3, rd_data_sharers_4, rd_data_sharers_5, rd_data_sharers_6, rd_data_sharers_7, rd_data_sharers_8, rd_data_sharers_9, rd_data_sharers_10, rd_data_sharers_11, rd_data_sharers_12, rd_data_sharers_13, rd_data_sharers_14, rd_data_sharers_15;
output owner_t rd_data_owner_0, rd_data_owner_1, rd_data_owner_2, rd_data_owner_3, rd_data_owner_4, rd_data_owner_5, rd_data_owner_6, rd_data_owner_7, rd_data_owner_8, rd_data_owner_9, rd_data_owner_10, rd_data_owner_11, rd_data_owner_12, rd_data_owner_13, rd_data_owner_14, rd_data_owner_15;
output hprot_t rd_data_hprot_0, rd_data_hprot_1, rd_data_hprot_2, rd_data_hprot_3, rd_data_hprot_4, rd_data_hprot_5, rd_data_hprot_6, rd_data_hprot_7, rd_data_hprot_8, rd_data_hprot_9, rd_data_hprot_10, rd_data_hprot_11, rd_data_hprot_12, rd_data_hprot_13, rd_data_hprot_14, rd_data_hprot_15;
output logic rd_data_dirty_bit_0, rd_data_dirty_bit_1, rd_data_dirty_bit_2, rd_data_dirty_bit_3, rd_data_dirty_bit_4, rd_data_dirty_bit_5, rd_data_dirty_bit_6, rd_data_dirty_bit_7, rd_data_dirty_bit_8, rd_data_dirty_bit_9, rd_data_dirty_bit_10, rd_data_dirty_bit_11, rd_data_dirty_bit_12, rd_data_dirty_bit_13, rd_data_dirty_bit_14, rd_data_dirty_bit_15;
output llc_way_t rd_data_evict_way_0, rd_data_evict_way_1, rd_data_evict_way_2, rd_data_evict_way_3, rd_data_evict_way_4, rd_data_evict_way_5, rd_data_evict_way_6, rd_data_evict_way_7, rd_data_evict_way_8, rd_data_evict_way_9, rd_data_evict_way_10, rd_data_evict_way_11, rd_data_evict_way_12, rd_data_evict_way_13, rd_data_evict_way_14, rd_data_evict_way_15;
output llc_state_t rd_data_state_0, rd_data_state_1, rd_data_state_2, rd_data_state_3, rd_data_state_4, rd_data_state_5, rd_data_state_6, rd_data_state_7, rd_data_state_8, rd_data_state_9, rd_data_state_10, rd_data_state_11, rd_data_state_12, rd_data_state_13, rd_data_state_14, rd_data_state_15;


endmodule
