"""
We use CLaSH generated modules in a lot of Verilator/Verilog code.
This requires knowlage of the bitwidths of the ports, but we cannot
get this from Haskell without faff, so parse the generated verilog.
"""
import math 

# 269 -> 276 (+6 over real bit width)
# 217 -> 222 (+6 over real bit width)
# 269 -> 271

__ALL__ = ["OUTPUT_BUNDLE_WIDTH", "INPUT_BUNDLE_WIDTH"]

def round_to_6(n):
    factor = n / 6.0
    return 6 * math.ceil(factor)

# input/output bundles
with open("build/verilog/findamp.v", "r") as f:
    l = f.read().split("\n")

outstr = list(filter(lambda s: "output_bundle" in s, l))[0]
OUTPUT_BUNDLE_WIDTH = int(outstr.split("[")[1].split(":")[0])+1

instr = list(filter(lambda s: "input_bundle" in s, l))[0]
INPUT_BUNDLE_WIDTH = int(instr.split("[")[1].split(":")[0])+1

with open("build/verilog/join_input.v", "r") as f:
    l = f.read().split("\n")

outstr = list(filter(lambda s: "wu" in s, l))[0]
WORKUNIT_WIDTH = int(outstr.split("[")[1].split(":")[0])+1

template = """
const int WUSZ = {};
const int INBSZ = {};
const int OUTBSZ = {};
""".format(WORKUNIT_WIDTH, INPUT_BUNDLE_WIDTH, OUTPUT_BUNDLE_WIDTH)

# generate a c++ hdr file that contains the needed typedefs
if __name__ == "__main__":
    print(template)