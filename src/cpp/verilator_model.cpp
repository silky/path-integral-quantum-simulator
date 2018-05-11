#include "Vcmult.h"
#include "sc_vardefs.h"

#include "systemc"
using namespace sc_core;

SC_MODULE(cmult_test)
{
  sc_in<bool> clock;
  sc_in<bool> reset;
  sc_out<uint32_t> Areal;
  sc_out<uint32_t> Aimag;
  
  sc_out<uint32_t> Breal;
  sc_out<uint32_t> Bimag;

  sc_in<uint32_t> Creal;
  sc_in<uint32_t> Cimag;
  
  void do_stim()
  {
    // if (reset) {
    //    dout = false;
    // } else if (clock.event()) {
    //     dout = din;}
  };
  
  SC_CTOR(cmult_test) {
    SC_METHOD(do_stim);
   	sensitive(reset);
	sensitive_pos(clock);
  }
};

int sc_main(int argc, char **argv) {
    
    sc_signal<uint32_t> SCD(Areal, Aimag, Breal, Bimag, Creal, Cimag);
    sc_signal<bool> SCD(rst);
    
    Verilated::commandArgs(argc, argv);
    sc_clock clk ("clk",10, 0.5, 3, true);
    Vcmult* top;
    cmult_test* stimgen;
    stimgen = new cmult_test("Stimuls generator");
    top = new Vcmult("top");   // SP_CELL (top, Vour);
    
    stimgen->clock(clk);
    stimgen->reset(rst);
    
    stimgen->Areal(Areal);
    stimgen->Aimag(Aimag);
    stimgen->Breal(Breal);
    stimgen->Bimag(Bimag);
    stimgen->Creal(Creal);
    stimgen->Cimag(Cimag);

    
    top->clk(clk);           // SP_PIN  (top, clk, clk);
    top->rst(rst);
    
    top->Areal(Areal);
    top->Aimag(Aimag);
    top->Breal(Breal);
    top->Bimag(Bimag);
    top->Creal(Creal);
    top->Cimag(Cimag);



    sc_start(100, SC_NS);
    // while (!Verilated::gotFinish()) { sc_start(1, SC_NS); } // we can't have verilog directives in clash code.
    delete top;
    exit(0);
}


