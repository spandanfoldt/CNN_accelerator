`timescale 1ns/1ps
`include "include.sv"

module neuron #(parameter layerNo = 0, neuronNo = 0, numWeight = 784, dataWidth = 16, sigmoidSize = 10, weightIntWidth = 1, actType = "relu", biasFile = "", weightFile = "")
    (input logic clk,
     input logic rst,
     input logic [dataWidth-1:0] in,
     input logic inValid,
     input logic weightValid,
     input logic biasValid,
     input logic [31:0] weightValue,
     input logic [31:0] biasValue,
     input logic [31:0] config_layer_num,
     input logic [31:0] config_neuron_num,
     output logic [dataWidth-1:0] out,
     output logic outValid);
     
    parameter addressWidth = $clog2(numWeight); 
    
    logic wen, ren;
    logic [addressWidth-1:0] w_addr;
    logic [addressWidth:0] r_addr;
    logic [dataWidth-1:0] w_in, w_out;
    logic [2*dataWidth-1:0] mul, sum, bias;
    logic [31:0] biasReg [0:0];
    logic weight_valid, mult_valid, mux_valid, sig_valid;
    logic [2*dataWidth:0] comboAdd, biasAdd;
    logic [dataWidth-1:0] myinputd;
    logic muxValid_d, muxValid_f;
    logic addr = 0;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            w_addr <= {addressWidth{1'b1}};
            wen <= 0;
        end
        
        else if(weightValid & (config_layer_num == layerNo) & (config_neuron_num == neuronNo)) begin
            w_in <= weightValue;
            w_addr <= w_addr + 1;
            wen <= 1;
        end
        else
            wen <= 0;
    end
    
    assign mux_valid = mult_valid;
    assign comboAdd = mul + sum;
    assign biasAdd = bias + sum;
    assign ren = inValid;
    
    `ifdef pretrained
        initial
            $readmemb(biasFile, biasReg);
        
        always_ff @(posedge clk)
            bias <= {biasReg[addr][dataWidth-1:0], {dataWidth{1'b0}}};
        
    `else    
        always_ff @(posedge clk) begin
            if(biasValid & (config_layer_num == layerNo) & (config_neuron_num == neuronNo))
                bias <= {biasValue[dataWidth-1:0], {dataWidth{1'b0}}};
        end
    `endif    
    
    
    always_ff @(posedge clk) begin
        if(rst | outValid)
            r_addr <= 0;
        else if (inValid)
            r_addr <= r_addr + 1;
     end
     
     always_ff @(posedge clk)
        mul <= $signed(myinputd) * $signed(w_out);
        
        
     always_ff @(posedge clk) begin
        if(rst | outValid)
            sum <= 0;
        else if((r_addr == numWeight) & muxValid_f) begin
            if(!bias[2*dataWidth-1] & !sum[2*dataWidth-1] & biasAdd[2*dataWidth-1]) begin
                sum[2*dataWidth-1] <= 1'b0;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
            end
            
            else if (bias[2*dataWidth-1] & sum[2*dataWidth-1] & !biasAdd[2*dataWidth-1]) begin
                sum[2*dataWidth-1] <= 1'b1;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
            end
            
            else
                sum <= biasAdd;
        end
        
        else if (mux_valid) begin
            if(!mul[2*dataWidth-1] & !sum[2*dataWidth-1] & comboAdd[2*dataWidth-1]) begin
                sum[2*dataWidth-1] <= 1'b0;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b1}};
            end
            
            else if(mul[2*dataWidth-1] & sum[2*dataWidth-1] & !comboAdd[2*dataWidth-1]) begin
                sum[2*dataWidth-1] <= 1'b1;
                sum[2*dataWidth-2:0] <= {2*dataWidth-1{1'b0}};
            end
            
            else
                sum <= comboAdd;
        end
    end
            
    always_ff @(posedge clk) begin
        myinputd <= in;
        weight_valid <= inValid;
        mult_valid <= weight_valid;
        sig_valid <= ((r_addr == numWeight) & muxValid_f) ? 1 : 0;
        outValid <= sig_valid;
        muxValid_d <= mux_valid;
        muxValid_f <= !mux_valid & muxValid_d;
    end    
    
    Weight_Memory #(.numWeight(numWeight),.neuronNo(neuronNo),.layerNo(layerNo),.addressWidth(addressWidth),.dataWidth(dataWidth),.weightFile(weightFile)) WMinst(
      .clk(clk),
      .wen(wen),
      .ren(ren),
      .wadd(w_addr),
      .radd(r_addr),
      .win(w_in),
      .wout(w_out));
  
  generate
    if(actType == "sigmoid") begin :siginst
        Sig_ROM #(.inWidth(sigmoidSize),.dataWidth(dataWidth)) Sig_ROMinst(
            .clk(clk),
            .in(sum[2*dataWidth-1-:sigmoidSize]),
            .out(out)); 
    end
    
    else begin :RELUinst
        relu #(.dataWidth(dataWidth),.weightIntWidth(weightIntWidth)) reluinst (
            .clk(clk),
            .in(sum),
            .out(out));
    end
  endgenerate
  
  `ifdef DEBUG
    always_ff @(posedge clk) begin
        if(outValid)
            $display("%0d %b", neuronNo, out);
    end
  `endif
     
endmodule