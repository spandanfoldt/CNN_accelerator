`timescale 1ns/1ps

module Sig_ROM #(parameter inWidth = 10, dataWidth = 16)
    (input logic clk,
     input [inWidth-1:0] in,
     output [dataWidth-1:0] out);
     
    reg [dataWidth-1:0] mem [2**inWidth-1:0];
    reg [inWidth-1:0] y;
    
    initial
        $readmemb("sigContent.mif", mem); 
     
     always_ff @(posedge clk) begin
        if($signed(in) >= 0)
            y <= in+(2**(inWidth-1));
        else
            y <= in-(2**(inWidth-1));
     end
     
     assign out = mem[y];
     
     
     
     
     
endmodule