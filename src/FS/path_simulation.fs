open MathNet.Numerics.LinearAlgebra.Complex
open System.Numerics
open Microsoft.FSharp.Collections
open QLib // cannot use open on static classes, as C# etc

open MyMath
let arith = Arith() // create instance of Arith
let x = arith.Add(10, 20) // call method Add


// Haskell could define a constant in type-land for number of qubits, that this lot could depend upon
//type operator = Matrix // complex due to the typedef
//type state = int // bitstring really

printfn "q is %A" (Qlib.StateRepr)



let Nqubits = 2

let ZeroIm (v : float) : Complex = Complex(v, 0.0)

let H1d : Complex [] = Array.map ZeroIm [| 1.0; 1.0; 1.0; -1.0 |]
let H = new DenseMatrix(2, 2, H1d) / (ZeroIm (sqrt 2.0))
let H' = H.Inverse()

let _ = List.map (fun s -> printfn "%A" (Qlib.StateRepr(s, Nqubits))) [0..4]

printfn "inverse of M is %A" H' // self-inverse as hermitian
