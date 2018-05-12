// Needed for the simple_target_socket
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <typeinfo>
#include <fstream>
#include <cassert>
#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "algo.h"
#include "loggingsocket.hpp"
#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include <complex>

enum depstate { INIT, REQUESTED, COMPLETE, DONT_CARE };

typedef struct workunit {
    state_t target;
    int depth;
    
    depstate deps[MAX_PRED_STATES];
    state_t  predecessors[MAX_PRED_STATES];
    amp_t    amplitudes[MAX_PRED_STATES];
    int wu_dest; // -1 means return, else idx in worklist.
    int wu_dst_pred_idx; // position in the predecessors list
} workunit_t;

bool can_eval(workunit_t wu) {
    bool can = true;
    for (int i=0; i<MAX_PRED_STATES; i++) {
        if (wu.deps[i] != COMPLETE && wu.deps[i] != DONT_CARE) {
            can = false;
            break;
        }
    }
    return can;
}

bool non_default(workunit_t wu) {
    bool non_default = false;
    for (int i=0; i<MAX_PRED_STATES; i++) {
        if (wu.deps[i] > INIT) {
            non_default = true;
            break;
        }
    }
    return non_default;
}

// Integrates over the priors that can lead to this state.
amp_t evaluate(workunit_t wu, gate_t gate) {
    amp_t resamp = {0.0, 0.0};
    int n_preds = (1<<gate.qubits.size());
    for (int i=0; i<n_preds; i++) {
        switch (gate.g) {
            case H:
              resamp += HapplySlice(
                  bitextract(wu.predecessors[i], gate.qubits),
                  wu.amplitudes[i],
                  bitextract(wu.target, gate.qubits));
              break;
            case CNOT:
              resamp += CNOTapplySlice(
                  bitextract(wu.predecessors[i], gate.qubits),
                  wu.amplitudes[i],
                  bitextract(wu.target, gate.qubits));
              break;
            default:
              cout << "UNSUPPORTED GATE! " << gate.g << endl;
              break;
        }
    }
    return resamp;
}

string print_priors(workunit_t wu) {
    // if (!can_eval(wu)) {
    //     return "NOT READY"
    // }
    ostringstream out;
    for (int i=0; i<MAX_PRED_STATES; i++) {
        if (wu.deps[i] == REQUESTED) {
            out << StateRepr(wu.predecessors[i]) << ":NRDY ";
        }
        if (wu.deps[i] == COMPLETE) {
            out << StateRepr(wu.predecessors[i]) << ":" << wu.amplitudes[i] << " ";
        }
    }
    return out.str();
}

void print_worklist(vector<workunit_t> worklist) {
    cout << "worklist is now:" << endl;
    for (workunit_t wu : worklist) {
        cout << "{ .target=" << wu.target <<
                 ", .deps=can_eval " << can_eval(wu) << " init " << non_default(wu) <<
                 ", .depth=" << wu.depth << 
                 ", .dest=" << wu.wu_dest << ", idx=" << wu.wu_dst_pred_idx << 
                 ", .preds=" << print_priors(wu) <<
                 "}" << endl;
    }
}

struct PrintWorkLists : sc_module {
    vector<workunit_t>& worklist;
    sc_time delay = sc_time(10, SC_NS);
        
    typedef PrintWorkLists SC_CURRENT_USER_MODULE;
    PrintWorkLists( ::sc_core::sc_module_name, vector<workunit_t>& worklist_ ) :  worklist(worklist_) {
        SC_THREAD(thread_process);
    }

    
    void thread_process() {
        do { wait(sc_time(10, SC_NS)); } while (worklist.size() == 0);
        
        while (worklist.size() > 0) {
            delay += sc_time(10, SC_NS);
            print_worklist(worklist);
            wait(delay);
            delay = sc_time(0, SC_NS);
        }
    }
};

struct FindAmp : sc_module {
  // socket for the hadamard gate
  sc_time delay = sc_time(10, SC_NS);
  vector<workunit_t> worklist;
  
  // tlm_utils::simple_target_socket<FindAmp> workrecv;

  SC_CTOR(FindAmp) {
    SC_THREAD(thread_process);
  }

