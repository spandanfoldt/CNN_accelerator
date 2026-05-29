`timescale 1ns/1ps

module axi_lite_wrapper #(parameter int C_S_AXI_DATA_WIDTH = 32, int C_S_AXI_ADDR_WIDTH =5)
    (input logic S_AXI_ACLK,
     input logic S_AXI_ARESETN,
     input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
     input logic [2:0] S_AXI_AWPROT,
     input logic S_AXI_AWVALID,
     output logic S_AXI_AWREADY,
     input logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
     input logic [(C_S_AXI_DATA_WIDTH/8)-1:0] S_SXI_WSTRB,
     input logic S_AXI_WVALID,
     output logic S_AXI_WREADY,
     output logic [1:0] S_AXI_BRESP,
     output logic S_AXI_BVALID,
     input logic S_AXI_BREADY,
     input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
     input logic [2:0] S_AXI_ARPROT,
     input logic S_AXI_ARVALID,
     output logic S_AXI_ARREADY,
     output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
     output logic [1:0] S_AXI_RRESP,
     output logic S_AXI_RVALID,
     input logic S_AXI_RREADY,
     
     output logic [31:0] layerNumber,
     output logic [31:0] neuronNumber,
     output logic weightValid,
     output logic biasValid,
     output logic [31:0] weightValue,
     output logic [31:0] biasValue,
     input logic [31:0] nnOut,
     input logic nnOut_valid,
     output logic axi_rd_en,
     input logic [31:0] axi_rd_data,
     output logic softReset);
    
    // AXI4LITE signals
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic axi_awready, axi_wready;
    logic [1:0] axi_bresp;
    logic axi_bvalid;
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic axi_arready;
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    logic [1:0] axi_rresp;
    logic axi_rvalid;
    
    
    localparam int ADDR_LSB = (C_S_AXI_DATA_WIDTH/32)+1;
    localparam int OPT_MEM_ADDR_BITS = 2;
    
    // slave registers
	logic [C_S_AXI_DATA_WIDTH-1:0]	weightReg;
	logic [C_S_AXI_DATA_WIDTH-1:0]	biasReg;
	logic [C_S_AXI_DATA_WIDTH-1:0]	outputReg;
	logic [C_S_AXI_DATA_WIDTH-1:0]	layerReg;
	logic [C_S_AXI_DATA_WIDTH-1:0]	neuronReg;
	logic [C_S_AXI_DATA_WIDTH-1:0]	statReg;
	logic [C_S_AXI_DATA_WIDTH-1:0]	controlReg;
	logic [C_S_AXI_DATA_WIDTH-1:0]	slv_reg7;
	
	logic slv_reg_rden;
	logic slv_reg_wren;
	logic [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
	int byte_index;
	logic aw_en;
	
	// I/0 connections assignments
	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;	
    
     
    assign layerNumber = layerReg;
    assign neuronNumber = neuronReg;
    assign weightValue = weightReg;
    assign biasValue = biasReg;
    assign softReset = controlReg[0];

    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_awready <= 0;
            aw_en <= 1;
        end
        else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1;
                aw_en <= 0;
            end
            else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1;
                axi_awready <= 0;
            end
            else
                axi_awready <= 0;
        
        end
    end
    
    
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0)
            axi_awaddr <= 0;
        else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
                axi_awaddr <= S_AXI_AWADDR;
        end
    end
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0)
            axi_awready <= 0;
        else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
                axi_wready <= 1;
                else
                    axi_wready <= 0;
        end
    end
    
    
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
          weightReg <= 0;
		  biasReg <= 0;
		  layerReg <= 0;
		  neuronReg <= 0;
		  slv_reg7 <= 0;
		  weightValid <= 1'b0;
		  biasValid <= 1'b0;
		  controlReg <= 0;
		end
		
		else begin
		  weightValid <= 0;
		  biasValid <= 0;
		  if (slv_reg_wren) begin
		      case (axi_awaddr[ADDR_LSB + OPT_MEM_ADDR_BITS:ADDR_LSB])
		          3'h0: begin
		              weightReg <= S_AXI_WDATA;
		              weightValid <= 1;
		          end
		          3'h1: begin
		              biasReg <= S_AXI_WDATA;
		              biasValid <= 1;
		          end
		          3'h3: layerReg <= S_AXI_WDATA;
		          3'h4: neuronReg <= S_AXI_WDATA;
		          3'h7: controlReg <= S_AXI_WDATA;
		      endcase
		  end
		end
    end
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0)
            outputReg <= 0;
        else if (nnOut_valid)
            outputReg <= nnOut;
    end
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_bvalid <= 'b0;
            axi_bresp <= 'b0;
        end
        else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 'b1;
                axi_bresp <= 'b0;
            end
            else begin
                if (S_AXI_BREADY && axi_bvalid)
                    axi_bvalid <= 'b0;
            end
        end
    end
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_arready <= 'b0;
            axi_araddr <= 'b0;
        end
        else begin
            if(~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 'b1;
                axi_araddr <= S_AXI_ARADDR;
            end
            else
                axi_arready <= 'b0;
        end
    end
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_rvalid <= 0;
            axi_rresp <= 0;
        end
        else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1;
                axi_rresp <= 0;
            end
            else if (axi_rvalid && S_AXI_RREADY)
                axi_rvalid <= 0;
        end
    end    
    
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always_comb begin
        case (axi_araddr[ADDR_LSB + OPT_MEM_ADDR_BITS:ADDR_LSB])
	        3'h0   : reg_data_out <= weightReg;
	        3'h1   : reg_data_out <= biasReg;
	        3'h2   : reg_data_out <= outputReg;
	        3'h3   : reg_data_out <= layerReg;
	        3'h4   : reg_data_out <= neuronReg;
	        3'h5   : reg_data_out <= axi_rd_data;
	        3'h6   : reg_data_out <= statReg;
	        3'h7   : reg_data_out <= controlReg;
	        default : reg_data_out <= 0;
	    endcase            
    end   
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0)
            statReg <= 0;
        else if (nnOut_valid)
            statReg <= 1;
        else if (axi_rvalid & S_AXI_RREADY & axi_araddr[ADDR_LSB + OPT_MEM_ADDR_BITS:ADDR_LSB]==3'h6)
            statReg <= 0;
    end
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (!axi_rd_en & axi_rvalid & S_AXI_RREADY & axi_araddr[ADDR_LSB + OPT_MEM_ADDR_BITS:ADDR_LSB] == 3'h5)
            axi_rd_en <= 1;
        else
            axi_rd_en <= 0;
    end
    
    always_ff @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0)
            axi_rdata <= 0;
        else begin
            if(slv_reg_rden)
                axi_rdata <= reg_data_out;
        end             
    end
    

endmodule