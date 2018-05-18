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
#MFLAGS=--profile=log:sample,report
MFLAGS=
RESTRICT_FLAG=-max-no-int-divs=1 -max-no-fp-divs=1 -max-no-int-muls=1 -max-no-fp-muls=1 -max-no-fp-addsubs=1

SYSC=/media/psf/Home/Projects/ACS/P35/systemc-2.3.2
CPPFLAGS=-std=c++14 -DSC_CPLUSPLUS=201402L -DSC_DISABLE_API_VERSION_CHECK=0 -Wno-unused-variable -Wall -g
INCLUDES=-I/usr/share/verilator/include/ -I$(SYSC)/include/
### SOFTWARE

build:
	mkdir build

packages:
	mono nuget.exe install MathNet.Numerics -Pre -OutputDirectory packages
	mono nuget.exe install MathNet.Numerics.FSharp -Pre -OutputDirectory packages

# /r:$(KDLL) /r:$(KRDLL)
build/QLib.dll: src/CS/QLib.cs build packages
	mcs -sdk:4.6 -unsafe -t:library src/CS/QLib.cs -r /usr/lib/mono/4.6.1-api/System.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -o build/QLib.dll

run: build/path_simulation.exe
	MONO_PATH=$(MPATH) mono $(MFLAGS) build/path_simulation.exe

run-direct: build/direct_calculation.exe
	MONO_PATH=$(MPATH) mono $(MFLAGS) build/direct_calculation.exe


clean:
	rm -rf build tests/a.out
	rm -rf src/CLaSH/verilog
	find src/CLaSH/ -name "*hi" -type f -delete
	
	find src/CLaSH/ -name "*.o" -type f -delete
	find src/CLaSH/ -name "*dyn_o" -type f -delete
	find tests -name "*hi" -type f -delete
	find tests -name "*dyn_o" -type f -delete


deepclean: clean # drop the mono packages - needs internet to rebuild.
	rm -rf packages


build/path_simulation.exe: src/FS/path_simulation.fs build/QLib.dll build/demo.dll build packages
	fsharpc -o build/path_simulation.exe --target:exe src/FS/path_simulation.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r build/QLib.dll -r build/demo.dll
	
build/direct_calculation.exe: src/FS/direct_calculation.fs build/QLib.dll build/demo.dll build packages
	fsharpc -o build/direct_calculation.exe --target:exe src/FS/direct_calculation.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r build/QLib.dll -r build/demo.dll

build/demo.dll: src/FS/demo.fs build packages
	fsharpc --target:library src/FS/demo.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -o build/demo.dll

## TLM model

build/model: src/cpp/model.cpp src/cpp/algo.cpp src/cpp/algo.h src/cpp/loggingsocket.hpp build
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ -I$(SYSC)/include/ src/cpp/model.cpp src/cpp/algo.cpp -o build/model

build/model2: src/cpp/model2.cpp src/cpp/algo.cpp src/cpp/algo.h src/cpp/loggingsocket.hpp build
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ -I$(SYSC)/include/ src/cpp/model2.cpp src/cpp/algo.cpp -o build/model2


build/cppexample: src/cpp/algo.cpp src/cpp/algo.h src/cpp/demo.cpp build
	g++ $(CPPFLAGS) src/cpp/algo.cpp src/cpp/demo.cpp -Isrc/cpp/ -o build/cppexample



## SYSC RTL MODEL

build/Vcmult.cpp: build/verilog/Driver/cmult/cmult.v build
	verilator -Wall --sc build/verilog/Driver/cmult/*.v --Mdir build/ --top-module cmult -Wno-fatal

build/verilator_model.o: src/cpp/verilator_model.cpp build/Vcmult.cpp build # Vcmult is for the .h file
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) -Ibuild/ -c src/cpp/verilator_model.cpp -o build/verilator_model.o

build/verilated.o: build/Vcmult.cpp build/verilator_model.o # recursive make considered harmful etc
	+make -C build -j -f Vcmult.mk Vcmult__ALL.a
	+make -C build -j -f Vcmult.mk verilator_model.o verilated.o

build/RTLmodel: build/verilated.o build/verilator_model.o
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) build/verilator_model.o build/Vcmult__ALL*.o build/verilated.o -o build/RTLmodel


# Hardware stuff

build/verilog/Driver/cmult/cmult.v: src/CLaSH/cmult.hs build
	cd build && stack exec -- clash --verilog ../src/CLaSH/cmult.hs	

build/verilog/Driver/findamp/findamp.v: src/CLaSH/FindAmp.hs build
	cd build && stack exec -- clash --verilog ../src/CLaSH/FindAmp.hs	

findamp-clash: build/verilog/Driver/findamp/findamp.v

clash: build/verilog/Driver/cmult/cmult.v

cmul-test: tests/cmul-test.v build/verilog/Driver/cmult/cmult.v
	iverilog tests/cmul-test.v build/verilog/Driver/cmult/*.v -o tests/cmultest
	
test-hwblocks: clash cmul-test
	tests/cmultest

tests/fixedpttests: "tests/data.txt"
	stack exec -- clash --make tests/createRomFile.hs
	./createRomFile "tests/data.txt" "tests/fixedpttests"


## Test stuff.

bwplots:
	python3 src/Python/socket_bandwidth_plot.py bwlog.csv 20us