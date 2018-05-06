#include <iostream>
#include <algorithm>

#include "algo.h"

using namespace std;

int debug_indent = 0;

vector<state_t> StateBall(state_t state, vector<int> qubits) {
  vector<state_t> stateball;
  state_t newstate;
  int NpriorStates = 1<<qubits.size(); // 2^number of bits
  if (DEBUG >= 3)
    cout << "creating stateball for " << qubits.size() << "qubits, should be " << NpriorStates <<  " in size" << endl;
  for (int i=0; i<NpriorStates; i++) {
    state_t subset = i;
    for (int idx=0; idx<NQUBITS; idx++) {

      // build the new state to insert
      auto replace_idx = find(qubits.begin(), qubits.end(), idx) - qubits.begin();
      if ( replace_idx != (qubits.end()-qubits.begin()) ) {
        // this bit is present in the vector.
        newstate[idx] = subset[replace_idx];
      } else {
        newstate[idx] = state[idx]; // it's always the same subset of changed bits so we can skip this, but clarity is good
      }
    }
    stateball.push_back( newstate );
  }
  if (DEBUG >= 2)
      cout << "stateball size " << stateball.size() << " should be " << (1<<qubits.size()) << endl;
  return stateball;
}

string PVec(vector<int> qubits) {
    ostringstream out;
    out << "[";
    for (int i : qubits) {
        out << i << ", ";
    }
    out << "]";
    return out.str();
}

state_t bitextract(state_t state, vector<int> qubits) {
    state_t ret = 0;
    for (int i=0; i<qubits.size(); i++) {
        ret[i] = state[qubits[i]];
    }
    // cout << "qubits " << PVec(qubits) << " from state " << StateRepr(state) << " are " << StateRepr(ret) << endl;
    return ret;
}

string StateRepr(state_t s) {
    ostringstream out;
    out << "|" << s.to_string() << ">";
    return out.str();
}

vector<amp_t> Happly(state_t in, amp_t inamp) {
    vector<amp_t> ret;
    ret.reserve(2);
    if (in.to_ulong() == 0) {
        ret[0] = inamp * sqrt22;
        ret[1] = inamp * sqrt22;
    } else { // state down
        ret[0] = inamp * sqrt22;
        ret[1] = inamp * (-sqrt22);
    }
    return ret;
}

vector<amp_t> CNOTapply(state_t in, amp_t inamp) {
    vector<amp_t> ret;
    ret.reserve(4);
    amp_t zero = {0.0, 0.0};
    ret[0] = (in == 0) ?  inamp : zero;
    ret[1] = (in == 1) ?  inamp : zero;
    ret[2] = (in == 3) ?  inamp : zero; // switch!
    ret[3] = (in == 2) ?  inamp : zero; // switch!
    return ret;
}

amp_t CNOTapplySlice(state_t in, amp_t inamp, state_t req) {
    amp_t res = CNOTapply(in, inamp)[req.to_ulong()];
    if (DEBUG >= 2)
        cout << std::string(debug_indent, ' ') << "applying CNOT on state " << StateRepr(in) << ":" << inamp.real() << " for target " << StateRepr(req) << ":" << res.real() << std::endl;
    return res;
}


amp_t HapplySlice(state_t in, amp_t inamp, state_t req) {
    vector<amp_t> ret;
    ret.reserve(2);
    if (in.to_ulong() == 0) {
        ret[0] = inamp * sqrt22;
        ret[1] = inamp * sqrt22;
    } else { // state down
        ret[0] = inamp * sqrt22;
        ret[1] = inamp * (-sqrt22);
    }
    return ret[req.to_ulong()];
}



amp_t CalcAmp(circuit_t remaining_circuit, state_t inital_state, state_t target_state) {
    // if (DEBUG) 
    //     cout << std::string(debug_indent, ' ') << "evaluating for target state " << StateRepr(target_state) << " with " << remaining_circuit.size() << " gates left." << std::endl;
    
    if (remaining_circuit.size() == 0) { // base case.
        amp_t ret = (target_state == inital_state) ? (amp_t){1.0, 0.0} : (amp_t){0.0, 0.0};
        if (DEBUG) 
            cout << std::string(debug_indent, ' ') << "base state " << StateRepr(target_state) << ret.real() << std::endl;
        return ret;
    }

    gate_t current_gate = remaining_circuit.back();
    circuit_t remainder = circuit_t(remaining_circuit.begin(), remaining_circuit.end()-1);
    
    vector<state_t> predecessors = StateBall(target_state, current_gate.qubits);
    
    vector<amp_t> predecessor_amplitudes;
    debug_indent += 1;
    for (state_t& p : predecessors) {
        predecessor_amplitudes.push_back( CalcAmp(remainder, inital_state, p) );
    }
    debug_indent -= 1;

    
    amp_t resultant_amplitude = {0.0, 0.0};
    
    vector<amp_t> res_partial_state_after_gate;
    amp_t addend;
    for (int i=0; i<predecessors.size(); i++) {
        switch (current_gate.g) {
        case H:
            addend = HapplySlice(bitextract(predecessors[i], current_gate.qubits),
                                               predecessor_amplitudes[i], 
                                               bitextract(target_state, current_gate.qubits));
          break;
        case CNOT:
            addend = CNOTapplySlice(bitextract(predecessors[i], current_gate.qubits),
                                                  predecessor_amplitudes[i], 
                                                  bitextract(target_state, current_gate.qubits));
          break;
        default:
          cout << "UNSUPPORTED GATE! " << current_gate.g << endl;
          addend = {0.0, 0.0};
          break;
        }
        
        if (DEBUG) 
            cout << std::string(debug_indent, ' ') << "adding amp from prior state " << StateRepr(predecessors[i]) << " : " << addend.real() << std::endl;

        resultant_amplitude += addend;
    }
    
    if (DEBUG) 
        cout << std::string(debug_indent, ' ') << "evaluating for target state " << StateRepr(target_state) << " with " << remaining_circuit.size() << " gates left. - amplitude " << resultant_amplitude.real() << std::endl;
    
    return resultant_amplitude;
}

