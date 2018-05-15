// Needed for the simple_target_socket
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <typeinfo>
#include <fstream>
#include <cassert>
#include <queue>
#include <tuple>
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
enum returntype { LOCAL, REMOTE }; //

typedef struct workunit {
    state_t target;
    state_t inital;
    int depth;

    depstate deps[MAX_PRED_STATES];
    state_t  predecessors[MAX_PRED_STATES];
    amp_t    amplitudes[MAX_PRED_STATES];

    returntype returnloc; // REMOTE means ret to upstream.
    int wu_dest;
    int wu_dst_pred_idx; // position in the predecessors list
} workunit_t;

typedef struct workreturn {
    state_t target;
    amp_t amplitude;
    
    int wu_dest;
    int wu_dst_pred_idx; // position in the predecessors list
} workreturn_t;

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
                 ", .dest=" << ((wu.returnloc == LOCAL) ? "LOCAL " : "REMOTE ") <<
                 wu.wu_dest << ", idx=" << wu.wu_dst_pred_idx <<
                 ", .preds=" << print_priors(wu) <<
                 "}" << endl;
    }
}

struct PrintWorkLists : sc_module {
    vector<workunit_t>* worklists[100];
    int len_worklists;
    sc_time delay = sc_time(10, SC_NS);

    typedef PrintWorkLists SC_CURRENT_USER_MODULE;
    PrintWorkLists( ::sc_core::sc_module_name, vector<workunit_t>* worklists_[], int len_worklists_ ) {
        len_worklists = len_worklists_;
        for (int i=0; i<len_worklists; i++) {
            worklists[i] = worklists_[i];
        }
        SC_THREAD(thread_process);
    }


    void thread_process() {
        int i;
        if (DEBUG) {
            while (1) {
                wait(sc_time(10, SC_NS));
                i = 0;
                for (int i=0; i<len_worklists; i++) {
                    cout << "----------------worklist " << i << endl;
                    print_worklist(*worklists[i]);
                }
                cout << "----iteration end\n\n " << i << endl;
            }
        }
    }
};

struct Initiator : sc_module {
    tlm_utils::simple_initiator_socket<Initiator, sizeof(workunit_t)> socket;
    tlm_utils::simple_target_socket<Initiator, sizeof(workreturn_t)> work_return; 
    
    tlm::tlm_generic_payload trans;
    workunit_t *wu;
    
    state_t target = 0;
    state_t inital = 0;
    int replycount = 0;
    vector<state_t> requests = {0, 1, 2, 3};
    
    SC_CTOR(Initiator) : socket("wu_gen") {
        socket.register_nb_transport_bw(this, &Initiator::nb_transport_bw);
        work_return.register_nb_transport_fw(this, &Initiator::work_return_fun);
        SC_THREAD(thread_process);
    } 

    void thread_process()
    {
        for (state_t& req : requests) {
            if (DEBUG) cout << "making a request" << endl;
            tlm::tlm_phase phase;
            sc_time delay;
            
            wu = new (workunit_t){
                  .target = req,
                  .inital = inital,
                  .depth  = circuit.size(), // global circuit
                  .deps   = {}, // just gonna rely on the first elem being 0.
                  .predecessors = {}, // zero
                  .amplitudes = {},
                  .returnloc = REMOTE
                  // .wu_dest = -1 // return this value.
                };

            
            trans.set_data_ptr( reinterpret_cast<unsigned char*>(wu) );
            
            phase = tlm::BEGIN_REQ;
            socket->nb_transport_fw( trans, phase, delay );
            wait(sc_time(30, SC_NS));
        }
    }

    virtual tlm::tlm_sync_enum work_return_fun( tlm::tlm_generic_payload& trans,
                                        tlm::tlm_phase& phase, sc_time& delay ) {
      replycount++;
      if (DEBUG) cout << "got a reply!" << endl;
      workreturn_t *wrecv_ptr = reinterpret_cast<workreturn_t*>(trans.get_data_ptr());
      
      cout << "final amplitude starting at " << StateRepr(inital)
           << " on circuit:" << endl;
      cout << StateRepr(wrecv_ptr->target) << ":" << wrecv_ptr->amplitude << endl;
      cout << "finished at " << sc_time_stamp() << endl;
      
      if (replycount == requests.size())
          sc_stop();
    }


