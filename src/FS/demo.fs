// This module defines the gate libary and the problem to be simulated by the different methods.
 
namespace Demo

open MathNet.Numerics.LinearAlgebra.Complex
open System.Numerics

module qdefs = 

  let ZeroIm (v : float) : Complex = Complex(v, 0.0)
  let ZeroImI (v : int) : Complex = Complex(float(v), 0.0)

  type operator = DenseMatrix // complex due to the typedef
  type circuit = (operator * int []) list // op acting on qubits, list. 

  let Nqubits = 2

  // Gate lib: shared by both methods.
  let H1d : Complex [] = Array.map ZeroIm [| 1.0; 1.0; 1.0; -1.0 |]
  let H : operator = DenseMatrix.Create(2, 2, fun x y -> H1d.[x+2*y] / (ZeroIm (sqrt 2.0)) ) 
  let I : operator = DenseMatrix.CreateDiagonal(2, 2, ZeroIm 1.0)

  let N1d : Complex [] = Array.map ZeroImI [| 1; 0; 0; 0;
                                              0; 1; 0; 0;
                                              0; 0; 0; 1;
                                              0; 0; 1; 0 |]
  let CNOT : operator = DenseMatrix.Create(4, 4, fun x y -> N1d.[x+4*y]) 

  let S1d : Complex [] = Array.map ZeroImI [| 1; 0; 0; 0;
                                              0; 0; 1; 0;
                                              0; 1; 0; 0;
                                              0; 0; 0; 1 |]
  let SWAP : operator = DenseMatrix.Create(4, 4, fun x y -> S1d.[x+4*y]) // swaps bits 0 and 1

  // example circuit for both methods to evaluate
  let simple_circuit : circuit =  (CNOT, [|1; 0|]) :: (H, [|0|]) :: []