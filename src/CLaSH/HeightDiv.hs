module HeightDiv where

import Clash.Prelude
import Data.Maybe
import HwTypes

splitpt :: State = 1

type RetQueue = Vec 10 (Maybe AmpReply) -- the queue of replies that need to be returned (oops)

heightdiv :: RetQueue -> (Maybe WorkUnit, Maybe AmpReply, Maybe AmpReply) -> (RetQueue, (Maybe WorkUnit, Maybe WorkUnit, Maybe AmpReply))
heightdiv queue (req, rpy_hi, rpy_low) = (queueout, (req_hi, req_low, rpy))
  where
    (req_hi, req_low) = -- make requests
      if isJust req then
        if wu_target (fromJust req) < splitpt then 
          (req, Nothing) 
        else 
          (Nothing, req)
      else
        (Nothing, Nothing)
    
    (queueout, rpy) = 
      let
        (queue', pushed) = if isJust rpy_hi then 
                             shiftInAt0 queue (singleton rpy_hi) 
                           else (queue, singleton Nothing) -- push new amp rpy
      in let
        (queue'', pushed') = if isJust rpy_low then 
                               shiftInAt0 queue' (singleton rpy_low) 
                             else (queue', singleton Nothing) -- push new amp rpy
      in let
        (queue''', rpyVecd) = shiftOutFrom0 (SNat :: SNat 1) queue''
      in
        (queue''', rpyVecd !! 0)


{-# ANN topEntity
  (Synthesize
    { t_name     = "heightdiv"
    , t_inputs   = [
        PortName "clk",
        PortName "rst",
        PortProduct "" [PortName "upstream_req", PortName "downstream_high_rply", PortName "downstream_low_rply"]
      ]
    , t_output  = PortProduct "" [PortName "downstream_high_req", PortName "downstream_low_req", PortName "upstream_rply"]
    }) #-}

initalstate = repeat Nothing

topEntity   
  :: Clock System
  -> Reset System
  -> Signal System (Maybe WorkUnit, Maybe AmpReply, Maybe AmpReply)
  -> Signal System (Maybe WorkUnit, Maybe WorkUnit, Maybe AmpReply)
topEntity clk rst =
  exposeClockResetEnable (mealy heightdiv initalstate) clk rst enableGen