    virtual tlm::tlm_sync_enum nb_transport_bw( tlm::tlm_generic_payload& trans,
                                                tlm::tlm_phase& phase, sc_time& delay )
    {
      // The timing annotation must be honored
      // m_peq.notify( trans, phase, delay );
      cout << "init got a txn, not sure what to do with this?" << endl;
      return tlm::TLM_ACCEPTED;
    }
};

struct BaseCase : sc_module {
    // basically a minimal blanking plate for the downstream ports of FindAmp
    // as the down ports need somthing to connect to
    tlm_utils::simple_target_socket<BaseCase, sizeof(workunit_t)> workrecv; // just send the wu
    tlm_utils::simple_initiator_socket<BaseCase, sizeof(workreturn_t)> workret; // return values
    tlm::tlm_generic_payload workret_trans;

    SC_CTOR(BaseCase) : workret("work_sender"), workrecv("work_recv") {
        workrecv.register_nb_transport_fw(this, &BaseCase::ProcessBaseCase);    
    }
    
    virtual tlm::tlm_sync_enum ProcessBaseCase( tlm::tlm_generic_payload& trans,
                                        tlm::tlm_phase& phase, sc_time& delay ) {
        
        if (DEBUG) cout << "got a base case!" << endl;
        workunit_t *wu_ptr = reinterpret_cast<workunit_t*>(trans.get_data_ptr());
        
        amp_t amplitude = (wu_ptr->target == wu_ptr->inital) ? (amp_t){1.0, 0.0} : (amp_t){0.0, 0.0};
        
        
        if (DEBUG) cout << "returning!" << endl;
        tlm::tlm_phase phase_ret;
        sc_time delay_ret;
        
        workreturn_t *wret = new (workreturn_t){
                            .target = wu_ptr->target,
                            .amplitude=amplitude,
                            .wu_dest = wu_ptr->wu_dest,
                            .wu_dst_pred_idx = wu_ptr->wu_dst_pred_idx
                        };

        
        workret_trans.set_data_ptr( reinterpret_cast<unsigned char*>(wret) );
        
        phase = tlm::BEGIN_REQ;
        workret->nb_transport_fw( workret_trans, phase_ret, delay_ret );
        return tlm::TLM_ACCEPTED;
    }

};

struct FindAmp : sc_module {
  // socket for the hadamard gate
  sc_time delay = sc_time(10, SC_NS);
  vector<workunit_t> worklist;
  
  // to avoid need for locks, we enqueue and dequeue in the tlm handlers.
  std::queue<workunit_t> workrequest_queue;
  std::queue<workreturn_t> workreplies_queue;

  // for up-circuit connection
  tlm_utils::simple_target_socket<FindAmp, sizeof(workunit_t)> workrecv; // just send the wu
  tlm_utils::simple_initiator_socket<FindAmp, sizeof(workreturn_t)> workret; // return values
  tlm::tlm_generic_payload workret_trans;
  
  // down-circuit connection
  tlm_utils::simple_initiator_socket<FindAmp, sizeof(workunit_t)> workrequestor;
  tlm_utils::simple_target_socket<FindAmp, sizeof(workreturn_t)> workreply; 
  tlm::tlm_generic_payload workrequestor_trans;
  int mindepth;
  
  vector<pair<sc_time, int>> worklist_sizes; // for util tracking.

  typedef FindAmp SC_CURRENT_USER_MODULE;
  FindAmp( ::sc_core::sc_module_name, int mindepth_ ) :  workrecv("upstream_recv"), 
                                          workret("upstream_reply"),
                                          workrequestor("downstream_send"),
                                          workreply("downstream_reply"), mindepth(mindepth_) {
      SC_THREAD(CalcAmpSC);
      workrecv.register_nb_transport_fw(this, &FindAmp::recv_wu);
      workreply.register_nb_transport_fw(this, &FindAmp::recv_reply);
  }
  
