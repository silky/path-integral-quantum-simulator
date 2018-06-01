module networkRTL(
    input clk,
    input rst,
    
    input [$WUSZ-1:0] stim_wu,
    output reg [$OUTBSZ-1:0] network_result
    );

    #for $var in range(len($network.amps)) 
    // start of FindAmp ${var}
    wire [$INBSZ-1:0] F_${var}_inputbundle;
    wire [$WUSZ-1:0] F_${var}_inputworkunit; // gets assigned by the source
    reg [16:0] F_${var}_depth = $network.amps[$var].depth;
    //reg [16:0] F_${var}_depth = 0;
    join_input F_${var}_inpack(.clk(clk), .rst(rst), 
                               .depthlim(F_${var}_depth),
                               .wu(F_${var}_inputworkunit),
                               .amp(F_${var}_inputamp),
                               .input_bundle(F_${var}_inputbundle)
                              );

    always @(posedge clk) begin
      if (F_${var}_inputworkunit != 0) begin
        \$display("F${var} got request");
      end
      if (F_${var}_inputamp != 0) begin
        \$display("F${var} got a ampreply");
      end
    end

    wire [$OUTBSZ-1:0] F_${var}_outputbundle;
    findamp F_${var}( .clk(clk), .rst(rst),
                       .input_bundle(F_${var}_inputbundle),
                       .output_bundle(F_${var}_outputbundle)); 
    
    wire [$WUSZ-1:0] F_${var}_outputwu;
    wire [$AMPSZ-1:0] F_${var}_outputamp;
    wire [$POSSZ-1:0] F_${var}_outputpos;

    split_output F_${var}_split( .clk(clk), .rst(rst),
                                 .output_bundle(F_${var}_outputbundle),
                                 .wu(F_${var}_outputwu), .pos(F_${var}_outputpos),
                                 .amp(F_${var}_outputamp));
    
    
    #if $network.amps[var].down_connection.type == "BASE" 
    reg [$AMPSZ-1:0] F_${var}_inputamp = 0; // base connection, ignore wu requests #slurp
    #else
    wire [$AMPSZ-1:0] F_${var}_inputamp; // div request connection
    assign F_${var}_inputamp = D_${network.amps[var].down_connection.idx}_upstreamamp;
    assign  D_${network.amps[var].down_connection.idx}_upstreamwureq = F_${var}_outputwu;
    #end if 
    
    wire signed [31:0] parsed_ptr_${var};
    parse_ptr P_${var}(.clk(clk), .rst(rst), .ptrbundle(F_${var}_outputpos), .ptrparsed(parsed_ptr_${var}));
    
    always @(posedge clk) begin
      if (F_${var}_outputwu != 0) begin
        \$display("F${var} making request");
      end
      if (F_${var}_outputamp != 0) begin
        \$display("F${var} sending a ampreply");
      end
    end
    // end of FindAmp ${var}
    #end for
    
    
    #for $var in range(len($network.divs)) 
    // start HeightDiv $var
    wire [$WUSZ-1:0] D_${var}_upstreamwureq;
    wire [$AMPSZ-1:0] D_${var}_upstreamamp;
    heightdiv D_${var}(.clk(clk), .rst(rst),
                       .upstream_req(D_${var}_upstreamwureq),
                       .upstream_rply(D_${var}_upstreamamp),
                       
                       .downstream_high_req(F_${network.divs[var].left.idx}_inputworkunit),
                       .downstream_high_rply(F_${network.divs[var].left.idx}_outputamp),
                       
                       .downstream_low_req(F_${network.divs[var].right.idx}_inputworkunit),
                       .downstream_low_rply(F_${network.divs[var].right.idx}_outputamp)
                      );
    always @(posedge clk) begin
      if (D_${var}_upstreamwureq != 0) begin
        \$display("D${var} got request from upstream");
      end
      if (D_${var}_upstreamamp != 0) begin
        \$display("D${var} sending a ampreply");
      end
      
      if (F_${network.divs[var].left.idx}_inputworkunit != 0) begin
        \$display("D${var} making request to left");
      end
      if (F_${network.divs[var].left.idx}_outputamp != 0) begin
        \$display("D${var} got reply from left");
      end
      if (F_${network.divs[var].right.idx}_inputworkunit != 0) begin
        \$display("D${var} making request to right");
      end
      if (F_${network.divs[var].right.idx}_outputamp != 0) begin
        \$display("D${var} got reply from right");
      end

    end
    // end HeightDiv $var
    #end for

    
    
    // input workunits.
    assign F_0_inputworkunit = stim_wu;
    
    // get the output from the first module
    always @(posedge clk) begin
        network_result <= F_0_outputbundle;
    end
    
    always @(posedge clk) begin
      \$display("FindAmps at ${"%d " * len($network.amps)}" #for $var in range(len($network.amps))
       , parsed_ptr_$var #slurp
       #end for
       );
    end

    
endmodule
