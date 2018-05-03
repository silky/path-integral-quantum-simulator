module Driver where

import Clash.Prelude

{-
We need to explore the possible state space, with some target state.

In the future we might delegate more state evaluations to other modules. The way this should work is to have a work request queue, that adds evalations onto an internal stack.

so - module that knowing the circuit, and given inital and target states, evaluates the amplitude of that state.

-}

data Amplitude = Amplitude { real :: SFixed 2 6,
                             imag :: SFixed 2 6 }

cmul :: Amplitude -> Amplitude -> Amplitude
{-# INLINE cmul #-}
cmul a b = Amplitude{
            real = (real a) * (real b) - (imag a) * (imag b),
            imag = (real a) * (imag b) - (imag a) * (real b)
          }

multiplier_mealy :: () -> (Amplitude, Amplitude) -> ((), Amplitude)
multiplier_mealy _ (a, b) = ((), cmul a b)

topEntity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System (Amplitude, Amplitude) 
  -> Signal System Amplitude
topEntity = exposeClockReset (mealy multiplier_mealy ())
