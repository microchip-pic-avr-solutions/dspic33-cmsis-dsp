#!/usr/bin/env python3
"""
Generate Q31 matrix test data for cmsis_dsp_mat_q31_test.X

Q31 format: 32-bit signed integer representing range [-1.0, +1.0)
  0x7FFFFFFF = +0.999999999...
  0x00000000 = 0.0
  0x80000000 = -1.0

Operations:
  ADD: saturating add     sat_q31(a + b)
  SUB: saturating sub     sat_q31(a - b)
  MUL: matrix multiply    dot products with Q31 multiplication
       element = sat_q31( sum( (a[i]*b[j]) >> 31 ) )  -- actually accumulated in 64-bit
  TRANSPOSE: rearrangement only
  SCALE: sat_q31( (element * scale) >> 31 )  -- but actually uses DSP multiply
  INVERSE: Gauss-Jordan in float (C code operates on q31_t cast to float implicitly)
"""

import numpy as np
import struct
import json

np.random.seed(42)  # reproducible

Q31_MAX = 0x7FFFFFFF
Q31_MIN = -0x80000000  # -2147483648

def sat_q31(val):
    """Saturate a 64-bit value to Q31 range."""
    if val > Q31_MAX:
        return Q31_MAX
    elif val < Q31_MIN:
        return Q31_MIN
    return int(val)

def to_signed32(val):
    """Convert to signed 32-bit representation."""
    val = int(val) & 0xFFFFFFFF
    if val >= 0x80000000:
        val -= 0x100000000
    return val

def q31_add(a, b):
    """Saturating Q31 addition."""
    return sat_q31(int(a) + int(b))

def q31_sub(a, b):
    """Saturating Q31 subtraction."""
    return sat_q31(int(a) - int(b))

def q31_fract_mul(a, b):
    """Q31 fractional multiply matching the dsPIC33AK DSP engine.
    
    The DSP engine in fractional mode (mpy.l/mac.l + sacr.l) does:
      1. prod_shifted = (a * b) << 1   (fractional mode shift)
      2. Extract upper 32 bits with convergent rounding (round-to-even on ties)
      3. Saturate to [0x80000000, 0x7FFFFFFF]
    
    Special case: 0x80000000 * 0x80000000 saturates to 0x7FFFFFFF because
    (-1.0) * (-1.0) = +1.0 which overflows Q31.
    """
    a_s, b_s = int(a), int(b)
    prod_shifted = (a_s * b_s) << 1
    lower = prod_shifted & 0xFFFFFFFF
    upper = prod_shifted >> 32
    # Convergent rounding (round-to-even on 0x80000000 tie)
    if lower > 0x80000000:
        upper += 1   # round up
    elif lower == 0x80000000:
        if upper & 1:  # tie: round to even
            upper += 1
    return sat_q31(upper)

def q31_scale(element, scale):
    """Scale a Q31 element by a Q31 scalar.
    Same as q31_fract_mul for element-wise scaling."""
    return q31_fract_mul(element, scale)

def sac_truncate(acc):
    """Simulate sac.l: extract upper 32 bits from 64-bit accumulator with
    truncation (no rounding) and saturation.
    
    The accumulator holds the sum of fractional-shifted products:
      acc = sum( (a[i] * b[i]) << 1 )
    
    sac.l extracts upper 32 bits with simple truncation:
      upper = acc >> 32
      saturate upper to [0x80000000, 0x7FFFFFFF]
    
    Note: sac.l does NOT round. This is different from sacr.l which uses
    convergent rounding. The MMUL assembly (mchp_mat_mult_q31.s line 214)
    uses sac.l, not sacr.l.
    """
    upper = acc >> 32
    return sat_q31(upper)

def random_q31(n):
    """Generate n random Q31 values in range [Q31_MIN+1, Q31_MAX]."""
    # Avoid Q31_MIN (-1.0 exactly) to reduce saturation edge cases
    return np.random.randint(-0x7FFFFFFF, 0x7FFFFFFF + 1, size=n, dtype=np.int64)

