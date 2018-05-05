// Needed for the simple_target_socket
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "algo.h"
#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include <complex>

// mirrors the HapplySlice func call
typedef struct Hinput {
  int ID;
  state_t state;
  amp_t amplitude;
  state_t req; 
} Hinput_t;

typedef struct Houtput {
  int ID;
  amp_t amplitude; 
} Houtput_t;

typedef union Htxn {
  Hinput_t in;
  Houtput_t out;
} Htxn_t; // used for a operator action - represents both the action and the
          // output - As transactional modelling is super directed twards memory
          // access

struct FindAmp : sc_module {
  // socket for the hadamard gate
  tlm_utils::simple_initiator_socket<FindAmp, sizeof(Htxn_t)> socket;
  tlm::tlm_generic_payload *trans =
      new tlm::tlm_generic_payload; // so we can use it from whereever
  sc_time delay = sc_time(10, SC_NS);

  SC_CTOR(FindAmp)
      : socket("socket") // Construct and name socket
  {
    SC_THREAD(thread_process);
  }

  void init_txns() {
    trans->set_command(tlm::TLM_WRITE_COMMAND);
    trans->set_address(0);
    trans->set_data_length(sizeof(Htxn_t));
    trans->set_streaming_width(
        sizeof(Htxn_t));           // = data_length to indicate no streaming
    trans->set_byte_enable_ptr(0); // 0 indicates unused
    trans->set_dmi_allowed(false); // Mandatory initial value
    trans->set_response_status(
        tlm::TLM_INCOMPLETE_RESPONSE); // Mandatory initial value
  }

  // layer 0: inital state, 1: after first gate applied, etc.

  void thread_process() {
    init_txns();

    state_t inital_state = 0;
    cout << "final amplitude for " << StateRepr(inital_state)
         << " on HH:" << endl;
    cout << StateRepr(0) << ":" << CalcAmpSC(circuit, inital_state, 0) << endl;
    

    // Initiator obliged to check response status and delay

    // cout << "trans = { " << (cmd ? 'W' : 'R') << ", " << hex << i
    //      << " } , data = " << hex << data << " at time " << sc_time_stamp()
    //      << " delay = " << delay << endl;

    // Realize the delay annotated onto the transport call
    wait(delay);
    delay = sc_time(0, SC_NS);
    cout << "Total estimated time: " << sc_time_stamp() << " delay = " << delay << endl;
  }

  amp_t CalcAmpSC(circuit_t remaining_circuit, state_t inital_state,
                  state_t target_state) {
    if (DEBUG)
      cout << "evaluating for target state " << StateRepr(target_state)
           << " with " << remaining_circuit.size() << " gates left."
           << "delay: " << delay << std::endl;

    if (remaining_circuit.size() == 0) // base case.
      return (target_state == inital_state) ? (amp_t){1.0, 0.0}
                                            : (amp_t){0.0, 0.0};

    gate_t current_gate = remaining_circuit.back();
    circuit_t remainder =
        circuit_t(remaining_circuit.begin(), remaining_circuit.end() - 1);

    vector<state_t> predecessors = StateBall(target_state, current_gate.qubits);
    delay += sc_time(5 * predecessors.size(), SC_NS); // for the stateball - it's just some bitflips!

    vector<amp_t> predecessor_amplitudes;
    for (state_t &p : predecessors) {
      predecessor_amplitudes.push_back(CalcAmpSC(remainder, inital_state, p));
      delay += sc_time(5, SC_NS); // pushing stuff onto the stack.
    }
    if (DEBUG)
      cout << "N predicessors: " << predecessor_amplitudes.size() << endl;

    amp_t resultant_amplitude = {0.0, 0.0};

    vector<amp_t> res_partial_state_after_gate;
    for (int i = 0; i < predecessors.size(); i++) {
      if (current_gate.g == H) {
        resultant_amplitude +=
            HapplySliceSC(bitextract(predecessors[i], current_gate.qubits),
                          predecessor_amplitudes[i],
                          bitextract(target_state, current_gate.qubits));
        delay += sc_time(5, SC_NS); // addition
      } else {
        cout << "UNSUPPORTED GATE! " << current_gate.g << endl;
      }
    }

    return resultant_amplitude;
  }

  amp_t HapplySliceSC(state_t in, amp_t inamp, state_t req) {
    Htxn_t data = {.in = {.ID = 0,
                          .state = in,
                          .amplitude = inamp,
                          .req = req}};
    trans->set_data_ptr(reinterpret_cast<unsigned char *>(&data));
    
    socket->b_transport(*trans, delay); // adds to the global delay.
    
    if (trans->is_response_error())
      SC_REPORT_ERROR("TLM-2", "Response error from b_transport");
    return data.out.amplitude;
  }
};

// Target module representing a Hadamard gate
struct Hop : sc_module {
  // TLM-2 socket, input is ID (16b), state (2b), amplitude (2*32b)
  tlm_utils::simple_target_socket<Hop, sizeof(Htxn_t)> socket;

  SC_CTOR(Hop) : socket("socket") {
    // Register callback for incoming b_transport interface method call
    socket.register_b_transport(this, &Hop::b_transport);
  }

  // TLM-2 blocking transport method
  virtual void b_transport(tlm::tlm_generic_payload &trans, sc_time &delay) {
    tlm::tlm_command cmd = trans.get_command();
    Htxn_t *txn = reinterpret_cast<Htxn_t *>(trans.get_data_ptr());
    unsigned int len = trans.get_data_length();
    unsigned char *byt = trans.get_byte_enable_ptr();
    unsigned int wid = trans.get_streaming_width();

    Hinput_t request = txn->in;
    Houtput_t reply;

    amp_t result = HapplySlice(request.state, request.amplitude, request.req);
    reply.amplitude = result;
    reply.ID = request.ID;

    txn->out = reply;
    // Obliged to set response status to indicate successful completion
    delay += sc_time(10, SC_NS);
    trans.set_response_status(tlm::TLM_OK_RESPONSE);
  }
};

SC_MODULE(Top) {
  FindAmp *amplitude_finder;
  Hop *hadamard_op;

  SC_CTOR(Top) {
    // Instantiate components
    amplitude_finder = new FindAmp("FindAmp");
    hadamard_op = new Hop("Hop");

    // One initiator is bound directly to one target with no intervening bus

    // Bind initiator socket to target socket
    amplitude_finder->socket.bind(hadamard_op->socket);
  }
};

int sc_main(int argc, char *argv[]) {
  Top top("top");
  sc_start();
  return 0;
}