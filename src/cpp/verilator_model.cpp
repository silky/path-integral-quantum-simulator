#include "Vfindamp.h"
#include "Vheightdiv.h"

#include "Vpack_input.h"
#include "Vpack_workunit.h"
#include "Vunpack_ampreply.h"
#include "Vunpack_output.h"
#include "Vparse_ptr.h"

#include "VnetworkRTL.h"

#include "Vjoin_input.h"
#include "Vjoin_output.h"
#include "Vsplit_input.h"
#include "Vsplit_output.h"
#include <bitset>

#include "sc_vardefs.h"
#include "widths.h"

#include "systemc"
using namespace sc_core;
// 
// const int WUSZ = 222;
// const int INBSZ = 276;
// const int OUTBSZ = INBSZ;

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

  sc_signal<sc_biguint<WUSZ>> wu_sig;
  sc_out<sc_biguint<WUSZ>> workunit;

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
        target.write(0);
        inital.write(0);
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

  sc_in<sc_biguint<OUTBSZ>> networkoutput;

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
  sc_signal<sc_biguint<WUSZ> > wu; // NC



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

  sc_in<sc_biguint<WUSZ>> stim_wu;
  sc_out<sc_biguint<OUTBSZ>> network_result;

  private:
  // top output
  sc_signal<sc_biguint<OUTBSZ> >	top_output_bundle;

  // join into top
  sc_signal<sc_biguint<WUSZ> > top_wu_input;
  sc_signal<uint32_t> top_depthlim; // Fixed value
  sc_signal<sc_biguint<INBSZ>>	input_bundle_to_top;
  
  // split from top - output_bundle_from_top is input here
  sc_signal<uint32_t>	top_pos_track;
  sc_signal<vluint64_t>	top_amp_output;
  sc_signal<sc_biguint<WUSZ> >	top_to_heightdiv_wu;

  // Heightdiv
  sc_signal<vluint64_t>	bottom_to_top_amp_rply;
  sc_signal<sc_biguint<WUSZ> >	bottom_high_req;
  sc_signal<sc_biguint<WUSZ> >	bottom_low_req;

  // join into bottom_low, bottom_high
  sc_signal<uint32_t> bottom_depthlim; // fixed value
  sc_signal<vluint64_t>	bottoms_amp_input; // fixed Nothing
  sc_signal<sc_biguint<INBSZ>>	input_bundle_to_bottom_low;
  sc_signal<sc_biguint<INBSZ>>	input_bundle_to_bottom_high;

  // bottom outputs
  sc_signal<sc_biguint<OUTBSZ> >	output_bundle_bottom_low;
  sc_signal<sc_biguint<OUTBSZ> >	output_bundle_bottom_high;

  // split from bottoms
  sc_signal<uint32_t>	pos_bottom_low;
  sc_signal<uint32_t>	pos_bottom_high;
  sc_signal<vluint64_t>	amp_bottom_high_to_div;
  sc_signal<sc_biguint<WUSZ> >	wu_bottom_high_tieoff;
  sc_signal<vluint64_t>	amp_bottom_low_to_div;
  sc_signal<sc_biguint<WUSZ> >	wu_bottom_low_tieoff;
  
  // debug
  
  sc_signal<bool> dbg_valid;
  sc_signal<uint32_t> dbg_destidx, dbg_destpredidx, dbg_realpt, dbg_imagpt, dbg_targetstate;
  
  public:
  void run() {
    if (top_wu_input.read() != 0) {
       cout << "top request" << endl;
    }
    if (bottom_high_req.read() != 0) {
       cout << "bottom_high_req" << endl;
    }
    if (bottom_low_req.read() != 0) {
       cout << "bottom_low_req" << endl;
    }
    
    if (bottom_to_top_amp_rply.read() != 0) {
       cout << "top got reply from lower" << endl;
       cout << "dest[" << dbg_destidx << "][" << dbg_destpredidx << "=" << parse_fixed(dbg_realpt) << "+i" << parse_fixed(dbg_imagpt) << " state:" << dbg_targetstate << endl;
       
    }
    
    if (amp_bottom_high_to_div.read() != 0) {
       cout << "bottom_high amp to divmod" << endl;
    }

    if (amp_bottom_low_to_div.read() != 0) {
       cout << "bottom_low amp to divmod" << endl;
    }


    if (clk.event()) {
      network_result = top_output_bundle;
      top_wu_input = stim_wu;
      
      cout << "ptrlocs: " << (int32_t)top_pos_track << " " << (int32_t)pos_bottom_low << "," << (int32_t)pos_bottom_high << endl;
    } 
  }

  SC_CTOR(Network) : SCD(top_output_bundle, top_wu_input, top_depthlim, input_bundle_to_top, top_pos_track, top_to_heightdiv_wu, bottom_to_top_amp_rply, bottom_high_req, bottom_low_req, bottom_depthlim, bottoms_amp_input, input_bundle_to_bottom_low, input_bundle_to_bottom_high, output_bundle_bottom_low, output_bundle_bottom_high, pos_bottom_low, pos_bottom_high, amp_bottom_high_to_div, wu_bottom_high_tieoff, amp_bottom_low_to_div, wu_bottom_low_tieoff),
  SCD(dbg_valid, dbg_destidx, dbg_destpredidx, dbg_realpt, dbg_imagpt, dbg_targetstate) {
    SC_METHOD(run);
    sensitive_pos(clk);

    // top findamp
    
    Vfindamp *top = new Vfindamp("top");
    top->clk(clk);
    top->rst(rst);
    
    top->input_bundle(input_bundle_to_top);
    top->output_bundle(top_output_bundle);
    
    Vjoin_input *top_joiner = new Vjoin_input("top_joiner");
    top_joiner->clk(clk);
    top_joiner->rst(rst);
    
    top_joiner->depthlim(top_depthlim); top_depthlim.write(2);
    top_joiner->amp(bottom_to_top_amp_rply);
    top_joiner->wu(top_wu_input);
    top_joiner->input_bundle(input_bundle_to_top);
    
    Vsplit_output *top_output_split = new Vsplit_output("top_output_split");
    top_output_split->clk(clk);
    top_output_split->rst(rst);
    
    top_output_split->output_bundle(top_output_bundle);
    top_output_split->pos(top_pos_track);
    top_output_split->amp(top_amp_output);
    top_output_split->wu(top_to_heightdiv_wu);
    
    // heightdiv
    
    Vheightdiv *heightdiv = new Vheightdiv("heightdiv");
    heightdiv->clk(clk);
    heightdiv->rst(rst);
    
    heightdiv->upstream_req(top_to_heightdiv_wu);
    heightdiv->upstream_rply(bottom_to_top_amp_rply);
    heightdiv->downstream_high_req(bottom_high_req);
    heightdiv->downstream_high_rply(amp_bottom_high_to_div);
    heightdiv->downstream_low_req(bottom_low_req);
    heightdiv->downstream_low_rply(amp_bottom_low_to_div);
    
    // heightdiv to top parser
    
    Vunpack_ampreply *debug_ampparser = new Vunpack_ampreply("debug_ampparser");
    debug_ampparser->clk(clk);
    debug_ampparser->rst(rst);
    
    debug_ampparser->ampreply(bottom_to_top_amp_rply);
    
    debug_ampparser->valid(dbg_valid);
    debug_ampparser->destidx(dbg_destidx);
    debug_ampparser->destpredidx(dbg_destpredidx);
    debug_ampparser->realpt(dbg_realpt);
    debug_ampparser->imagpt(dbg_imagpt);
    debug_ampparser->targetstate(dbg_targetstate);
    
    // bottom_low
    
    Vfindamp *bottom_low = new Vfindamp("bottom_low");
    bottom_low->clk(clk);
    bottom_low->rst(rst);
    
    bottom_low->input_bundle(input_bundle_to_bottom_low);
    bottom_low->output_bundle(output_bundle_bottom_low);
    
    Vjoin_input *bottom_low_joiner = new Vjoin_input("bottom_low_joiner");
    bottom_low_joiner->clk(clk);
    bottom_low_joiner->rst(rst);

    bottom_low_joiner->depthlim(bottom_depthlim); bottom_depthlim.write(0);
    bottom_low_joiner->amp(bottoms_amp_input); bottoms_amp_input.write(0);
    bottom_low_joiner->wu(bottom_low_req);
    bottom_low_joiner->input_bundle(input_bundle_to_bottom_low);
    
    Vsplit_output *bottom_low_output_split = new Vsplit_output("bottom_low_output_split");
    bottom_low_output_split->clk(clk);
    bottom_low_output_split->rst(rst);
    
    bottom_low_output_split->output_bundle(output_bundle_bottom_low);
    bottom_low_output_split->pos(pos_bottom_low);
    bottom_low_output_split->amp(amp_bottom_low_to_div);
    bottom_low_output_split->wu(wu_bottom_low_tieoff); // should be tieoff
    
    // bottom_high
    
    Vfindamp *bottom_high = new Vfindamp("bottom_high");
    bottom_high->clk(clk);
    bottom_high->rst(rst);
    
    bottom_high->input_bundle(input_bundle_to_bottom_high);
    bottom_high->output_bundle(output_bundle_bottom_high);
    
    Vjoin_input *bottom_high_joiner = new Vjoin_input("bottom_high_joiner");
    bottom_high_joiner->clk(clk);
    bottom_high_joiner->rst(rst);

    bottom_high_joiner->depthlim(bottom_depthlim);
    bottom_high_joiner->amp(bottoms_amp_input);
    bottom_high_joiner->wu(bottom_high_req);
    bottom_high_joiner->input_bundle(input_bundle_to_bottom_high);
    
    Vsplit_output *bottom_high_output_split = new Vsplit_output("bottom_high_output_split");
    bottom_high_output_split->clk(clk);
    bottom_high_output_split->rst(rst);
    
    bottom_high_output_split->output_bundle(output_bundle_bottom_high);
    bottom_high_output_split->pos(pos_bottom_high);
    bottom_high_output_split->amp(amp_bottom_high_to_div);
    bottom_high_output_split->wu(wu_bottom_high_tieoff); // should be tieoff

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

  // Network *net = new Network("Network");
  VnetworkRTL *net = new VnetworkRTL("topNetwork");

  stim->clk(clk);
  stim->rst(rst);
  finish_cond->clk(clk);
  finish_cond->rst(rst);
  net->clk(clk);
  net->rst(rst);

  // introduce a request into the network
  sc_signal<sc_biguint<WUSZ>> SCD(stim_wu);
  sc_signal<sc_biguint<OUTBSZ>> SCD(outputbundle);

  stim->workunit(stim_wu);
  net->stim_wu(stim_wu);
  net->network_result(outputbundle);
  finish_cond->networkoutput(outputbundle);

  sc_start(10000, SC_NS);
  exit(0);
}
