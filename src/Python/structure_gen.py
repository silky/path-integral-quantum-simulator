from Cheetah.Template import Template

from gen_config import Network
# from split_points import splits
import sys
# import numpy as np


# N = int(sys.argv[1])
# split_pos = splits(N, depth, a, b)[::-1]
# if (np.diff(split_pos) == 0).any():
#     raise IndexError
network = Network(split_locs=[1], nqubits=2)
# len(nosplits.amps)

# const int WUSZ = 222;
# const int INBSZ = 276;
# const int OUTBSZ = INBSZ;


WUSZ = 222;
INBSZ = 276;
OUTBSZ = 276;
AMPSZ = 47;
POSSZ = 5;

# nosplits.amps[0].down_connection.type
network.amps[0].down_connection.idx

print(network)
network.divs[0].left.idx
# network = nosplits
# general principle: declare wires by the source, assume existance at destination
import sys, os

pathname = os.path.dirname(sys.argv[0])  
src = os.path.split(pathname)[0]
verilog = os.path.join(src, "verilog", "networkRTL.tmpl.v")
print("template", verilog)

mod_top = open(verilog, "r").read()

t = Template(mod_top, searchList=[locals()])

with open(sys.argv[1], "w") as f:
    f.write(str(t))