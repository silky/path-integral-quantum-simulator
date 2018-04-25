export HPRLS=/media/psf/Home/Projects/ACS/kiwi_planner/bitbucket-hprls2
# KCC=$HPRLS/kiwipro/kiwic/distro/bin/kiwic

KCC=$(HPRLS)/kiwipro/kiwic/distro/bin/kiwic

KDLL=$(HPRLS)/kiwipro/kiwic/distro/support/Kiwi.dll
KRDLL=$(HPRLS)/kiwipro/kiwic/distro/support/KiwiRandom.dll

KCC=$(HPRLS)/kiwipro/kiwic/distro/bin/kiwic
VROOT=$(HPRLS)/hpr/hpr_ipblocks/cvip0
PPRED=-I$(HPRLS)/kiwipro/kiwic/distro/support/performance_predictor
# MPATH=$(HPRLS)/kiwipro/kiwic/distro/support
MPATH=/home/parallels/Projects/ACS/qsim/packages/MathNet.Numerics.4.4.0/lib/net461/
RESTRICT_FLAG=-max-no-int-divs=1 -max-no-fp-divs=1 -max-no-int-muls=1 -max-no-fp-muls=1 -max-no-fp-addsubs=1


build:
	mkdir build

packages:
	mono nuget.exe install MathNet.Numerics -Pre -OutputDirectory packages

# /r:$(KDLL) /r:$(KRDLL)
build/path_simulation.exe: src/CS/path_simulation.cs build packages
	mcs -sdk:4.6 -unsafe src/CS/path_simulation.cs -r /usr/lib/mono/4.6.1-api/System.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -o build/path_simulation.exe

run: build/path_simulation.exe
	MONO_PATH=$(MPATH) build/path_simulation.exe

clean:
	rm -rf build
