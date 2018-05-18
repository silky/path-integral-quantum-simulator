module FindAmp where

import Clash.Prelude
import Data.Maybe
import HwTypes

complete_elem :: Enum i => WorkUnit -> i -> Amplitude -> WorkUnit
complete_elem wu predidx amp =
  wu { wu_amplitudes = replace predidx amp (wu_amplitudes wu),
       wu_deps = replace predidx DS_COMPLETE (wu_deps wu) }

input_amp_update :: WorkList -> Maybe AmpReply -> WorkList
input_amp_update wlist update = 
  if isJust update then 
    let
      idx = ampreply_dest_idx (fromJust update)
      pred_idx = ampreply_dest_pred_idx (fromJust update)
      newamp = ampreply_amplitude (fromJust update)
    in let
      pwu = (wlist !! idx)
    in let
      prevamps = wu_amplitudes pwu
      prevdeps = wu_deps pwu
    in -- replace the amplitude in the element of the work list specified with the given value
      replace idx (complete_elem pwu pred_idx newamp) wlist
  else -- no update to make.
    wlist

input_wu_update :: WorkList -> PtrT -> Maybe WorkUnit -> (WorkList, PtrT)
input_wu_update wlist ptr wu =
  if isJust wu then
    (replace (ptr+1) (fromJust wu) wlist, ptr+1)
  else
    (wlist, ptr)

evaluatewu :: WorkList -> PtrT -> (WorkList, Maybe AmpReply)
evaluatewu wlist ptr =
  let
    wu = wlist !! ptr
  in let
    gate = circuit !! (wu_depth wu)
  in
    (wlist, Nothing)
    
makerequests :: WorkList -> PtrT -> (WorkList, PtrT, Maybe WorkUnit)
makerequests wlist ptr = (wlist, ptr, Nothing)

canevaluate :: WorkUnit -> Bool
canevaluate wu = foldl (\acc v -> if (v == DS_COMPLETE || v == DS_DONT_CARE) then acc else False) True (wu_deps wu)

requestsmade :: WorkUnit -> Bool
requestsmade wu = foldl (\acc v -> if not (v == DS_INIT) then acc else False) True (wu_deps wu)

-- this should try to evaluate the last element on the worklist.
-- if successful, should push the pointer up by 1 and write the value to the right place
-- else we try and make a "recursive" request, or wait.
tryevaluate :: WorkList -> PtrT -> (WorkList, PtrT, Output)
tryevaluate wlist ptr =
  if canevaluate (wlist !! ptr) then
    let
      ptr' = ptr-1
      (wlist', reply) = evaluatewu wlist ptr -- replaces the relevent higher element
    in
      -- no requests need to be made
      (wlist', ptr', Output { output_workunit = Nothing, output_amp = reply })
      
  else if not (requestsmade (wlist !! ptr)) then
    -- we can only make one request per cycle, so this will loop for a while.
    let
      (wlist', ptr', output_wu) = makerequests wlist ptr
    in
      (wlist', ptr', Output { output_workunit = output_wu, output_amp =Nothing })

  else -- cannot need to wait for external modules to add data to the final wu so we can work on it
    (wlist, ptr, Output { output_workunit = Nothing, output_amp = Nothing })


findamp_mealy :: ModuleState -> Input -> (ModuleState, Output)
findamp_mealy state input = let
    worklist' = input_amp_update (state_worklist state) (input_amp input)
  in let
    (worklist'', ptr'') = input_wu_update worklist' (state_workpos state) (input_wu input)
  in let
    (worklist''', ptr''', output) = tryevaluate worklist'' ptr''
  in
    (ModuleState { state_worklist = worklist''', state_workpos = ptr''' }, output)


initalstate = ModuleState { state_worklist = repeat emptywu, state_workpos = 0 }

{-# ANN topEntity
  (Synthesize
    { t_name     = "findamp"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortName "input_bundle"
      ]
    , t_output  = PortName "output_bundle"
    }) #-}

topEntity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System Input
  -> Signal System Output
topEntity = exposeClockReset (mealy findamp_mealy initalstate)


-- hardwaretranslate blocks let you go from Maybe x to (Bit, x)
-- hardwareTranslate :: (Bool, Maybe Output) -> (Bit, Bit, BitVector 64)
-- hardwareTranslate (halted, output) = (haltedBit, outputActive, outputValue)
--     where
--     haltedBit = if halted then 1 else 0
--     (outputActive, outputValue) = case output of
--         Nothing -> (0, 0)
--         Just (Output val) -> (1, pack val)
