module Interfaces where

import Clash.Prelude
import Data.Maybe
import HwTypes

-- data Input = Input { input_wu :: Maybe WorkUnit, input_amp :: Maybe AmpReply }
-- data InputUnp = InputUnp { inp_up_wu :: WorkUnit, inp_up_val :: Bit,
--                            inp_up_amp :: AmpReply, inp_up_val :: bit  }

b2b :: Bit -> Bool
b2b 0 = False
b2b 1 = True


-- the impl of maybe is an additional value added onto the subtype, Nothing. This is rendered as a additional bit
-- in the HW representantation, but this is not a fixed behaviour so use this packing module to integrate valid
-- signals.
-- data WorkUnit = WorkUnit {
--   wu_target :: State, -- BitVector 16
--   wu_inital :: State,
--   wu_depth :: CircuitPtr,
-- 
--   wu_deps :: Vec 8 DepStatus,
--   wu_preds_eval :: Bool,
--   wu_predecessors :: Vec 8 State,
--   wu_amplitudes :: Vec 8 Amplitude,
-- 
--   wu_returnloc :: RetType,
--   wu_ampreply_dest_idx :: PtrT, 
--   wu_ampreply_dest_pred_idx :: PredPtrT
-- } deriving (Show, Generic, NFData)

pack_input :: () -> (CircuitPtr, (State, State, CircuitPtr), Bit, AmpReply, Bit) -> ((), Input)
pack_input _ (splitdepth, (target, inital, depth), wu_enb, amp, amp_enb) =
  let
    wu = if b2b wu_enb then Just emptywu { wu_target=target, wu_inital=inital, wu_depth=depth, wu_returnloc=RT_UPSTREAM }
         else Nothing
  in let
    out = Input { input_wu = wu,
                  input_amp = if b2b amp_enb then Just amp else Nothing, input_depth_split = splitdepth }
  in
    ((), out)

unpack_output :: () -> Output -> ((), (WorkUnit, Bit, AmpReply, Bit, Signed 32))
unpack_output _ output = ((), (wu, wu_valid, amp, amp_valid, ptrloc))
  where
    (wu, wu_valid) = if isJust (output_workunit output) then 
                       (fromJust (output_workunit output), 1 :: Bit) 
                     else 
                       (emptywu, 0 :: Bit)
    (amp, amp_valid) = if isJust (output_amp output) then (fromJust (output_amp output), 1 :: Bit) else (emptyamp, 0 :: Bit)
    ptrloc = if isJust (output_ptr_dbg output) then unpack (resize (pack (fromJust (output_ptr_dbg output)))) else -1

{-# ANN pack_input_entity
  (Synthesize
    { t_name     = "pack_input"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortProduct "" [PortName "inp_splitdepth", PortProduct "" [PortName "target", PortName "inital", PortName "depth"], PortName "inp_wu_valid", PortName "inp_amp", PortName "inp_amp_valid" ]
      ]
    , t_output  = PortName "input_bundle"
    }) #-}

pack_input_entity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System (CircuitPtr, (State, State, CircuitPtr), Bit, AmpReply, Bit)
  -> Signal System Input
pack_input_entity = exposeClockReset (mealy pack_input ())



{-# ANN unpack_output_entity
  (Synthesize
    { t_name     = "unpack_output"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortName "output_bundle"
      ]
    , t_output  = PortProduct "" [ PortName "outp_wu", 
                                   PortName "outp_wu_valid", 
                                   PortName "outp_amp", 
                                   PortName "outp_amp_valid",
                                   PortName "ptrloc" ]
    }) #-}

unpack_output_entity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System Output
  -> Signal System (WorkUnit, Bit, AmpReply, Bit, Signed 32)
unpack_output_entity = exposeClockReset (mealy unpack_output ())

-- data Amplitude = Amplitude { real :: SFixed 2 10,
--                              imag :: SFixed 2 10 } deriving (Show, Generic, NFData)
-- data AmpReply = AmpReply { ampreply_target :: State, ampreply_amplitude :: Amplitude,
--                            ampreply_dest_idx :: PtrT, ampreply_dest_pred_idx :: PredPtrT } deriving (Show, Generic, NFData)


unpack_ampreply :: () -> AmpReply -> ((), (Signed 12, Signed 12, State, PtrT, PredPtrT))
unpack_ampreply _ rply = ((), (realpt, imagpt, target, dstidx, destpredidx))
  where
    realpt = unSF (real (ampreply_amplitude rply))
    imagpt = unSF (imag (ampreply_amplitude rply))
    target = ampreply_target rply
    dstidx = ampreply_dest_idx rply
    destpredidx = ampreply_dest_pred_idx rply

{-# ANN unpack_ampreply_entity
  (Synthesize
    { t_name     = "unpack_ampreply"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortName "ampreply"
      ]
    , t_output  = PortProduct "" [ PortName "realpt", -- real is a verilog keyword
                                   PortName "imagpt", 
                                   PortName "targetstate", 
                                   PortName "destidx",
                                   PortName "destpredidx" ]
    }) #-}

unpack_ampreply_entity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System AmpReply
  -> Signal System (Signed 12, Signed 12, State, PtrT, PredPtrT)
unpack_ampreply_entity = exposeClockReset (mealy unpack_ampreply ())

------- TESTBENCH GENERATION MODULES

