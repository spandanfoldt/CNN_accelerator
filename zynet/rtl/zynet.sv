`timescale 1ns/1ps
`include "include.sv"

module zynet #(parameter int C_S_AXI_DATA_WIDTH = 32, parameter int C_S_AXI_ADDR_WIDTH = 5)
    (input logic s_axi_clk,
     input logic s_axi_resetn,
     input logic [`dataWidth-1:0] axis_in_data,
     input logic axis_in_data_valid,
     input logic weight_valid,
     input logic bias_valid,
     input  logic [31:0] weightValue,
     input  logic [31:0] biasValue,
     input  logic [31:0] config_layer_num,
     input  logic [31:0] config_neuron_num,
     output logic axis_in_data_ready);
     
     assign axis_in_data_ready = 1'b1;
     logic reset;
     assign reset = ~s_axi_resetn;
     // localparam IDLE = 'b0, SEND = 'b1;
     
     typedef enum logic {IDLE, SEND} state_t;
     
     logic [`numNeuronLayer1*`dataWidth-1:0] x1_out;
     logic [`numNeuronLayer1-1:0] o1_valid;
     logic [`numNeuronLayer1*`dataWidth-1:0] hold_data1;
     logic [`dataWidth-1:0] out_data1;
     logic data_out_valid1;
     
     Layer1 #(.NN(`numNeuronLayer1), .numWeight(`numWeightLayer1), .dataWidth(`dataWidth), .layerNum(1), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`Layer1ActType))
           l1(.clk(s_axi_clk), .rst(reset), .weightValid(weight_valid), .biasValid(bias_valid), .weightValue(weightValue), .biasValue(biasValue), .config_layer_num(config_layer_num),
              .config_neuron_num(config_neuron_num), .x_valid(axis_in_data_valid), .x_in(axis_in_data), .o_valid(o1_valid), .x_out(x1_out));
     
     state_t state_1;
     int count_1;
     always_ff @(posedge s_axi_clk) begin
          if (reset) begin
            state_1 <= IDLE;
            count_1 <= 0;
            data_out_valid1 <= 0;
          end
          else begin
            case (state_1)
                IDLE: begin
                    count_1 <= 0;
                    data_out_valid1 <= 0;
                    if (o1_valid[0] == 1) begin
                        hold_data1 <= x1_out;
                        state_1 <= SEND;
                    end
                end
                SEND: begin
                    out_data1 <= hold_data1[`dataWidth-1:0];
                    hold_data1 <= hold_data1>>`dataWidth;
                    count_1 <= count_1 + 1;
                    data_out_valid1 <= 1;
                    if (count_1 == `numNeuronLayer1-1) begin
                        state_1 <= IDLE;
                        data_out_valid1 <= 0;
                    end
                end
            endcase
          end
     end
     
     
     
     logic [`numNeuronLayer2*`dataWidth-1:0] x2_out;
     logic [`numNeuronLayer2-1:0] o2_valid;
     logic [`numNeuronLayer2*`dataWidth-1:0] hold_data2;
     logic [`dataWidth-2:0] out_data2;
     logic data_out_valid2;
     
     Layer2 #(.NN(`numNeuronLayer2), .numWeight(`numWeightLayer2), .dataWidth(`dataWidth), .layerNum(2), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`Layer2ActType))
           l2(.clk(s_axi_clk), .rst(reset), .weightValid(weight_valid), .biasValid(bias_valid), .weightValue(weightValue), .biasValue(biasValue), .config_layer_num(config_layer_num),
              .config_neuron_num(config_neuron_num), .x_valid(data_out_valid1), .x_in(out_data1), .o_valid(o2_valid), .x_out(x2_out));
     
     state_t state_2;
     int count_2;
     always_ff @(posedge s_axi_clk) begin
          if (reset) begin
            state_2 <= IDLE;
            count_2 <= 0;
            data_out_valid2 <= 0;
          end
          else begin
            case (state_2)
                IDLE: begin
                    count_2 <= 0;
                    data_out_valid2 <= 0;
                    if (o2_valid[0] == 1) begin
                        hold_data2 <= x2_out;
                        state_2 <= SEND;
                    end
                end
                SEND: begin
                    out_data2 <= hold_data2[`dataWidth-1:0];
                    hold_data2 <= hold_data2>>`dataWidth;
                    count_2 <= count_2 + 1;
                    data_out_valid2 <= 1;
                    if (count_2 == `numNeuronLayer2-1) begin
                        state_2 <= IDLE;
                        data_out_valid2 <= 0;
                    end
                end
            endcase
          end
     end
     
     
     
     logic [`numNeuronLayer3*`dataWidth-1:0] x3_out;
     logic [`numNeuronLayer3-1:0] o3_valid;
     logic [`numNeuronLayer3*`dataWidth-1:0] hold_data3;
     logic [`dataWidth-1:0] out_data3;
     logic data_out_valid3;
     
     Layer3 #(.NN(`numNeuronLayer3), .numWeight(`numWeightLayer3), .dataWidth(`dataWidth), .layerNum(3), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`Layer3ActType))
           l3(.clk(s_axi_clk), .rst(reset), .weightValid(weight_valid), .biasValid(bias_valid), .weightValue(weightValue), .biasValue(biasValue), .config_layer_num(config_layer_num),
              .config_neuron_num(config_neuron_num), .x_valid(data_out_valid2), .x_in(out_data2), .o_valid(o3_valid), .x_out(x3_out));
     
     state_t state_3;
     int count_3;
     always_ff @(posedge s_axi_clk) begin
          if (reset) begin
            state_3 <= IDLE;
            count_3 <= 0;
            data_out_valid3 <= 0;
          end
          else begin
            case (state_3)
                IDLE: begin
                    count_3 <= 0;
                    data_out_valid3 <= 0;
                    if (o3_valid[0] == 1) begin
                        hold_data3 <= x3_out;
                        state_3 <= SEND;
                    end
                end
                SEND: begin
                    out_data3 <= hold_data3[`dataWidth-1:0];
                    hold_data3 <= hold_data3>>`dataWidth;
                    count_3 <= count_3 + 1;
                    data_out_valid3 <= 1;
                    if (count_3 == `numNeuronLayer3-1) begin
                        state_3 <= IDLE;
                        data_out_valid3 <= 0;
                    end
                end
            endcase
          end
     end
     
     
     
     logic [`numNeuronLayer4*`dataWidth-1:0] x4_out;
     logic [`numNeuronLayer4-1:0] o4_valid;
     logic [`numNeuronLayer4*`dataWidth-1:0] hold_data4;
     logic [`dataWidth-1:0] out_data4;
     logic data_out_valid4;
     
     Layer4 #(.NN(`numNeuronLayer4), .numWeight(`numWeightLayer4), .dataWidth(`dataWidth), .layerNum(4), .sigmoidSize(`sigmoidSize), .weightIntWidth(`weightIntWidth), .actType(`Layer4ActType))
           l4(.clk(s_axi_clk), .rst(reset), .weightValid(weight_valid), .biasValid(bias_valid), .weightValue(weightValue), .biasValue(biasValue), .config_layer_num(config_layer_num),
              .config_neuron_num(config_neuron_num), .x_valid(data_out_valid3), .x_in(out_data3), .o_valid(o4_valid), .x_out(x4_out));
     
     state_t state_4;
     int count_4;
     always_ff @(posedge s_axi_clk) begin
          if (reset) begin
            state_4 <= IDLE;
            count_4 <= 0;
            data_out_valid4 <= 0;
          end
          else begin
            case (state_4)
                IDLE: begin
                    count_4 <= 0;
                    data_out_valid4 <= 0;
                    if (o4_valid[0] == 1) begin
                        hold_data4 <= x4_out;
                        state_4 <= SEND;
                    end
                end
                SEND: begin
                    out_data4 <= hold_data4[`dataWidth-1:0];
                    hold_data4 <= hold_data4>>`dataWidth;
                    count_4 <= count_4 + 1;
                    data_out_valid4 <= 1;
                    if (count_4 == `numNeuronLayer4-1) begin
                        state_4 <= IDLE;
                        data_out_valid4 <= 0;
                    end
                end
            endcase
          end
     end
          
              
     
endmodule