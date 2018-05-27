#include "Vfindamp.h"
#include "Vpack_input.h"
#include "Vpack_workunit.h"
#include "Vunpack_ampreply.h"
#include "Vunpack_output.h"
#include "Vparse_ptr.h"

#include "Vjoin_input.h"
#include "Vjoin_output.h"
#include "Vsplit_input.h"
#include "Vsplit_output.h"
#include <bitset>

#include "sc_vardefs.h"

#include "systemc"
using namespace sc_core;

const int WUSZ = 211;
const int INBSZ = 260;
const int OUTBSZ = INBSZ + 3;

// SFixed 2 10
#define SHIFT_AMOUNT 10 // 2^16 = 65536
#define SHIFT_MASK                                                             \
  ((1 << SHIFT_AMOUNT) - 1) // 65535 (all LSB set, all MSB clear)

float parse_fixed(uint32_t fpt) {
  uint32_t intpart = (fpt >> SHIFT_AMOUNT) & SHIFT_MASK;
  uint32_t divpart = fpt & SHIFT_MASK;
  cout << "int " << intpart << " div " << divpart << endl;
  return (float)intpart + ((float)divpart / (float)(1 << SHIFT_AMOUNT));
}

SC_MODULE(stim_gen) {
  int clkcnt = 0;

  sc_in<bool> clk;
  sc_in<bool> rst;

  sc_signal<uint32_t> inp_splitdepth;
  sc_signal<uint32_t> depth;
  sc_signal<bool> inp_wu_valid;
  // sc_signal<bool>	inp_amp_valid;
  sc_signal<uint32_t> target;
  sc_signal<uint32_t> inital;
  // sc_signal<vluint64_t>	inp_amp;

  sc_signal<sc_bv<WUSZ>> wu_sig;
  sc_out<sc_bv<WUSZ>> workunit;

  void do_stim() {
    if (rst) {
      clkcnt = 0;

    } else if (clk.event()) {
      inp_splitdepth.write(0);
      // inp_amp_valid.write(0);
      // inp_amp.write(0);

      if (clkcnt == 1) {
        cout << "making request" << endl;
        inp_wu_valid.write(1);
        depth.write(2);
        target.write(1);
        inital.write(1);
      } else {
        inp_wu_valid.write(0);
      }
      clkcnt++;
    }
  };

  SC_CTOR(stim_gen)
      : SCD(clk, rst, inp_splitdepth, depth, inp_wu_valid, target, inital,
            wu_sig, workunit) {
    SC_METHOD(do_stim);
    sensitive(rst);
    sensitive_pos(clk);

    Vpack_workunit *packer = new Vpack_workunit("packer");
    packer->clk(clk);
    packer->rst(rst);

    packer->inp_splitdepth(inp_splitdepth);
    packer->depth(depth);
    packer->inp_wu_valid(inp_wu_valid);
    packer->target(target);
    packer->inital(inital);
    packer->workunit(workunit);
  }
};

SC_MODULE (print_ampreply) {
    sc_in<bool>	clk;
    sc_in<bool>	rst;
    sc_in<vluint64_t>	ampreply;

    private:
    sc_signal<bool> valid;
    sc_signal<uint32_t>	destidx;
    sc_signal<uint32_t>	destpredidx;
    sc_signal<uint32_t>	realpt;
    sc_signal<uint32_t>	imagpt;
    sc_signal<uint32_t>	targetstate;

    public:
        
    void run() {
        if (valid.read() != 0) {
            cout << "got a amp reply for target:" << targetstate << " wu[" << destidx << "][" << destpredidx << "]:" <<
            parse_fixed(realpt) << "+" << parse_fixed(imagpt) << "i" << endl; 
        }
    }
        
    SC_CTOR(print_ampreply) : SCD(valid, destidx, destpredidx, realpt, imagpt, targetstate) {
        SC_METHOD(run);
        sensitive_pos(clk);

        Vunpack_ampreply* ampunpk = new Vunpack_ampreply("printer_unpacker");
        ampunpk->clk(clk);
        ampunpk->rst(rst);
        
        ampunpk->valid(valid);
        ampunpk->ampreply(ampreply);
        ampunpk->destidx(destidx);
        ampunpk->destpredidx(destpredidx);
        ampunpk->realpt(realpt);
        ampunpk->imagpt(imagpt);
        ampunpk->targetstate(targetstate);
    }

};

