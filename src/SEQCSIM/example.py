import numpy as np
import json

"""
1 procedure SEQCSim::run():
2   curState := inputState; // Current basis state, in the computational basis
3   curAmp := 1; // Amplitude of current basis state
4   for PC =: 0 to #gates, // Index of current operation in the gate sequence
5       with respect to the operator gate[PC] and its operands,
6           for each neighbor nbri of curState,
7               if nbri = curState, amp[nbri] :=curAmp;
8               else amp[nbri] := calcAmp(nbri);
9           amp[] := opMatrix * amp[]; // Complex matrix product
10  prob[] := normSqr(amp[]); // Calc probs as normalized squares of amplitudes.
11  i := pickFromDist(prob[]); // Pick a random successor of the current state.
12  curState := nbri
; // Go to that neighbor.
13  curAmp := amp[nbri]. // Remember its amplitude, calculated earlier.
14
15 function SEQCSim::calcAmp(State nbr): // Recursive amplitude-calculation procedure
16  curState := nbr;
17  if PC=0, return (curState = inputState) ? 1 : 0; // At t=0, input state has all the amplitude.
18  else, with respect to the operator gate[PC−1] and its operands,
19  for each predecessor predi of curState,
20      PC := PC − 1;
21      amp[predi] = calcAmp(predi); // Recursive calculation of pred. amp.
22      PC := PC + 1;
23  amp[] := opMatrix * amp[]; // Complex matrix product
24  return amp[curState];
"""

# lets have a near-trivial circuit
# built in quirk:
circuit_s = """
{
  "cols": [
    [
      "H",
      "H"
    ],
    [
      "•",
      "Z"
    ]
  ]
}
"""

# we how have a thing to simulate!
circuit = json.loads(circuit_s)

# build our gates
cZ = np.array([ [1, 0, 0, 0],
                [0, 1, 0, 0],
                [0, 0, 1, 0],
                [0, 0, 0, -1] ])

H = (1/np.sqrt(2)) * np.array([[1, 1], 
                              [1, -1]])

# inital state, in the basis. all 0 qubits.
up = np.array([1.0+0j, 0])

# direct simulation: just to check
inital = np.kron(up, up)
state_1 = inital @ np.kron(H, H)
state_1

state_2 = state_1 @ cZ
state_2 # +++- - matches quirk.



class SEQCSim(object):
    
    def __init__(self):
        self.inputState = [up, up]
        self.gates = [ np.kron(H, H), cZ ]
    
    def run(self):
        curState = self.inputState
        curAmp = 1.0
        for PC in range(len(self.gates)):
            op = self.gates[PC]
            
            # wrt op gate[PC]