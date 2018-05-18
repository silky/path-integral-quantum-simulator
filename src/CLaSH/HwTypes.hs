module HwTypes where

import Clash.Prelude
import Data.Maybe

-- Quantum function/typedef dtuff

type State = BitVector 16
data Amplitude = Amplitude { real :: SFixed 2 10,
                             imag :: SFixed 2 10 }

czero = Amplitude { real=0, imag=0 }

booltb :: Bool -> Bit
booltb True = 1
booltb False = 0

substitute :: BitVector 3 -> Vec 3 (Unsigned 4) -> State -> State
substitute bits locs state = -- map replace state but I have a headache
  let
    s' = replaceBit (locs !! 0) (booltb (testBit bits 0))  state
  in let
    s'' = replaceBit (locs !! 1) (booltb (testBit bits 1))  s'
  in let
    s''' = replaceBit (locs !! 2) (booltb (testBit bits 2))  s''
  in
    s'''

stateball :: State -> Vec 3 (Unsigned 4) -> Vec 8 State
stateball state qubits = 
  imap (\i state -> substitute (pack i) qubits state) (repeat state)

data Gate = H | CNOT
data CircuitElem = CircuitElem { cgate :: Gate, cbits :: Vec 3 (Unsigned 4) }
type Circuit = Vec 2 CircuitElem

apply_0 :: Vec 3 (Unsigned 4) = $(listToVecTH [0::Unsigned 4, 0, 0])
apply_1 :: Vec 3 (Unsigned 4) = $(listToVecTH [0::Unsigned 4, 0, 0])

h0 = CircuitElem { cgate=H :: Gate, cbits=apply_0 }
circuit :: Circuit = repeat h0

-- data processing typedef stuff

data DepStatus = DS_INIT | DS_REQUESTED | DS_COMPLETE | DS_DONT_CARE deriving Eq
data RetType = RT_LOCAL | RT_UPSTREAM deriving Eq

data WorkUnit = WorkUnit {
  wu_target :: State,
  wu_inital :: State,
  wu_depth :: BitVector 16,

  wu_deps :: Vec 8 DepStatus,
  wu_predecessors :: Vec 8 State,
  wu_amplitudes :: Vec 8 Amplitude,

  wu_returnloc :: RetType,
  wu_ampreply_dest_idx :: BitVector 6, 
  wu_ampreply_dest_pred_idx :: BitVector 3
}

emptywu = WorkUnit { -- need defaults for non-Maybe (i.e. HW) types
  wu_target = 0,
  wu_inital = 0,
  wu_depth = 0,
  wu_deps = repeat DS_INIT,
  wu_predecessors = repeat 0,
  wu_amplitudes = repeat Amplitude { real=0, imag=0 },
  wu_returnloc = RT_LOCAL,
  wu_ampreply_dest_idx = 0 :: BitVector 6, 
  wu_ampreply_dest_pred_idx = 0
}

type WorkList = Vec 32 WorkUnit
type PtrT = Signed 7
data AmpReply = AmpReply { ampreply_target :: State, ampreply_amplitude :: Amplitude,
                           ampreply_dest_idx :: BitVector 6, ampreply_dest_pred_idx :: State }

emptyamp = AmpReply { ampreply_target = 0, ampreply_amplitude = czero,
                      ampreply_dest_idx  =0, ampreply_dest_pred_idx = 0 }


data ModuleState = ModuleState { state_worklist :: WorkList, state_workpos :: PtrT } -- signed to allow for -1: invalid signal (sas the wlist is a pow2 no spare signalling value without adding a bit)
data Input = Input { input_wu :: Maybe WorkUnit, input_amp :: Maybe AmpReply }
data Output = Output { output_workunit :: Maybe WorkUnit, output_amp :: Maybe AmpReply }