  void thread_process() {
    state_t inital_state = 0;
    cout << "final amplitude for " << StateRepr(inital_state)
         << " on HH:" << endl;
    cout << StateRepr(0) << ":" << CalcAmpSC(circuit, inital_state, 0) << endl;

    // Realize the delay annotated onto the transport call
    wait(delay);
    delay = sc_time(0, SC_NS);
    cout << "Total estimated time: " << sc_time_stamp() << " delay = " << delay
         << endl;
  }

  amp_t CalcAmpSC(circuit_t remaining_circuit, state_t inital_state,
                  state_t target_state) {
                      
    worklist.push_back({ 
                      .target = target_state, 
                      .depth  = remaining_circuit.size(),
                      .deps   = {}, // just gonna rely on the first elem being 0.
                      .predecessors = {}, // zero
                      .amplitudes = {},
                      .wu_dest = -1 // return this value.
                  });
    
    workunit_t wu;
    while (worklist.size() > 0) {
        // Realize the delay annotated onto the transport call
        wait(delay);
        delay = sc_time(0, SC_NS);
        //print_worklist(worklist);
        
        workunit_t& wu = worklist.back();
        
        if (wu.depth == 0) {
            cout << "reached base state - adding to wu[" << wu.wu_dest << "][" << wu.wu_dst_pred_idx << "]" << endl;
            
            amp_t amplitude = (wu.target == inital_state) ? (amp_t){1.0, 0.0} : (amp_t){0.0, 0.0};
            worklist[wu.wu_dest].amplitudes[wu.wu_dst_pred_idx] = amplitude;
            worklist[wu.wu_dest].deps[wu.wu_dst_pred_idx] = COMPLETE;
            worklist.pop_back(); // remove this element, as we have completed it.
            
        } else if (can_eval(wu)) {
            gate_t currentgate = remaining_circuit[wu.depth-1];
            amp_t amplitude = evaluate(wu, currentgate);
            worklist.pop_back(); // remove this element, as we have completed it.

            if (wu.wu_dest == -1) { // this is the target state we were invoked for
                return amplitude;
            } else { // evaluated somthing to propogate.
                worklist[wu.wu_dest].amplitudes[wu.wu_dst_pred_idx] = amplitude;
                worklist[wu.wu_dest].deps[wu.wu_dst_pred_idx] = COMPLETE;
                // cout << "propegation not impl, TODO" << endl;
            }
            
        } else if (!non_default(wu)) {            
            // need to add the deps to the list.
            // calculate pred states
            gate_t currentgate = remaining_circuit[wu.depth-1];
            vector<state_t> predecessors = StateBall(wu.target, currentgate.qubits);
            for (int i=0; i<predecessors.size(); i++) {
                wu.deps[i] = REQUESTED;
                wu.predecessors[i] = predecessors[i];
            }
            for (int i=predecessors.size(); i<MAX_PRED_STATES; i++) {
                wu.deps[i] = DONT_CARE;
            }
            
            // for each predecessor, push the wu to evaluate it.
            int dest_wu_idx = worklist.size()-1;
            for (int i=0; i<predecessors.size(); i++) {
                worklist.push_back({ 
                                  .target = predecessors[i], 
                                  .depth  = wu.depth-1,
                                  .deps   = {}, // just gonna rely on the first elem being 0.
                                  .predecessors = {}, // zero
                                  .amplitudes = {},
                                  // as we only pop from the pack, we can identify the requesting state by its current index.
                                  .wu_dest = dest_wu_idx,
                                  .wu_dst_pred_idx = i,
                              });
            }
            // cout << "cant evaluate, TODO" << endl;
            // break;
        } else { // no work to do.
            // pass! wait for the remote block to update some of our list.
        }
        delay += sc_time(10, SC_NS);
    }
    
    return (amp_t){999.9, 999.9}; // 
  }


};


SC_MODULE(Top) {
  FindAmp *amplitude_finder;
  PrintWorkLists *printer;

  SC_CTOR(Top) {
    // Instantiate components
    amplitude_finder = new FindAmp("FindAmp");
    printer = new PrintWorkLists("printer", amplitude_finder->worklist);
  }

  void print_bw() {
    ofstream myfile;
    myfile.open("bwlog.csv");
    myfile.close();
  }
};

int sc_main(int argc, char *argv[]) {
  Top top("top");
  sc_start();
  // if (BWLOG)
  //   top.print_bw();
  return 0;
}