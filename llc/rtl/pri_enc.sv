// Copyright(c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

module pri_enc #(parameter WIDTH = 16, parameter LOG_WIDTH = 4) (
    input logic [WIDTH-1:0] in,
    output logic [LOG_WIDTH-1:0] out,
    output logic out_valid
    );
    
    logic [1:0] valid;
    logic [LOG_WIDTH-2:0] out1, out2;

    pri_enc_half #(WIDTH/2, LOG_WIDTH-1) enc1(
        .in(in[WIDTH/2 -1:0]), 
        .out(out1),
        .out_valid(valid[0])
    );
   
    pri_enc_half #(WIDTH/2, LOG_WIDTH-1) enc2(
        .in(in[WIDTH-1:WIDTH/2]), 
        .out(out2),
        .out_valid(valid[1])
    );
    
    assign out_valid = |valid; 
    assign out = valid[0] ? {1'b0, out1} : {1'b1, out2};
   
endmodule 
    
