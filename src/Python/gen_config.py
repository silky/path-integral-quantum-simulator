# class Initiator(object):
#     pass
# 

import sys
import math

class AmpFinder(object):
    
    type = "FINDAMP"
    def __init__(self, depth, idx):
        self.idx = idx
        self.depth = depth
        self.down_connection = None
    
    def __str__(self):
        return "{},{},{}".format( self.depth, self.down_connection.type, self.down_connection.idx )


class HeightDiv(object):
    
    type = "HEIGHTDIV"
    def __init__(self, splitpt, idx):
        self.idx = idx
        self.splitpt = splitpt
        self.left = None
        self.right = None
    
    def __str__(self):
        """wat"""
        if self.left is None:
            raise Exception("HeightDiv {} left unconnected".format(self.idx))
        if self.right is None:
            raise Exception("HeightDiv {} right unconnected".format(self.idx))
        if self.left.type != self.right.type:
            raise Exception("HeightDiv  {} has incompatable lower objects".format(self.idx))
        return "{},{},{},{}".format(self.splitpt, self.left.type, self.left.idx, self.right.idx )

class Base():
    
    type = "BASE"
    def __init__(self, idx):
        self.idx = idx


class Network(object):
    
    def __init__(self, split_locs, nqubits, depth):
        self.amps = []
        self.divs = []
        self.bases = []
        self.inits = []
        self.qubits = nqubits
        self.depth = depth
        self.splits = split_locs
        self.circuitarities = [2] * self.depth # worst case
        
        # root of the tree.
        splitranges = list(zip( split_locs+[0], ["ROOT"]+split_locs ))
        atlevel = [2**i for i, _ in enumerate(splitranges)]
        
        for (splitlow, splithigh), count, prevcount in zip(splitranges, atlevel, ["NONE"]+atlevel[:-1]):
            # print("level starts at", splitlow, "ending at", splithigh, "have", count, "finders, that connect to", prevcount, "at the prev level")
            
            if splithigh != "ROOT": # if we are lower level than the last split, we need to make some divs
                # we need prevcount splits.
                for i in range(prevcount):
                    # print("making", prevcount, "div units")
                    div = HeightDiv(splitpt=i * int(prevcount/self.qubits), idx=len(self.divs))
                    self.amps[len(self.amps)-i-1].down_connection = div
                    self.divs.append(div)
            
            for i in range(count): # due to higher splits, need more at each level
                ampfinder = AmpFinder(depth=splitlow, idx=len(self.amps))
                self.amps.append(ampfinder)

                if splithigh != "ROOT": # don't need to connect it up at all
                    # we need to connect the N=count ampfinders to N=prevcount div modules.
                    # those modules are in self.divs[-prevcount-1:-1]
                    # releventdivs = self.divs[-prevcount:-1]
                    idx = len(self.divs) - math.floor(i / 2) - 1
                    # print("connecting ampfinder", ampfinder.idx, "to div", idx, "split depth", splithigh)
                    if i % 2 == 0:
                        self.divs[idx].left = ampfinder
                    else:
                        self.divs[idx].right = ampfinder
                if splitlow == 0:
                    base = Base(idx=len(self.bases))
                    self.bases.append(base)
                    ampfinder.down_connection = base
                    
    def __str__(self):
        header = "{}\n{}\n{}".format(len(self.amps), len(self.divs), len(self.bases))
        amps = [str(amp) for amp in self.amps]
        divs = [str(div) for div in self.divs]
        config = "\n".join([header] + amps + divs)
        return config

    def time(self, depth=None):
        """ Estimates the number of clock cycles needed for a given circuit layout. Returns number of clocks.
        """
        if depth is None:
            depth = self.depth
        
        if depth == 0:
            return 2
        
        reccalls = 2**self.circuitarities[depth-1]; # zero depth is base case
        callcount = reccalls / 2 if (depth in self.splits) else reccalls
        divdelay = 1 if (depth in self.splits) else 0
        recdelay = callcount * self.time(depth=depth-1)
        ourdelay = 4
        return ourdelay + divdelay + recdelay

    def _LUTs(self, stacksize):
        """Calculates a estimate size for a findamp module based upon the required stack size.
        """
        return int(stacksize*1798 - 2600)

    def area(self, maxparallel=1, depth=None):
        # stack required is the depth * max wu's in progress.
        if depth is None: # start at the top
            depth = self.depth
        
        limit = max(list(filter(lambda s: s<depth, self.splits)) + [0])
        ourdepth = depth - limit
        
        if limit == 0: # we are bottom
            return maxparallel * self._LUTs(ourdepth)
        else:
            return (maxparallel * self._LUTs(ourdepth)) + \
                   self.area(maxparallel=maxparallel*2, depth=limit)
         



# def time(depth, splits, circuitarities):
#     if depth == 0:
#         return 2
# 
#     reccalls = 2**circuitarities[depth];
#     callcount = reccalls / 2 if (depth in splits) else reccalls
#     divdelay = 1 if (depth in splits) else 0
#     recdelay = callcount * time(depth-1, splits, circuitarities)
#     ourdelay = 4
#     return ourdelay + divdelay + recdelay

