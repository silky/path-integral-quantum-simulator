-- NOTE(noon): I'm not sure what's up with this file; it seems unused as it's
-- certainly not close to compiling.
module Driver where

import Clash.Prelude

data Op = H | CNOT deriving (Enum)
data CircuitElem = (Op, Maybe QubitId, Maybe QubitId, Maybe QubitId) -- max 3 qubit gate here and in WorkSpec
data Circuit = Vec 2 CircuitElem

data QubitId = BitVector 32 -- uint basically but can be reduced. -- a basis state of the system.
-- data Amplitude = BitVector 64 -- pair of 32bit floats, but we should not rely upon this. opaque data type.
data Amplitude = Amplitude { real :: SFixed 2 14,
                             imag :: SFixed 2 14 }

data StateIdentifier = StateIdentifier { qubit :: QubitId,
                                         depth :: BitVector 16 }

-- we need to be able to identify the WorkSpec and amplitude that this request belongs to.
data RID = RID { ridwspec :: BitVector 4, -- as 16 length WorkList, needs to go up in proportion.
                 ridamp :: BitVector 3 -- 8 possible amplitudes, as 3-qubit max. 
              }
ridblank = { ridwspec = 0, ridamp = 0 }

-- work unit added by external device that we should evaluate.
-- vec 8 is for a max of a 3-qubit gate. 16 for 4 etc.
data WorkSpec = WorkSpec { wstarget :: StateIdentifier,
                           wspreds :: Maybe (Vec 8 StateIdentifier), -- might not have evalauated prior states yet
                           wsamps :: Vec 8 (Maybe Amplitude), -- the maybe evalauted predicessor states to this state.
                           wsdestination :: RID -- who wants this target state
                          }
workspecdefault = { wstarget = 0, wspreds = Nothing, wsamps = replicate 8 Nothing, wsdestination = ridblank }

data WorkList = Vec 16 (Maybe WorkSpec) -- buffer of outstanding requests, starts empty.

data WSRequest = WSRequest { reqtarget :: StateIdentifier, reqID :: RID }
data WSReply = WSReply { rpyamp :: Amplitude, rpyID :: RID }

data AddReq = (Amplitude, Amplitude)
data AddRpy = Amplitude
data OpReq  = OpReq { opReqinput :: QubitId, opRqtarget :: QubitId, opReqamp :: Amplitude } -- eventually need a ID
data OpRpy  = Amplitude -- currently single dispatch, so no need for a ID to identify target?

data State = State { Sworklist :: WorkList }

-- need some architecture. problem here is that it makes more sense for the bus message to have the destination on it, but how do we route? and tbh the only reason we are using the kiwi code is for float support, that we know we don't want.
-- we COULD just abandon busses for the ops - makes sense I think?
-- data Bus = WSRequest | WSReply | AddReq | AddRpy | 

-- take work units to add to the queue and reply with - more requests, or replies. Should also take 
ampcalcparam :: Circuit -> QubitId -> State -> (Maybe WSRequest, Maybe WSReply) -> (State, (Maybe WSRequest, Maybe WSReply))
ampcalcparam    c          initState  (queue)   (inreq, inrpy) = 
  match (queue, inreq, inrpy) with
    
  
  if isJust inreq then -- add the new request to the queue
    let 
      newWorkSpec = workspecdefault { WStarget = reqtarget (fromJust inreq), WSdestination = reqID (fromJust inreq) }
    in let
      newWL, oldElem = shiftInAt0 queue newWorkSpec
    in
      (newWL, Nothing, Nothing)
  else -- nothing to add, so we should try to make progress.
    let 
      witem = head queue
    if isNothing witem then
      (queue, Nothing, Nothing) -- empty queue, just pause.
    else if isNothing (wspreds witem) then -- have not worked out the predicessor states yet, so get those.
      


ampcalc = let 
  circuit = $(v [(H, Just 0, Nothing, Nothing) :: CircuitElem, 
                 (H, Just 0, Nothing, Nothing)])
  initstate : QubitId = 0 
in
  ampcalcparam circuit initstate

{-# ANN topEntity
  (Synthesize
    { t_name     = "cmult"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortProduct "" [PortProduct "" [PortName "Areal", PortName "Aimag"],
                        PortProduct "" [PortName "Breal", PortName "Bimag"]]
      ]
    , t_output  = PortProduct "" [
                    PortName "Creal",
                    PortName "Cimag"]


    }) #-}

topEntity   
  :: Clock System Source
  -> Reset System Asynchronous 
  -> Signal System (Amplitude, Amplitude) 
  -> Signal System Amplitude
topEntity = exposeClockReset (mealy multiplier_mealy ())

-- tmmorow: just make the haskell port of the f# code, direct recusion
