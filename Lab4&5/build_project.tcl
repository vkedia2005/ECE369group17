# =====================================================================
# build_project.tcl  -  ECE369 group 17
#
# Put this file in the Lab3 folder of the repo (next to the .v files).
#
# What it does:
#   - If NO project is open: creates a Vivado project in ./vivado_proj
#     (Nexys A7-100T, xc7a100tcsg324-1) and adds every source it finds.
#   - If a project IS open: adds only the files that aren't in it yet.
#
# Sorting rules (searches all subfolders):
#   *_tb.v          -> Simulation Sources only
#   other *.v       -> Design Sources
#   *.mem           -> Design Sources (used by synthesis AND simulation)
#   *.xdc           -> Constraints
#
# Files are linked, not copied, so edits and git pulls show up directly.
#
# How to run:
#   Vivado start screen -> Tcl Console:   source /full/path/to/Lab3/build_project.tcl
#   or from a terminal:                   vivado -mode tcl -source build_project.tcl
#   Re-run it any time someone adds a new file.
# =====================================================================

set root      [file normalize [file dirname [info script]]]
set proj_dir  [file join $root vivado_proj]
set proj_name lab4
set part      xc7a100tcsg324-1

# ---------- recursively find files with a given extension ----------
proc find_files {dir ext} {
    set found {}
    foreach f [glob -nocomplain -directory $dir -types f *$ext] {
        lappend found [file normalize $f]
    }
    foreach sub [glob -nocomplain -directory $dir -types d *] {
        # skip Vivado's own generated folders
        if {[string match "*vivado_proj*" $sub] || [string match "*.Xil*" $sub]} { continue }
        if {[string match "*.runs" $sub] || [string match "*.sim" $sub] || [string match "*.cache" $sub]} { continue }
        set found [concat $found [find_files $sub $ext]]
    }
    return $found
}

# ---------- open existing project or create a new one ----------
if {[catch {current_project}]} {
    if {[file exists [file join $proj_dir $proj_name.xpr]]} {
        puts "Opening existing project..."
        open_project [file join $proj_dir $proj_name.xpr]
    } else {
        puts "Creating new project in $proj_dir ..."
        create_project $proj_name $proj_dir -part $part
        set_property target_language Verilog [current_project]
    }
} else {
    puts "Project already open: syncing new files only."
}

# files already in the project (so we don't add twice)
set existing {}
foreach f [get_files -quiet] { lappend existing [file normalize $f] }

proc add_if_new {f fileset} {
    upvar existing existing
    if {[lsearch -exact $existing $f] < 0} {
        add_files -norecurse -fileset $fileset $f
        lappend existing $f
        puts "  added to $fileset: [file tail $f]"
    }
}

# ---------- Verilog: testbenches vs design ----------
foreach f [find_files $root .v] {
    if {[string match "*_tb.v" [file tail $f]]} {
        add_if_new $f sim_1
    } else {
        add_if_new $f sources_1
    }
}

# ---------- memory init files ----------
foreach f [find_files $root .mem] {
    add_if_new $f sources_1
}

# ---------- constraints ----------
foreach f [find_files $root .xdc] {
    add_if_new $f constrs_1
}

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Done. Set your top module (Design Sources) and sim top (Simulation Sources) as needed."
