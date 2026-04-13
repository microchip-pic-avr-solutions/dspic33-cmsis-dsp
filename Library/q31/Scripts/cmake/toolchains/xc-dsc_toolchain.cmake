# Tell CMake that we are building for a non-host (embedded) system
# "Generic" is typically used for bare-metal microcontrollers
set(CMAKE_SYSTEM_NAME Generic)

# Control how CMake searches for tools and libraries:
# - Programs (like executables) are found on the host system
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# - Libraries are searched only inside the toolchain root
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)

# - Header files are searched only inside the toolchain root
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# Root directory of the XC-DSC compiler installation
set(CMAKE_FIND_ROOT_PATH "${COMPILER_ROOT_FOLDER}")

# Path to the XC-DSC C compiler executable
set(CMAKE_C_COMPILER "${COMPILER_ROOT_FOLDER}/bin/xc-dsc-gcc.exe")


# -------------------------------------------------------------------
# Compiler option groups
# -------------------------------------------------------------------

# Select the target dsPIC device (passed in as MCPU_DEVICE)
# Example: -mcpu=33EP256MU806
set(MCPU_CONFIG "-mcpu=${MCPU_DEVICE}")

# Generate dependency files for Make/Ninja
# -MP   : Add phony targets to avoid dependency errors
# -MMD  : Generate dependencies excluding system headers
# -MF   : Specify dependency file name (CMake fills this in)
set(LINKING_CONFIG "-MP -MMD -MF")

# Memory model selection:
# -msmall-code   : Assume code fits in small memory space
# -msmall-data   : Assume data fits in small memory space
# -msmall-scalar : Optimize scalar accesses for small memory
# These reduce code size and improve performance on dsPICs
set(MEMORY_MODEL_CONFIG "-msmall-code -msmall-data -msmall-scalar")

# Warning configuration:
# -Wall          : Enable common compiler warnings
# -msfr-warn=on  : Warn on unsafe or improper SFR access
set(WARNING_CONFIG "-Wall -msfr-warn=on")

# Optimization level:
# -Os : Optimize for minimum code size (common for embedded)
set(OPTIMIZATION_CONFIG "-Os")

# Smart I/O:
# -msmart-io=1 : Optimize stdio functions (printf, etc.)
# by removing unused formatting code
set(SMART_IO_CONFIG "-msmart-io=1")

# Output format:
# -omf=elf : Generate ELF object files (required for most tools)
set(ELF_CONFIG "-omf=elf")

# -------------------------------------------------------------------
# Combine all compiler flags
# -------------------------------------------------------------------

# -mno-file :
# Prevents embedding the full build path into object files,
# improving reproducibility and keeping binaries smaller
set(CMAKE_C_FLAGS "${MCPU_CONFIG} ${LINKING_CONFIG} ${MEMORY_MODEL_CONFIG} ${WARNING_CONFIG} ${OPTIMIZATION_CONFIG} ${SMART_IO_CONFIG} ${ELF_CONFIG} -mno-file")
