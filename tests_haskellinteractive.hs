:l FindAmp.hs

let wlist :: WorkList = repeat emptywu
let ptr :: PtrT = 0
let empty = True

let (wlist', ptr', empty') = input_wu_update wlist ptr empty (Just (emptywu { wu_target=1, wu_inital=1, wu_depth=0, wu_returnloc=RT_UPSTREAM }))
ptr'
-- have the first element with given data.
makerequests wlist' ptr'


let (wlist'', ptr'', output) = tryevaluate wlist' ptr'

let (wlist''', reply) = evaluatewu wlist'' ptr''

-- works to evaluate a base case.

canevaluate (wlist' !! ptr')

let wlist' :: WorkList = replace 0 (emptywu { wu_target=1, wu_inital=1, wu_depth=2, wu_returnloc=RT_UPSTREAM }) wlist
let pt :: PtrT = 0

-- WORKS PROPERLY WITH SINGLE STATES.
:l FindAmp.hs

let emptyin = Input { input_wu=Nothing, input_amp=Nothing }
let testin = Input { input_wu= Just (emptywu { wu_target=1, wu_inital=1, wu_depth=0, wu_returnloc=RT_UPSTREAM }), input_amp=Nothing }

let mac = mealy findamp_mealy initalstate
let output = simulate mac ([testin] L.++ (L.repeat emptyin))
output L.!! 0
output L.!! 1
output L.!! 2 -- output
output L.!! 3 -- no output

-- and mult sep by a gap
let output = simulate mac ([testin, emptyin, testin] L.++ (L.repeat emptyin))
output L.!! 0
output L.!! 1 -- output
output L.!! 2
output L.!! 3 -- output

-- does work with immediate, but pushes back the first evaluation (as the latest takes priority) same as SysC, but perhaps a bad choice? or does it behave as backpressure.
let output = simulate mac ([testin, testin] L.++ (L.repeat emptyin))
output L.!! 0
output L.!! 1
output L.!! 2 -- output
output L.!! 3 -- output

-- test recursive ones now.
:l FindAmp.hs
let mac = mealy findamp_mealy initalstate

let emptyin = Input { input_wu=Nothing, input_amp=Nothing, input_depth_split = 0 }
let lv1test = emptyin { input_wu= Just (emptywu { wu_target=1, wu_inital=1, wu_depth=1, wu_returnloc=RT_UPSTREAM }), 
                        input_amp=Nothing }
let output = simulate mac ([lv1test] L.++ (L.repeat emptyin))

output L.!! 0
output L.!! 1
output L.!! 2
output L.!! 3
output L.!! 4
output L.!! 5
output L.!! 6
output L.!! 7
output L.!! 8
output L.!! 9
output L.!! 10
output L.!! 11
output L.!! 12
output L.!! 15 -- output! 0.707

-- deeper
let lv2test = Input { input_wu= Just (emptywu { wu_target=1, wu_inital=1, wu_depth=2, wu_returnloc=RT_UPSTREAM }), input_amp=Nothing }
let output = simulate mac ([lv2test] L.++ (L.repeat emptyin))

output L.!! 41 -- CORRECT!.

-- test routing.

-- problem: we are not addding the pred states anyware. Need to do this either when state added (i.e. makerequests, input_wu_update) or as another step and flag in the eval?

L.take 3 output
 
let testInput :: Signal System Input = stimuliGenerator (emptyin :> (repeat emptyin))

sampleN 7 