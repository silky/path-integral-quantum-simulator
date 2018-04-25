
export HPRLS=/media/psf/Home/Projects/ACS/kiwi_planner/bitbucket-hprls2
# KCC=$HPRLS/kiwipro/kiwic/distro/bin/kiwic

KCC=$(HPRLS)/kiwipro/kiwic/distro/bin/kiwic

KDLL=$(HPRLS)/kiwipro/kiwic/distro/support/Kiwi.dll
KRDLL=$(HPRLS)/kiwipro/kiwic/distro/support/KiwiRandom.dll
KFPDLL=$(HPRLS)/kiwipro/kiwic/distro/support/KiwiFpSqRoot.dll

KCC=$(HPRLS)/kiwipro/kiwic/distro/bin/kiwic
VROOT=$(HPRLS)/hpr/hpr_ipblocks/cvip0
PPRED=-I$(HPRLS)/kiwipro/kiwic/distro/support/performance_predictor
MPATH=$(HPRLS)/kiwipro/kiwic/distro/support
KICKOFF_LIBRARIES=$(HPRLS)/kiwipro/kiwi/userlib/kickoff-libraries
CVIP=$(VROOT)/cvgates.v $(VROOT)/cv_fparith.v # $(wildcard $(VROOT)/*.v)
# iface:	iface.hs
# 	stack exec -- clash --verilog OPL.hs

build:
	mkdir build

verilog: 
	mkdir verilog

# $(KICKOFF_LIBRARIES)/KiwiFpSqRoot/KiwiFpSqRoot.dll:$(KICKOFF_LIBRARIES)/KiwiFpSqRoot/KiwiFpSqRoot.cs
# 	mcs /target:library $(KICKOFF_LIBRARIES)/KiwiFpSqRoot/KiwiFpSqRoot.cs \
# 	/r:$(KDLL) /r:$(KRDLL) \
# 	-o $(KICKOFF_LIBRARIES)/KiwiFpSqRoot/KiwiFpSqRoot.dll
# 

build/hadamard.exe: src/hadamard.cs build
	mcs  -sdk:4.5 src/hadamard.cs \
	/r:$(KDLL) /r:$(KRDLL) /r:$(KFPDLL) \
	-o build/hadamard.exe

verilog/hadamard.v: build/hadamard.exe verilog
	cd verilog && $(KCC) ../build/hadamard.exe -vnl=hadamard.v -vnl-rootmodname=HROOT $(KIWIFLAGS) $(KFLAGS)


hostrun: build/hadamard.exe
	MONO_PATH=$(MPATH) build/hadamard.exe

build/hsim: verilog/hadamard.v verilog/h-test.v
	iverilog verilog/hadamard.v verilog/h-test.v $(CVIP) -o build/hsim

