import numpy as np
from scipy import special
# import matplotlib.pyplot as plt
from scipy import optimize
from math import floor
def findx(nsplit, fun):
    opt = optimize.minimize_scalar(lambda x: np.abs(fun(x)-nsplit), bounds=[0,1], method="bounded")
    return opt.x

def splits(nsplit, depth, a, b):
    locs = np.linspace(0, 1, nsplit+2)[1:-1]
    xsplits = [int(floor( findx(split, lambda x: special.betainc(a, b, x))*(depth-1) ))+1 for split in locs]
    return xsplits

splits(3, 12, 3, 2)

# def CDF(x):
#     return 
# 
# xsplits = [findx(split, CDF) for split in locs]
# 
# CDF(xsplits[-1])
# 
# plt.plot(X, CDF(X))
# for xsplit in xsplits:
#     plt.axvline(xsplit, color="red")
# plt.show()
