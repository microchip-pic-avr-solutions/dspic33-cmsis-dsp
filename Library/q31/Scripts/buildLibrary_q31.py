#!/bin/python3
"""
Build script for libcmsis-dsp-dspic33-elf-q31.a

This script compiles all Q31 DSP source files (.s and .c) and archives
them into a static library, mirroring the build process used for the
f32 library (libcmsis-dsp-dspic33-elf-f32.a).

Usage:
    python buildLibrary_q31.py
    python buildLibrary_q31.py -j json/libcmsis-dsp-dspic33-elf-q31.json
    python buildLibrary_q31.py -r          (rebuild from scratch)
    python buildLibrary_q31.py -c "C:/Program Files/Microchip/xc-dsc/v3.31"
"""

import argparse, os, sys, subprocess, shutil, json

NORMAL  = "\x1B""[0m"
RED     = "\x1B""[1;31m"
GREEN   = "\x1B""[1;32m"
YELLOW  = "\x1B""[1;33m"
BLUE    = "\x1B""[1;34m"

# Defaults (matching f32 build configuration)
DEVICE_DEFAULT = "GENERIC-32DSP-AK"
LIBRARY_DEFAULT = "cmsis-dsp-dspic33-elf-q31"
COMPILER_DEFAULT = "C:/Program Files/Microchip/xc-dsc/v3.31"

# Directory layout (relative to this script's location = Library/q31/Scripts/)
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.normpath(os.path.join(SCRIPT_DIR, "..", "..", ".."))
LIBRARY_DIR = os.path.normpath(os.path.join(SCRIPT_DIR, ".."))

INCLUDE_DIR = os.path.join(REPO_ROOT, "Include")
PRIVATE_INCLUDE_DIR = os.path.join(REPO_ROOT, "PrivateInclude")
SRC_DIR = os.path.join(REPO_ROOT, "Source")
BUILD_DIR = os.path.join(SCRIPT_DIR, "cmake", "build_q31")

# ─── Q31 Source Files ────────────────────────────────────────────────────────
# Organized to mirror the f32 CMakeLists.txt structure exactly.

Q31_SOURCES = [
    # BasicMathFunctions
    "BasicMathFunctions/mchp_add_q31.s",
    "BasicMathFunctions/mchp_dot_prod_q31.s",
    "BasicMathFunctions/mchp_mult_q31.s",
    "BasicMathFunctions/mchp_negate_q31.s",
    "BasicMathFunctions/mchp_scale_q31.s",
    "BasicMathFunctions/mchp_sub_q31.s",

    # ComplexMathFunctions
    "ComplexMathFunctions/mchp_cmplx_mag_squared_q31.s",

    # CommonTables (Q31 twiddle factors + init functions)
    "CommonTables/mchp_common_tables.c",

    # FastMathFunction (Q31 sqrt, needed by mchp_std_q31)
    "FastMathFunction/mchp_sqrt_q31.s",

    # MatrixFunctions
    "MatrixFunctions/mchp_mat_add_q31.s",
    "MatrixFunctions/mchp_mat_init_q31.s",
    "MatrixFunctions/mchp_mat_inverse_q31.c",
    "MatrixFunctions/mchp_mat_mult_q31.s",
    "MatrixFunctions/mchp_mat_scale_q31.s",
    "MatrixFunctions/mchp_mat_sub_q31.s",
    "MatrixFunctions/mchp_mat_trans_q31.s",

    # StatisticsFunctions
    "StatisticsFunctions/mchp_max_q31.s",
    "StatisticsFunctions/mchp_mean_q31.s",
    "StatisticsFunctions/mchp_min_q31.s",
    "StatisticsFunctions/mchp_power_q31.s",
    "StatisticsFunctions/mchp_std_q31.s",
    "StatisticsFunctions/mchp_var_q31.s",

    # SupportFunctions
    "SupportFunctions/mchp_copy_q31.s",

    # TransformFunctions
    "TransformFunctions/mchp_bitreversal_q31.s",
    "TransformFunctions/mchp_cfft_q31.s",
    "TransformFunctions/mchp_rfft_fast_q31.s",

    # WindowFunctions
    "WindowFunctions/mchp_bartlett_q31.c",
    "WindowFunctions/mchp_hamming_q31.c",
    "WindowFunctions/mchp_hanning_q31.c",

    # ControllerFunctions
    "ControllerFunctions/mchp_pid_q31.s",
    "ControllerFunctions/mchp_pid_init_q31.s",
    "ControllerFunctions/mchp_pid_reset_q31.s",

    # FilteringFunctions
    "FilteringFunctions/mchp_biquad_cascade_df1_q31.s",
    "FilteringFunctions/mchp_biquad_cascade_df1_init_q31.s",
    "FilteringFunctions/mchp_conv_q31.s",
    "FilteringFunctions/mchp_correlate_q31.s",
    "FilteringFunctions/mchp_fir_decimate_q31.s",
    "FilteringFunctions/mchp_fir_decimate_init_q31.s",
    "FilteringFunctions/mchp_fir_q31.s",
    "FilteringFunctions/mchp_fir_init_q31.s",
    "FilteringFunctions/mchp_fir_interpolate_q31.s",
    "FilteringFunctions/mchp_fir_interpolate_init_q31.s",
    "FilteringFunctions/mchp_fir_lattice_q31.s",
    "FilteringFunctions/mchp_fir_lattice_init_q31.s",
    "FilteringFunctions/mchp_iir_lattice_q31.s",
    "FilteringFunctions/mchp_iir_lattice_init_q31.s",
    "FilteringFunctions/mchp_lms_q31.s",
    "FilteringFunctions/mchp_lms_init_q31.s",
    "FilteringFunctions/mchp_lms_norm_q31.s",
    "FilteringFunctions/mchp_lms_norm_init_q31.s",
]


