open Demo.qdefs
open MathNet.Numerics.LinearAlgebra.Complex
open System.Numerics
open Microsoft.FSharp.Collections
open QLib // cannot use open on static classes, as C# etc
open System.Collections.Generic

type state = int // bitstring really

// show the mapping from ints to basis kets
// let _ = List.map (fun s -> printfn "%s" (Qlib.StateRepr(s, Nqubits))) [0..(1<<<Nqubits)-1]

// from last op in the circuit to first, reversed to layout on page
let insertBits (orignal : state) qubits (insert : state) : state = Qlib.insertBit(orignal, qubits, insert)

// takes a state and a gate, and retuns a list of states with the amplitude of observation (classically)
let applyGate (op : operator) (bits : int []) (s : state) : (state * Complex) list =
  let input = Qlib.partial_trace(s, bits)
  let resultant = input * op // resultant is vector in the subspace
  // let resultant_amplitudes = List.map (fun i -> resultant.[i]) [0..1<<<bits.Length-1]
  let resultant_amplitudes = Seq.toList resultant
  // printfn "resamp %A" resultant_amplitudes
  let resultant_states : state list = List.map (insertBits s bits) [0..(1<<<bits.Length)-1]
  List.zip resultant_states resultant_amplitudes

let cache = new Dictionary<_, _>()

// This does the real meat of the calculation.
let rec calcAmp (remaining_circuit : circuit) (initalstate : state) (currstate : state) : Complex =
  //printfn "    evaluating for state %A with %A remaining" (Qlib.StateRepr(currstate, Nqubits)) (remaining_circuit.Length)
  
  
  match remaining_circuit with
    | [] -> if currstate = initalstate // rec. base case
              then ZeroIm 1.0
              else ZeroIm 0.0
    | (op, bits)::tt  ->
          let succ, v = cache.TryGetValue( (remaining_circuit, initalstate, currstate) )
          if succ then             
            v 
          else
            // gets the ball of states that differ in the input to this gate
            let predecessors : state list = Seq.toList
                                              (Qlib.possiblePredecessorStates(
                                                  currstate, 
                                                  bits)
                                              )
            // each predecessor state can result in a range of further states. They are returned as a list of state*amplitude pairs, and the amplitude depends on the pred state we are calculating for
            let resultant_state_amplitudes : (state * Complex) list list = List.map (applyGate op bits) predecessors
            
            let predecessor_amplitudes : Complex list = List.map (calcAmp tt initalstate) predecessors
            
            // let _ = printfn "        Possible pred states (and amp): %A" (List.map (fun (s, a : Complex) -> (Qlib.StateRepr(s, Nqubits), (a.Real))) (List.zip predecessors predecessor_amplitudes))
            
            // printfn "        Resultant state vector \n%A " resultant_state_amplitudes
            
            let apply_pred_factor (factor : Complex) (states : (state * Complex) list) : (state * Complex) list = 
              List.map (fun (s, a) -> (s, a*factor)) states
            
            // we need to scale the possible observed basis states by the amplitude of the state that lead to it
            let resultant_state_amplitudes_scaled : (state * Complex) list list = 
              List.map (fun (fact, states) -> apply_pred_factor fact states) (List.zip predecessor_amplitudes resultant_state_amplitudes)
            
            // printfn "        scaled resultant amplitudes \n%A" resultant_state_amplitudes_scaled
            
            // pick out the state we curenttly care about.
            let resultant_state_amplitude = List.map (List.filter (fun (s, _) -> s = currstate)) resultant_state_amplitudes_scaled
            
            let amp = List.fold (fun acc (_,a) -> a+acc) (ZeroIm 0.0) (List.concat resultant_state_amplitude)
            // printfn "resultant amplitude for %A:%A" currstate amp
            cache.Add((remaining_circuit, initalstate, currstate), amp)
            amp

let inital_state : state = 0
//printfn "inital state:"
//let _ = List.map (fun s -> printfn "%s : %A" (Qlib.StateRepr(s, Nqubits)) (if s = inital_state then ZeroImI 1 else ZeroImI 0)) 
//                 [0..(1<<<Nqubits)-1]


printfn "final state:"
//let _ = List.map (fun s -> printfn "%s : %A" (Qlib.StateRepr(s, Nqubits)) (calcAmp simple_circuit inital_state s) ) 
//                 [0..(1<<<Nqubits)-1]

let _ = List.map (fun s -> (calcAmp simple_circuit inital_state s)) [0..(1<<<Nqubits)-1]
printfn "done"

//let _ = List.map (fun s -> printfn "%s : %A" (Qlib.StateRepr(s, Nqubits)) (calcAmp simple_circuit inital_state s) ) 
//                 (1 :: [])


