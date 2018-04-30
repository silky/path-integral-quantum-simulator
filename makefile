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
	mono nuget.exe install MathNet.Numerics.FSharp -Pre -OutputDirectory packages

# /r:$(KDLL) /r:$(KRDLL)
build/QLib.dll: src/CS/QLib.cs build packages
	mcs -sdk:4.6 -unsafe -t:library src/CS/QLib.cs -r /usr/lib/mono/4.6.1-api/System.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -o build/QLib.dll



run: build/path_simulation.exe
	MONO_PATH=$(MPATH) build/path_simulation.exe

run-direct: build/direct_calculation.exe
	MONO_PATH=$(MPATH) build/direct_calculation.exe


clean:
	rm -rf build

deepclean: clean
	rm -rf packages


build/path_simulation.exe: src/FS/path_simulation.fs build/QLib.dll build/demo.dll build packages
	fsharpc -o build/path_simulation.exe --target:exe src/FS/path_simulation.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r build/QLib.dll -r build/demo.dll
	
build/direct_calculation.exe: src/FS/direct_calculation.fs build/QLib.dll build/demo.dll build packages
	fsharpc -o build/direct_calculation.exe --target:exe src/FS/direct_calculation.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r build/QLib.dll -r build/demo.dll

build/demo.dll: src/FS/demo.fs build packages
	fsharpc --target:library src/FS/demo.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -o build/demo.dll