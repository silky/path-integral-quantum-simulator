from gen_config import Network
from split_points import splits
import subprocess as sp
import pint
import numpy as np
ureg = pint.UnitRegistry()
binfile = "/home/parallels/Projects/ACS/qsim/build/model2"

import GPy
import GPyOpt

bounds = [
{'name': 'a', 'type': 'continuous', 'domain': (0.1,10)}, 
{'name': 'b', 'type': 'continuous', 'domain': (0.1,10)},
{'name': 'Nlevels', 'type': 'discrete', 'domain': (1,2,3,4,5)}]
max_iter = 40  # maximum time 40 iterations
max_time = 30  # maximum time 60 seconds
batch_size = 4
num_cores = 4

DEPTH = 12
NQUBITS = 4
NSPLITS = 1

def costs(param_list):
    return [cost(*p) for p in param_list]

def cost(a=3, b=2, N=1):
    print(a, b, N)
    split_pos = splits(N, DEPTH, a, b)[::-1]
    if (np.diff(split_pos) == 0).any():
        return np.inf
    network = Network(split_locs=split_pos, nqubits=NQUBITS, depth=DEPTH)
    if network.area() > 53200: # limit to a size that fits.
        return np.inf
    return network.time() * 21.6 / 10*6 # clocks to ms

# need to generate the desired network design, and then compile the RTLmodel to simulate it. Would it be possible to port the TLM version - maybe? high effort when a dumb bash script can make it work
# def cost(a=3, b=2, N=1):
#     print(a, b, N)
#     split_pos = splits(N, depth, a, b)[::-1]
#     if (np.diff(split_pos) == 0).any():
#         return 999999
#     net_str = str(Network(split_locs=split_pos, nqubits=4))
#     p = sp.run([binfile, '-'], stdout=sp.PIPE, input=net_str.encode('ascii'))
#     try:
#         time = b" ".join( p.stdout.split(b"\n")[-4].split(b' ')[-2:] )
#         return ureg.Quantity(time.decode('ascii')).to(ureg.millisecond).magnitude
#     except Exception:
#         print("output was")
#         print(p.stdout.split(b"\n"))
#         print("network", split_pos, net_str)
#         return 999999


myProblem = GPyOpt.methods.BayesianOptimization(costs, domain=bounds,
acquisition_type = 'EI',              
                                            normalize_Y = True,
                                            initial_design_numdata = 10,
                                            evaluator_type = 'local_penalization',
                                                num_cores = num_cores, batch_size=batch_size)
myProblem.run_optimization(10)

print(myProblem.x_opt)
split_pos = splits(NSPLITS, DEPTH, *myProblem.x_opt[:2])[::-1]
print("split points at opt", split_pos)
print("cost at opt", cost(*myProblem.x_opt))
myProblem.plot_acquisition()
