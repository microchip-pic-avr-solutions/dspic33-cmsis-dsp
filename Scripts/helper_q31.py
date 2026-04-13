import os
from config_q31 import *

try:
    import numpy as np
    from numpy.linalg import inv
except:
    print("Installing Numpy....")
    os.system("python -m pip install numpy")


# ============================================================
# Q31 Conversion Utilities
# ============================================================

def float_to_q31(x):
    """Convert float [-1.0, +1.0) to Q31 integer."""
    return np.int32(np.clip(np.round(x * (2**31)), -2**31, 2**31 - 1))


def q31_to_float(x):
    """Convert Q31 integer back to float."""
    return np.float64(x) / (2**31)


def float_array_to_q31(arr):
    """Convert an entire numpy array of floats to Q31 integers."""
    arr = np.asarray(arr, dtype=np.float64)
    return np.array([float_to_q31(v) for v in arr], dtype=np.int32)


def q31_array_to_float(arr):
    """Convert an entire numpy array of Q31 integers to floats."""
    arr = np.asarray(arr, dtype=np.int32)
    return np.array([q31_to_float(v) for v in arr], dtype=np.float64)


# Saturate float values to Q31 representable range [-1.0, ~+1.0)
def floatRound_q31(f):
    max_pos = 0x7FFFFFFF / 0x80000000  # ~0.9999999995
    if f > max_pos:
        f = max_pos
    elif f < -1.0:
        f = -1.0
    elif abs(f) < 1.0 / 0x80000000:
        f = 0.0
    return f


# Q31 hex string to float
def Q31(a):
    try:
        if "list" in str(type(a)):
            c = []
            for i in a:
                c.append(Q31(i))
            return c
    except:
        pass
    c = int(a, 16) / int("0x80000000", 16)
    if c >= 1:
        c = -1 * (int("0x100000000", 16) - int(a, 16)) / int("0x80000000", 16)
    return c


# Float to Q31 hex integer (for display)
def iQ31(f):
    f = floatRound_q31(f)
    if f >= 0:
        return int(np.round(f * 0x80000000)) & 0xFFFFFFFF
    else:
        return int(np.round(f * 0x80000000)) & 0xFFFFFFFF


# ============================================================
# C Array Formatting for Q31
# ============================================================

def c_array_q31(arr):
    """
    Format a numpy array of Q31 int32 values as a C-compatible string.
    Output format: hex literals like 0x7FFFFFFF, 0x80000000, etc.
    """
    arr = np.asarray(arr, dtype=np.int32)
    parts = []
    for i, val in enumerate(arr):
        # Convert to unsigned 32-bit for hex display
        uval = int(val) & 0xFFFFFFFF
        parts.append(f"0x{uval:08X}")
    return ", ".join(parts)


def c_array_q31_decimal(arr):
    """
    Format a numpy array of Q31 int32 values as decimal C-compatible string.
    """
    arr = np.asarray(arr, dtype=np.int32)
    parts = []
    for val in arr:
        parts.append(str(int(val)))
    return ", ".join(parts)


# ============================================================
# File Replacement (same pattern as f32 version)
# ============================================================

def replace_test_file(test_name, content):
    """Write content to the file mapped by test_name in test_to_file."""
    if test_name not in test_to_file:
        print(f"WARNING: '{test_name}' not found in test_to_file dictionary!")
        return

    rel_path = test_to_file[test_name]

    # Try mchp root first, then arm root
    for root in [mchp_test_root, arm_test_root]:
        full_path = os.path.join(root, rel_path)
        dir_path = os.path.dirname(full_path)
        if os.path.exists(dir_path):
            with open(full_path, "w") as f:
                f.write(content)
            print(f"  Written: {full_path}")
            return

    # If directories don't exist, create under mchp root
    full_path = os.path.join(mchp_test_root, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w") as f:
        f.write(content)
    print(f"  Created: {full_path}")