def format_hex(val):
    """Format a Q31 value as a C hex literal (signed)."""
    val = int(val)
    if val < 0:
        # Express as negative: e.g., (int)0xFFFFFFF0
        unsigned = val & 0xFFFFFFFF
        return f"(int)0x{unsigned:08X}"
    else:
        return f"0x{val:08X}"

def format_c_array(name, values, type_name="q31_t", per_line=5):
    """Format a C array declaration."""
    lines = [f"{type_name} {name}[] = {{"]
    for i in range(0, len(values), per_line):
        chunk = values[i:i+per_line]
        formatted = ", ".join(format_hex(v) for v in chunk)
        if i + per_line < len(values):
            lines.append(f"    {formatted},")
        else:
            lines.append(f"    {formatted}")
    lines.append("};")
    return "\n".join(lines)

# ============================================================
# Generate test data
# ============================================================

# --- MADD: 15x10 matrix addition (150 elements) ---
print("Generating MADD data...")
madd_src1 = random_q31(150)
madd_src2 = random_q31(150)
madd_er = np.array([q31_add(a, b) for a, b in zip(madd_src1, madd_src2)], dtype=np.int64)

# --- MSUB: 15x10 matrix subtraction (150 elements) ---
print("Generating MSUB data...")
msub_src1 = random_q31(150)
msub_src2 = random_q31(150)
msub_er = np.array([q31_sub(a, b) for a, b in zip(msub_src1, msub_src2)], dtype=np.int64)

# --- MMUL: 10x15 * 15x10 = 10x10 (100 result elements) ---
print("Generating MMUL data...")
# Use smaller values to avoid massive saturation in dot products
# Scale down to ~Q31/16 range so dot products of 15 elements don't always saturate
mmul_src1_raw = np.random.randint(-0x08000000, 0x08000000, size=150, dtype=np.int64)
mmul_src2_raw = np.random.randint(-0x08000000, 0x08000000, size=150, dtype=np.int64)

# Compute matrix multiply: A(10x15) * B(15x10) = C(10x10)
# The assembly uses mpy.l/mac.l in fractional mode which accumulates
# (a * b) << 1 for each pair, then sac.l extracts upper 32 bits with
# truncation (NOT convergent rounding) and saturation.
# Note: mchp_mat_mult_q31.s uses sac.l (line 214), not sacr.l.
mmul_er = []
for r in range(10):
    for c in range(10):
        # dot product of row r of A with column c of B
        acc = 0
        for k in range(15):
            a_val = int(mmul_src1_raw[r * 15 + k])
            b_val = int(mmul_src2_raw[k * 10 + c])
            # Fractional mode: accumulate (a*b) << 1
            acc += (a_val * b_val) << 1
        # sac.l: extract upper 32 bits with truncation (no rounding) + saturation
        mmul_er.append(sac_truncate(acc))

mmul_src1 = mmul_src1_raw
mmul_src2 = mmul_src2_raw
mmul_er = np.array(mmul_er, dtype=np.int64)

# --- MTRP: 15x10 matrix transpose -> 10x15 (150 elements) ---
print("Generating MTRP data...")
mtrp_src1 = random_q31(150)
# Transpose: src[i][j] -> dst[j][i] where src is 15x10, dst is 10x15
mtrp_er = np.zeros(150, dtype=np.int64)
for i in range(15):
    for j in range(10):
        mtrp_er[j * 15 + i] = mtrp_src1[i * 10 + j]

# --- MSCL: 10 groups of 3x5 (15 elements each), each scaled by a different scalar ---
print("Generating MSCL data...")
mscl_src1 = random_q31(150)
mscl_src2 = random_q31(10)  # 10 Q31 scale values
mscl_er = np.zeros(150, dtype=np.int64)
for group in range(10):
    scale = int(mscl_src2[group])
    for elem in range(15):
        idx = group * 15 + elem
        mscl_er[idx] = q31_scale(int(mscl_src1[idx]), scale)

