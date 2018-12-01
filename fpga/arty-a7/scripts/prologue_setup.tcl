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
#     - Created from code at https://github.com/SI-RISCV/e200_opensource
#
#
# Description:
#   Sets up a project in Xilinx Vivado to synthesize, implement and/or simulate
#   a zero-riscy SoC for the Digilent Arty A7-35 demo board.
#
#   There are few environment variables to control the script:
#
#   - `VSRC`: A space separated list of RTL files to add to the project.
#   - `VINC_DIRS`: A space separated list of paths to be used as Verilog
#     include paths directives (`+incdir+...`).
#   - `TCM_INIT`: Path to a Verilog memory initialization file passed to
#     `$readmemh()` call for initializing the instruction Tightly Coupled
#     Memory (TCM). Addresses in the file shall start at 0 (and will map
#     to TCM address space as defined by the SoC address map, presently
#     `0x8000_0000`). Values shall be 32 bits. Any non-zero address hence
#     shall be word-aligned.
#

set name {arty_zr_soc}
set part_fpga {xc7a35ticsg324-1L}
set part_board {digilentinc.com:arty:part0:1.1}
set bootrom_inst {rom}

set top {arty_a7_shell}

set scriptdir [file dirname [info script]]
set commondir [file dirname $scriptdir]
set srcdir [file join $commondir rtl]
set constrsdir [file join $commondir constrs]

set wrkdir [file join [pwd] work/vivado]
set ipdir [file join $wrkdir ip]

create_project ${name}_proj $wrkdir -part $part_fpga -force 
set_property -dict [list \
  BOARD_PART $part_board \
  TARGET_LANGUAGE {Verilog} \
  SIMULATOR_LANGUAGE {Mixed} \
  TARGET_SIMULATOR {XSim} \
  DEFAULT_LIB {xil_defaultlib} \
  IP_REPO_PATHS $ipdir \
  ] [current_project]

#proc recglob { basedir pattern } {
#  set dirlist [glob -nocomplain -directory $basedir -type d *]
#  set findlist [glob -nocomplain -directory $basedir $pattern]
#  foreach dir $dirlist {
#    set reclist [recglob $dir $pattern]
#    set findlist [concat $findlist $reclist]
#  }
#  return $findlist
#}


if {[get_filesets -quiet sources_1] eq ""} {
  create_fileset -srcset sources_1
}
set obj [current_fileset]

#set srcmainverilogfiles [recglob $srcdir "*.v"]
#add_files -norecurse -fileset $obj $srcmainverilogfiles
set fpga_shell_files [glob -nocomplain -directory $srcdir "*.*v"]
add_files -norecurse -fileset $obj ${fpga_shell_files}

#if {[info exists ::env(VSRC_EXTRA)]} {
#  set extra_vsrcs [split $::env(VSRC_EXTRA)]
#  foreach extra_vsrc $extra_vsrcs {
#    add_files -norecurse -fileset $obj $extra_vsrc
#  }
#}

if {[info exists ::env(VSRC)]} {
  add_files -norecurse -fileset $obj [split [string trim $::env(VSRC)]]
}

if {[info exists ::env(VINC_DIRS)]} {
  set_property include_dirs [split [string trim $::env(VINC_DIRS)]] [current_fileset]
}

# Verilog defines passed to synthesis
set defs {SYNTHESIS}
if {[info exists ::env(TCM_INIT)]} {
  lappend defs TCM_INIT_FILE=\"$::env(TCM_INIT)\"
}
set_property verilog_define ${defs} [current_fileset]


### These paths and files should come from the caller, not within this script.
##if {[file exists [file join $srcdir include verilog]]} {
##  add_files -norecurse -fileset $obj [file join $srcdir include verilog DebugTransportModuleJtag.v]
##  add_files -norecurse -fileset $obj [file join $srcdir include verilog AsyncResetReg.v]
##}
#
#if {[get_filesets -quiet sim_1] eq ""} {
#  create_fileset -simset sim_1
#}
#set obj [current_fileset -simset]
#add_files -norecurse -fileset $obj [glob -directory $srcdir {*.v}]
#set_property TOP {tb} $obj

if {[get_filesets -quiet constrs_1] eq ""} {
  create_fileset -constrset constrs_1
}
set obj [current_fileset -constrset]
add_files -norecurse -fileset $obj [glob -directory $constrsdir {*.xdc}]

# -----------------------------------------------
# Create IPs
# -----------------------------------------------
file mkdir $ipdir
update_ip_catalog -rebuild

create_ip -vendor xilinx.com -library ip -name clk_wiz -module_name mmcm -dir $ipdir -force
set_property -dict [list \
  CONFIG.PRIMITIVE {MMCM} \
  CONFIG.RESET_TYPE {ACTIVE_LOW} \
  CONFIG.CLKOUT1_USED {true} \
  CONFIG.CLKOUT2_USED {true} \
  CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {10.000} \
  CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {20.000} \
  ] [get_ips mmcm]

create_ip -vendor xilinx.com -library ip -name proc_sys_reset -module_name reset_sys -dir $ipdir -force
set_property -dict [list \
  CONFIG.C_EXT_RESET_HIGH {false} \
  CONFIG.C_AUX_RESET_HIGH {false} \
  CONFIG.C_NUM_BUS_RST {1} \
  CONFIG.C_NUM_PERP_RST {1} \
  CONFIG.C_NUM_INTERCONNECT_ARESETN {1} \
  CONFIG.C_NUM_PERP_ARESETN {1} \
] [get_ips reset_sys]

# -----------------------------------------------
# Synthesis settings
# -----------------------------------------------
set_property STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION auto [get_runs synth_1]
