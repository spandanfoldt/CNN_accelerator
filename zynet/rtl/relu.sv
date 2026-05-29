`timescale 1ns/1ps
module relu #(parameter dataWidth = 16, weightIntWidth = 4)
    (input logic clk,
     input logic [2*dataWidth-1:0] in,
     output logic [dataWidth-1:0] out);
    
    always_ff @(posedge clk) begin
        if($signed(in) >= 0) begin
            if(|in[2*dataWidth-1:weightIntWidth+1])
                out <= {1'b0, {(dataWidth-1){1'b1}}};
            else
                out <= in[2*dataWidth-1-weightIntWidth-:dataWidth];
        end
        
        else
            out <= 0;
    end
endmodule