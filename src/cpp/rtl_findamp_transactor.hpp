#ifndef _FindAmpRTL_H_
#define _FindAmpRTL_H_
#include <systemc>
#include <vector>

#include "sc_vardefs.h"
#include "tlm_types.hpp"
#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

using namespace std;
using namespace sc_core;

#include "tlm_types.hpp"

struct FindAmpRTL : sc_core::sc_module {
    typedef FindAmpRTL SC_CURRENT_USER_MODULE;
    
    vector<workunit_t> worklist;

    // for up-circuit connection
    tlm_utils::simple_target_socket<FindAmpRTL, sizeof(workunit_t)>
        workrecv; // just send the wu
    tlm_utils::simple_initiator_socket<FindAmpRTL, sizeof(workreturn_t)>
        workret; // return values
    tlm::tlm_generic_payload workret_trans;

    // down-circuit connection
    tlm_utils::simple_initiator_socket<FindAmpRTL, sizeof(workunit_t)> workrequestor;
    tlm_utils::simple_target_socket<FindAmpRTL, sizeof(workreturn_t)> workreply;
    tlm::tlm_generic_payload workrequestor_trans;

    sc_in<bool> clk; // can't avoid it!
    sc_in<bool> rst; // can't avoid it!

    FindAmpRTL(::sc_core::sc_module_name, int mindepth_);
    ~FindAmpRTL(void);

private:
    
    sc_time delay = sc_time(10, SC_NS);

    // to avoid need for locks, we enqueue a nd dequeue in the tlm handlers.
    std::queue<workunit_t> workrequest_queue;
    std::queue<workreturn_t> workreplies_queue;

    int mindepth;
    
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

    // private internal wires to input
    sc_signal<uint32_t>	inp_splitdepth;
    sc_signal<uint32_t>	depth;
    sc_signal<bool>	inp_wu_valid;
    sc_signal<bool>	inp_amp_valid;
    sc_signal<uint32_t>	target;
    sc_signal<uint32_t>	inital;
    sc_signal<vluint64_t>	inp_amp;

    // RTL internal modules
    Vfindamp *top;
    Vpack_input *input;
    Vunpack_output *output;
    Vunpack_ampreply* ampparser;


    virtual tlm::tlm_sync_enum recv_wu(tlm::tlm_generic_payload &trans, tlm::tlm_phase &phase, sc_time &delay);

    virtual tlm::tlm_sync_enum recv_reply(tlm::tlm_generic_payload &trans, tlm::tlm_phase &phase, sc_time &delay);

    void QueueManage();

};
#endif /* _MDL_NAME_H_ */