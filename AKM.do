********************************************************************************
* AKM reads in RAIS data with selection criteria, conducts a final preparation 
* of the data, outsheets it to for use by AKM.m, and calls matlab to execute the 
* AKM estimation in AKM.m. This procedure is done both for all workers in the RAIS
* and for workers in the RAIS that are in firms covered by PIA.
*
* Alvarez, Engbom and Moser
* First created: 10/10/2014
* Last edited: 06/24/2017
********************************************************************************
set more off

* Variables to output to MATLAB.
local varlist_rais "wage persid empid age ano"
local varlist_pia "wage persid empid age ano va_pw"

if $dataset == 1 {
	disp "****************************************************************************************************************"
	disp "				*** RUNNING AKM ON FULL RAIS ***"
	disp "****************************************************************************************************************"
	
	global akm_start = $minyear
	global akm_end = $akm_start + $periodlength
	local akm = 1
	while `akm' <= $nperiods {
		disp "********** AKM routine for years ${akm_start} - ${akm_end} **********"
		forvalues yyyy = $akm_start/$akm_end {
			disp "* Year `yyyy'"
			display _newline(3)
			if `yyyy' == $akm_start qui use "$SAVE_CLEANED/selection`yyyy'", clear
			else qui append using "$SAVE_CLEANED/selection`yyyy'"
		}
	
		qui egen double empid = group(empresa_fic)
		
		* Generate lagged employer id
		qui xtset persid ano
		qui gen double lag_empid = l.empid
	
		* Make unique
		foreach var in age {
			qui egen `var'2 = group(`var')
			drop `var'
			rename `var'2 `var'
		}
		
		* run with hourly wage rates --- only available after 1994
		if $with_hours == 1 {
			bys ano: sum horas_contr, d
			drop if horas_contr < 30
			qui replace wage = wage_hourly
			qui drop if wage == .
		}
		
		* Output format to matlab for AKM
		format wage %6.5f
		format persid %12.0f
		format empid %12.0f
		format lag_empid %12.0f
		format age %2.0f
		format ano %4.0f
		
		disp "Summarize variables that are exported to MATLAB:"
		sum `varlist_rais'
		disp "Outsheet list of wages, IDs, and worker characteristics:"
		outsheet `varlist_rais' using "$SAVE_MATLAB/tomatlab_${with_hours}_${akm_start}_${akm_end}.csv", nonames nolabel replace
	
		* Keep only those with valid observation last period
		disp "Keep only those with valid firm last year:"
		keep if lag_empid < .
	
		sum empid lag_empid
		disp "Outsheet list of current and previous employer IDs:"
		outsheet empid lag_empid using "$SAVE_MATLAB/connected_${with_hours}_${akm_start}_${akm_end}.csv", nonames nolabel replace
	
		* Open shell, call matlab and MOVERS.m
		disp "***** Running MATLAB *****"
		!matlab -nodesktop -nojvm -nosplash -nodisplay -logfile ${SAVE_MATLAB}/log_${with_age}${with_hours}_${akm_start}_${akm_end} -r "clear all; close all; yyyy1 = ${akm_start}; yyyy2 = ${akm_end}; DATASET = ${dataset}; WITHAGE = ${with_age}; WITHHOURS = ${with_hours}; SAVE_MATLAB = '${SAVE_MATLAB}'; addpath('${MATLABBGLPATH}'); run '${MAINPATH}'/AKM.m"
	
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		local akm = `akm' + 1
		
	}
}
else {
	disp "****************************************************************************************************************"
	disp "				*** RUNNING AKM ON PIA ***"
	disp "****************************************************************************************************************"
	
	global akm_start = $minyear
	global akm_end = $akm_start + $periodlength
	local akm = 1
	while `akm' <= $nperiods {
		disp "********** AKM routine for years ${akm_start} - ${akm_end} **********"
		forvalues yyyy = $akm_start/$akm_end {
			disp "* Year `yyyy'"
			display _newline(3)
			if `yyyy' == $akm_start qui use "$SAVE_CLEANED/selection_PIA_`yyyy'", clear
			else qui append using "$SAVE_CLEANED/selection_PIA_`yyyy'"
		}
	
		qui egen double empid = group(empresa_fic)
		
		* Only firms in the sample for at least five years
		bys empid ano: gen ind = (_n==1)
		bys empid: egen firmyear = total(ind)
		keep if firmyear >= 5
		
		* Generate lagged employer id
		qui xtset persid ano
		qui gen double lag_empid = l.empid
	
		* Make unique
		foreach var in age {
			qui egen `var'2 = group(`var')
			drop `var'
			rename `var'2 `var'
		}
		
		* Output format to matlab for AKM
		format wage %6.5f
		format persid %12.0f
		format empid %12.0f
		format lag_empid %12.0f
		format age %2.0f
		format ano %4.0f
		format va_pw %7.5f
		
		disp "Summarize variables that are exported to MATLAB:"
		sum `varlist_pia'
		disp "Outsheet list of wages, IDs, and worker characteristics:"
		outsheet `varlist_pia' using "$SAVE_MATLAB/tomatlab_pia_${akm_start}_${akm_end}.csv", nonames nolabel replace
	
		* Keep only those with valid observation last period
		disp "Keep only those with valid firm last year:"
		keep if lag_empid < .
	
		sum empid lag_empid
		disp "Outsheet list of current and previous employer IDs:"
		outsheet empid lag_empid using "$SAVE_MATLAB/connected_pia_${akm_start}_${akm_end}.csv", nonames nolabel replace
	
		* Delete earlier output so as not to cause confusion
		capture confirm file "$SAVE_MATLAB/tostata_pia_${akm_start}_${akm_end}.txt"
		//if _rc != 601 rm "$SAVE_MATLAB/tostata_byperiod_${akm_start}_${akm_end}.txt"
	
		* Open shell, call matlab and MOVERS.m
		disp "***** Running MATLAB *****"
		!matlab -nodesktop -nojvm -nosplash -nodisplay -logfile ${SAVE_MATLAB}/log_${with_age}${with_va}_${akm_start}_${akm_end} -r "clear all; close all; yyyy1 = ${akm_start}; yyyy2 = ${akm_end}; DATASET = ${dataset}; WITHAGE = ${with_age}; WITHVA = ${with_va}; SAVE_MATLAB = '${SAVE_MATLAB}'; addpath('${MATLABBGLPATH}'); run '${MAINPATH}'/AKM.m"
		
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		local akm = `akm' + 1
		
	}
}
