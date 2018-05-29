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
.PHONY: archives cpclash


INTERFACES = build/verilog/pack_input.v \
						 build/verilog/unpack_output.v \
             build/verilog/unpack_ampreply.v \
						 build/verilog/pack_workunit.v \
						 build/verilog/parse_ptr.v

SPLITTERS = build/verilog/join_input.v \
						build/verilog/join_output.v \
						build/verilog/split_input.v \
						build/verilog/split_output.v

CLASH_MOD_NAMES = findamp heightdiv # real work done here
CLASH_MOD_NAMES += pack_input unpack_output unpack_ampreply pack_workunit parse_ptr # extracting base values
CLASH_MOD_NAMES += split_input join_input split_output join_output # splitting record types


packages:
	mono nuget.exe install MathNet.Numerics -Pre -OutputDirectory packages
	mono nuget.exe install MathNet.Numerics.FSharp -Pre -OutputDirectory packages

# /r:$(KDLL) /r:$(KRDLL)
build/QLib.dll: src/CS/QLib.cs  packages
	mcs -sdk:4.6 -unsafe -t:library src/CS/QLib.cs -r /usr/lib/mono/4.6.1-api/System.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -o build/QLib.dll

run: build/path_simulation.exe
	MONO_PATH=$(MPATH) mono $(MFLAGS) build/path_simulation.exe

run-direct: build/direct_calculation.exe
	MONO_PATH=$(MPATH) mono $(MFLAGS) build/direct_calculation.exe