SC_MODULE(testoutput) {
  sc_in<bool> clk;
  sc_in<bool> rst;

  sc_in<sc_bv<OUTBSZ>> networkoutput;

  // sc_in<> networkoutput;
  sc_signal<bool> gotamp;
  sc_signal<uint32_t> realpt;
  

  // ampparser signals
  sc_signal<uint32_t> destidx;     // NC
  sc_signal<uint32_t> destpredidx; // NC
  sc_signal<uint32_t> imagpt;      // NC
  sc_signal<uint32_t> targetstate; // NC
  
  // split signals
  sc_signal<uint32_t>	pos; // NC
  sc_signal<vluint64_t>	amp;
  sc_signal<sc_bv<211> > wu; // NC



  void run() {
    if (clk.event() && gotamp.read()) {
      cout << "seen finished at " << sc_time() << endl;
      // cout << "realpt is " << std::bitset<32> (real_input.read()) << endl;
      cout << "interp: " << parse_fixed(realpt.read()) << endl;
      sc_stop();
    }
  }

  SC_CTOR(testoutput) : SCD(clk, rst, networkoutput, gotamp, realpt),
  SCD(destidx, destpredidx, imagpt, targetstate) {
    SC_METHOD(run);
    sensitive_pos(clk);

    Vunpack_ampreply *ampparser = new Vunpack_ampreply("amp_parser_tester");
    ampparser->clk(clk);
    ampparser->rst(rst);
    
    Vsplit_output *splitter = new Vsplit_output("splitter");
    splitter->clk(clk);
    splitter->rst(rst);
    
    splitter->output_bundle(networkoutput);
    splitter->pos(pos);
    splitter->amp(amp);
    splitter->wu(wu);
    
    ampparser->ampreply(amp); // From outunpack
    ampparser->valid(gotamp);
    ampparser->destidx(destidx);
    ampparser->destpredidx(destpredidx);
    ampparser->realpt(realpt);
    ampparser->imagpt(imagpt);
    ampparser->targetstate(targetstate);
  }
};

