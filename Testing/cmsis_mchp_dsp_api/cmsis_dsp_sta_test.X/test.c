/**
;*****************************************************************************
;                                                                            *
;                       Software License Agreement                           *
;*****************************************************************************
;*****************************************************************************
;� [2026] Microchip Technology Inc. and its subsidiaries.                    *
;                                                                            *
;   Subject to your compliance with these terms, you may use Microchip       *
;   software and any derivatives exclusively with Microchip products.        *
;   You are responsible for complying with 3rd party license terms            *
;   applicable to your use of 3rd party software (including open source       *
;   software) that may accompany Microchip software. SOFTWARE IS ?AS IS.?     *
;   NO WARRANTIES, WHETHER EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS       *
;   SOFTWARE, INCLUDING ANY IMPLIED WARRANTIES OF NON-INFRINGEMENT,           *
;   MERCHANTABILITY, OR FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT         *
;   WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,             *
;   INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY          *
;   KIND WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF          *
;   MICROCHIP HAS BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE          *
;   FORESEEABLE. TO THE FULLEST EXTENT ALLOWED BY LAW, MICROCHIP?S            *
;   TOTAL LIABILITY ON ALL CLAIMS RELATED TO THE SOFTWARE WILL NOT            *
;   EXCEED AMOUNT OF FEES, IF ANY, YOU PAID DIRECTLY TO MICROCHIP FOR         *
;   THIS SOFTWARE.                                                            *
;*****************************************************************************
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "mchp_math_types.h"
#include "main.h"

/**
 * @brief : Compares expected vs observed results and return FAIL if mismatch found in compared data.
 *          Function also prints the index,expected and observed results in case of Failure.
 * @param numelem
 * @param Observed_result
 * @param Expected_result
 * @return BOOL (PASS/FAIL) Depending on comparison result.
 */


BOOL fractCompare(int tolerance /* = 0 */, int numelem, fractional* Observed_result, fractional* Expected_result) {
    BOOL FailureFlag = PASS;
    uint32_t averageDifference = 0;
    if (tolerance != 0)
        printf("\r\n Compare Tolerance = 0x%X", tolerance);
    for (int index = 0; index < numelem; index++) {
        averageDifference += abs(Observed_result[index] - Expected_result[index]);
        if (Observed_result[index] != Expected_result[index]) {
            if (tolerance >= abs(Observed_result[index] - Expected_result[index]))
                continue;
            printf(RED"\r\n index = %d :: Expected = 0x%08X :: Observed = 0x%08X :: Difference = 0x%X"RESET_COLOR, (unsigned int) index, (unsigned int) Expected_result[index], (unsigned int) Observed_result[index], (unsigned int) abs(Observed_result[index] - Expected_result[index]));
            FailureFlag = FAIL;
        }
    }
    averageDifference /= numelem;
    printf("\r\n Average Deviation value = 0x%08lX", averageDifference);
    return (FailureFlag);
}

/**
 * @brief : Compares expected vs observed results and return FAIL if mismatch found in compared data.
 *          Function also prints the index,expected and observed results in case of Failure.
 * @param numelem
 * @param Observed_result
 * @param Expected_result
 * @return BOOL (PASS/FAIL) Depending on comparison result.
 */

BOOL floatCompare(float tolerance_in_percentage, int numelem, float32_t* Observed_result, float32_t* Expected_result) {
    if (0.0 == tolerance_in_percentage)
        tolerance_in_percentage = 0.001;
    BOOL FailureFlag = PASS;
    for (int index = 0; index < numelem; index++) {
        if (0 == Expected_result[index]) {
            if (tolerance_in_percentage < fabs(Observed_result[index])) {
                printf(RED"\r\n index = %d :: Expected = %f :: Observed = %f Percentage_error = %f %% "RESET_COLOR, index, (Expected_result[index]), (Observed_result[index]), fabs(100 * (Expected_result[index] - Observed_result[index]) / Expected_result[index]));
                FailureFlag = FAIL;
            }
        } else if (tolerance_in_percentage < fabs(100 * (Expected_result[index] - Observed_result[index]) / Expected_result[index])) {
            printf(RED"\r\n index = %d :: Expected = %f :: Observed = %f Percentage_error = %f %% "RESET_COLOR, index, (Expected_result[index]), (Observed_result[index]), fabs(100 * (Expected_result[index] - Observed_result[index]) / Expected_result[index]));
            FailureFlag = FAIL;
        }
    }
    return (FailureFlag);
}

void setup_PMU() {
    HPCCONbits.ON = 0; // Turn-off PMU
    HPCCONbits.CLR = 1; // Clear PMU
    HPSEL0bits.SELECT0 = 1; // Set PMU to capture clock cycles  
    HPSEL0bits.SELECT1 = 2; // Set PMU to capture instruction fetched
    HPSEL0bits.SELECT2 = 3; // Set PMU to capture  cpu_to_pmu_signals.w_stage.fpu_wr_stall
    HPSEL0bits.SELECT3 = 4; // Set PMU to capture cpu_to_pmu_signals.w_stage.wr_stall

    HPSEL1bits.SELECT4 = 6; //  cpu_to_pmu_signals.hzd.hzd_stall_a_stage 
    HPSEL1bits.SELECT5 = 10; // cpu_to_pmu_signals.a_stage.rd_stall
    HPSEL1bits.SELECT6 = 11; // cpu_to_pmu_signals.a_stage.stalled
    HPSEL1bits.SELECT7 = 13; //  cpu_to_pmu_signals.f_stage.pmem_rd_stall

}
