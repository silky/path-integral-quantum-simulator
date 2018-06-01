"""With clash we can create parameterised hardware, but there is no way to expose this a a verilog module parameter.
Additionally, I don't know of a way to generate the annotations that cause CLaSH to genrate a module 
from within haskell, so we just template out some hs source.
"""

hdr = """module FindAmpParams where

import Clash.Prelude
import HwTypes
import FindAmp

-- GENERATED CODE
-- creates findamp modules manually parameterised by the 
"""

templ = """initalstate{0} :: ModuleState {0} = ModuleState {{ state_worklist = repeat emptywu, state_workpos = 0, state_wlist_empty = True }}

{{-# ANN topEntity{0}
  (Synthesize
    {{ t_name     = "findamp{0}"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortName "input_bundle"
      ]
    , t_output  = PortName "output_bundle"
    }}) #-}}

topEntity{0}  
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System Input
  -> Signal System Output
topEntity{0} = exposeClockReset (mealy findamp_mealy_N initalstate{0})
"""

output = "\n".join([hdr] + [templ.format(n) for n in range(2, 31)])
print(output)
