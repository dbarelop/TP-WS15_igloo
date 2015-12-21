# Created by Microsemi Libero Software 11.6.0.34
# Mon Dec 21 16:44:46 2015

# (NEW DESIGN)

# create a new design
new_design -name "top" -family "IGLOO"
set_device -die {AGLN250V2} -package {100 VQFP} -speed {STD} -voltage {1.2~1.5} -IO_DEFT_STD {LVCMOS 3.3V} -RESTRICTPROBEPINS {1} -RESTRICTSPIPINS {0} -TEMPR {COM} -UNUSED_MSS_IO_RESISTOR_PULL {None} -VCCI_1.2_VOLTR {COM} -VCCI_1.5_VOLTR {COM} -VCCI_1.8_VOLTR {COM} -VCCI_2.5_VOLTR {COM} -VCCI_3.3_VOLTR {COM} -VOLTR {COM}


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

# set working directory
set_defvar "DESDIR" "C:/Users/matze/Documents/igloo/system/teamprojekt/designer/impl2"

# set back-annotation output directory
set_defvar "BA_DIR" "C:/Users/matze/Documents/igloo/system/teamprojekt/designer/impl2"

# enable the export back-annotation netlist
set_defvar "BA_NETLIST_ALSO" "1"

# set EDIF options
set_defvar "EDNINFLAVOR" "GENERIC"

# set HDL options
set_defvar "NETLIST_NAMING_STYLE" "VHDL93"

# setup status report options
set_defvar "EXPORT_STATUS_REPORT" "1"
set_defvar "EXPORT_STATUS_REPORT_FILENAME" "top.rpt"

# legacy audit-mode flags (left here for historical reasons)
set_defvar "AUDIT_NETLIST_FILE" "1"
set_defvar "AUDIT_DCF_FILE" "1"
set_defvar "AUDIT_PIN_FILE" "1"
set_defvar "AUDIT_ADL_FILE" "1"

# import of input files
import_source  \
-format "edif" -edif_flavor "GENERIC" -netlist_naming "VHDL" {../../synthesis/top.edn}

# save the design database
save_design {top.adb}


compile
report -type "status" {top_compile_report.txt}
report -type "pin" -listby "name" {top_report_pin_byname.txt}
report -type "pin" -listby "number" {top_report_pin_bynumber.txt}

save_design