  virtual tlm::tlm_sync_enum recv_wu( tlm::tlm_generic_payload& trans,
                                      tlm::tlm_phase& phase, sc_time& delay ) {

    if (DEBUG) cout << "got a new request" << endl;
    workunit_t *wu_ptr = reinterpret_cast<workunit_t*>(trans.get_data_ptr());
    workrequest_queue.push(*wu_ptr);
    
    if (DEBUG) cout << "enqueued" << endl;
    return tlm::TLM_ACCEPTED;
  }
  
  virtual tlm::tlm_sync_enum recv_reply( tlm::tlm_generic_payload& trans,
                                      tlm::tlm_phase& phase, sc_time& delay ) {

    workreturn_t *wret_ptr = reinterpret_cast<workreturn_t*>(trans.get_data_ptr());
    if (DEBUG) cout << "got a reply - [" << wret_ptr->wu_dest << "][" << wret_ptr->wu_dst_pred_idx << "] = " << wret_ptr->amplitude << endl;
    workreplies_queue.push(*wret_ptr);

    // worklist[wret_ptr->wu_dest].amplitudes[wret_ptr->wu_dst_pred_idx] = wret_ptr->amplitude;
    // worklist[wret_ptr->wu_dest].deps[wret_ptr->wu_dst_pred_idx] = COMPLETE;

    return tlm::TLM_ACCEPTED;
  }


  void CalcAmpSC() {
    workunit_t wu;
    tlm::tlm_phase phase;
    sc_time delay;

    while (1) { // wait for stuff to come to us!
        worklist_sizes.push_back( (pair<sc_time, int>){sc_time_stamp(), worklist.size()} );
        wait(sc_time(10, SC_NS));
        
        if (!workrequest_queue.empty()) {
            worklist.push_back(workrequest_queue.front());
            workrequest_queue.pop();
            continue; // do one thing per loop.
        }
        
        if (!workreplies_queue.empty()) {
            workreturn_t retval = workreplies_queue.front();
            workreplies_queue.pop();
            
            worklist[retval.wu_dest].amplitudes[retval.wu_dst_pred_idx] = retval.amplitude;
            worklist[retval.wu_dest].deps[retval.wu_dst_pred_idx] = COMPLETE;
            continue; // do one thing per loop.
        }
        
        if (worklist.size() == 0) { continue; } // no work to do yet
        
        workunit_t& wu = worklist.back();

        if (wu.depth <= mindepth) {
            
            if (DEBUG) cout << "reached base state for this block at lvl " << mindepth << endl;

            // amp_t amplitude = (wu.target == wu.inital) ? (amp_t){1.0, 0.0} : (amp_t){0.0, 0.0};
            // worklist[wu.wu_dest].amplitudes[wu.wu_dst_pred_idx] = amplitude;
            // worklist[wu.wu_dest].deps[wu.wu_dst_pred_idx] = COMPLETE;
            // cout << "TODO: make request!" << endl;
            
            workunit_t workunit_req;
            workunit_req = wu; // copy
            workunit_req.returnloc = REMOTE;
            
            if (DEBUG) cout << "making work req from findamp" << endl;
            workrequestor_trans.set_data_ptr( reinterpret_cast<unsigned char*>(&workunit_req) );
            
            phase = tlm::BEGIN_REQ;
            workrequestor->nb_transport_fw( workrequestor_trans, phase, delay );
            worklist.pop_back(); // remove this element, as we have completed it.

        } else if (can_eval(wu)) {
            gate_t currentgate = circuit[wu.depth-1];
            amp_t amplitude = evaluate(wu, currentgate);
            worklist.pop_back(); // remove this element, as we have completed it.

            if (wu.returnloc == REMOTE) { // this is the target state we were invoked for
                // return amplitude;
                
                if (DEBUG) cout << "returning!" << endl;
                
                workreturn_t *wret = new (workreturn_t){
                                    .target = wu.target,
                                    .amplitude=amplitude,
                                    .wu_dest=wu.wu_dest,
                                    .wu_dst_pred_idx=wu.wu_dst_pred_idx // position in the predecessors list
                                };

                workret_trans.set_data_ptr( reinterpret_cast<unsigned char*>(wret) );
                
                phase = tlm::BEGIN_REQ;
                workret->nb_transport_fw( workret_trans, phase, delay );
                
            } else { // evaluated somthing to propogate.
                worklist[wu.wu_dest].amplitudes[wu.wu_dst_pred_idx] = amplitude;
                worklist[wu.wu_dest].deps[wu.wu_dst_pred_idx] = COMPLETE;
                // cout << "propegation not impl, TODO" << endl;
            }

        } else if (!non_default(wu)) {
            // need to add the deps to the list.
            // calculate pred states
            gate_t currentgate = circuit[wu.depth-1];
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
                worklist.push_back((workunit_t){
                                  .target = predecessors[i],
                                  .inital = wu.inital,
                                  .depth  = wu.depth-1,
                                  .deps   = {}, // just gonna rely on the first elem being 0.
                                  .predecessors = {}, // zero
                                  .amplitudes = {},
                                  // as we only pop from the pack, we can identify the requesting state by its current index.
                                  .returnloc = LOCAL,
                                  .wu_dest = dest_wu_idx,
                                  .wu_dst_pred_idx = i,
                              });
            }
        } else { // no work to do.
            // pass! wait for the remote block to update some of our list.
        }
    } // end while
  }
};

