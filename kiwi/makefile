export HPRLS=/media/psf/Home/Projects/ACS/kiwi_planner/bitbucket-hprls2
# KCC=$HPRLS/kiwipro/kiwic/distro/bin/kiwic

KCC=$(HPRLS)/kiwipro/kiwic/distro/bin/kiwic

KDLL=$(HPRLS)/kiwipro/kiwic/distro/support/Kiwi.dll
KRDLL=$(HPRLS)/kiwipro/kiwic/distro/support/KiwiRandom.dll

KCC=$(HPRLS)/kiwipro/kiwic/distro/bin/kiwic
VROOT=$(HPRLS)/hpr/hpr_ipblocks/cvip0
PPRED=-I$(HPRLS)/kiwipro/kiwic/distro/support/performance_predictor
MPATH=$(HPRLS)/kiwipro/kiwic/distro/support

RESTRICT_FLAG=-max-no-int-divs=1 -max-no-fp-divs=1 -max-no-int-muls=1 -max-no-fp-muls=1 -max-no-fp-addsubs=1

# I don't know sed/awk. I'm sorry.
define ADD_FSM_INIT
import re, sys

with open(sys.argv[1], "r") as f:
    flines=f.readlines()

pattern=re.compile(r" *reg \[[0-9]*:0\] bevelab10nz;")
defns = [l for l in flines if pattern.match(l)]
idx=flines.index(defns[0])
flines.insert(idx+1, " initial begin bevelab10nz <= 32'h0; end")

with open(sys.argv[1], "w") as f:
    f.writelines(flines)
endef
export ADD_FSM_INIT

RES_SMALL= \
    -max-no-int-divs=1 \
    -max-no-fp-divs=1 \
    -max-no-int-muls=1 \
    -max-no-fp-muls=1
#    -int-fl-limit-mul=20

# Finished at 120us on 100 MHz clock with resources constrained.


RES_BIG= \
    -max-no-int-divs=10 \
    -max-no-fp-divs=10 \
    -max-no-int-muls=10 \
    -max-no-fp-muls=10
#    -int-fl-limit-mul=20


# KIWIFLAGS= -vnl-resets=synchronous -kiwic-cil-dump=combined -kiwic-kcode-dump=enable -res2-loadstore-port-count=0 -vnl-roundtrip=disable $(RES_BIG) -bevelab-default-pause-mode=soft -bevelab-soft-pause-threshold=5 -kiwic-register-colours=1

KIWIFLAGS= $(RES_BIG) -vnl-subexpression-sharing=disable -res2-offchip-threshold=99999 -bevelab-default-pause-mode=soft -bevelab-soft-pause-threshold=1 -cil-uwind-budget=9999999

# pause_thresh 1 gives verilate clocks 71
# pause_thresh 100 gives verilate clocks dosn't, like, finish
# default pause thresh gives error
# default everything givces clocks 154

# default with master branch verilate clocks: 154
# pause_thresh 1 with master branch verilate clocks: 71 (oops)

# ------ with 30x30 and 10 steps
# laned-reads, 32 lanes: Done on end_assert at clock               150374
# laned-reads, 4 lanes: Done on end_assert at clock               150374 -huh
# 150374 without mergef as well, so lets fix this!



all: build/qsim.v
	echo "################ BUILD DONE #################"


build/qsim.v: build/qsim.exe makefile
	cd build && $(KCC) qsim.exe -vnl=qsim.v -vnl-rootmodname=GOLROOT $(KIWIFLAGS) $(KFLAGS)
	# python -c "$$ADD_FSM_INIT" build/gol.v

build/qsim.exe: qsim.cs
	mcs -unsafe -sdk:4.0 qsim.cs /r:/usr/lib/mono/4.0-api/System.Numerics.dll /r:$(KDLL) /r:$(KRDLL) -o build/qsim.exe

kiwi:
	cd $(HPRLS)/hpr/ && make -j4
	cd $(HPRLS)/kiwipro/kiwic/src/ && make -j4


run: build/qsim.exe
	MONO_PATH=$(MPATH) build/qsim.exe

clean:
	rm -rf build/*
	
