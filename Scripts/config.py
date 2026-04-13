import os

mchp_test_root = os.path.join(os.getcwd() + "/../Testing/cmsis_mchp_dsp_api/")
arm_test_root = os.path.join(os.getcwd() + "/../Testing/cmsis_arm_dsp_api/")
    
# Dictionary to get the path to the file to modify for each test

test_to_file = {
    #filter tests
    "fir_f32_test_inputs": "cmsis_dsp_fir_test.X/TestFilterLibraries/FIR/fir_f32_test_inputs.c",
    "fir_f32_test_header": "cmsis_dsp_fir_test.X/TestFilterLibraries/FIR/fir_f32_test.h",
    
    "fir_decim_f32_test_inputs": "cmsis_dsp_fir_decim_test.X/TestFilterLibraries/FIR/fir_decim_f32_test_inputs.c",
    "fir_decim_f32_test_header": "cmsis_dsp_fir_decim_test.X/TestFilterLibraries/FIR/fir_decim_f32_test.h",
    
    "fir_inter_f32_test_inputs": "cmsis_dsp_fir_inter_test.X/TestFilterLibraries/FIR/fir_inter_f32_test_inputs.c",
    "fir_inter_f32_test_header": "cmsis_dsp_fir_inter_test.X/TestFilterLibraries/FIR/fir_inter_f32_test.h",
    
    "fir_lattice_f32_test_inputs": "cmsis_dsp_fir_lattice_test.X/TestFilterLibraries/FIR/fir_lattice_f32_test_inputs.c",
    "fir_lattice_f32_test_header": "cmsis_dsp_fir_lattice_test.X/TestFilterLibraries/FIR/fir_lattice_f32_test.h",
    
    "fir_lms_f32_test_inputs": "cmsis_dsp_lms_test.X/TestFilterLibraries/LMS/fir_lms_f32_test_inputs.c",
    "fir_lms_f32_test_header": "cmsis_dsp_lms_test.X/TestFilterLibraries/LMS/fir_lms_f32_test.h",\
    
    "fir_lms_norm_f32_test_inputs": "cmsis_dsp_lms_norm_test.X/TestFilterLibraries/LMS/fir_lms_norm_f32_test_inputs.c",
    "fir_lms_norm_f32_test_header": "cmsis_dsp_lms_norm_test.X/TestFilterLibraries/LMS/fir_lms_norm_f32_test.h",

    "iir_lattice_f32_test_inputs": "cmsis_dsp_iir_lattice_test.X/TestFilterLibraries/IIR/iir_lattice_f32_test_inputs.c",
    "iir_lattice_f32_test_header": "cmsis_dsp_iir_lattice_test.X/TestFilterLibraries/IIR/iir_lattice_f32_test.h",
    
    "iir_canonic_f32_test_inputs": "cmsis_dsp_biquad_cascade_df2T_test.X/TestFilterLibraries/IIR/biquad_cascade_df2T_f32_test_inputs.c",
    "iir_canonic_f32_test_header": "cmsis_dsp_biquad_cascade_df2T_test.X/TestFilterLibraries/IIR/biquad_cascade_df2T_f32_test.h",

    "pid_f32_test_inputs": "cmsis_dsp_pid_test.X/TestControlLibraries/PID/pid_f32_test_inputs.c",
    "pid_f32_test_header": "cmsis_dsp_pid_test.X/TestControlLibraries/PID/pid_f32_test.h",

}