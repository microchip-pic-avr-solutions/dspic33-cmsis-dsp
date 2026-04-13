import os
import random
from math import *
import cmath
import numpy
from helper import *
from fir_f32 import *
from fir_decimate_f32 import *
from fir_interpolate_f32 import *
from fir_lattice_f32 import *
from lms_f32 import *
from lms_norm_f32 import *
from iir_lattice_f32 import *
from iir_biquad_cascade_df2T_f32 import *
from pid_f32 import *

# Test functions updated to randomize the files in the project folder.

fir_f32()
fir_decim_f32()
fir_inter_f32()
fir_lattice_f32()
lms_f32()
lms_norm_f32()
iir_lattice_f32()
iir_lattice_f32()
iir_canonic_f32()
pid_f32()

print(" \n\n End of Execution")