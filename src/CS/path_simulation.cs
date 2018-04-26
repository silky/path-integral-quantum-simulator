using System.Numerics;
using MathNet.Numerics.LinearAlgebra;
using System.Collections;
using System.Collections.Generic;
// A Hello World! program in C#.
using System;
using System.Linq;

// C#: sometimes you want to call a spoon a spoon, not a Object<Utensil<Fluids>> - even this is too discriptive!
// spoon in C#:
//       x,     y,     z,     Parts (handle, bowl etc) with mass
// Tuple<float, float, float, List<Tuple<String, float>>>

// basis defn:
// State[i] = amplitude of state i expressed as binary number.

// let's have a circut data structure.
// gate: using gate = Tuple<Matrix<Complex>, Matrix<Complex>, int> (Matrix, Inverse, arity)
// circuit-stage: using cstage = List<Tuple<gate, List<int>>> list of gates and the qubits to apply to
// circuit: List<cstage>

// YOU CAN'T NEST DECLS. really?
// using Operator = MathNet.Numerics.LinearAlgebra.Complex.DenseMatrix;
// // (Matrix, Inverse, arity)
// using Gate = System.Tuple<Operator, Operator, int>;
// // list of gates and the qubits to apply to
// using CStage = System.Collections.Generic.List<System.Tuple<Gate, System.Collections.Generic.List<int>>>;
// using Circuit = System.Collections.Generic.List<CStage>;

// NOPE: non-trivial construtors. This works for things you build dynamiclly.
// public class Operator : MathNet.Numerics.LinearAlgebra.Complex.DenseMatrix {}
// public class Gate : System.Tuple<Operator, Operator, int> {}
// public class CStage : System.Collections.Generic.List<System.Tuple<Gate, System.Collections.Generic.List<int>>> {}
// public class Circuit : System.Collections.Generic.List<CStage> {}

using Operator = MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>;
// // (Matrix, Inverse, arity)
using Gate = System.Tuple<
  MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>, 
  MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>, 
  int
>;
// // list of gates and the qubits to apply to - look at the commented using for somthing readable
using CStage = System.Collections.Generic.List<
  System.Tuple<
    System.Tuple<
      MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>,
      MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>, 
      int>, 
    System.Collections.Generic.List<int>
  >
>;

using Circuit = System.Collections.Generic.List<
  System.Collections.Generic.List<
    System.Tuple<
      System.Tuple<
        MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>, MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>, 
        int>, 
      System.Collections.Generic.List<int>
    >
  >
>;

// Type for a flattened circuit.
using LinCircuit = System.Collections.Generic.List<
  System.Tuple<
    System.Tuple<
      MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>, MathNet.Numerics.LinearAlgebra.Matrix<System.Numerics.Complex>, 
      int>, 
    System.Collections.Generic.List<int>
  >
>;


class Hello 
{
  static int Nqubits = 2;
  // basis rep: int, bit pos set: that qubit is up in that state
  
  // https://stackoverflow.com/questions/5283180/how-can-i-convert-bitarray-to-single-int
  // also, REALLY
  static int getIntFromBitArray(BitArray bitArray)
  {
      if (bitArray.Length > 32)
          throw new ArgumentException("Argument length shall be at most 32 bits.");

      int[] array = new int[1];
      bitArray.CopyTo(array, 0);
      return array[0];
  }
  
  static String StateRepr(int s) {
    String sBits = Convert.ToString(s, 2).PadLeft(Nqubits, '0');
    String ket = String.Format("|{0}>", sBits);
    return ket;
  }
  
  // take the partial trace over the basis state. 
  // returns a convetional state representation with the selected state amplitude 1+0j.
  // This only makes sense in the path integral formulation - this way of reducing the state discards all mutual information.
  static Vector<Complex> partial_trace(int state, int[] qubits) {
    BitArray state_bits = new BitArray(new int[] { state });
    BitArray traced_state_bits = new BitArray(qubits.Length);
    
    // do the trace
    for (int i=0; i<qubits.Length; i++) {
      traced_state_bits[i] = state_bits[qubits[i]];
    }
    
    // find the basis state index in the reduced subspace
    int traced_state = getIntFromBitArray(traced_state_bits);
    var traced_state_vector = Vector<Complex>.Build.Dense(
      1<<qubits.Length, 
      i => i == traced_state ? 1.0 : 0.0
    );
    return traced_state_vector;
  }
  
