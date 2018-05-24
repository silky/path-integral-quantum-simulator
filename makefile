.PHONY: archives clashinterfaces

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
# main module
build/verilog/axi_qsim.v: src/verilog/axi_qsim.yaml
	python AXI-iface-gen/gen.py -c src/verilog/axi_qsim.yaml -o build/verilog/axi_qsim.v


build/Vfindamp.cpp: build/verilog/FindAmp/findamp/findamp.v build
	verilator -Wall --sc build/verilog/FindAmp/findamp/*.v --Mdir build/ -Ibuild/verilog/FindAmp/findamp --top-module findamp -Wno-fatal

build/Vpack_input.cpp: build/verilog/Interfaces/pack_input/pack_input.v build
	verilator -Wall --sc build/verilog/Interfaces/pack_input/*.v --Mdir build/ -Ibuild/verilog/Interfaces/pack_input --top-module pack_input -Wno-fatal

build/Vunpack_output.cpp: build/verilog/Interfaces/unpack_output/unpack_output.v build
	verilator -Wall --sc build/verilog/Interfaces/unpack_output/*.v --Mdir build/ -Ibuild/verilog/Interfaces/unpack_output --top-module unpack_output -Wno-fatal

build/Vunpack_ampreply.cpp: build/verilog/Interfaces/unpack_ampreply/unpack_ampreply.v build
	verilator -Wall --sc build/verilog/Interfaces/unpack_ampreply/*.v --Mdir build/ -Ibuild/verilog/Interfaces/unpack_ampreply --top-module unpack_ampreply -Wno-fatal

build/Vfindamp__ALL.a: build/Vfindamp.cpp
	+make -C build -j -f Vfindamp.mk Vfindamp__ALL.a

build/Vpack_input__ALL.a: build/Vpack_input.cpp
	+make -C build -j -f Vpack_input.mk Vpack_input__ALL.a

build/Vunpack_output__ALL.a: build/Vunpack_output.cpp
	+make -C build -j -f Vunpack_output.mk Vunpack_output__ALL.a

build/Vunpack_ampreply__ALL.a: build/Vunpack_ampreply.cpp
	+make -C build -j -f Vunpack_ampreply.mk Vunpack_ampreply__ALL.a

build/verilator_model.o: src/cpp/verilator_model.cpp modulesources build # Vcmult is for the .h file
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) -Ibuild/ -c src/cpp/verilator_model.cpp src/cpp/rtl_findamp_transactor.cpp -o build/verilator_model.o

build/verilator_transactor.o: src/cpp/rtl_findamp_transactor.cpp modulesources build
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) -Ibuild/ -c src/cpp/rtl_findamp_transactor.cpp -o build/verilator_transactor.o

modulesources: build/Vfindamp.cpp build/Vpack_input.cpp build/Vunpack_output.cpp build/Vunpack_ampreply.cpp
archives: build/Vfindamp__ALL.a build/Vpack_input__ALL.a build/Vunpack_output__ALL.a build/Vunpack_ampreply__ALL.a

build/verilated.o: build/verilator_model.o build/verilator_transactor.o
	+make -C build -j -f Vfindamp.mk verilator_model.o verilated.o build/verilator_transactor.o

# input/output unpackers


build/RTLmodel: build/verilated.o archives
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) build/verilator_model.o build/V*__ALL*.o build/verilated.o -o build/RTLmodel


# Hardware stuff
# had to switch to vhdl as there was some syntax errors in the verilog clash output
build/verilog/Driver/cmult/cmult.v: src/CLaSH/cmult.hs build
	cd build && stack exec -- clash --vhdl ../src/CLaSH/cmult.hs

build/vhdl/FindAmp/findamp/findamp.vhdl: src/CLaSH/FindAmp.hs src/CLaSH/HwTypes.hs build
	cd build && stack exec -- clash --vhdl ../src/CLaSH/FindAmp.hs	-i../src/CLaSH/ 

build/verilog/FindAmp/findamp/findamp.v: src/CLaSH/FindAmp.hs src/CLaSH/HwTypes.hs build
	cd build && stack exec -- clash --verilog ../src/CLaSH/FindAmp.hs	-i../src/CLaSH/ 

build/vhdl/Interfaces/pack_input/pack_input.vhdl: src/CLaSH/Interfaces.hs src/CLaSH/HwTypes.hs build
	cd build && stack exec -- clash --vhdl ../src/CLaSH/Interfaces.hs	-i../src/CLaSH/

clashinterfaces: src/CLaSH/Interfaces.hs src/CLaSH/HwTypes.hs build
	cd build && stack exec -- clash --verilog ../src/CLaSH/Interfaces.hs	-i../src/CLaSH/

build/verilog/Interfaces/pack_input/pack_input.v: clashinterfaces
build/verilog/Interfaces/unpack_output/unpack_output.v: clashinterfaces
build/verilog/Interfaces/unpack_ampreply/unpack_ampreply.v: clashinterfaces

clash-vhdl: build/vhdl/FindAmp/findamp/findamp.vhdl build/vhdl/Interfaces/pack_input/pack_input.vhdl
clash-verilog: build/verilog/FindAmp/findamp/findamp.v build/verilog/Interfaces/pack_input/pack_input.v

clash: clash-vhdl clash-verilog

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