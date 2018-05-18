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
pack_input :: () -> (WorkUnit, Bit, AmpReply, Bit) -> ((), Input)
pack_input _ (wu, wu_enb, amp, amp_enb) =
  let
    out = Input { input_wu = if b2b wu_enb then Just wu else Nothing,
          input_amp = if b2b amp_enb then Just amp else Nothing }
  in
    ((), out)

unpack_output :: () -> Output -> ((), (WorkUnit, Bit, AmpReply, Bit))
unpack_output _ output = ((), (wu, wu_valid, amp, amp_valid))
  where
    (wu, wu_valid) = if isJust (output_workunit output) then 
                       (fromJust (output_workunit output), 1 :: Bit) 
                     else 
                       (emptywu, 0 :: Bit)
    (amp, amp_valid) = if isJust (output_amp output) then (fromJust (output_amp output), 1 :: Bit) else (emptyamp, 0 :: Bit)

{-# ANN pack_input_entity
  (Synthesize
    { t_name     = "pack_input"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortProduct "" [ PortName "inp_wu", PortName "inp_wu_valid", PortName "inp_amp", PortName "inp_amp_valid" ]
      ]
    , t_output  = PortName "input_bundle"
    }) #-}

pack_input_entity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System (WorkUnit, Bit, AmpReply, Bit)
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
                                   PortName "outp_amp_valid" ]
    }) #-}

unpack_output_entity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System Output
  -> Signal System (WorkUnit, Bit, AmpReply, Bit)
unpack_output_entity = exposeClockReset (mealy unpack_output ())
