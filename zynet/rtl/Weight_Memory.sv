`timescale 1ns/1ps

`include "include.sv"

module Weight_Memory #(parameter numWeight = 3, neuronNo = 5, layerNo = 10, addressWidth =10, dataWidth = 16, weightFile = "w_1_15.mif")
    (input logic clk,
     input logic wen,
     input logic ren,
     input logic [addressWidth-1:0] wadd,
     input logic [addressWidth-1:0] radd,
     input logic [dataWidth-1:0] win,
     output logic [dataWidth-1:0] wout);
     
     logic [dataWidth-1:0] mem [numWeight-1:0];
     
     `ifdef pretrained
        initial begin
            $readmemb(weightFile,mem);
        end
        
      `else
        always_ff @(posedge clk) begin
            if (wen)
                mem[wadd] <= win;
        end
       `endif
     
     always_ff @(posedge clk) begin
        if (ren)
            wout <= mem[radd];
     end
     
endmodule
    