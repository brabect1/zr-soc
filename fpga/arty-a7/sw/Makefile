# See LICENSE for license details.

# Specifying a particular shell type as we use some of its scripting specifics.
SHELL := bash

mfile := $(abspath $(lastword $(MAKEFILE_LIST)))
mdir  := $(dir $(mfile))

XLEN ?= 32

src_dir := $(if $(mdir),$(mdir),.)

RISCV_PREFIX ?= riscv-none-embed-
RISCV_GCC ?= $(RISCV_PREFIX)gcc
RISCV_GCC_OPTS ?= -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles
RISCV_OBJDUMP ?= $(RISCV_PREFIX)objdump
RISCV_OBJDUMP_OPTS ?= --disassemble-all
RISCV_OBJCOPY ?= $(RISCV_PREFIX)objcopy 
RISCV_OBJCOPY_OPTS ?= -O verilog 

ifeq ($(XLEN), 32)
    RISCV_GCC_OPTS += -march=rv32i -mabi=ilp32
endif

progs = \
    hello_world \


.PHONY: all
all: $(progs:%=%.elf) $(progs:%=%.bram_tcm)

.PHONY: clean
clean:
	rm -rf $(progs:%=%.elf) $(progs:%=%.verilog) $(progs:%=%.dump) $(progs:%=%.bram_tcm)

.PHONY: dummy
dummy:
	@echo $(src_dir)

%.elf: $(src_dir)/%.S
	$(RISCV_GCC) $(RISCV_GCC_OPTS) -I$(src_dir) -T$(src_dir)/link.ld $< -o $@

%.dump: %.elf 
	$(RISCV_OBJDUMP) $(RISCV_OBJDUMP_OPTS) $< > $@

%.verilog: %.elf 
	$(RISCV_OBJCOPY) $(RISCV_OBJCOPY_OPTS) $<   $@
	sed -i 's/@800/@000/g' $@
	sed -i 's/@200/@000/g' $@
	sed -i 's/@00002FB8/@00002000/g' $@

# The original Verilog dump is organized by bytes, while TCM is organized by words.
# Hence we need to group data by words and change byte addresses to word addresses.
# To do hexadecimal arithmetic in Bash, use `((...))`, but the result is decimal. Then
# use `printf "%X"` to get hexadecimal again. Also watch out for `\r` that appears at
# the end of the line in the original Verilog dump.
%.bram_tcm: %.verilog
	while read -r l; do if [[ $$l =~ ^@ ]]; then l=$${l/@/0x}; printf "@%X\n" $$(( $${l/$$'\r'} / 4 )); continue; fi; i=0; k=""; for ll in $$l; do k="$${ll}$${k}"; (( i+=1 )); if (( i > 3 )); then i=0; echo $$k; k=""; fi; done; done < $< > $@

