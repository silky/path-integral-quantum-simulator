// Needed for the simple_target_socket
#define SC_INCLUDE_DYNAMIC_PROCESSES

#include "systemc"
using namespace sc_core;
using namespace sc_dt;
using namespace std;

#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include "tlm_utils/simple_target_socket.h"

#include <complex>

typedef struct Hinput {
  int ID;
  state_t state;
  amp_t amplitude;
} Hinput_t;

typedef struct Houtput {
  int ID;
  amp_t amplitudes[2]; // 2 possible output states - thease are the relevent amplitudes for up, down
} Houtput_t;

typedef union Htxn { Hinput_t in; Houtput_t out; } Htxn_t; // used for a operator action - represents both the action and the output - As transactional modelling is super directed twards memory access


struct FindAmp : sc_module {
  // socket for the hadamard gate
  tlm_utils::simple_initiator_socket<FindAmp, sizeof(Htxn_t)> socket;

  SC_CTOR(FindAmp) : socket("socket") // Construct and name socket
  {
    SC_THREAD(thread_process);
  }

  // layer 0: inital state, 1: after first gate applied, etc.

  void thread_process() {

    // Internal data buffer used by initiator with generic payload
    Htxn_t data = { .in={ .ID=0, .state=1, .amplitude=(amp_t){ .real=1.0, .imag=0.0 } } };

    // TLM-2 generic payload transaction, reused across calls to b_transport
    tlm::tlm_generic_payload *trans = new tlm::tlm_generic_payload;
    sc_time delay = sc_time(10, SC_NS);

    // default stuff for the H gate transaction, boring.
    trans->set_command(tlm::TLM_WRITE_COMMAND);
    trans->set_address(0);
    trans->set_data_ptr(reinterpret_cast<unsigned char *>(&data));
    trans->set_data_length(sizeof(data));
    trans->set_streaming_width(sizeof(data)); // = data_length to indicate no streaming
    trans->set_byte_enable_ptr(0); // 0 indicates unused
    trans->set_dmi_allowed(false); // Mandatory initial value
    trans->set_response_status(tlm::TLM_INCOMPLETE_RESPONSE); // Mandatory initial value


    socket->b_transport(*trans, delay); // Blocking transport call

    // Initiator obliged to check response status and delay
    if (trans->is_response_error())
      SC_REPORT_ERROR("TLM-2", "Response error from b_transport");

    // cout << "trans = { " << (cmd ? 'W' : 'R') << ", " << hex << i
    //      << " } , data = " << hex << data << " at time " << sc_time_stamp()
    //      << " delay = " << delay << endl;

    cout << "resultant state amplitudes up:" << (amp_t)(data.out.amplitudes[0]) << endl;

    // Realize the delay annotated onto the transport call
    wait(delay);
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

    if (request.state == 0) {
        reply.amplitudes[0] = request.amplitude * sqrt22;
        reply.amplitudes[1] = request.amplitude * sqrt22;
    } else { // state down
        reply.amplitudes[0] = request.amplitude * sqrt22;
        reply.amplitudes[1] = request.amplitude * (-sqrt22);
    }

    txn->out = reply;
    // Obliged to set response status to indicate successful completion
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
