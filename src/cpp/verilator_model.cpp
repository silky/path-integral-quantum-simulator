#include "Vfindamp.h"
#include "Vpack_input.h"
#include "Vunpack_output.h"
#include "Vunpack_ampreply.h"
#include <bitset>

#include "sc_vardefs.h"

#include "systemc"
using namespace sc_core;

SC_MODULE(stim_gen) {
  int clkcnt = 0;

  sc_in<bool> clk;
  sc_in<bool> rst;
  
  sc_out<uint32_t>	inp_splitdepth;
  sc_out<uint32_t>	depth;
  sc_out<bool>	inp_wu_valid;
  sc_out<bool>	inp_amp_valid;
  sc_out<uint32_t>	target;
  sc_out<uint32_t>	inital;
  sc_out<vluint64_t>	inp_amp;

  void do_stim() {
    if (rst) {
      clkcnt = 0;
      inp_amp_valid.write(0);
      inp_wu_valid.write(0);
      
  } else if (clk.event()) {
      inp_splitdepth.write(0);
      inp_amp_valid.write(0);
      inp_amp.write(0);
      
      if (clkcnt == 1) {
          cout << "making request" << endl;
          inp_wu_valid.write(1);
          depth.write(1);
          target.write(1);
          inital.write(1);
      } else {
          inp_wu_valid.write(0);
      }
      clkcnt++;
    }
  };

  SC_CTOR(stim_gen) : SCD(clk, rst, inp_splitdepth, depth, inp_wu_valid, inp_amp_valid, target, inital, inp_amp) {
    SC_METHOD(do_stim);
    sensitive(rst);
    sensitive_pos(clk);
  }
};

// SFixed 2 10
#define SHIFT_AMOUNT 10 // 2^16 = 65536
#define SHIFT_MASK ((1 << SHIFT_AMOUNT) - 1) // 65535 (all LSB set, all MSB clear)

float parse_fixed(uint32_t fpt) {
    uint32_t intpart = (fpt >> SHIFT_AMOUNT) & SHIFT_MASK;
    uint32_t divpart = fpt & SHIFT_MASK;
    cout << "int " << intpart << " div " << divpart << endl;
    return (float)intpart + ((float)divpart/(float)(1<<SHIFT_AMOUNT));
}

SC_MODULE(testoutput) {
    sc_in<bool> clk;
    sc_in<bool> gotamp;
    sc_in<uint32_t>	ptrloc;
    sc_in<uint32_t> real_input;


    void run() {
        cout << "ptr is at " << (int32_t)(ptrloc) << endl;
        if (clk.event() && gotamp.read()) {
            cout << "seen finished at " << sc_time() << endl;
            // cout << "realpt is " << std::bitset<32> (real_input.read()) << endl;
            cout << "interp: " << parse_fixed(real_input.read()) << endl;
            sc_stop();
        }
    }
    
    SC_CTOR(testoutput) {
      SC_METHOD(run);
      sensitive_pos(clk);
    }

};

int sc_main(int argc, char **argv) {

  sc_signal<uint32_t> SCD(Areal, Aimag, Breal, Bimag, Creal, Cimag);
  sc_signal<bool> SCD(rst);

  Verilated::commandArgs(argc, argv);
  sc_clock clk("clk", 10, 0.5, 3, true);
  Vfindamp *top;
  Vpack_input *input;
  Vunpack_output *output;
  Vunpack_ampreply* ampparser;
  stim_gen *stim;
  top = new Vfindamp("top");
  // bottom = new Vfindamp("bottom");

  
  input = new Vpack_input("encodeinput");
  output = new Vunpack_output("decodeoutput");
  ampparser = new Vunpack_ampreply("amplitudeparser");
  stim = new stim_gen("stimuli");

  top->clk(clk);
  top->rst(rst);
  input->clk(clk);
  input->rst(rst);
  output->clk(clk);
  output->rst(rst);
  stim->clk(clk);
  stim->rst(rst);
  ampparser->clk(clk);
  ampparser->rst(rst);
  
  sc_signal<uint32_t>	inp_splitdepth;
  sc_signal<uint32_t>	depth;
  sc_signal<bool>	inp_wu_valid;
  sc_signal<bool>	inp_amp_valid;
  sc_signal<uint32_t>	target;
  sc_signal<uint32_t>	inital;
  sc_signal<vluint64_t>	inp_amp;

  input->inp_splitdepth(inp_splitdepth);
  stim->inp_splitdepth(inp_splitdepth);
  input->depth(depth);
  stim->depth(depth);
  input->inp_wu_valid(inp_wu_valid);
  stim->inp_wu_valid(inp_wu_valid);
  input->inp_amp_valid(inp_amp_valid);
  stim->inp_amp_valid(inp_amp_valid);
  input->target(target);
  stim->target(target);
  input->inital(inital);
  stim->inital(inital);
  input->inp_amp(inp_amp);
  stim->inp_amp(inp_amp);

  sc_signal<sc_bv<260> >	input_bundle;
  sc_signal<sc_bv<263> >	output_bundle;


  top->input_bundle(input_bundle);
  input->input_bundle(input_bundle);
  output->output_bundle(output_bundle);
  top->output_bundle(output_bundle);
  
  testoutput* finish_cond;
  finish_cond = new testoutput("finishcond");
  finish_cond->clk(clk);
  
  // output unpacker
  sc_signal<bool>	outp_wu_valid;
  sc_signal<bool>	outp_amp_valid;
  sc_signal<vluint64_t>	outp_amp;
  sc_signal<sc_bv<210> >	outp_wu;
  sc_signal<uint32_t>	ptrloc;
  
  // amp parser
  sc_signal<uint32_t>	destidx;
  sc_signal<uint32_t>	destpredidx;
  sc_signal<uint32_t>	realpt;
  sc_signal<uint32_t>	imagpt;
  sc_signal<uint32_t>	targetstate;

  
  output->outp_wu_valid(outp_wu_valid);
  output->outp_amp_valid(outp_amp_valid);
  output->outp_amp(outp_amp);
  output->outp_wu(outp_wu);
  output->ptrloc(ptrloc);
  
  ampparser->ampreply(outp_amp);
  ampparser->destidx(destidx);
  ampparser->destpredidx(destpredidx);
  ampparser->realpt(realpt);
  ampparser->imagpt(imagpt);
  ampparser->targetstate(targetstate);


  finish_cond->gotamp(outp_amp_valid);
  finish_cond->ptrloc(ptrloc);
  finish_cond->real_input(realpt);

  // finish_cond->gotwu(output->outp_wu_valid);

  sc_start(10000, SC_NS);
  // while (!Verilated::gotFinish()) { sc_start(1, SC_NS); } // we can't have
  // verilog directives in clash code.
  delete top;
  exit(0);
}