// split the circuit in half for performance reasons! this is where parallelism comes in
struct HeightDiv : sc_module {
    // up-circuit connection
    tlm_utils::simple_target_socket<HeightDiv, sizeof(workunit_t)> up_workrequestor;
    tlm_utils::simple_initiator_socket<HeightDiv, sizeof(workreturn_t)> up_workreply; 
    tlm::tlm_generic_payload workreply_trans;

    // down-circuit connection 1
    tlm_utils::simple_initiator_socket<HeightDiv, sizeof(workunit_t)> down_0_workrequestor;
    tlm_utils::simple_target_socket<HeightDiv, sizeof(workreturn_t)> down_0_workreply; 
    tlm::tlm_generic_payload workrequestor_0_trans;
    
    // down-circuit connection 2
    tlm_utils::simple_initiator_socket<HeightDiv, sizeof(workunit_t)> down_1_workrequestor;
    tlm_utils::simple_target_socket<HeightDiv, sizeof(workreturn_t)> down_1_workreply; 
    tlm::tlm_generic_payload workrequestor_1_trans;

    SC_CTOR(HeightDiv) : up_workrequestor("up_workrequestor"), up_workreply("up_workreply"),
                        down_0_workrequestor("down_0_workrequestor"), down_0_workreply("down_0_workreply")
                        // down_1_workrequestor("down_1_workrequestor"), down_1_workreply("down_1_workreply")
    {
        up_workrequestor.register_nb_transport_fw(this, &HeightDiv::WorkRequest_route); 
        down_0_workreply.register_nb_transport_fw(this, &HeightDiv::WorkReply_route);
        down_1_workreply.register_nb_transport_fw(this, &HeightDiv::WorkReply_route);

    }
    
    virtual tlm::tlm_sync_enum WorkRequest_route( tlm::tlm_generic_payload& trans,
                                            tlm::tlm_phase& phase, sc_time& delay ) {
        
        workunit_t wu = *reinterpret_cast<workunit_t*>(trans.get_data_ptr());
        if (wu.target.to_ulong() > (1<<NQUBITS)/2) { // upper
            workrequestor_0_trans.set_data_ptr( reinterpret_cast<unsigned char*>(&wu) );
            phase = tlm::BEGIN_REQ;
            down_0_workrequestor->nb_transport_fw( workrequestor_0_trans, phase, delay );
            return tlm::TLM_ACCEPTED;
        } else {
            workrequestor_1_trans.set_data_ptr( reinterpret_cast<unsigned char*>(&wu) );
            phase = tlm::BEGIN_REQ;
            down_1_workrequestor->nb_transport_fw( workrequestor_0_trans, phase, delay );
            return tlm::TLM_ACCEPTED;

        }
        
    }
    
