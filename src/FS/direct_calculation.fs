open Demo.qdefs
open MathNet.Numerics.LinearAlgebra.Complex
open System.Numerics
open Microsoft.FSharp.Collections
open QLib // cannot use open on static classes, as C# etc


// Haskell could define a constant in type-land for number of qubits, that this lot could depend upon
type state = DenseVector // bitstring really

let initalstate : state = DenseVector.Create(pown 2 Nqubits, fun i -> if i = 0 then ZeroIm 1.0 else ZeroIm 0.0)

//printfn "inital state:"
//let _ = List.map (fun s -> printfn "%s : %A" (Qlib.StateRepr(s, Nqubits)) (initalstate.[s]) ) 
//                 [0..(1<<<Nqubits)-1]


let OpDim (op : operator) : int = int (floor (sqrt (float (op.RowCount))))

// gate libary
// gets a operator acting on a qubit set starting at idx - use swap gates to get the rest of the way
let OpAtIdx (op : operator) idx =
  let dim : int = OpDim op
  // printfn "op dim %A, starting at idx: %A" dim idx // correct
  let before_qubits = idx
  let after_qubits  = (Nqubits) - (idx+dim)
  
  // printfn "before qubits: %A" before_qubits 
  // printfn "after qubits: %A" after_qubits 
  let before : operator = DenseMatrix.CreateDiagonal(pown 2 before_qubits, pown 2 before_qubits, ZeroIm 1.0) 
  let after  : operator = DenseMatrix.CreateDiagonal(pown 2 after_qubits, pown 2 after_qubits, ZeroIm 1.0) 
  // printfn "before matrix: %A" (before.ToTypeString())
  // printfn "after matrix: %A" (after.ToTypeString())

  let ret : operator = DenseMatrix.OfMatrix(after.KroneckerProduct(op).KroneckerProduct(before))
  ret

// printfn "H acting on 0\n%A" (OpAtIdx H 0)
// printfn "H acting on 1\n%A" (OpAtIdx H 1)


// generates a arbitary swap
let rec SWAPnn (src : int) (dest : int) : operator =
  match (src, dest) with
    | (s, d) when s = d -> DenseMatrix.CreateIdentity(pown 2 Nqubits)
    | (s, d) when s > d -> (OpAtIdx SWAP (s-1)) * (SWAPnn (s-1) d) // src larger than dest: use swaps from src-1 to dest.
    | (s, d) when s < d -> (SWAPnn d s) // (OpAtIdx SWAP s) * (SWAPnn (s+1) d)     // need to go down.

// printfn "SWAP on 0 \n%A" (OpAtIdx SWAP 0)
// printfn "SWAP 0 to 1\n%A" (SWAPnn 0 1)

// printfn "NULL SWAP 0 to 1\n%A" ((SWAPnn 0 1) * (SWAPnn 1 0)) // is idty


// need to expand single-qubit gates into the right places, and multi-qubit gates with swap chains.
let op_expand (op, bits) = 
  let bits = Array.toList bits
  match bits with
    | n::[]   -> OpAtIdx op n
    | srcBits -> 
      let dim = OpDim op
      let dstBits = [0..dim-1] // where the bits need to end up. lst 
      let PreSwaps =  List.map (fun (src, dst) -> SWAPnn src dst) (List.zip srcBits dstBits)
      let PostSwaps = List.map (fun (src, dst) -> SWAPnn src dst) (List.zip dstBits srcBits) // reversed!
      (List.reduce (*) PreSwaps) * (OpAtIdx op 0) * (List.reduce (*) PostSwaps)


let direct_circuit : operator list = List.map op_expand simple_circuit

let result_state = List.fold (*) initalstate (List.rev direct_circuit)
printfn "done"
//printfn "final state:"
//let _ = List.map (fun s -> printfn "%s : %A" (Qlib.StateRepr(s, Nqubits)) (result_state.[s]) ) 
//                 [0..(1<<<Nqubits)-1]