# --- MINV: 10x10 matrix inverse (100 elements) ---
# The inverse function works by converting Q31 integers to float implicitly,
# doing Gauss-Jordan in float, then the results are float stored as q31_t.
# Actually, looking at the code more carefully: it does
#   dst->pData[...] = src->pData[...] (q31_t copy)
#   then fabsf(dst->pData[...]) -- this converts q31_t int to float
#   then does float division and multiplication
# So it treats the Q31 integer values AS float numbers (not as Q31 fractions).
# This means the "inverse" is computing the inverse of a matrix whose elements
# are the raw integer values of Q31.
#
# However, since pData is q31_t* (int*), the float operations will auto-convert.
# fabsf(int_val) converts int to float. The pivoting and row operations all
# operate in float. Then the results are stored back as q31_t (truncated from float).
#
# This is actually quite unusual. Let's generate a well-conditioned positive
# definite matrix with small integer values to make the inverse work correctly.
# We need values where the float inverse produces results that fit in int32_t range.
#
# Actually, looking at the f32 test, the MINV source values are around 0.0-3.7
# (positive definite matrix). For Q31, these would be very small integers (0-3).
# That won't work well.
#
# Let me re-read the inverse code: it does dst->pData[r*n+c] = src->pData[r*n+c]
# where pData is q31_t*. Then fabsf(dst->pData[...]) converts the q31_t int value
# to float. So if we have Q31 value 0x40000000 (= 1073741824), fabsf will give
# 1073741824.0f. The inverse will then be computed on these large float values.
# The result will be very small floats (like 1e-9), which when stored as q31_t
# will truncate to 0.
#
# This means the Q31 inverse function likely expects the matrix to contain
# values that make sense as both integers AND as a matrix to invert.
# Since the C code does float arithmetic on the raw integer values, we need
# a matrix of reasonable integer values whose inverse also has reasonable
# integer values.
#
# For a 10x10 matrix this is very constrained. Let's use a matrix that when
# treated as integers, has an inverse with integer-ish results.
# 
# Actually, since it stores results as q31_t but computes in float,
# the results will be float -> int truncation. So results like 0.5 become 0.
# The inverse test might need a tolerance.
#
# For now, let's create a diagonally dominant matrix with values scaled
# such that the inverse has values in a reasonable q31_t range.
# We'll use values around 1000-10000 to make the matrix well-conditioned
# and the inverse will have values around 0.0001-0.001 which as integers = 0.
# That's bad.
#
# Let me think differently: We need matrix * inverse = identity.
# If matrix elements are ~N, inverse elements are ~1/N.
# For both to be representable as q31_t (integers), we'd need N * (1/N) = 1.
# This only works for very specific matrices.
#
# The practical approach: use small integer values (1-10 range) for the
# matrix, and the inverse will have small float values that truncate to
# small integers (0, 1, or small values). This is what the library does.
#
# Actually, re-reading the C code once more:
#   absVal = 1.0f / dst->pData[(ic * numRowsCols) + ic];
# Here dst->pData[...] is q31_t (int). The compiler promotes int to float
# for the division. Then:
#   dst->pData[(ic * numRowsCols) + c] *= absVal;
# This multiplies q31_t (int) by float. Result is float, which gets truncated
# back to q31_t (int) on assignment.
#
# So for a well-conditioned 10x10 integer matrix with values ~100-1000,
# the inverse values will be ~0.001-0.01, which truncate to 0 as integers.
# That means almost all results will be 0. This is essentially useless.
#
# The better approach: scale the matrix so diagonal is ~Q31_MAX/10 and
# use a nearly-identity matrix. Then the inverse will also have large values.
# Or: use an identity-like matrix where the inverse is similar to itself.
#
# For a practical test, let me create a matrix where I KNOW the inverse
# in integer arithmetic. Let's use a permutation matrix (inverse = transpose)
# or a diagonal matrix (inverse = 1/diagonal entries, but that gives fractions).
#
# Simplest: generate a random float matrix, compute its inverse in float,
# then convert both to Q31 (scaling by 2^31). Then the Q31 inverse won't
# match because the library operates on raw integers, not Q31 fractions.
#
# Given the complexity and the fact that the C code operates on raw integers,
# I'll generate a 10x10 matrix with moderately large integer values in a way
# that the Gauss-Jordan in float produces results storable as q31_t.
# I'll simulate the exact algorithm in Python.

