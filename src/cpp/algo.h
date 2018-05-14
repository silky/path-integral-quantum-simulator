#ifndef ALGO_H
#define ALGO_H

#include <bitset>
#include <vector>
#include <complex>

#define NQUBITS 4
#define MAX_OP_SIZE 2
#define DEBUG 0
#define BWLOG 1

using namespace std;

constexpr int MAX_PRED_STATES = (1<<MAX_OP_SIZE);

constexpr int NSTATES = (1<<NQUBITS);

typedef complex<float> amp_t;
static amp_t sqrt22 = {.real=sqrt(2)/2.0, .imag=0.0};

typedef bitset<NQUBITS> state_t;

enum gatelib { H, CNOT };
typedef struct gate { gatelib g; int arity; vector<int> qubits; } gate_t;
typedef vector<gate> circuit_t;

static vector<int> first_qubit = {0}; // for specifing a single qubit gate.
static vector<int> snd_qubit = {1}; // for specifing a single qubit gate.

// INDEXING REVERSED CURRENTLY - NQUBITS-1 is the 0th in quirk
static circuit_t circuit = {
    (gate_t){H, 1, {0}},
    (gate_t){H, 1, {1}},
    (gate_t){H, 1, {2}},
    (gate_t){H, 1, {3}},
    // (gate_t){H, 1, {4}},
    // (gate_t){H, 1, {5}},

    
    (gate_t){CNOT, 2, {0, 1}},
    (gate_t){CNOT, 2, {1, 2}},
    (gate_t){CNOT, 2, {2, 3}},
    // (gate_t){CNOT, 2, {3, 4}},
    // (gate_t){CNOT, 2, {4, 5}},


    (gate_t){H, 1, {0}},
    (gate_t){H, 1, {1}},
    (gate_t){H, 1, {2}},
    (gate_t){H, 1, {3}}
    // (gate_t){H, 1, {4}},
    // (gate_t){H, 1, {5}}

};

vector<state_t> StateBall(state_t, vector<int>);

state_t bitextract(state_t, vector<int>);

string StateRepr(state_t);

vector<amp_t> Happly(state_t, amp_t);
amp_t HapplySlice(state_t, amp_t, state_t);

vector<amp_t> CNOTapply(state_t, amp_t);
amp_t CNOTapplySlice(state_t, amp_t, state_t);

amp_t CalcAmp(circuit_t, state_t, state_t);

#endif