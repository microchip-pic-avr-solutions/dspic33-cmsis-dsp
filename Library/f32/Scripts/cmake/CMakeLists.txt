cmake_minimum_required(VERSION 3.30)

# ==============================================================================
# CMake Configuration for dspic33-cmsis-dsp Static Library
#
# This project builds a static DSP library of floating-point(f32) datatype and 
# (Q31) fixed-point datatype for dsPIC33 devices using Microchip XC-DSC 
# (xc-dsc-gcc) toolchain.
#
# The library contains optimized assembly and C implementations of
# CMSIS-DSP–style math, filtering, transform, and control functions.
# ==============================================================================

# ------------------------------------------------------------------------------
# Directory Layout
# ------------------------------------------------------------------------------
# All paths are relative to this CMakeLists.txt location

set(INCLUDE_DIR "../../../../Include")             # Public headers exposed to users
set(PRIVATE_INCLUDE_DIR "../../../../PrivateInclude") # Internal headers / ASM includes
set(SRC_DIR "../../../../Source")                  # DSP source implementations
set(UTILS_DIR "../../../../Utils")                 # Utility / support sources
set(LIBRARY_DIR "../../../")                    # Output directory for static library

# ------------------------------------------------------------------------------
# Project Settings
# ------------------------------------------------------------------------------
# Disable verbose makefile output for cleaner build logs
set(CMAKE_VERBOSE_MAKEFILE FALSE)

# ------------------------------------------------------------------------------
# Toolchain and Assembly Configuration
# ------------------------------------------------------------------------------
# CMake normally tries to test the compiler; this is disabled here because
# the XC-DSC toolchain does not behave like standard desktop compilers
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_C_COMPILER_WORKS TRUE)

# Explicitly configure the assembler to use Microchip's XC-DSC compiler
set(CMAKE_ASM_COMPILER "${COMPILER_ROOT_FOLDER}/bin/xc-dsc-gcc.exe")
set(CMAKE_ASM_COMPILER_ID "XC")
set(CMAKE_ASM_COMPILER_FORCED TRUE)

# Define the project (C language with ASM support)
project(${LIBRARY_NAME} C)

# Enable assembly language support
enable_language(ASM)

# Assembly flags:
#  - Target dsPIC device
#  - Include private headers needed by .s files
set(CMAKE_ASM_FLAGS " -mcpu='${MCPU_DEVICE}' -I'${PRIVATE_INCLUDE_DIR}'")

# ------------------------------------------------------------------------------
# Library Target Definition
# ------------------------------------------------------------------------------
# Build a static library containing all DSP functionality
add_library(${LIBRARY_NAME} STATIC)

# ------------------------------------------------------------------------------
# Include Directories
# ------------------------------------------------------------------------------
# PUBLIC  : Headers required by users of the library
# PRIVATE : Internal headers used only during compilation
target_include_directories(${LIBRARY_NAME}
    PUBLIC
        ${INCLUDE_DIR}
    PRIVATE
        ${PRIVATE_INCLUDE_DIR}
)

# ------------------------------------------------------------------------------
# Public Header Files
# ------------------------------------------------------------------------------
# These headers are not compiled, but are attached to the target so IDEs
# and downstream projects can easily discover the library interface
target_sources(${LIBRARY_NAME} PUBLIC
    ${INCLUDE_DIR}/arm_math.h
    ${INCLUDE_DIR}/mchp_common_tables.h
    ${INCLUDE_DIR}/mchp_dsp_config.h
    ${INCLUDE_DIR}/mchp_math.h
    ${INCLUDE_DIR}/mchp_math_types.h
    ${INCLUDE_DIR}/dsp/basic_math_functions.h
    ${INCLUDE_DIR}/dsp/complex_math_functions.h
    ${INCLUDE_DIR}/dsp/controller_functions.h
    ${INCLUDE_DIR}/dsp/filtering_functions.h
    ${INCLUDE_DIR}/dsp/matrix_functions.h
    ${INCLUDE_DIR}/dsp/statistics_functions.h
    ${INCLUDE_DIR}/dsp/support_functions.h
    ${INCLUDE_DIR}/dsp/transform_functions.h
    ${INCLUDE_DIR}/dsp/window_functions.h
)

