cmake_minimum_required(VERSION 3.30)

# ==============================================================================
# CMake Configuration for dspic33-cmsis-dsp Static Library
#
# This project builds a static DSP library of fixed-point (Q31) datatype
# for dsPIC33 devices using Microchip XC-DSC (xc-dsc-gcc) toolchain.
#
# The library contains optimized assembly and C implementations of
# CMSIS-DSP-style math, filtering, transform, and control functions.
# ==============================================================================

# ------------------------------------------------------------------------------
# Directory Layout
# ------------------------------------------------------------------------------
# All paths are relative to this CMakeLists.txt location

set(INCLUDE_DIR "../../../../Include")             # Public headers exposed to users
set(PRIVATE_INCLUDE_DIR "../../../../PrivateInclude") # Internal headers / ASM includes
set(SRC_DIR "../../../../Source")                  # DSP source implementations
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
    ${SRC_DIR}/BasicMathFunctions/mchp_add_q31.s
    ${SRC_DIR}/BasicMathFunctions/mchp_dot_prod_q31.s
    ${SRC_DIR}/BasicMathFunctions/mchp_mult_q31.s
    ${SRC_DIR}/BasicMathFunctions/mchp_negate_q31.s
    ${SRC_DIR}/BasicMathFunctions/mchp_scale_q31.s
    ${SRC_DIR}/BasicMathFunctions/mchp_sub_q31.s

    # --------------------------------------------------------------------------
    # Complex Math Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/ComplexMathFunctions/mchp_cmplx_mag_squared_q31.s

    # --------------------------------------------------------------------------
    # Common Tables (Q31 twiddle factors + init functions)
    # --------------------------------------------------------------------------
    ${SRC_DIR}/CommonTables/mchp_common_tables.c

    # --------------------------------------------------------------------------
    # Fast Math Functions (Q31 sqrt, needed by mchp_std_q31)
    # --------------------------------------------------------------------------
    ${SRC_DIR}/FastMathFunction/mchp_sqrt_q31.s

    # --------------------------------------------------------------------------
    # Matrix Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/MatrixFunctions/mchp_mat_add_q31.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_init_q31.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_inverse_q31.c   # Implemented in C
    ${SRC_DIR}/MatrixFunctions/mchp_mat_mult_q31.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_scale_q31.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_sub_q31.s
    ${SRC_DIR}/MatrixFunctions/mchp_mat_trans_q31.s

    # --------------------------------------------------------------------------
    # Statistics Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/StatisticsFunctions/mchp_max_q31.s
    ${SRC_DIR}/StatisticsFunctions/mchp_mean_q31.s
    ${SRC_DIR}/StatisticsFunctions/mchp_min_q31.s
    ${SRC_DIR}/StatisticsFunctions/mchp_power_q31.s
    ${SRC_DIR}/StatisticsFunctions/mchp_std_q31.s
    ${SRC_DIR}/StatisticsFunctions/mchp_var_q31.s

    # --------------------------------------------------------------------------
    # Support Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/SupportFunctions/mchp_copy_q31.s

    # --------------------------------------------------------------------------
    # Transform Functions (FFT / RFFT)
    # --------------------------------------------------------------------------
    ${SRC_DIR}/TransformFunctions/mchp_bitreversal_q31.s
    ${SRC_DIR}/TransformFunctions/mchp_cfft_q31.s
    ${SRC_DIR}/TransformFunctions/mchp_rfft_fast_q31.s

    # --------------------------------------------------------------------------
    # Window Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/WindowFunctions/mchp_bartlett_q31.c
    ${SRC_DIR}/WindowFunctions/mchp_hamming_q31.c
    ${SRC_DIR}/WindowFunctions/mchp_hanning_q31.c

    # --------------------------------------------------------------------------
    # Controller Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/ControllerFunctions/mchp_pid_q31.s
    ${SRC_DIR}/ControllerFunctions/mchp_pid_init_q31.s
    ${SRC_DIR}/ControllerFunctions/mchp_pid_reset_q31.s

    # --------------------------------------------------------------------------
    # Filtering Functions
    # --------------------------------------------------------------------------
    ${SRC_DIR}/FilteringFunctions/mchp_biquad_cascade_df1_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_biquad_cascade_df1_init_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_conv_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_correlate_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_decimate_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_decimate_init_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_init_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_interpolate_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_interpolate_init_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_lattice_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_fir_lattice_init_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_iir_lattice_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_iir_lattice_init_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_init_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_norm_q31.s
    ${SRC_DIR}/FilteringFunctions/mchp_lms_norm_init_q31.s
)

# ------------------------------------------------------------------------------
# Library Output Configuration
# ------------------------------------------------------------------------------
# Place the generated static library (.a) in the top-level library directory
set_target_properties(${LIBRARY_NAME} PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY ${LIBRARY_DIR}
)
