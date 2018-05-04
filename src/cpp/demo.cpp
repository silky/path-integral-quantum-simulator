#include <iostream>

#include "algo.h"

int main(void) {
    vector<int> ActOnZero = {0};
    auto stateball = StateBall(0, ActOnZero);
    
    cout << "stateball for |00> for gate on bit 0:" << endl;
    for (auto& prior_state : stateball) {
        cout << StateRepr(prior_state) << endl;
    }
    state_t inital_state = 1;
    cout << "final amplitude for " << StateRepr(inital_state) << " on HH:" << endl;
    // cout << StateRepr(0) << ":" << CalcAmp(circuit, inital_state, 0) << endl;
    for (int i=0; i<NSTATES; i++) {
        cout << StateRepr(i) << ":" << CalcAmp(circuit, inital_state, i) << endl;
    }
}