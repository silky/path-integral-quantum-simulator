module FindAmp where

import Clash.Prelude
import Data.Maybe
import HwTypes
import Debug.Trace
import qualified Data.List as L

type WorkList = Vec 5 WorkUnit -- Circuitlen + 1 (or the depth of this module+1)
data ModuleState n =
  ModuleState 
    { state_worklist :: Vec n WorkUnit, state_workpos :: PtrT
     -- | signed to allow for -1: invalid signal (sas the wlist is a pow2 no spare signalling value without adding a bit)
     , state_wlist_empty :: Bool
    }
    deriving (Generic, NFDataX)


{-# INLINE complete_elem #-}
complete_elem :: Enum i => WorkUnit -> i -> Amplitude -> WorkUnit
complete_elem wu predidx amp =
  wu { wu_amplitudes = replace predidx amp (wu_amplitudes wu),
       wu_deps = replace predidx DS_COMPLETE (wu_deps wu) }

{-# INLINE input_amp_update #-}
input_amp_update :: KnownNat n => Vec n WorkUnit -> Maybe AmpReply -> Vec n WorkUnit
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

{-# INLINE input_wu_update #-}
input_wu_update :: KnownNat n => Vec n WorkUnit -> PtrT -> Bool -> Maybe WorkUnit -> (Vec n WorkUnit, PtrT, Bool)
input_wu_update wlist ptr empty wu =
  if isJust wu then
    let
      newptr = if empty then 0 else (ptr+1)
    in
      (replace newptr (fromJust wu) wlist, newptr, False)
  else
    (wlist, ptr, empty)


{-# INLINE evaluatewu #-}
evaluatewu :: KnownNat n => Vec n WorkUnit -> PtrT -> (Vec n WorkUnit, Maybe AmpReply)
evaluatewu wlist ptr =
  let
    wu = wlist !! ptr
    gatedepth = trace "eval depth" (traceShowId (wu_depth wu)) -- this depth
    targetgatedepth = if (wu_depth wu) > 0 then (wu_depth wu)-1 else 0 -- when adding new wu's, what gate to spec

    targetptr = (wu_ampreply_dest_idx (wlist !! ptr))
    targetpred = (wu_ampreply_dest_pred_idx (wlist !! ptr))
    target_wu = (wlist !! (wu_ampreply_dest_idx (wlist !! ptr)))
  in let
    resamp = if gatedepth == 0 then -- base case
              trace "evaluate complete, base case" (if (wu_target wu) == (wu_inital wu) then Amplitude { real = 1.0, imag = 0.0 } else czero)
            else -- not base case
                let
                  gate = cgate (circuit !! (gatedepth-1))
                  qubits = cbits (circuit !! (gatedepth-1))
                  join = zip3 (wu_deps wu) (wu_predecessors wu) (wu_amplitudes wu)
                in let
                  calc_resamp predecessor predamp = cmul (evaluategate gate (extractbits qubits predecessor) 
                                                                            (extractbits qubits (wu_target wu))) 
                                                         predamp
                in let
                  resamp_l = map (\(deptype, pstate, pamp) -> if deptype == DS_COMPLETE then calc_resamp pstate pamp else czero) join
                in
                  fold cadd (trace "evaluate complete, summing" (traceShowId resamp_l))

  in 
    if ((wu_returnloc wu) == RT_LOCAL) then
      let
        updatedwu = target_wu { wu_amplitudes = replace targetpred resamp (wu_amplitudes target_wu), 
                                wu_deps = replace targetpred DS_COMPLETE (wu_deps target_wu) }
      in
      -- (replace (trace ("sub [" L.++ (show targetptr) L.++ "][" L.++ (show targetpred) L.++ "] with " L.++ (show resamp)) targetptr) updatedwu wlist, Nothing)
      (replace (trace ("sub [" L.++ (show targetptr) L.++ "][" L.++ (show targetpred) L.++ "] with " L.++ (show resamp)) targetptr) updatedwu wlist, Nothing)
    else -- RT_UPSTREAM
      (wlist, Just AmpReply { ampreply_target=(wu_target wu), ampreply_amplitude=resamp, 
                              ampreply_dest_idx= targetptr, ampreply_dest_pred_idx=targetpred })
    

-- This function transitions wu's from DS_INIT to either DS_REQUESTED or DS_DONT_CARE.
{-# INLINE makerequests #-}
makerequests :: KnownNat n => CircuitPtr -> Vec n WorkUnit -> PtrT -> (Vec n WorkUnit, PtrT, Maybe WorkUnit)
makerequests depthsplit wlist ptr = 
  let
    wu = wlist !! ptr
  in let
    -- there is at last one INIT state in this, as requestsmade != True
    idxtoreq :: PredPtrT = fromJust (elemIndex DS_INIT (wu_deps wu))
    -- (ifoldr (\idx val acc -> if val == DS_INIT then idx else acc) 0 (wu_deps wu))
    destdepth =  (wu_depth wu) - 1
    -- qubitcount =  -- lean on lazy eval here
  in let
    newtarget = (wu_predecessors wu) !! idxtoreq
  in
    if (wu_depth wu) == 0 then -- this is the base case, we don't have any deps. set to DONT_CARE so we can eval, destdepth would be -1
      let
        wlist' = replace ptr (wu { wu_deps = repeat DS_DONT_CARE }) wlist
      in
        (wlist', ptr, Nothing)

    else if idxtoreq < gateQubitCount (cgate ( circuit !! destdepth )) then -- split point, > add to us, and we need it. only if we heed this evaluation
      let
        newwu = emptywu { wu_target=trace ("adding new wu targetting " L.++ (show newtarget)) newtarget,
                          wu_inital=(wu_inital wu),
                          wu_depth=destdepth,
                          wu_ampreply_dest_pred_idx=idxtoreq }
      in let
        (wlist', remote_req, ptr') = if destdepth >= depthsplit then 
                                (replace (ptr+1) (newwu { 
                                                    wu_ampreply_dest_idx=ptr,
                                                    wu_returnloc=RT_LOCAL 
                                                  }) wlist,
                                 Nothing, ptr+1)
                              else
                                (wlist, Just (newwu { 
                                                wu_ampreply_dest_idx=ptr,
                                                wu_returnloc=RT_UPSTREAM 
                                              }), 
                                 ptr) -- make a remote request!
      in let
        wlist'' = replace ptr (wu { wu_deps = replace idxtoreq DS_REQUESTED (wu_deps wu) }) wlist' -- mark as requested
      in
        (wlist'', ptr', remote_req)

    else if idxtoreq >= gateQubitCount (cgate (circuit !! destdepth)) then -- we don't need this pred state, so set don't care
      let
        wlist' = replace ptr (wu { wu_deps = replace idxtoreq DS_DONT_CARE (wu_deps wu) }) wlist
      in
        (wlist', ptr, Nothing)

    else --SHOULD NOT BE HERE?
      (wlist, ptr, Nothing)

{-# INLINE canevaluate #-}
canevaluate :: WorkUnit -> Bool
canevaluate wu = foldl (\acc v -> if (v == DS_COMPLETE || v == DS_DONT_CARE) then acc else False) True (wu_deps wu)

{-# INLINE requestsmade #-}
requestsmade :: WorkUnit -> Bool
requestsmade wu = foldl (\acc v -> if not (v == DS_INIT) then acc else False) True (wu_deps wu)

-- this should try to evaluate the last element on the worklist.
-- if successful, should push the pointer up by 1 and write the value to the right place
-- else we try and make a "recursive" request, or wait.
-- we know it's not empty
{-# INLINE tryevaluate #-}
tryevaluate :: KnownNat n => CircuitPtr -> Vec n WorkUnit -> PtrT -> (Vec n WorkUnit, PtrT, Bool, Output)
tryevaluate depthsplitpt wlist ptr =
  if canevaluate (wlist !! ptr) then
    let
      (next_ptr, next_empty) = if ptr > 0 then (ptr-1, False) else (0, True)
      (wlist', reply) = evaluatewu wlist ptr -- replaces the relevent higher element
    in
      -- no requests need to be made
      (wlist', next_ptr, next_empty, emptyout { output_amp = reply })
  
  else if not (wu_preds_eval (wlist !! ptr)) then -- if this depth != 0 then we need to add pred states. can't make it empty, as we are just working on current.
    let
      wu = (wlist !! ptr)
    in let
      wlist' = replace 
                ptr 
                (wu { wu_preds_eval = True, 
                      wu_predecessors = if (wu_depth wu) == 0 then (wu_predecessors wu)
                                        else 
                                          let
                                            gate = cgate (circuit !! ((wu_depth wu)-1) )
                                            qubits = cbits (circuit !! ((wu_depth wu)-1) )
                                          in
                                            stateball (wu_target wu) (arity gate) qubits} ) 
                wlist
    in
      (wlist', ptr, False, emptyout)
      
  else if not (requestsmade (wlist !! ptr)) then
    -- we can only make one request per cycle, so this will loop for a while.
    let
      (wlist', ptr', output_wu) = makerequests depthsplitpt wlist ptr
    in
      (wlist', ptr', False, emptyout { output_workunit = output_wu }) -- makerequests can't remove wu's

  else -- cannot need to wait for external modules to add data to the final wu so we can work on it
    (wlist, ptr, False, emptyout) -- we know the wlist is not empty


findamp_mealy_N :: KnownNat n => ModuleState n -> Input -> (ModuleState n, Output)
findamp_mealy_N state input = 
  let
    worklist' = if not (state_wlist_empty state) then
       input_amp_update (state_worklist state) (input_amp input)
    else
      (state_worklist state) -- we can't update any states if it's empty

  in let
    (worklist'', ptr'', empty'') = input_wu_update worklist' (state_workpos state) (state_wlist_empty state) (input_wu input)

  in let
    (worklist''', ptr''', empty''', output) = if not empty'' then -- skip if no work to do!
      tryevaluate (input_depth_split input) worklist'' ptr'' -- this sould be able to set empty as well
    else
      (worklist'', ptr'', empty'', emptyout)

  in
    (ModuleState { state_worklist = worklist''', state_workpos = ptr''', state_wlist_empty = empty''' }, output { output_ptr_dbg = if not empty''' then Just ptr''' else Nothing })

-- findamp_mealy = findamp_mealy_N d5
initalstate :: ModuleState 5 = ModuleState { state_worklist = repeat emptywu, state_workpos = 0, state_wlist_empty = True }

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
  :: Clock System
  -> Reset System
  -> Signal System Input
  -> Signal System Output
topEntity clk rst =
  exposeClockResetEnable (mealy findamp_mealy_N initalstate) clk rst en
  where
    en = enableGen


-- hardwaretranslate blocks let you go from Maybe x to (Bit, x)
-- hardwareTranslate :: (Bool, Maybe Output) -> (Bit, Bit, BitVector 64)
-- hardwareTranslate (halted, output) = (haltedBit, outputActive, outputValue)
--     where
--     haltedBit = if halted then 1 else 0
--     (outputActive, outputValue) = case output of
--         Nothing -> (0, 0)
--         Just (Output val) -> (1, pack val)
