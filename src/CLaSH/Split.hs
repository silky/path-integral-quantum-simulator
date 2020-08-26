-- for making connections, we need to split and rejoin the Input and Output signals. 
-- Does not need to be fundemental types

module Split where

import Clash.Prelude
import Data.Maybe
import HwTypes


join_input :: () -> (Maybe WorkUnit, Maybe AmpReply, CircuitPtr) -> ((), Input)
join_input _ (input_wu, input_amp, input_depth_split) =
  ((), Input { input_wu=input_wu, input_amp=input_amp, input_depth_split=input_depth_split })

split_input :: () -> Input -> ((), (Maybe WorkUnit, Maybe AmpReply, CircuitPtr))
split_input _ input =
  ((), (input_wu input,  input_amp input, input_depth_split input))

split_output :: () -> Output -> ((), (Maybe WorkUnit, Maybe AmpReply, Maybe PtrT))
split_output _ output = ((), (output_workunit output, output_amp output, output_ptr_dbg output))

join_output :: () -> (Maybe WorkUnit, Maybe AmpReply, Maybe PtrT) -> ((), Output)
join_output _ (wu, amp, ptr) = ((), Output { output_workunit=wu, output_amp=amp, output_ptr_dbg=ptr })

{-# ANN join_input_entity
  (Synthesize
    { t_name     = "join_input"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortProduct "" [PortName "wu", PortName "amp", PortName "depthlim" ]
      ]
    , t_output  = PortName "input_bundle"
    }) #-}
join_input_entity   
  :: Clock System 
  -> Reset System 
  -> Signal System (Maybe WorkUnit, Maybe AmpReply, CircuitPtr)
  -> Signal System Input
join_input_entity clk rst = exposeClockResetEnable (mealy join_input ()) clk rst enableGen


{-# ANN split_input_entity
  (Synthesize
    { t_name     = "split_input"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortName "input_bundle"
      ]
    , t_output = PortProduct "" [PortName "wu", PortName "amp", PortName "depthlim"]
    }) #-}
split_input_entity   
  :: Clock System 
  -> Reset System 
  -> Signal System Input
  -> Signal System (Maybe WorkUnit, Maybe AmpReply, CircuitPtr)
split_input_entity clk rst = exposeClockResetEnable (mealy split_input ()) clk rst enableGen


{-# ANN split_output_entity
  (Synthesize
    { t_name     = "split_output"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortName "output_bundle"
      ]
    , t_output = PortProduct "" [PortName "wu", PortName "amp", PortName "pos" ]
  }) #-}
split_output_entity   
  :: Clock System 
  -> Reset System 
  -> Signal System Output
  -> Signal System (Maybe WorkUnit, Maybe AmpReply, Maybe PtrT)
split_output_entity clk rst = exposeClockResetEnable (mealy split_output ()) clk rst enableGen

{-# ANN join_output_entity
  (Synthesize
    { t_name     = "join_output"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortProduct "" [PortName "wu", PortName "amp", PortName "pos" ]
      ]
    , t_output  = PortName "output_bundle"
  }) #-}
join_output_entity   
  :: Clock System 
  -> Reset System 
  -> Signal System (Maybe WorkUnit, Maybe AmpReply, Maybe PtrT)
  -> Signal System Output
join_output_entity clk rst = exposeClockResetEnable (mealy join_output ()) clk rst enableGen