    virtual tlm::tlm_sync_enum WorkReply_route( tlm::tlm_generic_payload& trans,
                                            tlm::tlm_phase& phase, sc_time& delay ) {
        
        workreturn_t wrt = *reinterpret_cast<workreturn_t*>(trans.get_data_ptr());
        workreply_trans.set_data_ptr( reinterpret_cast<unsigned char*>(&wrt) );
        phase = tlm::BEGIN_REQ;
        up_workreply->nb_transport_fw( workreply_trans, phase, delay );
        return tlm::TLM_ACCEPTED;
    }
};

// layout discr: list of split points + bool of if height split or not.
// if there is a height split, we need to maintain that split for all sub-things.
// perhaps be more specific? 
// explicit tree. basic unit: (findamp, HeightDiv) pair.
// be super basic:

#define MAX_MODULES 100
SC_MODULE(Top) {
  FindAmp *amplitude_finders[MAX_MODULES];
  HeightDiv *divs[MAX_MODULES];
  BaseCase *basecases[MAX_MODULES];
  

  Initiator *init;
  PrintWorkLists *printer;
  
  int n_amp_finders; // = 3;
  int n_divs; // = 1;
  int n_base_cases; // = 2;
  
  int ampdepths[MAX_MODULES] = { 3, 0, 0 }; // same length as n_amp_finders
  amp_connspec ampconns[MAX_MODULES];// = { {HEIGHTDIV, 0}, {BASE, 0}, {BASE, 1} };
  div_connspec divconns[MAX_MODULES];//= { {FINDAMP, {1, 2}} };

  moduletypes parsemod(string s) {
      if (s == "INITIATOR ") {
          return INITIATOR;
      } else if (s == "FINDAMP") {
          return FINDAMP;
      } else if (s == "HEIGHTDIV") {
          return HEIGHTDIV;
      } else if (s == "BASE") {
          return BASE;
      } else {
          cout << "could not parse module type spec \"" << s  << "\" (mabye there is whitespace?)" << endl;
          exit(5);
      }

  }
  
  void parse_spec() {
      ifstream config("config.cfg", ios::in);
      string line;
      getline(config, line);
      n_amp_finders = std::stoi(line);
      getline(config, line);
      n_divs = std::stoi(line);
      getline(config, line);
      n_base_cases = std::stoi(line);
      
      moduletypes modtype;
      int modidx;
      for (int i=0; i<n_amp_finders; i++) {
          std::getline(config, line, ','); // get depth
          ampdepths[i] = std::stoi(line);
          
          std::getline(config, line, ','); // get connection type
          modtype = parsemod(line);
          std::getline(config, line); // get conn idx.
          modidx = std::stoi(line); 
          ampconns[i] = { modtype, modidx };
      }
      
      int leftidx;
      int rightidx;
      for (int i=0; i<n_divs; i++) {
          std::getline(config, line, ','); // get connection type
          modtype = parsemod(line);
          std::getline(config, line, ','); // get conn idx.
          leftidx = std::stoi(line); 
          std::getline(config, line); // get conn idx.
          rightidx = std::stoi(line); 
          divconns[i] = { modtype, {leftidx, rightidx} };
      }

  }

  SC_CTOR(Top) {
    parse_spec();
    // Instantiate components
    for (int i=0; i<n_amp_finders; i++) {
        amplitude_finders[i] = new FindAmp("FindAmp", ampdepths[i]);
    }
    for (int i=0; i<n_divs; i++) {
        divs[i] = new HeightDiv("HeightDiv");
    }
    for (int i=0; i<n_base_cases; i++) {
        basecases[i] = new BaseCase("BaseCase");
    }
        
    vector<workunit_t>* worklists[n_amp_finders];
    for (int i=0; i<n_amp_finders; i++) {
        worklists[i] = &amplitude_finders[i]->worklist;
    }
    
    printer = new PrintWorkLists("printer", worklists, n_amp_finders);
    init = new Initiator("init");
    // by only making requests to the top ampfinder, if we request lower than it's cuttoff,
    // it will process the first workunit whilst distributing the prev levels to lower.
    // this is slightly dumb but not a problem currently, just a counterintuative layering violation.
    // we could fix this in findamp by checking the level before enqueue, but this is probably a net loss. alt fix here by requesting to the right module, but this complicates networking needing 1 more port per findamp for no benifit x2.
    init->socket.bind(amplitude_finders[n_amp_finders-1]->workrecv);
    init->work_return.bind(amplitude_finders[n_amp_finders-1]->workret);

    amp_connspec ampconn;
    // in Python I would solve this with ducktyping - not sure how to do the dynamic dispatch on a object of unknown type in cpp without the switch?
    for (int i=0; i<n_amp_finders; i++) {
        ampconn = ampconns[i];
        switch (ampconn.type) {
        case FINDAMP: // direct connection to the next layer down
            cout << "ampfind direct connection - you might want to merge this!" << endl;
            amplitude_finders[i]->workrequestor.bind(amplitude_finders[ampconn.idx]->workrecv);
            amplitude_finders[i]->workreply.bind(amplitude_finders[ampconn.idx]->workret);
            break;
        case HEIGHTDIV:
            amplitude_finders[i]->workrequestor.bind(divs[ampconn.idx]->up_workrequestor);
            amplitude_finders[i]->workreply.bind(divs[ampconn.idx]->up_workreply);
            break;
        case BASE:
            amplitude_finders[i]->workrequestor.bind(basecases[ampconn.idx]->workrecv);
            amplitude_finders[i]->workreply.bind(basecases[ampconn.idx]->workret);
            break;
        case INITIATOR:
            cout << "CONNECTION ERROR: tried to make a request to an initator." << endl;
            break;
        }
    }
 
    div_connspec divconn;
    for (int i=0; i<n_divs; i++) {
        divconn = divconns[i];
        switch (divconn.type) {
        case FINDAMP: // direct connection to the next layer down            
            divs[i]->down_0_workrequestor.bind(amplitude_finders[divconn.idx[0]]->workrecv);
            divs[i]->down_0_workreply.bind(amplitude_finders[divconn.idx[0]]->workret);
            
            divs[i]->down_1_workrequestor.bind(amplitude_finders[divconn.idx[1]]->workrecv);
            divs[i]->down_1_workreply.bind(amplitude_finders[divconn.idx[1]]->workret);
            break;
        case HEIGHTDIV:
            cout << "nested divs - you probably don't want this." << endl;
            divs[i]->down_0_workrequestor.bind(divs[divconn.idx[0]]->up_workrequestor);
            divs[i]->down_0_workreply.bind(divs[divconn.idx[0]]->up_workreply);
            
            divs[i]->down_1_workrequestor.bind(divs[divconn.idx[1]]->up_workrequestor);
            divs[i]->down_1_workreply.bind(divs[divconn.idx[1]]->up_workreply);
            break;
        case BASE:
            cout << "div to basecase - no point, you don't want this." << endl;
            divs[i]->down_0_workrequestor.bind(basecases[divconn.idx[0]]->workrecv);
            divs[i]->down_0_workreply.bind(basecases[divconn.idx[0]]->workret);
            
            divs[i]->down_1_workrequestor.bind(basecases[divconn.idx[1]]->workrecv);
            divs[i]->down_1_workreply.bind(basecases[divconn.idx[1]]->workret);
            break;
        case INITIATOR:
            cout << "CONNECTION ERROR: tried to make a request to an initator. you def dont want this." << endl;
            break;
        }
    }
  }
  
  std::string sizelog(vector<pair<sc_time, int>>& log) {
      ostringstream times;
      ostringstream sizes;
      for (auto& i : log) {
          sc_time t = i.first;
          times << i.first << ",";
          sizes << i.second << ",";
      }
      return times.str() + "\n" + sizes.str();
  }
  
  void save_size_logs() {
      ofstream myfile;
      for (int i=0; i<n_amp_finders; i++) {
          ostringstream filename;
          filename << "logs/sizelog_" << i << ".csv";
          myfile.open(filename.str());
          myfile << sizelog(amplitude_finders[i]->worklist_sizes);
          myfile.close();
      }

  }

  void print_bw() {}
};

int sc_main(int argc, char *argv[]) {
  Top top("top");
  sc_start();
  top.save_size_logs();
  
  // if (BWLOG)
  //   top.print_bw();
  return 0;
}
