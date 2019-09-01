#
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
# 
# Change log:
#     2018, Nov., Tomas Brabec
#     - Created.
#

# Need to constrain the shell as we use some advanced scripting.
SHELL = bash

# Name of the top module.
TOP ?= arty_a7_shell

# Name of the testbench module.
SIMTOP ?= tb

# Path to a file containing a list Verilog/SystemVerilog files to synthesize.
FLIST ?=

# A list of Verilog/SystemVerilog files to synthesize. If FLIST is set, its
# contents will add to whatever is in VSRC.
VSRC ?=

# A list of Verilog/SystemVerilog include paths.
VINC_DIRS ?=

TCM_INIT ?=

.PHONY: help
help:
	@echo $(VSRC)

ifneq ($(FLIST), )
FLIST_SHA :=$(shell echo -n $$(readlink -f $(FLIST)) | sha1sum | cut -c1-10)
FLIST_MAKEFILE := work/Makeinclude.$(FLIST_SHA).mk

-include $(FLIST_MAKEFILE)

$(FLIST_MAKEFILE): $(FLIST)
	@mkdir -p $(dir $@) && \
        if [ -e $@ ]; then echo "Updating $@ ..."; else echo "Creating $@ ..."; fi && \
        shopt -s extglob && \
        d="$(dir $(FLIST))"; \
        for f in $$(cat $(FLIST)); do \
            f=$${f##+([[:space:]])}; f=$${f%%+([[:space:]])}; \
            if [ -z "$$f" ] || [[ $$f =~ ^# ]]; then continue; fi; \
            if [[ $$f =~ ^\+incdir\+(.*) ]]; then \
              incdir="$${BASH_REMATCH[1]}"; \
              if [ -z "$${incdir}" ] || [[ $${incdir} =~ ^# ]]; then continue; fi; \
              if [[ $${incdir} =~ ^/ ]]; then echo "VINC_DIRS += $${incdir}"; else echo "VINC_DIRS += $$d/$${incdir}"; fi; \
              continue; \
            fi; \
            if [[ $$f =~ ^/ ]]; then echo "VSRC += $$f"; else echo "VSRC += $$d/$$f"; fi; \
        done > $@

endif

export VSRC
export VINC_DIRS
$(if $(TOP),$(eval export TOP))
$(if $(SIMTOP),$(eval export SIMTOP))

dummy:
	@echo "TCM_INIT=$${TCM_INIT}"

.PHONY: setup
setup: scripts/prologue_setup.tcl $(VSRC) $(VINC_DIRS) $(TCM_INIT)
	$(if $(TCM_INIT),TCM_INIT=$(abspath $(TCM_INIT)) )vivado \
        -nojournal \
        -mode gui \
        -source scripts/prologue_setup.tcl

.PHONY: clean
clean:
	rm -rf work vivado.log

# while read -r l; do if [[ $l =~ ^@ ]]; then echo $l; continue; fi; i=0; k=""; for ll in $l; do k="${ll}${k}"; (( i+=1 )); if (( i > 3 )); then i=0; echo $k; k=""; fi; done; done < isa/rebuild/soc-p-uart-regs.verilog
