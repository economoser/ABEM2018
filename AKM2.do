* ******************************************************************************
* ******************************************************************************
* AKM2.do
* A follow-up routine to AKM.do, to be run after MATLAB completes successfully.
* The code outputs all individual and firm effects for later analysis.
*
* Alvarez, Engbom and Moser
* First created: 10/10/2014
* Last edited: 06/24/2017
* ******************************************************************************
* ******************************************************************************

set more off
if $dataset == 1 {
	global akm_start = $minyear
	global akm_end = $akm_start + $periodlength
	local akm = 1
	while `akm' <= $nperiods {
		disp "********** AKM2 FOR PERIOD ${akm_start} - ${akm_end} **********"
		* Read MATLAB output
		insheet using "$SAVE_MATLAB/tostata_${with_age}${with_hours}_${akm_start}_${akm_end}.txt", double names tab clear
		sum
		* Add other variables
		global matchupdate = ""
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' > $akm_start global matchupdate = "match_update"
			merge 1:1 persid ano using "$SAVE_CLEANED/selection`yyyy'", keep(match $matchupdate master) ///
				keepusing(persid empresa_fic ano occup wage_hourly wage age clascnae95 edu fsize loc) ///
				update nogen
		}
		global matchupdate = ""
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' > $akm_start global matchupdate = "match_update"
			merge m:1 empresa_fic ano using "$SAVE_CLEANED/exenst`yyyy'", keep(match $matchupdate master) ///
				update nogen
		}
		
		* Generate the residual
		if $with_hours == 1 {
			rename wage wage_monthly 
			qui rename wage_hourly wage
		}
		qui gen resid = wage - person - firm - xb_year - xb_age
		
		* Label variables
		label variable person "Estimated person effect"
		label variable firm "Estimated firm effect"
		label variable xb_year "Estimated year effect"
		label variable xb_age "Estimated age effect"
		label variable resid "Residual from AKM regression"
		label variable exit "Employed by exiting firm"
		label variable entry "Employed by entrant firm"
		
		* Save
		compress
		sum
		save "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", replace
		
		* Merge with PIA for future analysis
		if $akm_start >= 1996 {
			rename ano year
			qui merge m:1 empresa_fic year using "F:\ipea\projetos\2015\Projetos IBGE\03605000601_2015_96 - Princeton\9_Chris_JMP/PIA_composition", keep(match) keepusing(cnae4 revop_pw* vaop_pw* inv_v_pw capital_pw export_intensity) nogen force
			rename year ano
			foreach def in "" "_resid" "_resid2" {
				rename revop_pw`def' vbp_pw`def'
				rename vaop_pw`def' va_pw`def'
			}
			rename cnae4 pia_cnae
			qui keep if va_pw < . & vbp_pw < .
			qui compress 
			save "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", replace
		}
		
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		local akm = `akm'+1

	}
}
else {
	global akm_start = $minyear
	global akm_end = $akm_start + $periodlength
	local akm = 1
	while `akm' <= $nperiods {	
		disp "********** AKM2 FOR PERIOD ${akm_start} - ${akm_end} **********"
		* Read MATLAB output
		insheet using "$SAVE_MATLAB/tostata_pia_${with_age}${with_va}_${akm_start}_${akm_end}.txt", double names tab clear
		sum

		* Add other variables
		global matchupdate = ""
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' > $akm_start global matchupdate = "match_update"
			merge 1:1 persid ano using "$SAVE_CLEANED/selection_PIA_`yyyy'", keep(match $matchupdate master) ///
				keepusing(persid empresa_fic ano occup wage age clascnae95 edu fsize) ///
				update nogen
		}
		global matchupdate = ""
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' > $akm_start global matchupdate = "match_update"
			merge m:1 empresa_fic ano using "$SAVE_CLEANED/exenst`yyyy'", keep(match $matchupdate master) ///
				update nogen
		}
		
		* Generate the residual
		qui gen resid = wage - person - firm - xb_year - xb_age - xb_va
		
		* Label variables
		label variable person "Estimated person effect"
		label variable firm "Estimated firm effect (incl sector)"
		label variable xb_year "Estimated year effect"
		label variable xb_age "Estimated age effect"
		label variable xb_va "Estimated value added effect"
		label variable resid "Residual from AKM regression"
		label variable exit "Employed by exiting firm"
		label variable entry "Employed by entrant firm"
		
		*** Save
		compress
		sum
		save "$SAVE_CLEANED/lset_allpia_${with_age}${with_va}_${akm_start}_${akm_end}.dta", replace
		
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		local akm = `akm'+1
	}
}
clear all
