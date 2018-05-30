f = open("build/timing_report.txt")
l = f.read()

lines = l.split("\n")

maxidx = lines.index("Max Delay Paths")
maxidx
maxdelay = lines[maxidx+10].strip().split(":")[1].strip().split(' ')[0]

f = open("build/util_report.txt")
l = f.read()

lines = l.split("\n")

utilidx = [i for i, s in enumerate(lines) if s.startswith("| Slice LUTs*")][0]

luts = int(lines[utilidx].split("|")[2])

dspidx = [i for i, s in enumerate(lines) if s.startswith("| DSPs")][0]
dsps = int(lines[dspidx].split("|")[2])

print("delay={}, luts={}, dsps={}".format(maxdelay,luts,dsps))