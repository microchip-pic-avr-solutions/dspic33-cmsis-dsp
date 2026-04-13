"""
Generate All Q31 Test Vectors
-----------------------------
Master script to generate all Q31 format test vectors for CMSIS DSP testing.
"""

import os
import random
from math import *
import cmath
import numpy
from helper_q31 import *
from fir_q31 import *
from fir_decimate_q31 import *
from fir_interpolate_q31 import *
from fir_lattice_q31 import *
from lms_q31 import *
from lms_norm_q31 import *
from iir_lattice_q31 import *
from iir_biquad_cascade_df1_q31 import *
from pid_q31 import *
from statistics_q31 import *

print("=" * 60)
print("  CMSIS DSP Q31 Test Vector Generator")
print("=" * 60)

# Run all Q31 test vector generators
fir_q31()
fir_decim_q31()
fir_inter_q31()
fir_lattice_q31()
lms_q31()
lms_norm_q31()
iir_lattice_q31()
iir_canonic_q31()
pid_q31()
statistics_q31()

print("\n" + "=" * 60)
print("  End of Q31 Execution")
print("=" * 60)
