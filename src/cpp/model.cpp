// Needed for the simple_target_socket
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include <typeinfo>

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "algo.h"
#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include <complex>

#define N_H_OPS 8
// currently the parrell code assumes same no of blocks
#define N_CNOT_OPS N_H_OPS

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

typedef Htxn_t CNOTtxn_t; // for now, it's just the same thing. If we get more
                          // efficent at passing the states this might change.

struct FindAmp : sc_module {
  // socket for the hadamard gate
  tlm_utils::simple_initiator_socket<
      FindAmp, sizeof(Htxn_t), tlm::tlm_base_protocol_types> *sockets[N_H_OPS];
  tlm_utils::simple_initiator_socket<FindAmp, sizeof(Htxn_t),
                                     tlm::tlm_base_protocol_types>
      *CNOTsocks[N_CNOT_OPS];

  tlm::tlm_generic_payload transactions[N_H_OPS + N_CNOT_OPS]; // array of ptrs
                                                               // to txn objects
                                                               // for each
                                                               // module
  sc_time delay = sc_time(10, SC_NS);

  SC_CTOR(FindAmp) {
    for (int i = 0; i < N_H_OPS; i++) {
      char txt[20];
      sprintf(txt, "socket_H_%d", i);
      sockets[i] = new tlm_utils::simple_initiator_socket<
          FindAmp, sizeof(Htxn_t), tlm::tlm_base_protocol_types>(txt);

      init_txn(&transactions[i]);
    }
    for (int i = 0; i < N_CNOT_OPS; i++) {
      char txt[20];
      sprintf(txt, "socket_CNOT_%d", i);
      CNOTsocks[i] = new tlm_utils::simple_initiator_socket<
          FindAmp, sizeof(Htxn_t), tlm::tlm_base_protocol_types>(txt);

      init_txn(&transactions[N_H_OPS + i]);
    }
    SC_THREAD(thread_process);
  }

  void init_txn(tlm::tlm_generic_payload *txn) {
    txn->set_command(tlm::TLM_WRITE_COMMAND);
    txn->set_address(0);
    txn->set_data_length(sizeof(Htxn_t));
    txn->set_streaming_width(
        sizeof(Htxn_t));         // = data_length to indicate no streaming
    txn->set_byte_enable_ptr(0); // 0 indicates unused
    txn->set_dmi_allowed(false); // Mandatory initial value
    txn->set_response_status(
        tlm::TLM_INCOMPLETE_RESPONSE); // Mandatory initial value
  }

  // layer 0: inital state, 1: after first gate applied, etc.

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
    delay += sc_time(5 * predecessors.size(),
                     SC_NS); // for the stateball - it's just some bitflips!

    vector<amp_t> predecessor_amplitudes;
    for (state_t &p : predecessors) {
      predecessor_amplitudes.push_back(CalcAmpSC(remainder, inital_state, p));
      delay += sc_time(5, SC_NS); // pushing stuff onto the stack.
    }
    if (DEBUG)
      cout << "N predecessors: " << predecessor_amplitudes.size() << endl;

    amp_t resultant_amplitude = {0.0, 0.0};

    vector<amp_t> res_partial_state_after_gate;
    int Npreds = predecessors.size();
    if (DEBUG)
      cout << "parallel invocations: " << Npreds / N_H_OPS
           << " serial invocations: " << (Npreds % N_H_OPS) << endl;

    sc_time delay_accumulator, localdelay;
    for (int i = 0; i < Npreds / N_H_OPS; i++) { // parallel iterations.
      delay_accumulator = sc_time(0, SC_NS);
      for (int j = 0; j < N_H_OPS; j++) {
        localdelay = sc_time(0, SC_NS); // for parallel invocations, we use the
                                        // max of the parallel versions.
        int idx = i * N_H_OPS + j;

        switch (current_gate.g) {
        case H:
          resultant_amplitude += HapplySliceSC(
              bitextract(predecessors[idx], current_gate.qubits),
              predecessor_amplitudes[idx],
              bitextract(target_state, current_gate.qubits), j, localdelay);
          delay += sc_time(5, SC_NS); // addition
          break;
        case CNOT:
          resultant_amplitude += CNOTapplySliceSC(
              bitextract(predecessors[idx], current_gate.qubits),
              predecessor_amplitudes[idx],
              bitextract(target_state, current_gate.qubits), j, localdelay);
          delay += sc_time(5, SC_NS); // addition
          break;
        default:
          cout << "UNSUPPORTED GATE! " << current_gate.g << endl;
          break;
        }

        if (localdelay > delay_accumulator) {
          delay_accumulator = localdelay;
        }
      }
      delay += delay_accumulator;
    }