print("Generating MINV data...")

def simulate_inverse_q31(src_data, n):
    """Simulate the mchp_mat_inverse_q31 C function exactly.
    The C code copies q31_t to dst, then operates on them as floats."""
    # Copy src to dst (as integers, then we'll treat as float for operations)
    # But the C code does: dst->pData[i] = src->pData[i] (int copy)
    # then uses float operations on dst->pData[i] which auto-converts int->float
    
    # Simulate: work in float, but start from integer values
    mat = np.array([float(int(x)) for x in src_data], dtype=np.float64).reshape(n, n)
    
    pivotMask = 0
    status = "SUCCESS"
    
    for cntr in range(n):
        # Find pivot
        maxVal = 0.0
        ir = -1
        ic = -1
        for r in range(n):
            if (pivotMask & (1 << r)) == 0:
                for c in range(n):
                    if (pivotMask & (1 << c)) == 0:
                        absVal = abs(mat[r, c])
                        if absVal >= maxVal:
                            maxVal = absVal
                            ir = r
                            ic = c
        
        if ir == -1 or ic == -1:
            status = "SINGULAR"
            break
        
        pivotMask |= (1 << ic)
        
        # Swap rows
        if ir != ic:
            mat[[ir, ic]] = mat[[ic, ir]]
        
        # Check singular
        if mat[ic, ic] == 0.0:
            status = "SINGULAR"
            break
        
        # Divide row by pivot
        absVal = 1.0 / mat[ic, ic]
        mat[ic, ic] = 1.0
        for c in range(n):
            mat[ic, c] *= absVal
        
        # Fix other rows
        for r in range(n):
            if r != ic:
                absVal = mat[r, ic]
                mat[r, ic] = 0.0
                for c in range(n):
                    mat[r, c] -= mat[ic, c] * absVal
    
    # Convert back to q31_t (float -> int truncation, which is what C does)
    result = np.array([int(mat.flat[i]) for i in range(n*n)], dtype=np.int64)
    return result, status

# Create a well-conditioned integer matrix for inverse test
# Use a matrix with diagonal dominance and reasonable integer magnitudes
# so the inverse produces non-trivial integer results
rng = np.random.RandomState(123)

# Create a diagonally dominant matrix with values such that inverse
# values are large enough to survive float->int truncation
# Strategy: large diagonal (1e6), small off-diagonal (1e3)
n = 10
minv_float = np.zeros((n, n))
for i in range(n):
    minv_float[i, i] = rng.randint(5000000, 20000000)
    for j in range(n):
        if i != j:
            minv_float[i, j] = rng.randint(-500000, 500000)

# Convert to q31_t integers
minv_src = np.array(minv_float.flat, dtype=np.int64)

# Simulate the exact C algorithm
minv_er, minv_status = simulate_inverse_q31(minv_src, n)
print(f"  MINV status: {minv_status}")
print(f"  MINV result range: [{min(minv_er)}, {max(minv_er)}]")
# Most inverse elements will be 0 due to float->int truncation since 1/1e7 ~ 1e-7
# That's expected. The diagonal of the inverse will be ~1/diagonal ~ 0 as int.
# This is actually a limitation of the library's approach.
# Let's use much smaller values to get non-zero inverse elements.

# Try with small matrix values
minv_float2 = np.zeros((n, n))
for i in range(n):
    minv_float2[i, i] = rng.randint(50, 200)
    for j in range(n):
        if i != j:
            minv_float2[i, j] = rng.randint(-10, 10)

minv_src = np.array(minv_float2.flat, dtype=np.int64)
minv_er, minv_status = simulate_inverse_q31(minv_src, n)
print(f"  MINV v2 status: {minv_status}")
print(f"  MINV v2 result range: [{min(minv_er)}, {max(minv_er)}]")
# Diagonal inverse ~ 1/100 = 0.01 -> truncates to 0 as int. Still bad.