clean:
	rm -rf build/* tests/a.out
	rm -rf src/CLaSH/verilog
	find src/CLaSH/ -name "*hi" -type f -delete
	
	find src/CLaSH/ -name "*.o" -type f -delete
	find src/CLaSH/ -name "*dyn_o" -type f -delete
	find tests -name "*hi" -type f -delete
	find tests -name "*dyn_o" -type f -delete


deepclean: clean # drop the mono packages - needs internet to rebuild.
	rm -rf packages


build/path_simulation.exe: src/FS/path_simulation.fs build/QLib.dll build/demo.dll  packages
	fsharpc -o build/path_simulation.exe --target:exe src/FS/path_simulation.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r build/QLib.dll -r build/demo.dll
	
build/direct_calculation.exe: src/FS/direct_calculation.fs build/QLib.dll build/demo.dll  packages
	fsharpc -o build/direct_calculation.exe --target:exe src/FS/direct_calculation.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r build/QLib.dll -r build/demo.dll

build/demo.dll: src/FS/demo.fs  packages
	fsharpc --target:library src/FS/demo.fs -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -r packages/MathNet.Numerics.4.4.0/lib/net461/MathNet.Numerics.dll -o build/demo.dll

## TLM model

build/model: src/cpp/model.cpp src/cpp/algo.cpp src/cpp/algo.h src/cpp/loggingsocket.hpp 
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ -I$(SYSC)/include/ src/cpp/model.cpp src/cpp/algo.cpp -o build/model

# build/RTLmodel: build/verilated.o archives
# 	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) build/verilator_model.o build/V*__ALL*.o build/verilated.o -o build/RTLmodel

build/model2: src/cpp/model2.cpp src/cpp/algo.cpp src/cpp/algo.h src/cpp/loggingsocket.hpp src/cpp/tlm_types.cpp
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ -I$(SYSC)/include/ $(INCLUDES) -Ibuild/ src/cpp/model2.cpp src/cpp/algo.cpp src/cpp/tlm_types.cpp -o build/model2 


build/cppexample: src/cpp/algo.cpp src/cpp/algo.h src/cpp/demo.cpp 
	g++ $(CPPFLAGS) src/cpp/algo.cpp src/cpp/demo.cpp -Isrc/cpp/ -o build/cppexample

build/tlm_types.o: src/cpp/tlm_types.cpp
		g++ $(CPPFLAGS) -c src/cpp/tlm_types.cpp -Isrc/cpp/ -o build/tlm_types.o

## SYSC RTL MODEL
# main module

## AXI interface module
build/verilog/axi_qsim.v: src/verilog/axi_qsim.yaml
	python AXI-iface-gen/gen.py -c src/verilog/axi_qsim.yaml -o build/verilog/axi_qsim.v

build/verilog/networkRTL.v: src/Python/structure_gen.py src/verilog/networkRTL.tmpl.v build/verilog/findamp.v build/verilog/join_input.v build/verilog/split_output.v
	mkdir -p build/verilog
	python3 src/Python/structure_gen.py build/verilog/networkRTL.v

# we need to exclude the top level modules from the verilator generators
ALLMODV = `find build/verilog/ -name "*.v" -not -name "networkRTL.v"`
	
build/V%.cpp: build/verilog/%.v 
	verilator -Wall --sc $(ALLMODV) --Mdir build/ -Ibuild/verilog/ --top-module $(basename $(notdir $^)) -Wno-fatal

build/VnetworkRTL.cpp: build/verilog/networkRTL.v 
	verilator -Wall --sc build/verilog/*.v --Mdir build/ -Ibuild/verilog/ --top-module $(basename $(notdir $^)) -Wno-fatal


## Now the parts are in a consistant directory, we can use makefile rules to be a bit more consise

build/V%__ALL.a: build/V%.cpp
	+make -C build -j -f $(addsuffix .mk, $(basename $(notdir $^))) $(notdir $@)


build/verilator_model.o: src/cpp/verilator_model.cpp modulesources  # Vcmult is for the .h file
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) -Ibuild/ -c src/cpp/verilator_model.cpp -o build/verilator_model.o

build/verilator_transactor.o: src/cpp/rtl_findamp_transactor.cpp modulesources 
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) -Ibuild/ -c src/cpp/rtl_findamp_transactor.cpp -o build/verilator_transactor.o


modulesources: $(foreach modname, $(CLASH_MOD_NAMES), $(subst XX,$(modname), build/VXX.cpp) ) build/VnetworkRTL.cpp
	# build/Vfindamp.cpp build/Vpack_input.cpp build/Vunpack_output.cpp build/Vunpack_ampreply.cpp
archives: $(foreach modname, $(CLASH_MOD_NAMES), $(subst XX,$(modname), build/VXX__ALL.a) ) build/VnetworkRTL__ALL.a

build/verilated.o: build/verilator_model.o build/verilator_transactor.o
	+make -C build -j -f Vfindamp.mk verilator_model.o verilated.o build/verilator_transactor.o

# input/output unpackers


build/RTLmodel: build/verilated.o archives
	g++ $(CPPFLAGS) -lsystemc -L$(SYSC)/lib-linux64/ $(INCLUDES) build/verilator_model.o build/V*__ALL*.a build/verilated.o -o build/RTLmodel


# Hardware stuff
# had to switch to vhdl as there was some syntax errors in the verilog clash output
# nope fixed it: real is a verilog reserved word and the clash builtin permutation vector funcs are good

MATCHSTR = ".*\(.v\|.manifest\|.inc\)\'"

build/verilog/findamp.v: src/CLaSH/FindAmp.hs src/CLaSH/HwTypes.hs 
	cd build && stack exec -- clash --verilog ../src/CLaSH/FindAmp.hs	-i../src/CLaSH/ 
	-mv `find build/verilog/FindAmp -regex $(MATCHSTR)` build/verilog/

build/verilog/heightdiv.v: src/CLaSH/HeightDiv.hs src/CLaSH/HwTypes.hs 
	cd build && stack exec -- clash --verilog ../src/CLaSH/HeightDiv.hs	-i../src/CLaSH/ 
	-mv `find build/verilog/HeightDiv -regex $(MATCHSTR)` build/verilog/


build/clashinterfaces: src/CLaSH/Interfaces.hs src/CLaSH/HwTypes.hs 
	cd build && stack exec -- clash --verilog ../src/CLaSH/Interfaces.hs	-i../src/CLaSH/
	-mv `find build/verilog/Interfaces -regex $(MATCHSTR)` build/verilog/
	touch build/clashinterfaces # the generated files and the src do not share a common stem, so we use this as a hack

build/clashsplitters: src/CLaSH/Split.hs src/CLaSH/HwTypes.hs 
	cd build && stack exec -- clash --verilog ../src/CLaSH/Split.hs	-i../src/CLaSH/
	-mv `find build/verilog/Split -regex $(MATCHSTR)` build/verilog/
	touch build/clashsplitters


$(INTERFACES): build/clashinterfaces
interfaces: $(INTERFACES)
	
$(SPLITTERS): build/clashsplitters
splitters: $(SPLITTERS)

clash: build/verilog/findamp.v build/clashsplitters build/clashinterfaces 


## Test stuff.

bwplots:
	python3 src/Python/socket_bandwidth_plot.py bwlog.csv 20us