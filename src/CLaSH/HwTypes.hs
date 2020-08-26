{-# LANGUAGE DeriveGeneric, DeriveAnyClass #-}

module HwTypes where

import Clash.Prelude
import Data.Maybe
import GHC.Generics (Generic)
import Debug.Trace
import GHC.TypeNats
import Control.DeepSeq
-- Quantum function/typedef dtuff

type State = BitVector 16
type StateIdx = Index 16
type NumT = SFixed 3 10
data Amplitude = Amplitude { real :: NumT,
                             imag :: NumT } deriving (Show, Generic, NFDataX)

sqrt22 = $$(fLit ((sqrt 2.0) / 2.0)) :: NumT
zero = $$(fLit 0.0) :: NumT
czero = Amplitude { real=zero, imag=zero }

cmul :: Amplitude -> Amplitude -> Amplitude
{-# INLINE cmul #-}
cmul a b = trace "mult " (traceShow (a, b) (Amplitude{
            real = (real a) * (real b) - (imag a) * (imag b),
            imag = (real a) * (imag b) - (imag a) * (real b)
          }))

cadd a b = Amplitude{
            real = (real a) + (real b),
            imag = (imag a) + (imag b)
          }


booltb :: Bool -> Bit
booltb True = 1
booltb False = 0

-- substitute1 :: BitVector 1 -> StateIdx -> State -> State
-- substitute1 bits loc state = -- map replace state but I have a headache
--     replaceBit loc (booltb (testBit bits 0)) state

substitute1 :: BitVector 1 -> Vec 1 StateIdx -> State -> State
substitute1 bits locs state = -- map replace state but I have a headache
  replaceBit (locs !! 0) (booltb (testBit bits 0))  state

substitute2 :: BitVector 2 -> Vec 2 StateIdx -> State -> State
substitute2 bits locs state = -- map replace state but I have a headache
  let
    s' = replaceBit (locs !! 0) (booltb (testBit bits 0))  state
  in let
    s'' = replaceBit (locs !! 1) (booltb (testBit bits 1))  s'
  in
    s''

-- substitute3 :: BitVector 3 -> Vec 3 StateIdx -> State -> State
-- substitute3 bits locs state = -- map replace state but I have a headache
--   let
--     s' = replaceBit (locs !! 0) (booltb (testBit bits 0))  state
--   in let
--     s'' = replaceBit (locs !! 1) (booltb (testBit bits 1))  s'
--   in let
--     s''' = replaceBit (locs !! 2) (booltb (testBit bits 2))  s''
--   in
--     s'''

stateball1 :: State -> Vec 1 StateIdx -> Vec 2 State
stateball1 state qubits = 
  imap (\i state -> substitute1 (pack i) qubits state) (repeat state)

stateball2 :: State -> Vec 2 StateIdx -> Vec 4 State
stateball2 state qubits = 
  imap (\i state -> substitute2 (pack i) qubits state) (repeat state)

-- stateball3 :: State -> Vec 3 StateIdx -> Vec 8 State
-- stateball3 state qubits = 
--   imap (\i state -> substitute3 (pack i) qubits state) (repeat state)

stateball :: State -> Unsigned 2 -> Vec 2 StateIdx -> Vec 4 State
stateball state n qubits =
  if n == 1 then 
    (stateball1 state (take (SNat :: SNat 1) qubits)) ++ (repeat 0)
  else
    (stateball2 state (take (SNat :: SNat 2) qubits))
  -- else
  --   stateball3 state (take (SNat :: SNat 3) qubits)

arity :: Gate -> Unsigned 2
arity H = 1
arity CNOT = 2
arity I = 1

-- take the bitidxs from state and shift into an otherwise empty state, tested
extractbits :: Vec 2 (Index 16) -> State -> State
extractbits bitidxs state =
  v2bv (reverse ((gather (reverse (bv2v state)) bitidxs) ++ repeat 0))
  
data Gate = H | CNOT | I deriving Show
data CircuitElem = CircuitElem { cgate :: Gate, cbits :: Vec 2 StateIdx } deriving Show

-- state count. oops
gateQubitCount :: Gate -> Index 4
gateQubitCount H = 2
gateQubitCount I = 2
gateQubitCount CNOT = 4

-- qubit evaluation
evaluategate :: Gate -> State -> State -> Amplitude
evaluategate H i o = evaluateH (slice d0 d0 i) (slice d0 d0 o)
evaluategate I i o = evaluateI (slice d0 d0 i) (slice d0 d0 o)
evaluategate CNOT i o = evaluateCNOT (slice d1 d0 i) (slice d1 d0 o)


-- evaluategate' :: Gate -> State -> State -> Amplitude
evaluateH :: BitVector 1 -> BitVector 1 -> Amplitude
evaluateH 1 1 = Amplitude { real = -sqrt22, imag = zero }
evaluateH _ _ = Amplitude { real =  sqrt22, imag = zero } -- pattern matching!

evaluateI :: BitVector 1 -> BitVector 1 -> Amplitude
evaluateI i o = if i == o
                   then czero { real = 1 }
                   else czero

-- t-table for CNOT
-- 00 -> 00
-- 01 -> 01
-- 10 -> 11
-- 11 -> 10
evaluateCNOT :: BitVector 2 -> BitVector 2 -> Amplitude
evaluateCNOT 0 0 = Amplitude { real = 1, imag = zero }
evaluateCNOT 1 1 = Amplitude { real = 1, imag = zero }
evaluateCNOT 2 3 = Amplitude { real = 1, imag = zero }
evaluateCNOT 3 2 = Amplitude { real = 1, imag = zero }
evaluateCNOT _ _ = Amplitude { real = zero, imag = zero } -- all other in-out pairs are 0

-- 

-- data processing typedef stuff

data DepStatus = DS_INIT | DS_REQUESTED | DS_COMPLETE | DS_DONT_CARE deriving (Eq, Show, Generic, NFDataX)
data RetType = RT_LOCAL | RT_UPSTREAM deriving (Eq, Show, Generic, NFDataX)

type PredPtrT = Index 4

data WorkUnit = WorkUnit {
  wu_target :: State,
  wu_inital :: State,
  wu_depth :: CircuitPtr,

  wu_deps :: Vec 4 DepStatus,
  wu_preds_eval :: Bool,
  wu_predecessors :: Vec 4 State,
  wu_amplitudes :: Vec 4 Amplitude,

  wu_returnloc :: RetType,
  wu_ampreply_dest_idx :: PtrT, 
  wu_ampreply_dest_pred_idx :: PredPtrT
} deriving (Show, Generic, NFDataX)

emptywu = WorkUnit { -- need defaults for non-Maybe (i.e. HW) types
  wu_target = 0,
  wu_inital = 0,
  wu_depth = 0,
  wu_deps = repeat DS_INIT,
  wu_preds_eval = False,
  wu_predecessors = repeat 0,
  wu_amplitudes = repeat Amplitude { real=0, imag=0 },
  wu_returnloc = RT_LOCAL,
  wu_ampreply_dest_idx = 0, 
  wu_ampreply_dest_pred_idx = 0
}

-- type WorkList = Vec 5 WorkUnit -- Circuitlen + 1 (or the depth of this module+1)
-- type PtrT = Index 5 --Signed 7 -- ptr to a worklist element
-- data ModuleState = ModuleState { state_worklist :: WorkList, state_workpos :: PtrT, state_wlist_empty :: Bool } -- signed to allow for -1: invalid signal (sas the wlist is a pow2 no spare signalling value without adding a bit)

type PtrT = Index 33 --Signed 7 -- ptr to a worklist element. we need this globaly as it goes in the workunit request

data AmpReply = AmpReply { ampreply_target :: State, ampreply_amplitude :: Amplitude,
                           ampreply_dest_idx :: PtrT, ampreply_dest_pred_idx :: PredPtrT } deriving (Show, Generic, NFDataX)

emptyamp = AmpReply { ampreply_target = 0, ampreply_amplitude = czero,
                      ampreply_dest_idx  =0, ampreply_dest_pred_idx = 0 }

data Input = Input { input_wu :: Maybe WorkUnit, input_amp :: Maybe AmpReply, input_depth_split :: CircuitPtr } deriving (Show, Generic, NFDataX)
data Output = Output { output_workunit :: Maybe WorkUnit, output_amp :: Maybe AmpReply, output_ptr_dbg :: Maybe PtrT } deriving (Show, Generic, NFDataX)
emptyout = Output { output_workunit = Nothing, output_amp = Nothing, output_ptr_dbg = Nothing }

-- circuit defs

type Circuit = Vec 4 CircuitElem
type CircuitPtr = Index 5 -- Circuitlen + 1 -- verilator does not like large indices!

apply_0 :: Vec 2 StateIdx = 0 :> 0:> Nil
apply_1 :: Vec 2 StateIdx = 1 :> 0:> Nil

h0 = CircuitElem { cgate=H :: Gate, cbits=apply_0 }
i0 = CircuitElem { cgate=I :: Gate, cbits=apply_0 }

circuit :: Circuit = repeat h0
