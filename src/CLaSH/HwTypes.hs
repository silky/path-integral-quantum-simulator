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
data Amplitude = Amplitude { real :: SFixed 2 10,
                             imag :: SFixed 2 10 } deriving (Show, Generic, NFData)

czero = Amplitude { real=0, imag=0 }
sqrt22 = $$(fLit ((sqrt 2.0) / 2.0)) :: SFixed 2 10

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

-- take the bitidxs from state and shift into an otherwise empty state, tested
extractbits :: Vec 2 (Index 16) -> State -> State
extractbits bitidxs state =
  v2bv ( (gather (bv2v state) bitidxs) ++ repeat 0)
  
  -- let
  --   extractbit idx extractidx acc = 
  --     replace idx ((bv2v state) !! (15-extractidx)) acc -- indexing is reversed hype
  -- in
  --   v2bv (ifoldr extractbit (repeat 0) bitidxs)
  
data Gate = H | CNOT deriving Show
data CircuitElem = CircuitElem { cgate :: Gate, cbits :: Vec 2 StateIdx } deriving Show


gateQubitCount :: Gate -> Index 4
gateQubitCount H = 2
gateQubitCount CNOT = 4

-- qubit evaluation

evaluategate :: Gate -> State -> State -> Amplitude
evaluategate H 1 1 = Amplitude { real = -sqrt22, imag = 0 }
evaluategate H _ _ = Amplitude { real =  sqrt22, imag = 0 } -- pattern matching!

-- t-table for CNOT
-- 00 -> 00
-- 01 -> 01
-- 10 -> 11
-- 11 -> 10
evaluategate CNOT 0 0 = Amplitude { real = 1, imag = 0 }
evaluategate CNOT 1 1 = Amplitude { real = 1, imag = 0 }
evaluategate CNOT 2 3 = Amplitude { real = 1, imag = 0 }
evaluategate CNOT 3 2 = Amplitude { real = 1, imag = 0 }
evaluategate CNOT _ _ = Amplitude { real = 0, imag = 0 } -- all other in-out pairs are 0

-- 

-- data processing typedef stuff

data DepStatus = DS_INIT | DS_REQUESTED | DS_COMPLETE | DS_DONT_CARE deriving (Eq, Show, Generic, NFData)
data RetType = RT_LOCAL | RT_UPSTREAM deriving (Eq, Show, Generic, NFData)

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
} deriving (Show, Generic, NFData)

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

type WorkList = Vec 3 WorkUnit -- Circuitlen + 1 (or the depth of this module+1)
type PtrT = Index 10 --Signed 7 -- ptr to a worklist element

data AmpReply = AmpReply { ampreply_target :: State, ampreply_amplitude :: Amplitude,
                           ampreply_dest_idx :: PtrT, ampreply_dest_pred_idx :: PredPtrT } deriving (Show, Generic, NFData)

emptyamp = AmpReply { ampreply_target = 0, ampreply_amplitude = czero,
                      ampreply_dest_idx  =0, ampreply_dest_pred_idx = 0 }

data ModuleState = ModuleState { state_worklist :: WorkList, state_workpos :: PtrT, state_wlist_empty :: Bool } -- signed to allow for -1: invalid signal (sas the wlist is a pow2 no spare signalling value without adding a bit)
data Input = Input { input_wu :: Maybe WorkUnit, input_amp :: Maybe AmpReply, input_depth_split :: CircuitPtr } deriving (Show, Generic, NFData)
data Output = Output { output_workunit :: Maybe WorkUnit, output_amp :: Maybe AmpReply, output_ptr_dbg :: Maybe PtrT } deriving (Show, Generic, NFData)
emptyout = Output { output_workunit = Nothing, output_amp = Nothing, output_ptr_dbg = Nothing }

-- circuit defs

type Circuit = Vec 2 CircuitElem
type CircuitPtr = Index 3 -- Circuitlen + 1 

apply_0 :: Vec 2 StateIdx = 0 :> 0:> Nil
apply_1 :: Vec 2 StateIdx = 1 :> 0:> Nil

h0 = CircuitElem { cgate=H :: Gate, cbits=apply_0 }
circuit :: Circuit = repeat h0
