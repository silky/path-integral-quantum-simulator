#include <iostream>
#include <algorithm>

#include "algo.h"

using namespace std;


vector<state_t> StateBall(state_t state, vector<int> qubits) {
  vector<state_t> stateball;
  state_t newstate;
  for (state_t subset=0; subset.to_ulong()<=qubits.size(); subset = subset.to_ulong() + 1) {
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
  return stateball;
}

state_t bitextract(state_t state, vector<int> qubits) {
    state_t ret = 0;
    for (int i=0; i<qubits.size(); i++) {
        ret[i] = state[qubits[i]];
    }
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
    if (DEBUG) 
        cout << "evaluating for target state " << StateRepr(target_state) << " with " << remaining_circuit.size() << " gates left." << std::endl;
    
    if (remaining_circuit.size() == 0) // base case.
        return (target_state == inital_state) ? (amp_t){1.0, 0.0} : (amp_t){0.0, 0.0};
    

    gate_t current_gate = remaining_circuit.back();
    circuit_t remainder = circuit_t(remaining_circuit.begin(), remaining_circuit.end()-1);
    
    vector<state_t> predecessors = StateBall(target_state, current_gate.qubits);
    
    vector<amp_t> predecessor_amplitudes;
    for (state_t& p : predecessors) {
        predecessor_amplitudes.push_back( CalcAmp(remainder, inital_state, p) );
    }
    
    amp_t resultant_amplitude = {0.0, 0.0};
    
    vector<amp_t> res_partial_state_after_gate;
    for (int i=0; i<predecessors.size(); i++) {
        if (current_gate.g == H) {
            resultant_amplitude += HapplySlice(bitextract(predecessors[i], current_gate.qubits),
                                               predecessor_amplitudes[i], 
                                               bitextract(target_state, current_gate.qubits));
        } else {
            cout << "UNSUPPORTED GATE! " << current_gate.g << endl;
        }
    }
    
    return resultant_amplitude;
}

