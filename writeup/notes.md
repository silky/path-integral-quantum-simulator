
# idea: to create a quantum circut sim that can distribute over AWS cards

current state of the art:
  direct matrix calculation: state is vec<2^states>, op is matrix<2^n, 2^n> in size, very large.
  SPECqsim: sample intermediate states to reduce the intermediate state size to 2n numbers. requires exponential reruns 
  IBM: find mostly-unentanged subspaces and sim them separately. good for qsup, not good for algos


Zynq: 16qubits
349mb onhip: 25 qubits. 36qubits over all the blades in a box. scaling is poor. for SPECqsim qubit count = 45744128, HUGE. Is slower than matrix products if you can fit the state in memory.

doing the specqsim thing or not, need to efficiently work with product states.
 a  b  
(H . I)(|1>|0>) == H|1> . I|0>  for a product state, but
(H . I)(|11> + |00>) is not reducible. so each operator needs to be able to accept the full width of 2^n input.

can simplify: (I . H . I) == P(H . I . I)P^-1 where P is a simple reorder matrix
can have the "rewiring" matrix before and after each op.

|a> - H - . - H - |
          |       |
|b> - H - O - H - | MEASURE
                  |
|c> - H - I - I - |

             The H's here need to work on the combined state of |ab> as possibly entangled.
  
keep upper triangular mutual information matrix.
1 0 0
0 1 0
0 0 1
  |
  v
1 0 0
0 1 0
0 0 1
  |
  v
1 1 0 <- mutual information can exist as both participated in the same gate.
1 1 0
0 0 1
  |
  v
1 1 0
1 1 0
0 0 1

# what sysint needs for this to work

new dataflow type: qubit vector, of exponential size
convertors (P gates) that can fill in the not participating elements of the state with don't cares
and convertors to AXI or whatever so it can go over the bridges.

for SPECqsim states are always expressible as product states so we can just use the simple 1/2/3qubit gate forms. SPECqsim 2009, was going to be a FPGA impl but ran out of funds and got bored, joined a networking corp.

systolic: ploytope: points discribe computations, have input dimentions:
  no not quite right.
  
  dataflow: in from some edges, flow through computational nodes. 
    input is initial state vector + RNG samples.
  
  say 5 sources of input: got some hyperobject with many dims of input, need to flatten.
  
  transformation from spce to space-time repr.

writeup!
  kiwi - remote is slow.

title, abstract, conclusion! do a writeup for thursday?
Synt rules in interconn. 