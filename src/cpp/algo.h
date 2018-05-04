#ifndef ALGO_H
#define ALGO_H

#include <bitset>
#include <vector>
#include <complex>

#define NQUBITS 2
#define DEBUG 0

using namespace std;

constexpr int NSTATES = (1<<NQUBITS);

typedef complex<float> amp_t;
static amp_t sqrt22 = {.real=sqrt(2)/2.0, .imag=0.0};

typedef bitset<NQUBITS> state_t;

enum gatelib { H, CNOT };
typedef struct gate { gatelib g; int arity; vector<int> qubits; } gate_t;
typedef vector<gate> circuit_t;

static vector<int> first_qubit = {0}; // for specifing a single qubit gate.
static circuit_t circuit = {
    (gate_t){H, 1, first_qubit},
    (gate_t){H, 1, first_qubit}
};

vector<state_t> StateBall(state_t, vector<int>);

state_t bitextract(state_t, vector<int>);

string StateRepr(state_t);

vector<amp_t> Happly(state_t, amp_t);

amp_t CalcAmp(circuit_t, state_t, state_t);

#endif