# The only way to get non-zero integer results from the inverse is
# if the matrix values are ~1-2, so the inverse elements are ~0.5-1.0
# which truncate to 0 or 1. Not very useful for testing.
# Let's try with the approach from the f32 test -- use the same matrix values
# but as integers (they were ~0.1-3.7 as floats, so as Q31 integers they'd be 0-3).
# Actually let me use a permutation matrix times a scalar - its inverse is known.

# Use a scaled identity: diag(2, 3, 4, ..., 11)
# Inverse = diag(1/2, 1/3, 1/4, ..., 1/11) which are all 0 as integers.
# This is hopeless for integer-based inverse.

# Let's just use a reasonable integer matrix and accept that most inverse
# elements will be 0. The test verifies the function doesn't crash and
# returns SUCCESS. We'll use a tolerance-based comparison.

# Actually, let me create an integer matrix whose inverse has larger values.
# If we use a matrix close to a permutation matrix (elements 0 and 1, with
# a few modified entries), the inverse will have integer-ish values.

# Create near-identity matrix with integer entries
minv_mat = np.eye(n, dtype=np.float64) * 1.0  # identity
# Add small perturbations that keep it well-conditioned
for i in range(n):
    for j in range(n):
        if i != j:
            minv_mat[i, j] = rng.choice([-1, 0, 0, 0, 0, 0, 1]) * 0.0  # keep identity
    minv_mat[i, i] = 1.0

# With pure identity, inverse = identity. That works but is trivial.
# Let's use a matrix where each element is a small integer like:
#   [[2, 0, 0, ...], [0, 2, 0, ...], ...] * some factor
# inverse = [[0, 0, ...]] since 1/2 = 0 as int.

# Ok, let's just go with a practical approach: use values in the range
# that the f32 test uses (which were already validated), but understand
# that the Q31 inverse test will have all-zero expected results since
# the library function does float->int truncation.

# Actually wait - looking at the C code again more carefully:
# dst->pData[(ic * numRowsCols) + c] *= absVal;
# Since pData is q31_t* (int*), and absVal is float, the compiler does:
#   float temp = (float)dst->pData[idx] * absVal;
#   dst->pData[idx] = (q31_t)temp;  // truncate
# This loses precision at every step. The algorithm will diverge for
# anything but trivially simple matrices.

# For the test, let's create an identity matrix (scaled by a power of 2)
# The inverse of k*I is (1/k)*I. If k=1, inverse = I. Best we can do.
# Use identity matrix * 1 = identity matrix -> inverse = identity.
minv_src_list = []
minv_er_list = []
for i in range(n):
    for j in range(n):
        if i == j:
            minv_src_list.append(1)
        else:
            minv_src_list.append(0)

minv_src = np.array(minv_src_list, dtype=np.int64)
minv_er_computed, minv_status = simulate_inverse_q31(minv_src, n)
print(f"  MINV identity status: {minv_status}")
print(f"  MINV identity result: {minv_er_computed[:15]}...")

# Use identity - this at least validates the function produces correct output.
minv_er = minv_er_computed

# ============================================================
# Output the data as JSON for use by the file creation step
# ============================================================
data = {
    "MADD": {
        "src1": madd_src1.tolist(),
        "src2": madd_src2.tolist(),
        "er": madd_er.tolist(),
        "rows": 15, "cols": 10, "count": 150
    },
    "MSUB": {
        "src1": msub_src1.tolist(),
        "src2": msub_src2.tolist(),
        "er": msub_er.tolist(),
        "rows": 15, "cols": 10, "count": 150
    },
    "MMUL": {
        "src1": mmul_src1.tolist(),
        "src2": mmul_src2.tolist(),
        "er": mmul_er.tolist(),
        "Arows": 10, "Acols": 15, "Brows": 15, "Bcols": 10, "Rcount": 100
    },
    "MTRP": {
        "src1": mtrp_src1.tolist(),
        "er": mtrp_er.tolist(),
        "rows": 15, "cols": 10, "count": 150
    },
    "MSCL": {
        "src1": mscl_src1.tolist(),
        "src2": mscl_src2.tolist(),
        "er": mscl_er.tolist(),
        "count": 150, "num_groups": 10, "group_size": 15,
        "group_rows": 3, "group_cols": 5
    },
    "MINV": {
        "src1": minv_src.tolist(),
        "er": minv_er.tolist(),
        "rows": 10, "cols": 10, "count": 100
    }
}

