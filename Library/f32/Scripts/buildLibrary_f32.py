#!/bin/python3

import argparse, os, sys, traceback, subprocess
import glob, shutil, json

NORMAL  = "\x1B""[0m"
RED     = "\x1B""[1;31m"
GREEN   = "\x1B""[1;32m"
YELLOW  = "\x1B""[1;33m"
BLUE    = "\x1B""[1;34m"
MAGENTA = "\x1B""[1;35m"
CYAN    = "\x1B""[1;36m"

GENERATOR = "Unix Makefiles"

CMAKE_ROOT = "cmake"
BUILD_ROOT = os.path.join(CMAKE_ROOT, "build")
TOOLCHAIN_ROOT = os.path.join(CMAKE_ROOT, "toolchains")
LIBRARY_ROOT = "../../../"
INCLUDE_ROOT = os.path.join("../../../", "Include")
PRIVATE_INCLUDE_ROOT = os.path.join("../../../", "PrivateInclude")

TOOLCHAIN_DEFAULT = "xc-dsc_toolchain.cmake"
DEVICE_DEFAULT = "GENERIC-32DSP-AK"
LIBRARY_DEFAULT = 'cmsis-dsp-dspic33-elf-f32'
COMPILER_DEFAULT = "C:/Program Files/Microchip/xc-dsc/v3.31"

SHOW_COMMANDS = True

# Run commands as a set.
def run_commands(cmds, capture_output=False):
    '''
        Run a set of commands, provided as a list.
    '''
    captured_output=[]
    for c in cmds:
        try:
            # If the command is already a list, use it as-is.
            if type(c) is list:
                cmd = c
            else:
                cmd = c.split(' ')

            if SHOW_COMMANDS is True:
                print("\nRunning command '%s'" % ' '.join(cmd))

            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)

            # Pull output until done.
            while True:
                output = proc.stdout.readline()
                if proc.poll() is not None:
                    break

                # Print and log the output.
                if output:
                    if capture_output is True:
                        captured_output.append(output)
                    else:
                        print(output.strip().decode("utf-8"))

            # Get the return code...
            retcode = proc.poll()
            if retcode:
                raise Exception(RED + "Command '%s' failed with result code %d" % (' '.join(cmd), retcode) + NORMAL)

        except OSError:
            raise Exception(RED + "Failed to start execution of command '%s'" % ' '.join(cmd) + NORMAL)

    if True == capture_output:
        return captured_output
    else:
        return None


# Clean artifacts.
def clean(options):
    result = True
    curdir = os.getcwd()

    try:
        builddir = os.path.join(curdir, BUILD_ROOT)

        print(YELLOW + "Cleaning artifacts..." + NORMAL)
        for p in [builddir]:
            if os.path.exists(p):
                print("  Removing directory '%s'" % p)
                shutil.rmtree(p)

        print("")

    except Exception as ex:
        print(RED + "\nFailed to clean files: %s" % str(ex) + NORMAL)
        result = False

    os.chdir(curdir)
    return result


# Generate the CMake build files.
def generate(options):
    result = True
    curdir = os.getcwd()

    try:
        builddir = os.path.join(curdir, BUILD_ROOT)

        if not os.path.exists(builddir):
            print(YELLOW + "Creating build directory '%s'" % builddir + NORMAL)
            os.makedirs(builddir)

        os.chdir(builddir)

        print(YELLOW + "\nRunning CMake generation..." + NORMAL)
        CMAKEFILE_CMD = [['cmake',
                        '%s' % os.path.join(curdir, CMAKE_ROOT),
                        '-G', GENERATOR,
                        '-DLIBRARY_NAME=%s' % options.library,
                        '-DMCPU_DEVICE=%s' % options.device,
                        '-DCMAKE_TOOLCHAIN_FILE=%s' % options.toolchain_fullpath,
                        '-DCOMPILER_ROOT_FOLDER=%s' % options.compiler]]

        run_commands(CMAKEFILE_CMD)
        print("")

    except Exception as ex:
        print(RED + "\nFailed to generate files: %s" % str(ex) + NORMAL)
        result = False

    os.chdir(curdir)
    return result