def compile_file(src_path, obj_path, compiler, device, is_c_file):
    """Compile a single source file (.s or .c) to an object file."""

    if is_c_file:
        # C file: full C flags matching xc-dsc_toolchain.cmake
        cmd = [
            os.path.join(compiler, "bin", "xc-dsc-gcc.exe"),
            "-mcpu=%s" % device,
            "-msmall-code", "-msmall-data", "-msmall-scalar",
            "-Wall", "-msfr-warn=on",
            "-Os",
            "-msmart-io=1",
            "-omf=elf",
            "-mno-file",
            "-I%s" % INCLUDE_DIR,
            "-I%s" % PRIVATE_INCLUDE_DIR,
            "-c", src_path,
            "-o", obj_path,
        ]
    else:
        # Assembly file: ASM flags
        cmd = [
            os.path.join(compiler, "bin", "xc-dsc-gcc.exe"),
            "-mcpu=%s" % device,
            "-I%s" % PRIVATE_INCLUDE_DIR,
            "-I%s" % INCLUDE_DIR,
            "-c", src_path,
            "-o", obj_path,
        ]

    proc = subprocess.run(cmd, capture_output=True, text=True)

    # The compiler emits DFP/license warnings on stderr even on success
    if proc.returncode != 0:
        print(RED + "  FAILED: %s" % os.path.basename(src_path) + NORMAL)
        print(proc.stdout)
        print(proc.stderr)
        return False

    return True


def clean(build_dir):
    """Remove the build directory."""
    if os.path.exists(build_dir):
        print(YELLOW + "Cleaning build directory '%s'..." % build_dir + NORMAL)
        shutil.rmtree(build_dir)


