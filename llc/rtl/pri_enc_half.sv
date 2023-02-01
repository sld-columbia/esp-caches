// Copyright(c) 2011-2023 Columbia University, System Level Design Group
// SPDC-License-Identifier: Apache-2.0

module pri_enc_half #(parameter WIDTH = 8, parameter LOG_WIDTH = 3)(
    input logic [WIDTH-1:0] in, 
    output logic [LOG_WIDTH-1:0] out, 
    output logic out_valid
    );

    always_comb begin 
        out = 0;
        for (int i = WIDTH - 1; i >=0; i--) begin 
            if (in[i]) begin 
                out = i; 
            end
        end
    end

    assign out_valid = |(in);

endmodule    
