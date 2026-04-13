import os

# Root paths for Q31 tests
mchp_test_root = os.path.join(os.getcwd(), "..", "Testing", "cmsis_mchp_dsp_api")
arm_test_root = os.path.join(os.getcwd(), "..", "Testing", "cmsis_arm_dsp_api")

# Dictionary to get the path to the file to modify for each Q31 test
test_to_file = {
    # Filter tests
    "fir_q31_test_inputs": "cmsis_dsp_fir_q31_test.X/TestFilterLibraries/FIR/fir_q31_test_inputs.c",
    "fir_q31_test_header": "cmsis_dsp_fir_q31_test.X/TestFilterLibraries/FIR/fir_q31_test.h",

    "fir_decim_q31_test_inputs": "cmsis_dsp_fir_decim_q31_test.X/TestFilterLibraries/FIR/fir_decim_q31_test_inputs.c",
    "fir_decim_q31_test_header": "cmsis_dsp_fir_decim_q31_test.X/TestFilterLibraries/FIR/fir_decim_q31_test.h",

    "fir_inter_q31_test_inputs": "cmsis_dsp_fir_inter_q31_test.X/TestFilterLibraries/FIR/fir_inter_q31_test_inputs.c",
    "fir_inter_q31_test_header": "cmsis_dsp_fir_inter_q31_test.X/TestFilterLibraries/FIR/fir_inter_q31_test.h",

    "fir_lattice_q31_test_inputs": "cmsis_dsp_fir_lattice_q31_test.X/TestFilterLibraries/FIR/fir_lattice_q31_test_inputs.c",
    "fir_lattice_q31_test_header": "cmsis_dsp_fir_lattice_q31_test.X/TestFilterLibraries/FIR/fir_lattice_q31_test.h",

    "fir_lms_q31_test_inputs": "cmsis_dsp_lms_q31_test.X/TestFilterLibraries/LMS/fir_lms_q31_test_inputs.c",
    "fir_lms_q31_test_header": "cmsis_dsp_lms_q31_test.X/TestFilterLibraries/LMS/fir_lms_q31_test.h",

    "fir_lms_norm_q31_test_inputs": "cmsis_dsp_lms_norm_q31_test.X/TestFilterLibraries/LMS/fir_lms_norm_q31_test_inputs.c",
    "fir_lms_norm_q31_test_header": "cmsis_dsp_lms_norm_q31_test.X/TestFilterLibraries/LMS/fir_lms_norm_q31_test.h",

    "iir_lattice_q31_test_inputs": "cmsis_dsp_iir_lattice_q31_test.X/TestFilterLibraries/IIR/iir_lattice_q31_test_inputs.c",
    "iir_lattice_q31_test_header": "cmsis_dsp_iir_lattice_q31_test.X/TestFilterLibraries/IIR/iir_lattice_q31_test.h",

    "iir_canonic_q31_test_inputs": "cmsis_dsp_biquad_cascade_df1_q31_test.X/TestFilterLibraries/IIR/biquad_cascade_df1_q31_test_inputs.c",
    "iir_canonic_q31_test_header": "cmsis_dsp_biquad_cascade_df1_q31_test.X/TestFilterLibraries/IIR/biquad_cascade_df1_q31_test.h",

    # Control tests
    "pid_q31_test_inputs": "cmsis_dsp_pid_q31_test.X/TestControlLibraries/PID/pid_q31_test_inputs.c",
    "pid_q31_test_header": "cmsis_dsp_pid_q31_test.X/TestControlLibraries/PID/pid_q31_test.h",

    # Statistics tests
    "vmax_q31_test_inputs": "cmsis_dsp_sta_q31_test.X/TestStatisticsLibraries/Maximum/VMAX_q31_test_inputs.c",
    "vmin_q31_test_inputs": "cmsis_dsp_sta_q31_test.X/TestStatisticsLibraries/Minimum/VMIN_q31_test_inputs.c",
    "vmean_q31_test_inputs": "cmsis_dsp_sta_q31_test.X/TestStatisticsLibraries/Mean/VMEAN_q31_test_inputs.c",
    "vpow_q31_test_inputs": "cmsis_dsp_sta_q31_test.X/TestStatisticsLibraries/Power/VPOW_q31_test_inputs.c",
    "vvar_q31_test_inputs": "cmsis_dsp_sta_q31_test.X/TestStatisticsLibraries/Variance/VVAR_q31_test_inputs.c",
    "vstd_q31_test_inputs": "cmsis_dsp_sta_q31_test.X/TestStatisticsLibraries/Standard_Deviation/VSTD_q31_test_inputs.c",

    # FFT tests
    "fft_q31_test_inputs": "cmsis_dsp_fft_q31_test.X/TestFFTLibraries/FFT/FFT_q31_test_inputs.c",
    "ifft_q31_test_inputs": "cmsis_dsp_fft_q31_test.X/TestFFTLibraries/IFFT/IFFT_q31_test_inputs.c",
    "rfft_q31_test_inputs": "cmsis_dsp_fft_q31_test.X/TestFFTLibraries/RFFT/RFFT_q31_test_inputs.c",
    "irfft_q31_test_inputs": "cmsis_dsp_fft_q31_test.X/TestFFTLibraries/IRFFT/IRFFT_q31_test_inputs.c",
}
