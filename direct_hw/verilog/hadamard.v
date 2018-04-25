

// CBG Orangepath HPR L/S System

// Verilog output file generated at 4/7/2018 9:44:21 PM
// Kiwi Scientific Acceleration (KiwiC .net/CIL/C# to Verilog/SystemC compiler): Version Alpha 0.3.5k : 1st Mar 2018 Unix 4.13.0.38
//  /media/psf/Home/Projects/ACS/kiwi_planner/bitbucket-hprls2/kiwipro/kiwic/distro/lib/kiwic.exe ../build/hadamard.exe -vnl=hadamard.v -vnl-rootmodname=HROOT
`timescale 1ns/1ns


module HROOT(    
/* portgroup= abstractionName=kiwicmiscio10 */
    output reg hadamard_running,
    output reg hadamard_done,
    output reg /*fp*/ [31:0] hadamard_downout,
    output reg /*fp*/ [31:0] hadamard_upout,
    input hadamard_go,
    input /*fp*/ [31:0] hadamard_down,
    input /*fp*/ [31:0] hadamard_up,
    output reg [7:0] ksubsAbendSyndrome,
    output reg [7:0] ksubsGpioLeds,
    output reg [7:0] ksubsManualWaypoint,
    
/* portgroup= abstractionName=res2-directornets */
output reg [4:0] buildhadamard10PC10nz_pc_export,
    
/* portgroup= abstractionName=HFAST1 pi_name=dram0bank */
output dram0bank_OPREQ,
    input dram0bank_OPRDY,
    input dram0bank_ACK,
    output dram0bank_RWBAR,
    output [255:0] dram0bank_WDATA,
    output [21:0] dram0bank_ADDR,
    input [255:0] dram0bank_RDATA,
    output [31:0] dram0bank_LANES,
    
/* portgroup= abstractionName=L2590-vg pi_name=net2batch10 */
input clk,
    
/* portgroup= abstractionName=directorate-vg-dir pi_name=directorate10 */
input reset);
// abstractionName=res2-contacts pi_name=CV_FP_FL4_ADDER_SP
  wire/*fp*/  [31:0] CVFPADDER10_FPRR;
  reg/*fp*/  [31:0] CVFPADDER10_XX;
  reg/*fp*/  [31:0] CVFPADDER10_YY;
  wire CVFPADDER10_fail;
// abstractionName=res2-contacts pi_name=CV_FP_FL15_DIVIDER_SP
  wire/*fp*/  [31:0] CVFPDIVIDER10_FPRR;
  reg/*fp*/  [31:0] CVFPDIVIDER10_NN;
  reg/*fp*/  [31:0] CVFPDIVIDER10_DD;
  wire CVFPDIVIDER10_fail;
// abstractionName=res2-contacts pi_name=CV_FP_FL4_ADDER_SP
  wire/*fp*/  [31:0] CVFPADDER12_FPRR;
  reg/*fp*/  [31:0] CVFPADDER12_XX;
  reg/*fp*/  [31:0] CVFPADDER12_YY;
  wire CVFPADDER12_fail;
// abstractionName=res2-contacts pi_name=CV_FP_FL15_DIVIDER_SP
  wire/*fp*/  [31:0] CVFPDIVIDER12_FPRR;
  reg/*fp*/  [31:0] CVFPDIVIDER12_NN;
  reg/*fp*/  [31:0] CVFPDIVIDER12_DD;
  wire CVFPDIVIDER12_fail;
// abstractionName=res2-morenets
  reg/*fp*/  [31:0] CVFPDIVIDER12RRh10hold;
  reg CVFPDIVIDER12RRh10shot0;
  reg CVFPDIVIDER12RRh10shot1;
  reg CVFPDIVIDER12RRh10shot2;
  reg CVFPDIVIDER12RRh10shot3;
  reg CVFPDIVIDER12RRh10shot4;
  reg CVFPDIVIDER12RRh10shot5;
  reg CVFPDIVIDER12RRh10shot6;
  reg CVFPDIVIDER12RRh10shot7;
  reg CVFPDIVIDER12RRh10shot8;
  reg CVFPDIVIDER12RRh10shot9;
  reg CVFPDIVIDER12RRh10shot10;
  reg CVFPDIVIDER12RRh10shot11;
  reg CVFPDIVIDER12RRh10shot12;
  reg CVFPDIVIDER12RRh10shot13;
  reg CVFPDIVIDER12RRh10shot14;
  reg/*fp*/  [31:0] CVFPDIVIDER10RRh10hold;
  reg CVFPDIVIDER10RRh10shot0;
  reg CVFPDIVIDER10RRh10shot1;
  reg CVFPDIVIDER10RRh10shot2;
  reg CVFPDIVIDER10RRh10shot3;
  reg CVFPDIVIDER10RRh10shot4;
  reg CVFPDIVIDER10RRh10shot5;
  reg CVFPDIVIDER10RRh10shot6;
  reg CVFPDIVIDER10RRh10shot7;
  reg CVFPDIVIDER10RRh10shot8;
  reg CVFPDIVIDER10RRh10shot9;
  reg CVFPDIVIDER10RRh10shot10;
  reg CVFPDIVIDER10RRh10shot11;
  reg CVFPDIVIDER10RRh10shot12;
  reg CVFPDIVIDER10RRh10shot13;
  reg CVFPDIVIDER10RRh10shot14;
  reg/*fp*/  [31:0] CVFPADDER12RRh10hold;
  reg CVFPADDER12RRh10shot0;
  reg CVFPADDER12RRh10shot1;
  reg CVFPADDER12RRh10shot2;
  reg CVFPADDER12RRh10shot3;
  reg/*fp*/  [31:0] CVFPADDER10RRh10hold;
  reg CVFPADDER10RRh10shot0;
  reg CVFPADDER10RRh10shot1;
  reg CVFPADDER10RRh10shot2;
  reg CVFPADDER10RRh10shot3;
  reg [4:0] buildhadamard10PC10nz;
 always   @(* )  begin 
       CVFPDIVIDER12_NN = 32'sd0;
       CVFPDIVIDER12_DD = 32'sd0;
       CVFPDIVIDER10_NN = 32'sd0;
       CVFPDIVIDER10_DD = 32'sd0;
       CVFPADDER12_XX = 32'sd0;
       CVFPADDER12_YY = 32'sd0;
       CVFPADDER10_XX = 32'sd0;
       CVFPADDER10_YY = 32'sd0;

      case (buildhadamard10PC10nz)
          32'h4/*4:buildhadamard10PC10nz*/:  begin 
               CVFPADDER10_YY = 32'sh8000_0000^hadamard_down;
               CVFPADDER10_XX = hadamard_up;
               CVFPADDER12_YY = hadamard_up;
               CVFPADDER12_XX = hadamard_down;
               end 
              
          32'h8/*8:buildhadamard10PC10nz*/:  begin 
               CVFPDIVIDER10_DD = 32'h3fb5_04f7;
               CVFPDIVIDER10_NN = ((32'h8/*8:buildhadamard10PC10nz*/==buildhadamard10PC10nz)? CVFPADDER10_FPRR: CVFPADDER10RRh10hold);
               CVFPDIVIDER12_DD = 32'h3fb5_04f7;
               CVFPDIVIDER12_NN = ((32'h8/*8:buildhadamard10PC10nz*/==buildhadamard10PC10nz)? CVFPADDER12_FPRR: CVFPADDER12RRh10hold);
               end 
              endcase
       end 
      

 always   @(posedge clk )  begin 
      //Start structure cvtToVerilog../build/hadamard/1.0
      if (reset)  begin 
               buildhadamard10PC10nz_pc_export <= 32'd0;
               hadamard_upout <= 32'd0;
               hadamard_downout <= 32'd0;
               hadamard_done <= 32'd0;
               hadamard_running <= 32'd0;
               ksubsManualWaypoint <= 32'd0;
               ksubsGpioLeds <= 32'd0;
               ksubsAbendSyndrome <= 32'd0;
               CVFPADDER10RRh10hold <= 32'd0;
               CVFPADDER10RRh10shot1 <= 32'd0;
               CVFPADDER10RRh10shot2 <= 32'd0;
               CVFPADDER10RRh10shot3 <= 32'd0;
               CVFPADDER12RRh10hold <= 32'd0;
               CVFPADDER12RRh10shot1 <= 32'd0;
               CVFPADDER12RRh10shot2 <= 32'd0;
               CVFPADDER12RRh10shot3 <= 32'd0;
               CVFPDIVIDER10RRh10hold <= 32'd0;
               CVFPDIVIDER10RRh10shot1 <= 32'd0;
               CVFPDIVIDER10RRh10shot2 <= 32'd0;
               CVFPDIVIDER10RRh10shot3 <= 32'd0;
               CVFPDIVIDER10RRh10shot4 <= 32'd0;
               CVFPDIVIDER10RRh10shot5 <= 32'd0;
               CVFPDIVIDER10RRh10shot6 <= 32'd0;
               CVFPDIVIDER10RRh10shot7 <= 32'd0;
               CVFPDIVIDER10RRh10shot8 <= 32'd0;
               CVFPDIVIDER10RRh10shot9 <= 32'd0;
               CVFPDIVIDER10RRh10shot10 <= 32'd0;
               CVFPDIVIDER10RRh10shot11 <= 32'd0;
               CVFPDIVIDER10RRh10shot12 <= 32'd0;
               CVFPDIVIDER10RRh10shot13 <= 32'd0;
               CVFPDIVIDER10RRh10shot14 <= 32'd0;
               CVFPDIVIDER12RRh10hold <= 32'd0;
               CVFPDIVIDER12RRh10shot1 <= 32'd0;
               CVFPDIVIDER12RRh10shot2 <= 32'd0;
               CVFPDIVIDER12RRh10shot3 <= 32'd0;
               CVFPDIVIDER12RRh10shot4 <= 32'd0;
               CVFPDIVIDER12RRh10shot5 <= 32'd0;
               CVFPDIVIDER12RRh10shot6 <= 32'd0;
               CVFPDIVIDER12RRh10shot7 <= 32'd0;
               CVFPDIVIDER12RRh10shot8 <= 32'd0;
               CVFPDIVIDER12RRh10shot9 <= 32'd0;
               CVFPDIVIDER12RRh10shot10 <= 32'd0;
               CVFPDIVIDER12RRh10shot11 <= 32'd0;
               CVFPDIVIDER12RRh10shot12 <= 32'd0;
               CVFPDIVIDER12RRh10shot13 <= 32'd0;
               CVFPDIVIDER12RRh10shot14 <= 32'd0;
               CVFPDIVIDER12RRh10shot0 <= 32'd0;
               CVFPDIVIDER10RRh10shot0 <= 32'd0;
               CVFPADDER12RRh10shot0 <= 32'd0;
               CVFPADDER10RRh10shot0 <= 32'd0;
               buildhadamard10PC10nz <= 32'd0;
               end 
               else  begin 
              
              case (buildhadamard10PC10nz)
                  32'h0/*0:buildhadamard10PC10nz*/:  begin 
                       hadamard_upout <= 32'h0;
                       hadamard_downout <= 32'h0;
                       hadamard_done <= 1'h0;
                       hadamard_running <= 1'h0;
                       ksubsManualWaypoint <= 8'h0;
                       ksubsGpioLeds <= 8'h80;
                       ksubsAbendSyndrome <= 8'h80;
                       buildhadamard10PC10nz <= 32'h1/*1:buildhadamard10PC10nz*/;
                       end 
                      
                  32'h1/*1:buildhadamard10PC10nz*/: if (hadamard_go)  begin 
                           hadamard_done <= 1'h0;
                           hadamard_running <= 1'h1;
                           buildhadamard10PC10nz <= 32'h4/*4:buildhadamard10PC10nz*/;
                           end 
                           else  buildhadamard10PC10nz <= 32'h2/*2:buildhadamard10PC10nz*/;

                  32'h17/*23:buildhadamard10PC10nz*/:  begin 
                       hadamard_upout <= ((32'h17/*23:buildhadamard10PC10nz*/==buildhadamard10PC10nz)? CVFPDIVIDER12_FPRR: CVFPDIVIDER12RRh10hold
                      );

                       hadamard_downout <= ((32'h17/*23:buildhadamard10PC10nz*/==buildhadamard10PC10nz)? CVFPDIVIDER10_FPRR: CVFPDIVIDER10RRh10hold
                      );

                       hadamard_done <= 1'h1;
                       buildhadamard10PC10nz <= 32'h3/*3:buildhadamard10PC10nz*/;
                       end 
                      endcase
              if (CVFPDIVIDER12RRh10shot14)  CVFPDIVIDER12RRh10hold <= CVFPDIVIDER12_FPRR;
                  if (CVFPDIVIDER10RRh10shot14)  CVFPDIVIDER10RRh10hold <= CVFPDIVIDER10_FPRR;
                  if (CVFPADDER12RRh10shot3)  CVFPADDER12RRh10hold <= CVFPADDER12_FPRR;
                  if (CVFPADDER10RRh10shot3)  CVFPADDER10RRh10hold <= CVFPADDER10_FPRR;
                  
              case (buildhadamard10PC10nz)
                  32'h2/*2:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h3/*3:buildhadamard10PC10nz*/;

                  32'h3/*3:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h1/*1:buildhadamard10PC10nz*/;

                  32'h4/*4:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h5/*5:buildhadamard10PC10nz*/;

                  32'h5/*5:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h6/*6:buildhadamard10PC10nz*/;

                  32'h6/*6:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h7/*7:buildhadamard10PC10nz*/;

                  32'h7/*7:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h8/*8:buildhadamard10PC10nz*/;

                  32'h8/*8:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h9/*9:buildhadamard10PC10nz*/;

                  32'h9/*9:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'ha/*10:buildhadamard10PC10nz*/;

                  32'ha/*10:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'hb/*11:buildhadamard10PC10nz*/;

                  32'hb/*11:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'hc/*12:buildhadamard10PC10nz*/;

                  32'hc/*12:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'hd/*13:buildhadamard10PC10nz*/;

                  32'hd/*13:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'he/*14:buildhadamard10PC10nz*/;

                  32'he/*14:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'hf/*15:buildhadamard10PC10nz*/;

                  32'hf/*15:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h10/*16:buildhadamard10PC10nz*/;

                  32'h10/*16:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h11/*17:buildhadamard10PC10nz*/;

                  32'h11/*17:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h12/*18:buildhadamard10PC10nz*/;

                  32'h12/*18:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h13/*19:buildhadamard10PC10nz*/;

                  32'h13/*19:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h14/*20:buildhadamard10PC10nz*/;

                  32'h14/*20:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h15/*21:buildhadamard10PC10nz*/;

                  32'h15/*21:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h16/*22:buildhadamard10PC10nz*/;

                  32'h16/*22:buildhadamard10PC10nz*/:  buildhadamard10PC10nz <= 32'h17/*23:buildhadamard10PC10nz*/;
              endcase
               buildhadamard10PC10nz_pc_export <= buildhadamard10PC10nz;
               CVFPADDER10RRh10shot1 <= CVFPADDER10RRh10shot0;
               CVFPADDER10RRh10shot2 <= CVFPADDER10RRh10shot1;
               CVFPADDER10RRh10shot3 <= CVFPADDER10RRh10shot2;
               CVFPADDER12RRh10shot1 <= CVFPADDER12RRh10shot0;
               CVFPADDER12RRh10shot2 <= CVFPADDER12RRh10shot1;
               CVFPADDER12RRh10shot3 <= CVFPADDER12RRh10shot2;
               CVFPDIVIDER10RRh10shot1 <= CVFPDIVIDER10RRh10shot0;
               CVFPDIVIDER10RRh10shot2 <= CVFPDIVIDER10RRh10shot1;
               CVFPDIVIDER10RRh10shot3 <= CVFPDIVIDER10RRh10shot2;
               CVFPDIVIDER10RRh10shot4 <= CVFPDIVIDER10RRh10shot3;
               CVFPDIVIDER10RRh10shot5 <= CVFPDIVIDER10RRh10shot4;
               CVFPDIVIDER10RRh10shot6 <= CVFPDIVIDER10RRh10shot5;
               CVFPDIVIDER10RRh10shot7 <= CVFPDIVIDER10RRh10shot6;
               CVFPDIVIDER10RRh10shot8 <= CVFPDIVIDER10RRh10shot7;
               CVFPDIVIDER10RRh10shot9 <= CVFPDIVIDER10RRh10shot8;
               CVFPDIVIDER10RRh10shot10 <= CVFPDIVIDER10RRh10shot9;
               CVFPDIVIDER10RRh10shot11 <= CVFPDIVIDER10RRh10shot10;
               CVFPDIVIDER10RRh10shot12 <= CVFPDIVIDER10RRh10shot11;
               CVFPDIVIDER10RRh10shot13 <= CVFPDIVIDER10RRh10shot12;
               CVFPDIVIDER10RRh10shot14 <= CVFPDIVIDER10RRh10shot13;
               CVFPDIVIDER12RRh10shot1 <= CVFPDIVIDER12RRh10shot0;
               CVFPDIVIDER12RRh10shot2 <= CVFPDIVIDER12RRh10shot1;
               CVFPDIVIDER12RRh10shot3 <= CVFPDIVIDER12RRh10shot2;
               CVFPDIVIDER12RRh10shot4 <= CVFPDIVIDER12RRh10shot3;
               CVFPDIVIDER12RRh10shot5 <= CVFPDIVIDER12RRh10shot4;
               CVFPDIVIDER12RRh10shot6 <= CVFPDIVIDER12RRh10shot5;
               CVFPDIVIDER12RRh10shot7 <= CVFPDIVIDER12RRh10shot6;
               CVFPDIVIDER12RRh10shot8 <= CVFPDIVIDER12RRh10shot7;
               CVFPDIVIDER12RRh10shot9 <= CVFPDIVIDER12RRh10shot8;
               CVFPDIVIDER12RRh10shot10 <= CVFPDIVIDER12RRh10shot9;
               CVFPDIVIDER12RRh10shot11 <= CVFPDIVIDER12RRh10shot10;
               CVFPDIVIDER12RRh10shot12 <= CVFPDIVIDER12RRh10shot11;
               CVFPDIVIDER12RRh10shot13 <= CVFPDIVIDER12RRh10shot12;
               CVFPDIVIDER12RRh10shot14 <= CVFPDIVIDER12RRh10shot13;
               CVFPDIVIDER12RRh10shot0 <= (32'h8/*8:buildhadamard10PC10nz*/==buildhadamard10PC10nz);
               CVFPDIVIDER10RRh10shot0 <= (32'h8/*8:buildhadamard10PC10nz*/==buildhadamard10PC10nz);
               CVFPADDER12RRh10shot0 <= (32'h4/*4:buildhadamard10PC10nz*/==buildhadamard10PC10nz);
               CVFPADDER10RRh10shot0 <= (32'h4/*4:buildhadamard10PC10nz*/==buildhadamard10PC10nz);
               end 
              //End structure cvtToVerilog../build/hadamard/1.0


       end 
      

  CV_FP_FL4_ADDER_SP CVFPADDER10(
        .clk(clk),
        .reset(reset),
        .RR(CVFPADDER10_FPRR),
        .XX(CVFPADDER10_XX
),
        .YY(CVFPADDER10_YY),
        .FAIL(CVFPADDER10_fail));
  CV_FP_FL15_DIVIDER_SP CVFPDIVIDER10(
        .clk(clk),
        .reset(reset),
        .RR(CVFPDIVIDER10_FPRR),
        .NN(CVFPDIVIDER10_NN
),
        .DD(CVFPDIVIDER10_DD),
        .FAIL(CVFPDIVIDER10_fail));
  CV_FP_FL4_ADDER_SP CVFPADDER12(
        .clk(clk),
        .reset(reset),
        .RR(CVFPADDER12_FPRR),
        .XX(CVFPADDER12_XX
),
        .YY(CVFPADDER12_YY),
        .FAIL(CVFPADDER12_fail));
  CV_FP_FL15_DIVIDER_SP CVFPDIVIDER12(
        .clk(clk),
        .reset(reset),
        .RR(CVFPDIVIDER12_FPRR),
        .NN(CVFPDIVIDER12_NN
),
        .DD(CVFPDIVIDER12_DD),
        .FAIL(CVFPDIVIDER12_fail));
// Structural Resource (FU) inventory:// 1 vectors of width 5
// 38 vectors of width 1
// 12 vectors of width 32
// Total state bits in module = 427 bits.
// 132 continuously assigned (wire/non-state) bits 
//   cell CV_FP_FL4_ADDER_SP count=2
//   cell CV_FP_FL15_DIVIDER_SP count=2
// Total number of leaf cells = 4
endmodule

//  
// Layout wiring length esimtation mode is LAYOUT_lcp.
//HPR L/S (orangepath) auxiliary reports.
//KiwiC compilation report
//Kiwi Scientific Acceleration (KiwiC .net/CIL/C# to Verilog/SystemC compiler): Version Alpha 0.3.5k : 1st Mar 2018
//4/7/2018 9:44:17 PM
//Cmd line args:  /media/psf/Home/Projects/ACS/kiwi_planner/bitbucket-hprls2/kiwipro/kiwic/distro/lib/kiwic.exe ../build/hadamard.exe -vnl=hadamard.v -vnl-rootmodname=HROOT


//----------------------------------------------------------

//Report from KiwiC-fe.rpt:::
//KiwiC: front end input processing of class or method called KiwiSystem.Kiwi
//
//root_walk start thread at a static method (used as an entry point). Method name=KiwiSystem/Kiwi/.cctor uid=cctor14
//
//KiwiC start_thread (or entry point) uid=cctor14 full_idl=KiwiSystem.Kiwi..cctor
//
//Root method elaborated: specificf=S_kickoff_collate leftover=1+0
//
//KiwiC: front end input processing of class or method called System.BitConverter
//
//root_walk start thread at a static method (used as an entry point). Method name=System/BitConverter/.cctor uid=cctor12
//
//KiwiC start_thread (or entry point) uid=cctor12 full_idl=System.BitConverter..cctor
//
//Root method elaborated: specificf=S_kickoff_collate leftover=1+1
//
//KiwiC: front end input processing of class or method called hadamard
//
//root_walk start thread at a static method (used as an entry point). Method name=hadamard/.cctor uid=cctor10
//
//KiwiC start_thread (or entry point) uid=cctor10 full_idl=hadamard..cctor
//
//Root method elaborated: specificf=S_kickoff_collate leftover=1+2
//
//KiwiC: front end input processing of class or method called hadamard
//
//root_compiler: start elaborating class 'hadamard'
//
//elaborating class 'hadamard'
//
//compiling static method as entry point: style=Root idl=hadamard/Main_hw
//
//Performing root elaboration of method hadamard.Main_hw
//
//KiwiC start_thread (or entry point) uid=Mainhw10 full_idl=hadamard.Main_hw
//
//root_compiler class done: hadamard
//
//Report of all settings used from the recipe or command line:
//
//   kiwife-directorate-ready-flag=absent
//
//   kiwife-directorate-endmode=auto-restart
//
//   kiwife-directorate-startmode=self-start
//
//   cil-uwind-budget=10000
//
//   kiwic-cil-dump=disable
//
//   kiwic-kcode-dump=disable
//
//   kiwic-register-colours=disable
//
//   array-4d-name=KIWIARRAY4D
//
//   array-3d-name=KIWIARRAY3D
//
//   array-2d-name=KIWIARRAY2D
//
//   kiwi-dll=Kiwi.dll
//
//   kiwic-dll=Kiwic.dll
//
//   kiwic-zerolength-arrays=disable
//
//   kiwifefpgaconsole-default=enable
//
//   kiwife-directorate-style=basic
//
//   postgen-optimise=enable
//
//   kiwife-cil-loglevel=20
//
//   kiwife-ataken-loglevel=20
//
//   kiwife-gtrace-loglevel=20
//
//   kiwife-firstpass-loglevel=20
//
//   kiwife-overloads-loglevel=20
//
//   root=$attributeroot
//
//   srcfile=../build/hadamard.exe
//
//   kiwic-autodispose=disable
//
//END OF KIWIC REPORT FILE
//

//----------------------------------------------------------

//Report from restructure2:::
//Offchip Load/Store (and other) Ports
//*-----------+--------------------------+----------+--------+--------+-------+-----------*
//| Name      | Protocol                 | No Words | Awidth | Dwidth | Lanes | LaneWidth |
//*-----------+--------------------------+----------+--------+--------+-------+-----------*
//| dram0bank | IPB_HFAST1 PD_halfduplex | 4194304  | 22     | 256    | 32    | 8         |
//*-----------+--------------------------+----------+--------+--------+-------+-----------*
//

//----------------------------------------------------------

//Report from restructure2:::
//Restructure Technology Settings
//*---------------------------+---------+---------------------------------------------------------------------------------*
//| Key                       | Value   | Description                                                                     |
//*---------------------------+---------+---------------------------------------------------------------------------------*
//| int-flr-mul               | 1000    |                                                                                 |
//| max-no-fp-addsubs         | 6       | Maximum number of adders and subtractors (or combos) to instantiate per thread. |
//| max-no-fp-muls            | 6       | Maximum number of f/p multipliers or dividers to instantiate per thread.        |
//| max-no-int-muls           | 3       | Maximum number of int multipliers to instantiate per thread.                    |
//| max-no-fp-divs            | 2       | Maximum number of f/p dividers to instantiate per thread.                       |
//| max-no-int-divs           | 2       | Maximum number of int dividers to instantiate per thread.                       |
//| max-no-rom-mirrors        | 8       | Maximum number of times to mirror a ROM per thread.                             |
//| max-ram-data_packing      | 8       | Maximum number of user words to pack into one RAM/loadstore word line.          |
//| fp-fl-dp-div              | 5       |                                                                                 |
//| fp-fl-dp-add              | 4       |                                                                                 |
//| fp-fl-dp-mul              | 3       |                                                                                 |
//| fp-fl-sp-div              | 15      |                                                                                 |
//| fp-fl-sp-add              | 4       |                                                                                 |
//| fp-fl-sp-mul              | 5       |                                                                                 |
//| res2-offchip-threshold    | 1000000 |                                                                                 |
//| res2-combrom-threshold    | 64      |                                                                                 |
//| res2-combram-threshold    | 32      |                                                                                 |
//| res2-regfile-threshold    | 8       |                                                                                 |
//| res2-loadstore-port-count | 1       |                                                                                 |
//*---------------------------+---------+---------------------------------------------------------------------------------*
//

//----------------------------------------------------------

//Report from restructure2:::
//PC codings points for buildhadamard10PC10 
//*--------------------------------+-----+---------+--------------+------+--------+-------+-----+------*
//| gb-flag/Pause                  | eno | Root Pc | hwm          | Exec | Reverb | Start | End | Next |
//*--------------------------------+-----+---------+--------------+------+--------+-------+-----+------*
//| XU32'0:"0:buildhadamard10PC10" | 811 | 0       | hwm=0.0.0    | 0    |        | -     | -   | 1    |
//| XU32'1:"1:buildhadamard10PC10" | 809 | 1       | hwm=0.0.0    | 1    |        | -     | -   | 4    |
//| XU32'1:"1:buildhadamard10PC10" | 810 | 1       | hwm=0.0.0    | 1    |        | -     | -   | 2    |
//| XU32'2:"2:buildhadamard10PC10" | 808 | 2       | hwm=0.0.0    | 2    |        | -     | -   | 3    |
//| XU32'4:"4:buildhadamard10PC10" | 807 | 3       | hwm=0.0.0    | 3    |        | -     | -   | 1    |
//| XU32'8:"8:buildhadamard10PC10" | 806 | 4       | hwm=0.19.0   | 23   |        | 5     | 23  | 3    |
//*--------------------------------+-----+---------+--------------+------+--------+-------+-----+------*
//

//----------------------------------------------------------

//Report from restructure2:::
//  Absolute key numbers for scheduled edge res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'0:"0:buildhadamard10PC10" 811 :  major_start_pcl=0   edge_private_start/end=-1/-1 exec=0 (dend=0)
//Simple greedy schedule for res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'0:"0:buildhadamard10PC10"
//res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'0:"0:buildhadamard10PC10"
//*------+-----+---------+----------------------------------------------------------------------------------------------------------------------*
//| pc   | eno | Phaser  | Work                                                                                                                 |
//*------+-----+---------+----------------------------------------------------------------------------------------------------------------------*
//| F0   | -   | R0 CTRL |                                                                                                                      |
//| F0   | 811 | R0 DATA |                                                                                                                      |
//| F0+E | 811 | W0 DATA | ksubsAbendSyndrome te=te:F0 write(U8'128) ksubsGpioLeds te=te:F0 write(U8'128) ksubsManualWaypoint te=te:F0 write(U\ |
//|      |     |         | 8'0) hadamard.running te=te:F0 write(U1'0) hadamard.done te=te:F0 write(U1'0) hadamard.downout te=te:F0 write(0f) h\ |
//|      |     |         | adamard.upout te=te:F0 write(0f)                                                                                     |
//*------+-----+---------+----------------------------------------------------------------------------------------------------------------------*
//

//----------------------------------------------------------

//Report from restructure2:::
//  Absolute key numbers for scheduled edge res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'1:"1:buildhadamard10PC10" 809 :  major_start_pcl=1   edge_private_start/end=-1/-1 exec=1 (dend=0)
//,   Absolute key numbers for scheduled edge res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'1:"1:buildhadamard10PC10" 810 :  major_start_pcl=1   edge_private_start/end=-1/-1 exec=1 (dend=0)
//Simple greedy schedule for res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'1:"1:buildhadamard10PC10"
//res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'1:"1:buildhadamard10PC10"
//*------+-----+---------+--------------------------------------------------------------------------*
//| pc   | eno | Phaser  | Work                                                                     |
//*------+-----+---------+--------------------------------------------------------------------------*
//| F1   | -   | R0 CTRL |                                                                          |
//| F1   | 810 | R0 DATA |                                                                          |
//| F1+E | 810 | W0 DATA |                                                                          |
//| F1   | 809 | R0 DATA |                                                                          |
//| F1+E | 809 | W0 DATA | hadamard.running te=te:F1 write(U1'1) hadamard.done te=te:F1 write(U1'0) |
//*------+-----+---------+--------------------------------------------------------------------------*
//

//----------------------------------------------------------

//Report from restructure2:::
//  Absolute key numbers for scheduled edge res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'2:"2:buildhadamard10PC10" 808 :  major_start_pcl=2   edge_private_start/end=-1/-1 exec=2 (dend=0)
//Simple greedy schedule for res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'2:"2:buildhadamard10PC10"
//res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'2:"2:buildhadamard10PC10"
//*------+-----+---------+------*
//| pc   | eno | Phaser  | Work |
//*------+-----+---------+------*
//| F2   | -   | R0 CTRL |      |
//| F2   | 808 | R0 DATA |      |
//| F2+E | 808 | W0 DATA |      |
//*------+-----+---------+------*
//

//----------------------------------------------------------

//Report from restructure2:::
//  Absolute key numbers for scheduled edge res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'4:"4:buildhadamard10PC10" 807 :  major_start_pcl=3   edge_private_start/end=-1/-1 exec=3 (dend=0)
//Simple greedy schedule for res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'4:"4:buildhadamard10PC10"
//res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'4:"4:buildhadamard10PC10"
//*------+-----+---------+------*
//| pc   | eno | Phaser  | Work |
//*------+-----+---------+------*
//| F3   | -   | R0 CTRL |      |
//| F3   | 807 | R0 DATA |      |
//| F3+E | 807 | W0 DATA |      |
//*------+-----+---------+------*
//

//----------------------------------------------------------

//Report from restructure2:::
//  Absolute key numbers for scheduled edge res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'8:"8:buildhadamard10PC10" 806 :  major_start_pcl=4   edge_private_start/end=5/23 exec=23 (dend=19)
//Simple greedy schedule for res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'8:"8:buildhadamard10PC10"
//res2: nopipeline: Thread=buildhadamard10PC10 state=XU32'8:"8:buildhadamard10PC10"
//*-------+-----+----------+--------------------------------------------------------------------------------------------------------------------------------------*
//| pc    | eno | Phaser   | Work                                                                                                                                 |
//*-------+-----+----------+--------------------------------------------------------------------------------------------------------------------------------------*
//| F4    | -   | R0 CTRL  |                                                                                                                                      |
//| F4    | 806 | R0 DATA  | CVFPADDER12 te=te:F4 *fixed-func-ALU*(hadamard.down, hadamard.up) CVFPADDER10 te=te:F4 *fixed-func-ALU*(hadamard.up, -hadamard.down) |
//| F5    | 806 | R1 DATA  |                                                                                                                                      |
//| F6    | 806 | R2 DATA  |                                                                                                                                      |
//| F7    | 806 | R3 DATA  |                                                                                                                                      |
//| F8    | 806 | R4 DATA  | CVFPDIVIDER12 te=te:F8 *fixed-func-ALU*(E1, 1.414214f) CVFPDIVIDER10 te=te:F8 *fixed-func-ALU*(E2, 1.414214f)                        |
//| F9    | 806 | R5 DATA  |                                                                                                                                      |
//| F10   | 806 | R6 DATA  |                                                                                                                                      |
//| F11   | 806 | R7 DATA  |                                                                                                                                      |
//| F12   | 806 | R8 DATA  |                                                                                                                                      |
//| F13   | 806 | R9 DATA  |                                                                                                                                      |
//| F14   | 806 | R10 DATA |                                                                                                                                      |
//| F15   | 806 | R11 DATA |                                                                                                                                      |
//| F16   | 806 | R12 DATA |                                                                                                                                      |
//| F17   | 806 | R13 DATA |                                                                                                                                      |
//| F18   | 806 | R14 DATA |                                                                                                                                      |
//| F19   | 806 | R15 DATA |                                                                                                                                      |
//| F20   | 806 | R16 DATA |                                                                                                                                      |
//| F21   | 806 | R17 DATA |                                                                                                                                      |
//| F22   | 806 | R18 DATA |                                                                                                                                      |
//| F23   | 806 | R19 DATA |                                                                                                                                      |
//| F23+E | 806 | W0 DATA  | hadamard.done te=te:F23 write(U1'1) hadamard.downout te=te:F23 write(E3) hadamard.upout te=te:F23 write(E4)                          |
//*-------+-----+----------+--------------------------------------------------------------------------------------------------------------------------------------*
//

//----------------------------------------------------------

//Report from restructure2:::
//Highest off-chip SRAM/DRAM location in use on port dram0bank is <null> (--not-used--) bytes=1048576

//----------------------------------------------------------

//Report from enumbers:::
//Concise expression alias report.
//
//  E1 =.= hadamard.down+hadamard.up
//
//  E2 =.= hadamard.up+-hadamard.down
//
//  E3 =.= Cf((hadamard.up+-hadamard.down)/1.414214f)
//
//  E4 =.= Cf((hadamard.down+hadamard.up)/1.414214f)
//

//----------------------------------------------------------

//Report from IP-XACT input/output:::
//Write IP-XACT component file for hadamard to hadamard

//----------------------------------------------------------

//Report from verilog_render:::
//Structural Resource (FU) inventory:
//1 vectors of width 5
//
//38 vectors of width 1
//
//12 vectors of width 32
//
//Total state bits in module = 427 bits.
//
//132 continuously assigned (wire/non-state) bits 
//
//Total number of leaf cells = 0
//

//Major Statistics Report:
//Thread KiwiSystem/Kiwi/.cctor uid=cctor14 has 6 CIL instructions in 1 basic blocks
//Thread System/BitConverter/.cctor uid=cctor12 has 2 CIL instructions in 1 basic blocks
//Thread hadamard/.cctor uid=cctor10 has 6 CIL instructions in 1 basic blocks
//Thread hadamard/Main_hw uid=Mainhw10 has 19 CIL instructions in 5 basic blocks
//Thread mpc10 has 5 bevelab control states (pauses)
//Reindexed thread buildhadamard10PC10 with 24 minor control states
// eof (HPR L/S Verilog)