# ------------------------------------------------------------------------------
# Private Assembly Include Files
# ------------------------------------------------------------------------------
# Common assembler macros, constants, and definitions
target_sources(${LIBRARY_NAME} PRIVATE
    ${PRIVATE_INCLUDE_DIR}/dspcommon.inc
)

# ------------------------------------------------------------------------------
# DSP Source Files
# ------------------------------------------------------------------------------
# The following sections group DSP functions by CMSIS-style categories.
# Most performance-critical routines are implemented in dsPIC assembly.

target_sources(${LIBRARY_NAME} PRIVATE

    # --------------------------------------------------------------------------
    # Basic Math Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/BasicMathFunctions/mchp_add_f32.s
    ${SRC_DIR}/BasicMathFunctions/mchp_dot_prod_f32.s
    ${SRC_DIR}/BasicMathFunctions/mchp_mult_f32.s
    ${SRC_DIR}/BasicMathFunctions/mchp_negate_f32.s
    ${SRC_DIR}/BasicMathFunctions/mchp_scale_f32.s
    ${SRC_DIR}/BasicMathFunctions/mchp_sub_f32.s

    # --------------------------------------------------------------------------
    # Complex Math Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/ComplexMathFunctions/mchp_cmplx_mag_squared_f32.s
    ${SRC_DIR}/ComplexMathFunctions/mchp_cmplx_mag_f32.s

    # --------------------------------------------------------------------------
    # Matrix Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/MatrixFunctions/mchp_mat_add_f32.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_init_f32.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_inverse_f32.c   # Implemented in C
    ${SRC_DIR}/MatrixFunctions/mchp_mat_mult_f32.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_scale_f32.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_sub_f32.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_trans_f32.s

    # --------------------------------------------------------------------------
    # Statistics Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/StatisticsFunctions/mchp_max_f32.s
    ${SRC_DIR}/StatisticsFunctions/mchp_mean_f32.s
    ${SRC_DIR}/StatisticsFunctions/mchp_min_f32.s
    ${SRC_DIR}/StatisticsFunctions/mchp_power_f32.s
    ${SRC_DIR}/StatisticsFunctions/mchp_std_f32.s
    ${SRC_DIR}/StatisticsFunctions/mchp_var_f32.s

    # --------------------------------------------------------------------------
    # Support Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/SupportFunctions/mchp_copy_f32.s

    # --------------------------------------------------------------------------
    # Transform Functions (FFT / RFFT)
    # --------------------------------------------------------------------------
    ${SRC_DIR}/TransformFunctions/mchp_bitreversal_f32.s
    ${SRC_DIR}/TransformFunctions/mchp_cfft_f32.s
    ${SRC_DIR}/TransformFunctions/mchp_rfft_fast_f32.s

    # --------------------------------------------------------------------------
    # Window Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/WindowFunctions/mchp_bartlett_f32.c
    ${SRC_DIR}/WindowFunctions/mchp_hamming_f32.c
    ${SRC_DIR}/WindowFunctions/mchp_hanning_f32.c

    # --------------------------------------------------------------------------
    # Controller Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/ControllerFunctions/mchp_pid_f32.s
    ${SRC_DIR}/ControllerFunctions/mchp_pid_init_f32.s
    ${SRC_DIR}/ControllerFunctions/mchp_pid_reset_f32.s

    # --------------------------------------------------------------------------
    # Filtering Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/FilteringFunctions/mchp_biquad_cascade_df2T_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_biquad_cascade_df2T_init_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_conv_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_correlate_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_decimate_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_decimate_init_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_init_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_interpolate_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_interpolate_init_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_lattice_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_lattice_init_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_iir_lattice_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_iir_lattice_init_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_init_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_norm_f32.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_norm_init_f32.s

    # --------------------------------------------------------------------------
    # Utility / Lookup Tables
    # --------------------------------------------------------------------------
    ${UTILS_DIR}/mchp_twid_f32.s
)

# ------------------------------------------------------------------------------
# Library Output Configuration
# ------------------------------------------------------------------------------
# Place the generated static library (.a) in the top-level library directory
set_target_properties(${LIBRARY_NAME} PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY ${LIBRARY_DIR}
)
