// Copyright(c) 2011-2019 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

module pri_enc #(parameter WIDTH = 16, parameter LOG_WIDTH = 4) (
    input logic [WIDTH-1:0] in,
    output logic [LOG_WIDTH-1:0] out,
    output logic out_valid
    );
    
    logic [3:0] valid;
    logic [LOG_WIDTH-3:0] out1, out2, out3, out4; 
    
    pri_enc_quarter #(WIDTH/4, LOG_WIDTH-2) enc1(
        .in(in[WIDTH/4 -1:0]), 
        .out(out1),
        .out_valid(valid[0])
    );
   
    pri_enc_quarter #(WIDTH/4, LOG_WIDTH-2) enc2(
        .in(in[WIDTH/2 -1:WIDTH/4]), 
        .out(out2),
        .out_valid(valid[1])
    );
    
    pri_enc_quarter #(WIDTH/4, LOG_WIDTH-2) enc3(
        .in(in[3*WIDTH/4 -1:WIDTH/2]), 
        .out(out3),
        .out_valid(valid[2])
    );
 
    pri_enc_quarter #(WIDTH/4, LOG_WIDTH-2) enc4(
        .in(in[WIDTH-1:3*WIDTH/4]), 
        .out(out4),
        .out_valid(valid[3])
    );

    assign out_valid = |valid; 
    assign out = (valid[0] | valid[1]) ?
        (valid[0] ? {2'b00, out1} : {2'b01, out2})
        : (valid[2] ? {2'b10, out3} : {2'b11, out4});
   
endmodule 
    
