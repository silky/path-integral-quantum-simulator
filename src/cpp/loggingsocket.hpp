#include "tlm.h"
#include "tlm_utils/simple_initiator_socket.h"
#include <vector>
#include <utility>
#include <string>

using namespace tlm_utils;

template< typename MODULE, unsigned int BUSWIDTH = 32
        , typename TYPES = tlm::tlm_base_protocol_types >
class logging_socket
  : public simple_initiator_socket_b<MODULE,BUSWIDTH,TYPES>
{
  typedef typename TYPES::tlm_payload_type txn_type;
  typedef  tlm::tlm_blocking_transport_if<txn_type>  transport;
  typedef simple_initiator_socket_b<MODULE,BUSWIDTH,TYPES> socket_b;
  
public:
  logging_socket() : socket_b() {}
  explicit logging_socket(const char* name) : socket_b(name) {}
  
  // bits and the time that they were sent.
  std::vector<std::pair<sc_time, int>> log;

  
  // (*this)-> ??
  void b_transport(txn_type& trans, sc_core::sc_time& t) {
      // std::cout << "calling b_transport" << std::endl;
      log.push_back(std::pair<sc_time, int>(sc_time_stamp(), BUSWIDTH));
      (*this)->b_transport(trans, t);
  }
  
  std::string printlog() {
      ostringstream out;
      out << BUSWIDTH << ",";
      for (auto& i : log) {
          sc_time t = i.first;
          out << t << ",";
      }
      return out.str();
  }
};