  static Matrix<Complex> Hm = Matrix<Complex>.Build.DenseOfArray( new Complex[,] {{ 1.0, 1.0 }, { 1.0, -1.0 }}) / Math.Sqrt(2);
  
  static Matrix<Complex> Im = Matrix<Complex>.Build.DenseIdentity(2);


  // we never need to operate on full states, as we know it's only basis states.
  // after operating, probably not in a basis anymore!
  static Vector<Complex> H(Vector<Complex> instate) {
    // need vector (amp_up, amp_down)
    return instate * Hm;
  }
  
  // makes copies of the vectors passed in, as this is a terrible way to do this. really.
  static Vector<Complex> KronProd(Vector<Complex>[] states) {
    Matrix<Complex> retval = Matrix<Complex>.Build.Dense(1, 1, 1);
    foreach (var state in states) {
      retval = retval.KroneckerProduct(MathNet.Numerics.LinearAlgebra.Complex.DenseMatrix.OfColumnVectors(new Vector<Complex>[] { state } ));
    }
    return retval.Column(0);
  }
  
  // generates the possible pred gates of state from a gate involving the given qubits.
  static List<int> possiblePredecessorStates(int state, List<int> qubits) {
    List<int> poss = new List<int>{};
    
    // we want all posible combinations of the bits refered to by the locations in qubits.
    var substutions = Enumerable.Range(0, 1<<qubits.Count);
    foreach (int sub in substutions) {
      BitArray state_bits = new BitArray(new int[] { state });
      BitArray sub_bits = new BitArray(new int[] { sub });
      for (int i=0; i<qubits.Count; i++) {
        state_bits[qubits[i]] = sub_bits[i];
      }
      int new_pred_state = getIntFromBitArray(state_bits);
      poss.Add(new_pred_state);
    }
    return poss;
  }
  
  static Complex calcAmp(int neighbour, int initalState, LinCircuit remainder) {
    if (remainder.Count == 0) {
      return neighbour == initalState ? 1.0 : 0.0; // no calculation to do
    }
    return 0.0;
    
  }
  
  static void Main() 
  {
    Gate Hademard = new Gate(Hm, Hm, 1);
    Gate Idty = new Gate(Im, Im, 1);
    
    // lets just do th recursive bit!
    // target state: 
    int target = 2; // should be sqrt(2)+0i amplitude.
    
    CStage first_stage = new CStage{Tuple.Create(Hademard, new List<int> {0}), 
                                    Tuple.Create(Idty, new List<int> {1}) };
                                    
    // Circuit c = new Circuit{ new List<CStage> {first_stage} };
    // 
    // LinCircuit c_flat = new LinCircuit{};
    // foreach (var stage in c) {
    // }
    // foreach (var gate_bit_tple in stage) {
    //   c_flat.Add(gate_bit_tple);
    // }
    
    LinCircuit c_flat = new LinCircuit{Tuple.Create(Hademard, new List<int> {0}), Tuple.Create(Idty, new List<int> {1})}; // H on bit 0, then idty on bit 1. all trivial gates for now.

    // 
    // // gate identity = new gate()
    // var S = Vector<Complex>.Build; // implicit elementwise multiplication with the vector of basis states.
    // // var Sm = Matrix<Complex>.Build; // implicit elementwise multiplication with the vector of basis states. Matrix for KronProduct.
    // // var Sm = MathNet.Numerics.LinearAlgebra.Complex.DenseMatrix.OfColumnVectors;
    // 
    // // a state is a single elemnet of the basis: a integer.
    // int current_state = 1; // |01> initally!
    // Complex CurAmp = 1.0;
    // 
    // foreach (var stage in c) {
    //   foreach (var gate_ in first_stage) {
    //     // we need to process for each possible input sta
    //   }
    //   // we have a list of gates - nned the qubits for those gates.
    // 
    // }
    
    int inital_state = 1;
    // first gate set: [H, I].
    var first_qubit_after_gates = H(partial_trace(inital_state, new int[] {0}));
    var second_qubit_after_gates = partial_trace(inital_state, new int[] {1});
    var state_after_gates = KronProd(new Vector<Complex>[] {
       first_qubit_after_gates,
       second_qubit_after_gates
    });
    
    
    // Vector<Complex> state = S.
    
    // basis = V.Dense(1 << Nqubits, i => i); no need for the explicit basis
    
    for (int s=0; s< 1<<Nqubits; s++) {
      Console.WriteLine("State {0} is {1}", s, StateRepr(s));
    }
    Console.WriteLine("state after gates is {0}", state_after_gates);


  }
}
