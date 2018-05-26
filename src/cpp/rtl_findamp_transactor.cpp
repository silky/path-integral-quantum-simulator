#include <bitset>
#include <cmath>
#include <queue>
#include <vector>

#include "Vfindamp.h"
#include "Vpack_input.h"
#include "Vunpack_ampreply.h"
#include "Vunpack_output.h"
#include "rtl_findamp_transactor.hpp"

#include "sc_vardefs.h"
#include "tlm.h"
#include "tlm_types.hpp"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include "systemc"
using namespace sc_core;

// SFixed 2 10
#define SHIFT_AMOUNT 10
#define SHIFT_MASK  ((1 << SHIFT_AMOUNT) - 1)

float parse_fixed(uint32_t fpt) {
  int32_t intpart = (fpt >> SHIFT_AMOUNT) & SHIFT_MASK;
  uint32_t divpart = fpt & SHIFT_MASK;
  return (float)intpart + ((float)divpart / (float)(1 << SHIFT_AMOUNT));
}

uint32_t to_fixed(float val) {
  int32_t intpart = trunc(val); // twards zero
  uint32_t divpart = (uint32_t)((1 << SHIFT_AMOUNT) * (val - trunc(val)));
  return (intpart << SHIFT_AMOUNT) ^ divpart;
}

FindAmpRTL::FindAmpRTL(::sc_core::sc_module_name, int mindepth_)
    : workrecv("upstream_recv"), workret("upstream_reply"),
      workrequestor("downstream_send"), workreply("downstream_reply"),
      mindepth(mindepth_) {

  // sc_clock ;
  // clk = clkint.signal();
  // workrecv.register_nb_transport_fw(this, &FindAmpRTL::recv_wu);
  // workreply.register_nb_transport_fw(this, &FindAmpRTL::recv_reply);
  SC_METHOD(QueueManage);
  sensitive_pos << clk;

  inp_splitdepth.write(mindepth); // should stay set

  if (mindepth != 0)
    cout << "RTL depth splitting not ready yet - need new protocol adaptors"
         << endl;

  // create and connect all the submodules!
  // top = new Vfindamp("top");
  // input = new Vpack_input("encodeinput");
  // output = new Vunpack_output("decodeoutput");
  // ampparser = new Vunpack_ampreply("amplitudeparser");

  // top->clk(clk);
  // top->rst(rst);
  // input->clk(clk);
  // input->rst(rst);
  // output->clk(clk);
  // output->rst(rst);
  // ampparser->clk(clk);
  // ampparser->rst(rst);

  // input->inp_splitdepth(inp_splitdepth);
  // input->depth(depth);
  // input->inp_wu_valid(inp_wu_valid);
  // input->inp_amp_valid(inp_amp_valid);
  // input->target(target);
  // input->inital(inital);
  // input->inp_amp(inp_amp);
  // 
  // sc_signal<sc_bv<260>> input_bundle;
  // sc_signal<sc_bv<263>> output_bundle;
  // 
  // top->input_bundle(input_bundle);
  // input->input_bundle(input_bundle);
  // output->output_bundle(output_bundle);
  // top->output_bundle(output_bundle);
  // 
  // output->outp_wu_valid(outp_wu_valid);
  // output->outp_amp_valid(outp_amp_valid);
  // output->outp_amp(outp_amp);
  // output->outp_wu(outp_wu);
  // output->ptrloc(ptrloc);
  // 
  // ampparser->ampreply(outp_amp);
  // ampparser->destidx(destidx);
  // ampparser->destpredidx(destpredidx);
  // ampparser->realpt(realpt);
  // ampparser->imagpt(imagpt);
  // ampparser->targetstate(targetstate);
}

// FindAmpRTL::~FindAmpRTL() {};

tlm::tlm_sync_enum FindAmpRTL::recv_wu(tlm::tlm_generic_payload &trans,
                                       tlm::tlm_phase &phase, sc_time &delay) {

  // if (DEBUG)
  //   cout << "got a new request" << endl;
  // 
  // workunit_t *wu_ptr = reinterpret_cast<workunit_t *>(trans.get_data_ptr());
  // workrequest_queue.push(*wu_ptr);
  // 
  // if (DEBUG)
  //   cout << "enqueued" << endl;
  return tlm::TLM_ACCEPTED;
}

tlm::tlm_sync_enum FindAmpRTL::recv_reply(tlm::tlm_generic_payload &trans,
                                          tlm::tlm_phase &phase,
                                          sc_time &delay) {

  // workreturn_t *wret_ptr =
  //     reinterpret_cast<workreturn_t *>(trans.get_data_ptr());
  // if (DEBUG)
  //   cout << "got a reply - [" << wret_ptr->wu_dest << "]["
  //        << wret_ptr->wu_dst_pred_idx << "] = " << wret_ptr->amplitude << endl;
  // workreplies_queue.push(*wret_ptr);
  return tlm::TLM_ACCEPTED;
}

void FindAmpRTL::QueueManage() {
  // // called every posedge clk.
  // if (!workrequest_queue.empty()) {
  //   workunit_t &newwu = workrequest_queue.front();
  //   workrequest_queue.pop(); // remove that element
  // 
  //   depth = newwu.depth;
  //   target = newwu.target.to_ulong();
  //   inital = newwu.inital.to_ulong();
  //   inp_wu_valid = 1;
  // } else {
  //   inp_wu_valid = 0;
  // }
  // 
  // if (!workreplies_queue.empty()) {
  //   workreturn_t retval = workreplies_queue.front();
  //   workreplies_queue.pop();
  //   cout << "amplitude reply not impl yet for RTL" << endl;
  // }
  // inp_amp_valid = 0;
  // 
  // if (outp_amp_valid == 1) {
  //   cout << "returning!" << endl;
  //   tlm::tlm_phase phase;
  //   sc_time delay; // I don't know how to handle this - there is no return
  //                  // data so it would be ignored anyway
  // 
  //   workreturn_t *wret = new (workreturn_t){
  //       .target = targetstate.read(),
  //       .amplitude = (amp_t){.real = parse_fixed(realpt.read()),
  //                            .imag = parse_fixed(imagpt.read())},
  //       .wu_dest = destidx.read(),
  //       .wu_dst_pred_idx =
  //           destpredidx.read() // position in the predecessors list
  //   };
  // 
  //   workret_trans.set_data_ptr(reinterpret_cast<unsigned char *>(wret));
  // 
  //   phase = tlm::BEGIN_REQ;
  //   workret->nb_transport_fw(workret_trans, phase, delay);
  // }
}
