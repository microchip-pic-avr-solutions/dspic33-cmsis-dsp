#include <xc.h>
#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include "main.h"

/**
 * @brief : Compares expected vs observed results and return FAIL if mismatch found in compared data.
 *          Function also prints the index,expected and observed results in case of Failure.
 * @param numelem
 * @param Observed_result
 * @param Expected_result
 * @return BOOL (PASS/FAIL) Depending on comparision result.
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

BOOL floatCompare(float tolerance_in_percentage, int numelem, float* Observed_result, float* Expected_result) {
    if (0.0 == tolerance_in_percentage)
        tolerance_in_percentage = 0.001;
    BOOL FailureFlag = PASS;
    printf("\r\n Validating results : Tolerance = %f %%", (float) tolerance_in_percentage);
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

void PMU_Initialize(){
    HPCCONbits.ON = 0;                  // Turn-off PMU
    HPCCONbits.CLR = 1;                 // Clear PMU
    HPSEL0bits.SELECT0 = 1;             // Set PMU to capture clock cycles  
    HPSEL0bits.SELECT1 = 2;             // Set PMU to capture instruction fetched
    HPSEL0bits.SELECT2 = 3;             // Set PMU to capture  cpu_to_pmu_signals.w_stage.fpu_wr_stall
    HPSEL0bits.SELECT3 = 4;             // Set PMU to capture cpu_to_pmu_signals.w_stage.wr_stall
	
	HPSEL1bits.SELECT4 = 6;              //  cpu_to_pmu_signals.hzd.hzd_stall_a_stage 
    HPSEL1bits.SELECT5 = 10;             // cpu_to_pmu_signals.a_stage.rd_stall
    HPSEL1bits.SELECT6 = 11;             // cpu_to_pmu_signals.a_stage.stalled
    HPSEL1bits.SELECT7 = 13;             //  cpu_to_pmu_signals.f_stage.pmem_rd_stall

}
