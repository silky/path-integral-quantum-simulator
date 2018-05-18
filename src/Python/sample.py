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
max_time = 300  # maximum time 60 seconds
batch_size = 16
num_cores = 4

depth = 12


def cost(a=3, b=2, N=1):
    print(a, b, N)
    split_pos = splits(N, depth, a, b)[::-1]
    if (np.diff(split_pos) == 0).any():
        return 999999
    net_str = str(Network(split_locs=split_pos, nqubits=4))
    p = sp.run([binfile, '-'], stdout=sp.PIPE, input=net_str.encode('ascii'))
    try:
        time = b" ".join( p.stdout.split(b"\n")[-4].split(b' ')[-2:] )
        return ureg.Quantity(time.decode('ascii')).to(ureg.millisecond).magnitude
    except Exception:
        print("output was")
        print(p.stdout.split(b"\n"))
        print("network", split_pos, net_str)
        return 999999

myProblem = GPyOpt.methods.BayesianOptimization(lambda x: cost(*x[0]), domain=bounds,
acquisition_type = 'EI',              
                                            normalize_Y = True,
                                            initial_design_numdata = 10,
                                            evaluator_type = 'local_penalization',
                                                num_cores = 3, batch_size=3)
myProblem.run_optimization(10)

myProblem.plot_acquisition()
print(myProblem.x_opt)
print("split points at opt", myProblem.x_opt)