def build_library(options):
    """Compile all Q31 sources and create the static library archive."""

    compiler = options.compiler
    device = options.device
    library_name = options.library

    # Resolve paths
    lib_output = os.path.join(LIBRARY_DIR, "lib%s.a" % library_name)
    build_dir = BUILD_DIR

    # Create build directory
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    print(YELLOW + "\nCompiling Q31 source files..." + NORMAL)
    print(BLUE + "  Device: " + NORMAL + device)
    print(BLUE + "  Compiler: " + NORMAL + compiler)
    print(BLUE + "  Output: " + NORMAL + lib_output)
    print("")

    obj_files = []
    failed = []
    total = len(Q31_SOURCES)

    for i, rel_src in enumerate(Q31_SOURCES, 1):
        src_path = os.path.join(SRC_DIR, rel_src)

        if not os.path.exists(src_path):
            print(RED + "  [%d/%d] MISSING: %s" % (i, total, rel_src) + NORMAL)
            failed.append(rel_src)
            continue

        # Object file name: basename.obj (matching CMake convention: e.g., mchp_add_q31.s.obj)
        obj_name = os.path.basename(rel_src) + ".obj"
        obj_path = os.path.join(build_dir, obj_name)

        is_c_file = rel_src.endswith(".c")
        basename = os.path.basename(rel_src)

        print("  [%d/%d] %s" % (i, total, basename), end="", flush=True)

        if compile_file(src_path, obj_path, compiler, device, is_c_file):
            obj_files.append(obj_path)
            print(GREEN + " OK" + NORMAL)
        else:
            failed.append(rel_src)

    print("")

    if failed:
        print(RED + "Failed to compile %d file(s):" % len(failed) + NORMAL)
        for f in failed:
            print(RED + "  - %s" % f + NORMAL)
        return False

    print(YELLOW + "Creating static library archive..." + NORMAL)
    print("  %d object files -> %s" % (len(obj_files), os.path.basename(lib_output)))

    # Remove old library if it exists
    if os.path.exists(lib_output):
        os.remove(lib_output)

    # Create archive using xc-dsc-ar
    ar_exe = os.path.join(compiler, "bin", "xc-dsc-ar.exe")
    cmd = [ar_exe, "rcs", lib_output] + obj_files

    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        print(RED + "Archive creation failed!" + NORMAL)
        print(proc.stdout)
        print(proc.stderr)
        return False

    # Verify
    if os.path.exists(lib_output):
        size = os.path.getsize(lib_output)
        print(GREEN + "\n  Created: %s (%d bytes)" % (os.path.basename(lib_output), size) + NORMAL)
    else:
        print(RED + "  Library file not found after archiving!" + NORMAL)
        return False

    return True


if __name__ == "__main__":

    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write(RED + 'error: %s\n' % message + NORMAL)
            self.print_help()
            sys.exit(2)

    try:
        parser = MyParser(description=__doc__)
        parser.add_argument('-j', '--jsonfile', help='JSON file with build configuration', type=str)
        parser.add_argument('-r', '--rebuild', help='run a clean build (remove artifacts)', action="store_true")
        parser.add_argument('-l', '--library', help='library file name', type=str, default=LIBRARY_DEFAULT)
        parser.add_argument('-d', '--device', help='MCPU device flag', type=str, default=DEVICE_DEFAULT)
        parser.add_argument('-c', '--compiler', help='path to compiler', type=str, default=COMPILER_DEFAULT)

        options = parser.parse_args()

        # Load JSON config if provided
        if options.jsonfile is not None:
            jsonpath = options.jsonfile
            if not os.path.isabs(jsonpath):
                jsonpath = os.path.join(SCRIPT_DIR, jsonpath)

            if not os.path.exists(jsonpath):
                parser.error("Missing JSON input file '%s'" % jsonpath)

            with open(jsonpath, 'r') as cf:
                config = json.load(cf)

            options.compiler = config.get("compiler", options.compiler)
            options.library = config.get("library", options.library)
            options.device = config.get("device", options.device)

        # Validate compiler path
        gcc_path = os.path.join(options.compiler, "bin", "xc-dsc-gcc.exe")
        if not os.path.exists(gcc_path):
            parser.error("Compiler not found at '%s'" % gcc_path)

        ar_path = os.path.join(options.compiler, "bin", "xc-dsc-ar.exe")
        if not os.path.exists(ar_path):
            parser.error("Archiver not found at '%s'" % ar_path)

        print(YELLOW + "Building Q31 library with options:" + NORMAL)
        print(BLUE + "   library: " + NORMAL + "%s" % options.library)
        print(BLUE + "    device: " + NORMAL + "%s" % options.device)
        print(BLUE + "  compiler: " + NORMAL + "%s" % options.compiler)
        print("")

        result = True

        if options.rebuild:
            clean(BUILD_DIR)

        if result:
            result = build_library(options)

        if result:
            print(GREEN + "\nBuild complete." + NORMAL)
        else:
            print(RED + "\nBuild failed!" + NORMAL)
            sys.exit(1)

    except Exception as ex:
        print(RED + "\nBuild failed: %s" % str(ex) + NORMAL)
        import traceback
        print(traceback.format_exc())
        sys.exit(1)

    sys.exit(0)
