import csv
import pandas as pd
import numpy as np
import pint
ureg = pint.UnitRegistry()
import sys
names = []
times = []

with open(sys.argv[1], "r") as f:
    dat = csv.reader(f, delimiter=",")

    for line in dat:
        name, datasize, *timelist, _ = line
        names.append(name)
        times.append(timelist)
        

def convertold(tlist):
    t = [int(t.split(" ")[0]) * (1 if t.split(" ")[1] == "ns" else 1000) for t in tlist]
    dt = np.diff(t)
    dd = 32//8
    factor = ((1 * ureg.bits) / (1 * ureg.nanosecond)).to(ureg.megabyte / ureg.seconds).magnitude
    rate = dd/dt * factor
    rate = pd.Series(data=rate, index=pd.to_datetime(t[1:], unit="ns"))
    return rate[len(t)//100:]

def convert(tlist):
    t = [int(t.split(" ")[0]) * (1 if t.split(" ")[1] == "ns" else 1000) for t in tlist]
    d = np.cumsum([32]*len(t))
    pds = pd.Series(d, index=pd.to_datetime(t, unit="ns"))
    dddt = pds.diff() / pds.index.to_series().diff().dt.total_seconds()
    factor = ((1 * ureg.bits) / (1 * ureg.second)).to(ureg.megabyte / ureg.seconds).magnitude
    rate = dddt * factor
    return rate

# t = [int(t.split(" ")[0]) * (1 if t.split(" ")[1] == "ns" else 1000) for t in times[0]]
# d = np.cumsum([8]*len(t))
# 
# pds = pd.Series(d, index=pd.to_datetime(t, unit="ns"))
# 
# 
# bws = bw
# plt.plot(bws)
# plt.show()

# def convert(tlist):
#     deltatimes = np.array([int(t.split(" ")[0]) * (1 if t.split(" ")[1] == "ns" else 1000) for t in tlist]) / (10**9)
#     assert((np.diff(deltatimes) >= 0).all())
#     bytes = [32/8]*len(deltatimes)
#     return np.gradient(deltatimes, np.array(bytes))


import matplotlib.pyplot as plt

# rate.max()
# 
# rate.mean()

for time, name in zip(times, names):
    pds = convert(time)
    plt.plot(pds.resample(sys.argv[2]).mean().rolling(window=20,center=True,win_type='blackmanharris').mean(), label=name, linestyle="--") 

plt.xlabel("Time, s")
plt.ylabel("Bandwidth, Mb/s")
plt.legend()
plt.show()

# if __name__ != "__main__": # for interactive code.
#     plt.plot(pds.resample('2us').mean().rolling(window='2us',center=False).mean())
#     plt.show()
    
    