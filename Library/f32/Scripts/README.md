![Microchip logo](https://raw.githubusercontent.com/wiki/Microchip-MPLAB-Harmony/Microchip-MPLAB-Harmony.github.io/images/microchip_logo.png)

# dspic33-cmsis-dsp Source Files Repository
This repository contains source files for the dspic33-cmsis-dsp. CMake is used to build the source into a library for use within MPLAB® X projects.

## Building the dspic33-cmsis-dsp Library
To build the library, the following must be installed:

* make
* CMake
* Python (3.10 or later)
* Microchip XC-DSC (version 3.21 or later)

### Installing for Builds in Windows
The packages can be found at these links:
* [make (through Cygwin installer)](https://www.cygwin.com/install.html)
* [CMake](https://github.com/Kitware/CMake/releases)
* [Python 3.10 or later](https://www.python.org)
* [Microchip XC-DSC](https://www.microchip.com/en-us/tools-resources/develop/mplab-xc-compilers/xc-dsc#downloads)

### Installing for Builds in Linux
For Linux, the make, CMake and Python installers are installed with the relevant package manager.
* [Microchip XC-DSC](https://www.microchip.com/en-us/tools-resources/develop/mplab-xc-compilers/xc-dsc#downloads)

### Executing the Build
Once the prerequisites are installed, open a Command prompt or Unix terminal and navigate to the root of the repository.<br>
Then, launch the `buildLibrary_f32.py` script with the desired arguments:

    usage: buildLibrary_f32.py [-h] [-j JSONFILE] [-r] [-q] [-l LIBRARY]
                           [-d DEVICE] [-t TOOLCHAIN] [-c COMPILER]

    options:
      -h, --help            show this help message and exit
      -j JSONFILE, --jsonfile JSONFILE
                            JSON file with build configuration
      -r, --rebuild         run a clean build (remove artifacts)
      -q, --quiet           run a quiet build (no make command output)
      -l LIBRARY, --library LIBRARY
                            library file name
      -d DEVICE, --device DEVICE
                            MCPU device flag
      -t TOOLCHAIN, --toolchain TOOLCHAIN
                            toolchain file to use
      -c COMPILER, --compiler COMPILER
                            path to compiler

A JSON file that provides the library, device, toolchain, and compiler parameters can be found in the `.\json` directory.<br>
Update this file as needed.

## Example Parameters
### JSON input
    python buildLibrary_f32.py -j json\libcmsis-dsp-dspic33-elf-f32.json

### Parameterized Input (Defaults, Build)
    python buildLibrary_f32.py

### Parameterized Input (Defaults, Rebuild)
    python buildLibrary_f32.py -r

### Parameterized Input (All)
    python buildLibrary_f32.py -l cmsis-dsp-dspic33-elf -d GENERIC-32DSP-AK -t xc-dsc_toolchain.cmake -c "C:\Program Files\Microchip\xc-dsc\v3.31" -r -q
