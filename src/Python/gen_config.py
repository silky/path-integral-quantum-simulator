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
    
    def __init__(self, split_locs, nqubits):
        self.amps = []
        self.divs = []
        self.bases = []
        self.inits = []
        self.qubits = nqubits
        
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

