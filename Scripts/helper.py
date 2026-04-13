import os
from config import *

try:
    import numpy as np
    from numpy.linalg import inv
except:
    print("Installing Numpy....")
    os.system("python -m pip install numpy")

def float_to_q31(x):
    return np.int32(np.clip(x * (2**31), -2**31, 2**31 - 1))

def q31_to_float(x):
    return x / float(2**31)
    
# Hex_int to str
def hTs(a):
    try:
        v = []
        if type(a[0]) == complex:
            for i in a:
                v.append(complex((int(i.real)), (int(i.imag))))
        elif "list" in str(type(a)[0]):
            for i in a:
                v.append(hTs(i))
    except:
        v = hex(a)
    return v


# Q31_hex_str to float
def Q31(a):
    try:
        if "list" in str(type(a)[0]):
            c = []
            for i in a:
                c.append(Q31(i))
    except:
        c = int(a, 16) / int("0x80000000", 16)
        if c >= 1:
            c = -1 * (int("0x100000000", 16) - int(a, 16)) / int("0x80000000", 16)
    return c
    
# Float to Q31_hex_str
def iQ31(a):
    try:
        if "list" in str(type(a)[0]):
            v = []
            for i in a:
                v.append(iQ31(i))
    except:
        if a > int("0x7FFFFFFF", 16) / int("0x80000000", 16):
            v = "0x7FFFFFFF"
        elif a <= -1:
            v = "0x80000000"
        elif (a < 1 / 0x80000000 and a > 0):
            v = "0x00000000"
        elif (a > -1 / 0x80000000 and a < 0):
            v = "0xFFFFFFFF"
        elif a >= 0:
            v = hex(int(round(a * float(int("0x80000000", 16)), 0)))
        elif a > -1:
            v = hex(int(int("0x100000000", 16) + round(a * float(int("0x80000000", 16)), 0)))

    return v

# Funtion to saturate float values to Q31 limit.
def floatRound(f):
    if f > int("0x7FFFFFFF", 16) / int("0x80000000", 16):
        f = int("0x7FFFFFFF", 16) / int("0x80000000", 16)
    elif f < -1:
        f = -1
    elif (f < 0x1 / 0x80000000 and f > 0) or (f > -0x1 / 0x80000000 and f < 0):
        f = 0
    return f

# Format a Python array in C format such that it can be copy-pasted directly into C source.
def c_array(python_array):
    array_str = "{"

    array_len = len(python_array)

    for i in range(array_len):
        elem = python_array[i]

        if isinstance(elem, str):
            array_str += elem
        elif isinstance(elem, float):
            array_str += str(elem)
        elif isinstance(elem, list) or isinstance(elem, np.ndarray):
            array_str += "{"
            for j in range(len(elem)):
                elemj = elem[j]
                if isinstance(elemj, str):
                    array_str += elemj
                elif isinstance(elemj, list):
                    pass  # Reserved
                elif isinstance(elemj, float):
                    array_str += str(elemj)
                else:
                    # To do: Zero-extend?
                    array_str += hex(
                        elemj & 0xFFFFFFFF)  # Note: Negative numbers frequently appear with a minus sign, believe the AND puts them in unsigned format?
                    # May need to revisit this if it doesn't really work...
                if (j < len(elem) - 1):
                    array_str += ", "
            array_str += "}"

        elif isinstance(elem, int):
            array_str += hex(
                elem & 0xFFFFFFFF)  # Note: Negative numbers frequently appear with a minus sign, believe the AND puts them in unsigned format?
        else:
            array_str += hex(elem)  #
        # else:
        # To do: Zero-extend?
        # array_str += hex(elem & 0xFFFFFFFF) #Note: Negative numbers frequently appear with a minus sign, believe the AND puts them in unsigned format?
        # May need to revisit this if it doesn't really work...
        if (i < array_len - 1):
            array_str += ", "

    array_str += "}"

    return array_str
    
disclaimer = """/*
© [2026] Microchip Technology Inc. and its subsidiaries.

    Subject to your compliance with these terms, you may use Microchip 
    software and any derivatives exclusively with Microchip products. 
    You are responsible for complying with 3rd party license terms  
    applicable to your use of 3rd party software (including open source  
    software) that may accompany Microchip software. SOFTWARE IS ?AS IS.? 
    NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS 
    SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,  
    MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT 
    WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE, 
    INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY 
    KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF 
    MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE 
    FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S 
    TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT 
    EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR 
    THIS SOFTWARE.
*/"""
    

def replace_test_file(test_name, new_data):
    new_data = new_data.replace("<<INSERT_DISCLAIMER_HERE>>", str(disclaimer))
    mchp_test_file_path = mchp_test_root + test_to_file[test_name]
    arm_test_file_path = arm_test_root + test_to_file[test_name]
    if "<<INSERT_" in new_data or "_HERE>>" in new_data:
        raise Exception("Unsubtituted text found, new file isn't valid. Contents: \n " + new_data)
    with open(mchp_test_file_path, 'w') as f:
        f.write(new_data)
    with open(arm_test_file_path, 'w') as f:
        f.write(new_data)
    


def check_test_file(test_name):
    test_file_path = test_root + test_to_file[test_name]
    with open(test_file_path, 'r') as f:
        return f.readlines()
    


    
