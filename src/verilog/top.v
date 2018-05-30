`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: U. Of Cam
// Engineer: Thomas Parks 
// 
// Create Date: 05/22/2018 03:05:54 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: Zynq
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input clk,
    input rst,
    
    // AXI interface
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [8-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [32-1 : 0] S_AXI_WDATA,
    input wire [(32/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [8-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [32-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY,

    
    output allones
    );
      
    reg [31:0] SN = 32'h1;
    reg [31:0] status = 0;
    wire [31:0] target, inital, control;
    // control[0] - go
    // control[1] - reset
    // control[2:1] - depth to evaluate
    
    reg ready = 0; // ready for a new request.
    // state diagram:
    // 0: ready=0, running=0
    // 1: ready=1, running=0
    // 2: ready=0, running=1
    // 3: ready=0, running=0 -> need reset signal to go again

    axi_qsim axi_iface(
      .SN(SN),
      .status(status),
      .target(target),
      .inital(inital),
      .control(control),

      .S_AXI_ACLK(S_AXI_ACLK),
      .S_AXI_ARESETN(S_AXI_ARESETN),
      .S_AXI_AWADDR(S_AXI_AWADDR),
      .S_AXI_AWPROT(S_AXI_AWPROT),
      .S_AXI_AWVALID(S_AXI_AWVALID),
      .S_AXI_AWREADY(S_AXI_AWREADY),
      .S_AXI_WDATA(S_AXI_WDATA),
      .S_AXI_WSTRB(S_AXI_WSTRB),
      .S_AXI_WVALID(S_AXI_WVALID),
      .S_AXI_WREADY(S_AXI_WREADY),
      .S_AXI_BRESP(S_AXI_BRESP),
      .S_AXI_BVALID(S_AXI_BVALID),
      .S_AXI_BREADY(S_AXI_BREADY),
      .S_AXI_ARADDR(S_AXI_ARADDR),
      .S_AXI_ARPROT(S_AXI_ARPROT),
      .S_AXI_ARVALID(S_AXI_ARVALID),
      .S_AXI_ARREADY(S_AXI_ARREADY),
      .S_AXI_RDATA(S_AXI_RDATA),
      .S_AXI_RRESP(S_AXI_RRESP),
      .S_AXI_RVALID(S_AXI_RVALID),
      .S_AXI_RREADY(S_AXI_RREADY)
    );
    
    // DUT to (un)packing modules
    wire done;
    reg [1:0] inp_splitdepth = 0; // totally ignored by pack_workunit
    reg [15:0] target_input = 0;
    reg [15:0] inital_input = 0;
    reg [4:0]  depth_input  = 4; // total num of gates to process.
    reg inp_wu_valid = 0;
    
    wire [221:0] wu_input;
    wire [275:0] network_result;
     
    networkRTL network(
        .clk(clk),
        .rst(rst),
        .stim_wu(wu_input),
        .network_result(network_result)
        );
    
    pack_workunit inputpacker(.clk(clk), .rst(rst),
                        .inp_splitdepth(inp_splitdepth),
                        .target(target_input),
                        .inital(inital_input),
                        .depth(depth_input),
                        .inp_wu_valid(inp_wu_valid),
                        .workunit(wu_input));
    
    wire [210:0] wu_out;
    wire [48:0] amp_out;
    wire [4:0] pos_out;
    
    split_output outsplit( 
        .clk(clk), .rst(rst),
        .output_bundle(network_result),
        .wu(wu_out),
        .amp(amp_out),
        .pos(pos_out)
        );

    // amprply parts
    wire signed [12:0] realpt;
    wire signed [12:0] imagpt;
    reg signed [12:0] lastreal = 0;
    
    unpack_ampreply unpackamp( 
        .clk(clk), .rst(rst),
        .ampreply(amp_out),
        .valid(done),
        .realpt(realpt),
        .imagpt(imagpt)
        );

    wire signed [31:0] ptrparsed;
    parse_ptr parseptr( // Inputs
        .clk(clk), .rst(rst),
        .ptrbundle(pos_out),
        .ptrparsed(ptrparsed)
        );
    

    
    // states: 0: rst 1: wait 2: exec 3: return
    reg [1:0] state = 0;
    
    always @(posedge clk) begin
      status <= { lastreal, 10'd0, ptrparsed[6:0], ready, state };
    end
    
    always @(posedge clk) begin
    
      if (rst == 1'b1 ) begin
        state <= 0;
      end
      
      case (state)
        2'd0: begin
                state <= 1;
              end
        
        2'd1: begin
                if (control[0] == 1) begin
                  inp_wu_valid <= 1; // other signals will be read by PACK
                  state <= 2;
                end else begin
                  state <= 1;
                // wait for valid input on the AXI bus.
                end
              end
        
        2'd2: begin
                if (done == 1) begin
                  lastreal <= realpt;
                  state <= 3;
                end else begin
                  state <= 2;
                end
              end
        
        2'd3: begin
                if (control[2] == 1) begin
                  state <= 0;
                end else begin
                  state <= 3;
                end
              end
      endcase
    end
    
    assign allones = ^network_result;
    
    
endmodule
