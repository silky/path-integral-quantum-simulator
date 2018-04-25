

`timescale 1ns/10ps

module tbench();
  reg clk, reset;
  reg [16:0] clks;
  initial begin reset = 1; clk = 0; # 400 reset = 0; clks = 0; end
  always #50 clk = !clk;

  initial begin # (50 * 500) $display("Finish HDL simulation on timeout %t.", $time); $finish(); end

  wire lowrst;
  assign lowrst = ~reset;
  
  reg [31:0] upin;
  reg [31:0] downin;
  reg go;
  
  wire [31:0] upout;
  wire [31:0] downout;
  wire done;
  wire running;

  
  HROOT DUT( .clk(clk), .reset(reset), .hadamard_up(upin), .hadamard_down(downin), .hadamard_go(go),
             .hadamard_upout(upout), .hadamard_downout(downout), .hadamard_done(done), .hadamard_running(running) );
  
  initial begin #500
    // upin <= 32'h3f800000;
    // downin <= 32'h00000000;
    
    upin <= 32'h00000000;
    downin <= 32'h3f800000;

    go = 1;
  end
  
  initial begin #600
    // upin <= 0;
    // downin <= 0;
    go = 0;
  end


  reg [63:0] upd;
  reg [63:0] downd;
        
  always @(posedge clk) begin
    clks = clks + 1;
    
    // credit https://stackoverflow.com/a/19710576 - Moberg
    upd = {upout[31], upout[30], {3{~upout[30]}}, upout[29:23], upout[22:0], {29{1'b0}}};
    downd = {downout[31], downout[30], {3{~downout[30]}}, downout[29:23], downout[22:0], {29{1'b0}}};

    $display("clk %d, go %b, runnig %b, done %b, out %f|0>+%f|1>", clks, go, running, done, $bitstoreal(upd), $bitstoreal(downd));
    if (done == 1) begin
      $finish;
    end
  end
endmodule
  
// eof
