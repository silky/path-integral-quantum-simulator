using System.Numerics;
using MathNet.Numerics.LinearAlgebra;
using System.Collections;
using System.Collections.Generic;
// A Hello World! program in C#.
using System;

namespace QLib
{

  public class Qlib // no static?
  {
    public Qlib() {}

    public static int getIntFromBitArray(BitArray bitArray)
    {
        if (bitArray.Length > 32)
            throw new ArgumentException("Argument length shall be at most 32 bits.");

        int[] array = new int[1];
        bitArray.CopyTo(array, 0);
        return array[0];
    }
    
    public static String StateRepr(int s, int Nqubits) {
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
      for (int sub=0; sub<1<<qubits.Count; sub++) {
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
  
  // static Complex calcAmp(int neighbour, int initalState, LinCircuit remainder) {
  //   if (remainder.Count == 0) {
  //     return neighbour == initalState ? 1.0 : 0.0; // no calculation to do
  //   } else {
  //     var CurrentGate = remainder[integerList.Count - 1]; // last gate
  //     // calculate prior amplitudes
  //     List<Complex> priorAmplitudes = new List<Complex>{};
  //     foreach (var prior in possiblePredecessorStates(initalState, CurrentGate.Item2)) {
  //       Complex a = calcAmp(prior, )
  //     }
  //   }
  // 
  //   for 
  //   return 0.0;
  // 
  // }
  
  }
}