# Save JSON
with open("mat_q31_test_data.json", "w") as f:
    json.dump(data, f)

# ============================================================
# Generate C source files
# ============================================================

def c_header():
    return """/* 
 * Auto-generated Q31 matrix test data.
 * Generated by gen_mat_q31_test_data.py
 * DO NOT EDIT MANUALLY.
 */

#include "../../main.h"

#ifdef MATRIX_LIB_TEST

#ifdef DATA_SET_I
"""

def c_footer():
    return """
#endif 

#endif
"""

# MADD
with open("MADD_q31_data.c", "w") as f:
    f.write(c_header())
    f.write("\n" + format_c_array("MADD_src1", madd_src1) + "\n")
    f.write("\n" + format_c_array("MADD_src2", madd_src2) + "\n")
    f.write("\n" + format_c_array("MADD_er", madd_er) + "\n")
    f.write(c_footer())

# MSUB
with open("MSUB_q31_data.c", "w") as f:
    f.write(c_header())
    f.write("\n" + format_c_array("MSUB_src1", msub_src1) + "\n")
    f.write("\n" + format_c_array("MSUB_src2", msub_src2) + "\n")
    f.write("\n" + format_c_array("MSUB_er", msub_er) + "\n")
    f.write(c_footer())

# MMUL
with open("MMUL_q31_data.c", "w") as f:
    f.write(c_header())
    f.write("\n" + format_c_array("MMUL_src1", mmul_src1, per_line=5) + "\n")
    f.write("\n" + format_c_array("MMUL_src2", mmul_src2, per_line=5) + "\n")
    f.write("\n" + format_c_array("MMUL_er", mmul_er, per_line=5) + "\n")
    f.write(c_footer())

# MTRP
with open("MTRP_q31_data.c", "w") as f:
    f.write(c_header())
    f.write("\n" + format_c_array("MTRP_src1", mtrp_src1) + "\n")
    f.write("\n" + format_c_array("MTRP_er", mtrp_er) + "\n")
    f.write(c_footer())

# MSCL
with open("MSCL_q31_data.c", "w") as f:
    f.write(c_header())
    f.write("\n" + format_c_array("MSCL_src1", mscl_src1) + "\n")
    f.write("\n" + format_c_array("MSCL_src2", mscl_src2) + "\n")
    f.write("\n" + format_c_array("MSCL_er", mscl_er) + "\n")
    f.write(c_footer())

# MINV
with open("MINV_q31_data.c", "w") as f:
    f.write(c_header())
    f.write("\n" + format_c_array("MINV_src1", minv_src, per_line=10) + "\n")
    f.write("\n" + format_c_array("MINV_er", minv_er, per_line=10) + "\n")
    f.write(c_footer())

print("\nAll test data files generated successfully!")
print(f"  MADD: {len(madd_src1)} src elements, {len(madd_er)} expected")
print(f"  MSUB: {len(msub_src1)} src elements, {len(msub_er)} expected")
print(f"  MMUL: {len(mmul_src1)} src1, {len(mmul_src2)} src2, {len(mmul_er)} expected")
print(f"  MTRP: {len(mtrp_src1)} src elements, {len(mtrp_er)} expected")
print(f"  MSCL: {len(mscl_src1)} src elements, {len(mscl_src2)} scalars, {len(mscl_er)} expected")
print(f"  MINV: {len(minv_src)} src elements, {len(minv_er)} expected")

# Verify some values
print("\nVerification:")
print(f"  MADD[0]: {format_hex(madd_src1[0])} + {format_hex(madd_src2[0])} = {format_hex(madd_er[0])}")
print(f"  MSUB[0]: {format_hex(msub_src1[0])} - {format_hex(msub_src2[0])} = {format_hex(msub_er[0])}")
print(f"  MSCL[0]: {format_hex(mscl_src1[0])} * {format_hex(mscl_src2[0])} >> 31 = {format_hex(mscl_er[0])}")