    // we also need to do the localdelay dance here.
    int startidx = Npreds - (Npreds % N_H_OPS);
    delay_accumulator = sc_time(0, SC_NS);
    for (int i = startidx; i < Npreds; i++) {
      localdelay = sc_time(0, SC_NS);
      switch (current_gate.g) {
      case H:
        resultant_amplitude += HapplySliceSC(
            bitextract(predecessors[i], current_gate.qubits),
            predecessor_amplitudes[i],
            bitextract(target_state, current_gate.qubits), i, localdelay);
        delay += sc_time(5, SC_NS); // addition
        break;
      case CNOT:
        resultant_amplitude += CNOTapplySliceSC(
            bitextract(predecessors[i], current_gate.qubits),
            predecessor_amplitudes[i],
            bitextract(target_state, current_gate.qubits), i, localdelay);
        delay += sc_time(5, SC_NS); // addition
        break;
      default:
        cout << "UNSUPPORTED GATE! " << current_gate.g << endl;
        break;
      }

      if (localdelay > delay_accumulator) {
        delay_accumulator = localdelay;
      }
    }
    
    delay += delay_accumulator;
    return resultant_amplitude;
  }

  amp_t HapplySliceSC(state_t in, amp_t inamp, state_t req, int idx,
                      sc_time &locdelay) {
    Htxn_t data = {
        .in = {.ID = 0, .state = in, .amplitude = inamp, .req = req}};
    transactions[idx].set_data_ptr(reinterpret_cast<unsigned char *>(&data));

    (*sockets[idx])
        ->b_transport(transactions[idx], locdelay); // no momber named b_transport

    if (transactions[idx].is_response_error())
      SC_REPORT_ERROR("TLM-2", "Response error from b_transport");
    return data.out.amplitude;
  }
  
  amp_t CNOTapplySliceSC(state_t in, amp_t inamp, state_t req, int idx,
                      sc_time &locdelay) {
    CNOTtxn_t data = {
        .in = {.ID = 0, .state = in, .amplitude = inamp, .req = req}};
    transactions[idx+N_H_OPS].set_data_ptr(reinterpret_cast<unsigned char *>(&data));

    (*CNOTsocks[idx])
        ->b_transport(transactions[idx+N_H_OPS], locdelay); // no momber named b_transport

    if (transactions[idx+N_H_OPS].is_response_error())
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

// Target module representing a Hadamard gate
struct CNOTop : sc_module {
  // TLM-2 socket, input is ID (16b), state (2b), amplitude (2*32b)
  tlm_utils::simple_target_socket<CNOTop, sizeof(CNOTtxn_t)> socket;

  SC_CTOR(CNOTop) : socket("socket") {
    // Register callback for incoming b_transport interface method call
    socket.register_b_transport(this, &CNOTop::b_transport);
  }

  // TLM-2 blocking transport method
  virtual void b_transport(tlm::tlm_generic_payload &trans, sc_time &delay) {
    tlm::tlm_command cmd = trans.get_command();
    Htxn_t *txn = reinterpret_cast<CNOTtxn_t *>(trans.get_data_ptr());

    Hinput_t request = txn->in;
    Houtput_t reply;

    amp_t result = CNOTapplySlice(request.state, request.amplitude, request.req);
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
  Hop *hadamard_ops[N_H_OPS];
  CNOTop *cnot_ops[N_CNOT_OPS];

  SC_CTOR(Top) {
    // Instantiate components
    amplitude_finder = new FindAmp("FindAmp");

    // One initiator is bound directly to one target with no intervening bus

    // Bind initiator socket to target socket
    for (int i = 0; i < N_H_OPS; i++) {
      hadamard_ops[i] = new Hop("Hop");
      amplitude_finder->sockets[i]->bind(hadamard_ops[i]->socket);
    }
    for (int i = 0; i < N_CNOT_OPS; i++) {
      cnot_ops[i] = new CNOTop("CNOTop");
      amplitude_finder->CNOTsocks[i]->bind(cnot_ops[i]->socket);
    }

  }
};

int sc_main(int argc, char *argv[]) {
  Top top("top");
  sc_start();
  return 0;
}