SC_MODULE(Network) {
  sc_in<bool> clk;
  sc_in<bool> rst;

  sc_in<sc_bv<WUSZ>> stim_wu;
  // sc_out<sc_bv<OUTBSZ>> network_result;
  sc_out<sc_bv<OUTBSZ>> network_result;

  private:
  sc_signal<sc_bv<INBSZ>> input_bundle_w;
  sc_signal<sc_bv<OUTBSZ>> output_bundle_from_top;
  sc_signal<sc_bv<OUTBSZ>> output_bundle_to_out;
  

  // Vjoin_input signals
  sc_signal<uint32_t>	depthlim;
  sc_signal<vluint64_t>	amp;
  sc_signal<sc_bv<211> >	wu;
  
  // Top output split connections
  sc_signal<uint32_t>	top_pos_output_NC; // NC
  sc_signal<vluint64_t>	top_amp_output_NC; // NC
  sc_signal<sc_bv<211> >	top_to_bottom_wu;


  // Vjoin_into_bottom signals
  sc_signal<uint32_t>	bottom_depthlim;
  sc_signal<vluint64_t>	bottom_amplitude_input;
  sc_signal<sc_bv<INBSZ>> bottom_input_bundle;

  // Bottom output split connections
  sc_signal<uint32_t>	bottom_pos_output_NC; // NC
  sc_signal<vluint64_t>	bottom_to_top_amp; 
  sc_signal<sc_bv<263> >	bottom_to_outsplit_bundle;
  sc_signal<sc_bv<211> >	bottom_wu_out_NC; // NC


  sc_signal<uint32_t> ptr, ptr2;

  public:
  void run() {
    if (top_to_bottom_wu.read() != 0) {
         cout << "request:" << top_to_bottom_wu.read() << endl;
    }

    // if (top_to_bottom_wu.read() == 0) {
    //     cout << "top to bottom wu zero" << endl;
    // } else {
    //     cout << "top to bottom wu: " << top_to_bottom_wu << endl;
    // }
    
    if (clk.event()) {
      network_result = output_bundle_from_top;
      wu = stim_wu;
      amp = 0;
      // network_result.write(output_bundle_w.read());
      cout << "ptrlocs: " << (int32_t)ptr << " " << (int32_t)ptr2 << endl;
    } 
  }

  SC_CTOR(Network)
      : SCD(clk, rst, stim_wu, network_result, input_bundle_w, output_bundle_from_top, output_bundle_to_out),
      SCD(depthlim, amp, wu),
      SCD(top_pos_output_NC, top_amp_output_NC, top_to_bottom_wu),
      SCD(bottom_depthlim, bottom_amplitude_input, bottom_input_bundle),
      SCD(bottom_pos_output_NC, bottom_to_top_amp, bottom_to_outsplit_bundle, bottom_wu_out_NC),
      SCD(ptr, ptr2) {
    SC_METHOD(run);
    sensitive_pos(clk);

    // network everything!

    Vfindamp *top = new Vfindamp("top_findamp");
    top->clk(clk);
    top->rst(rst);

    // you need to delare signals as classs members - as locals, they are
    // dstroyed at ctor term and they need to continue to exist

    top->input_bundle(input_bundle_w);
    top->output_bundle(output_bundle_from_top);  // CRASHES.

    Vjoin_input *joiner = new Vjoin_input("joiner");
    joiner->clk(clk);
    joiner->rst(rst);
    
    depthlim.write(1);
    joiner->depthlim(depthlim);
    joiner->amp(bottom_to_top_amp);
    joiner->wu(wu);
    joiner->input_bundle(input_bundle_w);
    
    // we need to extract the requested workunit for bottom to process.
    Vsplit_output *top_output_split = new Vsplit_output("top_output_split");
    top_output_split->clk(clk);
    top_output_split->rst(rst);
    
    // SCD(top_pos_output_NC, top_amp_output_NC, top_to_outsplit_bundle, top_to_bottom_wu),

    top_output_split->pos(top_pos_output_NC);
    top_output_split->amp(top_amp_output_NC);
    top_output_split->output_bundle(output_bundle_from_top);
    top_output_split->wu(top_to_bottom_wu);
    
    Vparse_ptr *parsetopptr = new Vparse_ptr("parsetopptr");
    parsetopptr->clk(clk);
    parsetopptr->rst(rst);
    parsetopptr->ptrbundle(top_pos_output_NC);
    parsetopptr->ptrparsed(ptr);

    
    // AMPFINDER MK 2!
    // need a output_spliter to get the requested wu from top
    // need join_input to get the wu+empty amp into the 
    // need another 
    
    Vfindamp *bottom = new Vfindamp("bottom_findamp");
    bottom->clk(clk);
    bottom->rst(rst);
    bottom->input_bundle(bottom_input_bundle);

    Vjoin_input *join_into_bottom = new Vjoin_input("join_into_bottom");
    join_into_bottom->clk(clk);
    join_into_bottom->rst(rst);


    // SCD(bottom_depthlim, bottom_amplitude_input, bottom_workunit_input, bottom_input_bundle),
    bottom_depthlim.write(0);
    join_into_bottom->depthlim(bottom_depthlim);
    join_into_bottom->amp(bottom_amplitude_input);
    join_into_bottom->wu(top_to_bottom_wu);
    join_into_bottom->input_bundle(bottom_input_bundle);

    
    // we need to extract the requested workunit for bottom to process.
    Vsplit_output *bottom_output_split = new Vsplit_output("bottom_output_split");
    bottom_output_split->clk(clk);
    bottom_output_split->rst(rst);
    
    // SCD(bottom_pos_output_NC, bottom_to_top_amp, bottom_to_outsplit_bundle, bottom_wu_out_NC),
    
    bottom->output_bundle(bottom_to_outsplit_bundle);
    bottom_output_split->pos(bottom_pos_output_NC);
    bottom_output_split->amp(bottom_to_top_amp);
    bottom_output_split->output_bundle(bottom_to_outsplit_bundle);
    bottom_output_split->wu(bottom_wu_out_NC);
    
    Vparse_ptr *parsebottomptr = new Vparse_ptr("parsebottomptr");
    parsebottomptr->clk(clk);
    parsebottomptr->rst(rst);
    parsebottomptr->ptrbundle(bottom_pos_output_NC);
    parsebottomptr->ptrparsed(ptr2);
    
    // PROBES
    print_ampreply* commprint = new print_ampreply("commprint");
    commprint->clk(clk);
    commprint->rst(rst);
    commprint->ampreply(bottom_to_top_amp);
    

    // Vsplit_output *so = new Vsplit_output("so");
    // Vjoin_output *jo = new Vjoin_output("jo");
  }
};

int sc_main(int argc, char **argv) {

  sc_signal<uint32_t> SCD(Areal, Aimag, Breal, Bimag, Creal, Cimag);
  sc_signal<bool> SCD(rst);

  Verilated::commandArgs(argc, argv);
  sc_clock clk("clk", 10, 0.5, 3, true);

  stim_gen *stim;
  stim = new stim_gen("stimuli");

  testoutput* finish_cond;
  finish_cond = new testoutput("finishcond");

  Network *net = new Network("Network");

  stim->clk(clk);
  stim->rst(rst);
  finish_cond->clk(clk);
  finish_cond->rst(rst);
  net->clk(clk);
  net->rst(rst);

  // introduce a request into the network
  sc_signal<sc_bv<WUSZ>> SCD(stim_wu);
  sc_signal<sc_bv<OUTBSZ>> SCD(outputbundle);

  stim->workunit(stim_wu);
  net->stim_wu(stim_wu);
  net->network_result(outputbundle);
  finish_cond->networkoutput(outputbundle);

  sc_start(1000, SC_NS);
  exit(0);
}
