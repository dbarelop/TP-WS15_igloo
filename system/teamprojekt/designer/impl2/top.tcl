# Created by Microsemi Libero Software 11.6.0.34
# Mon Dec 21 17:58:12 2015

# (OPEN DESIGN)

open_design "top.adb"

# set default back-annotation base-name
set_defvar "BA_NAME" "top_ba"
set_defvar "IDE_DESIGNERVIEW_NAME" {Impl2}
set_defvar "IDE_DESIGNERVIEW_COUNT" "2"
set_defvar "IDE_DESIGNERVIEW_REV0" {Impl1}
set_defvar "IDE_DESIGNERVIEW_REVNUM0" "1"
set_defvar "IDE_DESIGNERVIEW_REV1" {Impl2}
set_defvar "IDE_DESIGNERVIEW_REVNUM1" "2"
set_defvar "IDE_DESIGNERVIEW_ROOTDIR" {C:\Users\matze\Documents\igloo\system\teamprojekt\designer}
set_defvar "IDE_DESIGNERVIEW_LASTREV" "2"


# import of input files
import_source  \
-format "edif" -edif_flavor "GENERIC" -netlist_naming "VHDL" {../../synthesis/top.edn} -merge_physical "yes" -merge_timing "yes"
compile
report -type "status" {top_compile_report.txt}
report -type "pin" -listby "name" {top_report_pin_byname.txt}
report -type "pin" -listby "number" {top_report_pin_bynumber.txt}

save_design
