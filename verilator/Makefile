# Copyright 2018 Tomas Brabec
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SHELL=bash

vdir = ../rtl
#       $(vdir)/riscv-dbg/src/dm_pkg.sv \
#       $(vdir)/riscv-dbg/src/riscv_pkg.sv \
#       $(vdir)/riscv-dbg/src/ariane_axi_pkg.sv \
#       $(filter-out $(vdir)/riscv-dbg/src/%_pkg.sv,$(wildcard $(vdir)/riscv-dbg/src/*.*v*)) \
#
vsrc = tb_verilator.sv spi_model.sv uart_model.sv \
       $(vdir)/ibex/ibex_pkg.sv \
       $(vdir)/riscv-dbg/src/dm_pkg.sv \
       $(filter-out $(foreach f,ibex_register_file% ibex_pkg.sv ibex_core_tracing.sv ibex_tracer%,$(vdir)/ibex/$(f)),$(wildcard $(vdir)/*.*v* $(vdir)/ibex/*.*v*)) \
       $(vdir)/ibex/ibex_register_file_ff.sv \
       $(wildcard $(vdir)/pulp/*.*v*) \
       $(vdir)/riscv-dbg/debug_rom/debug_rom.sv \
       $(filter-out $(foreach f,dm_pkg.sv,$(vdir)/riscv-dbg/src/$(f)),$(wildcard $(vdir)/riscv-dbg/src/*.*v*)) \
       $(wildcard $(vdir)/riscv_jtag_dm/*.*v*) \
       $(wildcard $(vdir)/perips/*.*v*)
csrc = rbb_server.cpp sim.cpp
cflags =
objdir = obj
obj = sim
vflags = -CFLAGS "-I..$(if $(cflags), $(cflags))" -LDFLAGS "-lpthread" --cc --exe --Mdir $(objdir)  \
	 --top-module tb_verilator \
	 -Wno-WIDTH -Wno-UNOPTFLAT -Wno-CASEINCOMPLETE -Wno-LITENDIAN
vflags_extra = --trace
sflags =

isa_test_patts ?= \
                  rv32ui*\
                  rv32um* \
                  rv32uc* \
#                  rv32ua* \
#                  rv32mi* \

isa_test_dir ?= ../isa-tests/generated
isa_tests ?= $(basename $(notdir $(wildcard $(foreach p,$(isa_test_patts),$(isa_test_dir)/$(p).verilog))))


.PHONY: help
help:
	@echo -e "Usage:\n\tmake [ooptions] [target] [<variable>=<value>]"
	@echo -e "\nTargets:"
	@echo -e "  help        prints this help message"
	@echo -e "  list-tests  lists available ISA tests"
	@echo -e "  build       creates a testbench binary ($(objdir)/$(obj))"
	@echo -e "  regression  runs all tests listed by 'list-tests'"
	@echo -e "  test-<name> runs a single test"
	@echo -e "  clean       delete all outputs"
	@echo -e "\nVariables:"
	@echo -e "  isa_test_dir     path to a folder with *.verilog files"
	@echo -e "  isa_test_patts   space separated list of patterns of ISA tests"
	@echo -e "                   (actual: '$(isa_test_patts)')"
	@echo -e "  isa_tests        space separated list of tests to run for 'regression',"
	@echo -e "                   use 'make list' to display the corresponding list"
	@echo -e "  cflags           extra C++ compiler flags"
	@echo -e "                   use cflags='-DVCDTRACE=1' to enable VCD dump into dump.vcd file."
	@echo -e "\nExamples:"
	@echo -e "  make build test-rv32ui-p-xori"
	@echo -e "  make regression isa_tests=rv32ui-p-xori"
	@echo -e "  make regression isa_patts='rv32ui*'"
	@echo -e "  make test-rv32ui-p-add isa_test_dir=../isa-tests/rebuild"
	@echo -e ""

.PHONY: list-tests list
list list-tests:
	@echo $(isa_tests)


.PHONY: all build
all build: $(objdir)/$(obj)

.PHONY: verilate
verilate: $(objdir)/Vtb_verilator.mk

$(objdir)/Vtb_verilator.mk: $(vsrc)
	verilator $(vflags) $(vflags_extra) -o $(notdir $(obj)) $(csrc) $(vsrc) && touch $@

$(objdir)/$(obj): $(objdir)/Vtb_verilator.mk $(csrc)
	make -C $(objdir) -f Vtb_verilator.mk

.PHONY: clean
clean:
	rm -rf $(objdir) results dump.vcd && for f in *.verilog; do if [ -L $${f} ]; then unlink $${f}; fi; done

.PHONY: regression
regression: $(isa_tests:%=test-%)

test-%: $(isa_test_dir)/%.verilog
	@test -e $*.verilog || ln -s $<
	@mkdir -p results && echo "Running '$*' test ..." && $(objdir)/$(obj) +TESTCASE=$* $(sflags) > results/$*.log

.PHONY: dummy
dummy:
	@echo $(isa_tests)