# Run the build.
def build(options):
    result = True
    curdir = os.getcwd()

    try:
        incdir = os.path.join(curdir, INCLUDE_ROOT)
        privateincdir = os.path.join(curdir, PRIVATE_INCLUDE_ROOT)
        libdir = os.path.join(curdir, LIBRARY_ROOT)

        os.chdir(BUILD_ROOT)

        print(YELLOW + "Building library..." + NORMAL)

        CMAKE_CMD = [['cmake', '--build', '.']]
        if options.quiet is False:
            CMAKE_CMD[0].append('-v')

        run_commands(CMAKE_CMD)

        # if not os.path.exists(libdir):
        #     print(YELLOW + "Creating output directory '%s'" % libdir.replace(curdir + os.sep, '') + NORMAL)
        #     os.makedirs(libdir)

        # print(YELLOW + "\nCopying include files to '%s'..." % libdir.replace(curdir + os.sep, '') + NORMAL)
        # for f in glob.glob(r"%s/*.h" % incdir):
        #     print("  %s" % f.replace(curdir + os.sep, ''))
        #     shutil.copy(f, libdir)

        # print(YELLOW + "\nCopying Private Include files to '%s'..." % libdir.replace(curdir + os.sep, '') + NORMAL)
        # for f in glob.glob(r"%s/*.h" % privateincdir):
        #     print("  %s" % f.replace(curdir + os.sep, ''))
        #     shutil.copy(f, libdir)

        print("")

    except Exception as ex:
        print(RED + "\nFailed to build files: %s" % str(ex) + NORMAL)
        result = False

    os.chdir(curdir)
    return result


# Main
if __name__ == "__main__":

    # Defined this class to support verbose help on argument error.
    class MyParser(argparse.ArgumentParser):
        def error(self, message):
            sys.stderr.write(RED + 'error: %s\n' % message + NORMAL)
            self.print_help()
            sys.exit(2)

    try:
        # Specify arguments.
        parser = MyParser(description=__doc__)

        parser.add_argument('-j', '--jsonfile', help='JSON file with build configuration', type=str)
        parser.add_argument('-r', '--rebuild', help='run a clean build (remove artifacts)', action="store_true")
        parser.add_argument('-q', '--quiet', help='run a quiet build (no make command output)', action="store_true")
        parser.add_argument('-l', '--library', help='library file name', type=str, default=LIBRARY_DEFAULT)
        parser.add_argument('-d', '--device', help='MCPU device flag', type=str, default=DEVICE_DEFAULT)
        parser.add_argument('-t', '--toolchain', help='toolchain file to use', type=str, default=TOOLCHAIN_DEFAULT)
        parser.add_argument('-c', '--compiler', help='path to compiler', type=str, default=COMPILER_DEFAULT)

        options = parser.parse_args()

        if options.jsonfile is not None:
            if not os.path.exists(options.jsonfile):
                parser.error("Missing JSON input file '%s'" % options.jsonfile)

            # Load the config file.
            options.config = None
            try:
                with open(options.jsonfile, 'r') as cf:
                    options.config = json.load(cf)

            except Exception as ex:
                parser.error("Unable to load configuration JSON file: %s" % str(ex))

            options.compiler = options.config.get("compiler", None)
            options.library = options.config.get("library", None)
            options.device = options.config.get("device", None)
            options.toolchain = options.config.get("toolchain", None)

            if any (x is None for x in [options.library, options.device, options.compiler, options.toolchain]):
                parser.error("JSON file missing required options.")

        options.toolchain_fullpath = os.path.join(os.getcwd(), TOOLCHAIN_ROOT, options.toolchain)
        if not os.path.exists(options.toolchain_fullpath):
            parser.error("Device toolchain '%s' not found." % options.toolchain_fullpath)

        if not os.path.exists(options.compiler):
            parser.error("Compiler path '%s' not found." % options.compiler)

        print(YELLOW + "Building library with options:" + NORMAL)
        print(BLUE + "   library: " + NORMAL + "%s" % options.library)
        print(BLUE + "    device: " + NORMAL + "%s" % options.device)
        print(BLUE + " toolchain: " + NORMAL + "%s" % options.toolchain)
        print(BLUE + "  compiler: " + NORMAL + "%s" % options.compiler)
        print("")

        result = True

        if options.rebuild is True:
            result = clean(options)

        if result is True:
            if not os.path.exists(os.path.join(os.getcwd(), BUILD_ROOT)):
                result = generate(options)
            else:
                print(YELLOW + "Build directory exists; Makefile generation skipped.\r\n" + NORMAL)

        if result is True:
            result = build(options)

        if result is True:
            print(GREEN + "Build complete." + NORMAL)
        else:
            print(RED + "Build failed!" + NORMAL)

    except Exception as ex:
        print(RED + "\nBuild failed: %s" % str(ex) + NORMAL)
        print(traceback.format_exc())
        sys.exit(1)

    sys.exit(0)
