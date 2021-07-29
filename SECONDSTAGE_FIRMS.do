* ******************************************************************************
* Second stage, firms
*
* "Firms and the Decline in Earnings Inequality in Brazil"
*
* by Jorge Alvarez (International Monetary Fund),
* Benguria Benguria (University of Kentucky),
* Niklas Engbom (Princeton University), and
* Christian Moser (Columbia University)
*
* This file may be used to reproduce figures 6-8 and E1 and tables 6, 7, E1 and 
* E2.
*
* First created: 10/09/2014
* Last edited: 06/24/2017
********************************************************************************
global prepare = 1
global regress = 1
global binscatter = 1
global OUTREGPATH = "F:\ipea\projetos\2015\Projetos IBGE\03605000998_2014_35 - Princeton\2_output\4_summary_statistics"

if $prepare == 1 {
	disp "**** Generating firm-level data set for lset ****"
	global akm_start = $minyear
	global akm_end = $akm_start + $periodlength
	local akm = 1
	while `akm' <= $nperiods {
		disp "**** Period ${akm_start} - ${akm_end} ****"
		*** Load
		use "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
		
		* normalize person and firm effects in each period
		foreach var in firm person {
			qui sum `var'
			qui replace `var' = `var' - r(mean)
		}
		* generate education measure
		gen edu_low = (edu < 7)
		gen edu_middle = (edu >= 7 & edu < 12)
		gen edu_hs = (edu >= 12 & edu < 16)
		gen edu_college = (edu >= 16 & edu < .)
		
		* region
		egen region = group(loc)
		
		* collapse to period-level 
		qui collapse (first) firm clascnae95 (max) exit entry (median) region (mean) person wage fsize age edu edu_low edu_middle edu_hs edu_college (sd) var_resid = resid (count) weight = wage, by(empresa_fic)
		qui replace var_resid = var_resid^2
		qui replace region = round(region)
		
		label var firm "firm effect"
		label var exit "exiting this period"
		label var entry "entered this period"
		label var person "average person effect"
		label var wage "mean wage"
		label var fsize "mean firm size"
		label var age "average age of a firm´s workforce"
		label var edu "average years of education"
		label var edu_low "fraction of workforce with 0-6 years of education"
		label var edu_middle "fraction of workforce with 7-11 years of education"
		label var edu_hs "fraction of workforce with 12-15 years of education"
		label var edu_college "fraction of workforce with 16 or more years of education"
		label var var_resid "Within firm residual variance"
		
		qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
		disp "Saving firm level data for period ${akm_start} - ${akm_end}"
		save "$SAVE_CLEANED/lset_firmlevel_${with_age}${with_hours}_${akm_start}_${akm_end}", replace
		
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		local akm = `akm'+1		
	} 

	if ${minyear} == 1988 & ${maxyear} == 2012  {
		disp "Append RAIS data across periods"
		global akm_start = $minyear
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			if $akm_start == $minyear qui use "$SAVE_CLEANED/lset_firmlevel_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			else qui append using "$SAVE_CLEANED/lset_firmlevel_${with_age}${with_hours}_${akm_start}_${akm_end}"
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		cap qui egen double empid = group(empresa_fic)
		compress
		save "$SAVE_CLEANED/lset_firmlevel_${with_age}${with_hours}_${minyear}(${periodlength})${maxyear}", replace
	}


	disp "*** Generating firm-level data set for PIA ***"
	global akm_start = max(${minyear},1996)
	global akm_end = $akm_start + $periodlength
	local akm = 1
	while `akm' <= $nperiods {
		*** Load
		use "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
		
		disp "*** ANALYSIS AT ANNUAL LEVEL BEFORE COLLAPSING TO FIRM-PERIODS ***"	
		* normalize person and firm effects in each period
		foreach var in firm person {
			qui sum `var'
			qui replace `var' = `var' - r(mean)
		}
		
		* generate a normalized value added per worker measure in each year
		foreach meas in va_pw vbp_pw {
			qui gen `meas'_norm = .
			forvalues yyyy = $akm_start/$akm_end {
				qui sum `meas' if ano == `yyyy'
				qui replace `meas'_norm = `meas' - r(mean) if ano == `yyyy'
				foreach var in resid resid2 {
					qui sum `meas'_`var' if ano == `yyyy'
					qui replace `meas'_`var' = `meas'_`var' - r(mean) if ano == `yyyy'
				}
			}
		}
		
		* generate education measure
		qui gen edu_low = (edu < 7)
		qui gen edu_middle = (edu >= 7 & edu < 12)
		qui gen edu_hs = (edu >= 12 & edu < 16)
		qui gen edu_college = (edu >= 16 & edu < .)
		
		* regions
		egen region = group(loc)
		
		* save PIA firm-year-level data
		preserve
		qui collapse (first) firm exit entry pia_cnae (median) region (mean) person wage va_pw va_pw_resid va_pw_resid2 va_pw_norm vbp_pw vbp_pw_resid vbp_pw_resid2 vbp_pw_norm capital_pw export_intensity fsize edu edu_low edu_middle edu_hs edu_college age (sd) var_resid = resid (count) weight = wage, by(empresa_fic ano) fast
		qui replace var_resid = var_resid^2
		qui replace region = round(region)
		save "$SAVE_CLEANED/lset_PIA_firmlevel_yearly_${with_age}${with_hours}_${akm_start}_${akm_end}", replace
		restore

		* collapse to period-level
		qui collapse (first) firm pia_cnae (max) exit entry (median) region (mean) person wage va_pw va_pw_resid va_pw_resid2 va_pw_norm vbp_pw vbp_pw_resid vbp_pw_resid2 vbp_pw_norm capital_pw export_intensity fsize edu edu_low edu_middle edu_hs edu_college age (sd) var_resid = resid (count) weight = wage, by(empresa_fic) fast
		qui replace var_resid = var_resid^2
		qui replace region = round(region)
		
		* labels
		label var export_intensity "exporter intensity"
		label var firm "firm effect"
		label var exit "exiting this period"
		label var entry "entered this period"
		label var wage "mean wage"
		label var va_pw "mean value added per worker"
		label var va_pw_resid "mean value added per worker (controlling for worker composition)"
		label var va_pw_resid2 "mean value added per worker (controlling for worker composition and sectors)"
		label var va_pw_norm "normalized value added per worker"
		label var vbp_pw "mean revenues per worker"
		label var vbp_pw_resid "mean revenues per worker (controlling for worker composition)"
		label var vbp_pw_resid2 "mean revenues per worker (controlling for worker composition and sectors)"
		label var vbp_pw_norm "normalized revenues per worker"
		label var capital_pw "mean capital per worker"
		label var fsize "mean firm size"
		label var var_resid "Within firm residual variance"
		label var edu "average years of education"
		label var edu_low "fraction of workforce with 0-6 years of education"
		label var edu_middle "fraction of workforce with 7-11 years of education"
		label var edu_hs "fraction of workforce with 12-15 years of education"
		label var edu_college "fraction of workforce with 16 or more years of education"
		label var age "average age of a firm's workers"
		
		qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
		disp "Saving PIA firm level data for period ${akm_start} - ${akm_end}"
		save "$SAVE_CLEANED/lset_PIA_firmlevel_${with_age}${with_hours}_${akm_start}_${akm_end}", replace

		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		local akm = `akm'+1
	}

	if $maxyear == 2012 {
		disp "*** Append PIA data across periods"
		global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			if $akm_start == 1996 use "$SAVE_CLEANED/lset_PIA_firmlevel_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			else append using "$SAVE_CLEANED/lset_PIA_firmlevel_${with_age}${with_hours}_${akm_start}_${akm_end}"
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		cap drop empid
		qui egen double empid = group(empresa_fic)
		compress
		xtset empid period
		save "$SAVE_CLEANED/lset_PIA_firmlevel_${with_age}${with_hours}_1996(${periodlength})2012", replace
	}
}
if $regress {
	*** firm regressions
	local i = 1
	local j = 1
	local sheet = 0
	foreach indepvar in "fsize" "c.fsize##c.fsize"   "va_pw" "c.va_pw##c.va_pw" "va_pw fsize" "c.va_pw##c.fsize"   "vbp_pw" "c.vbp_pw##c.vbp_pw" "vbp_pw fsize" "c.vbp_pw##c.fsize"   "export_ind" "export_intensity" "export_ind export_intensity" "export_ind c.export_intensity##c.export_intensity" "export_ind export_intensity fsize" "export_ind fsize" "export_ind##c.fsize" "export_ind#c.fsize c.export_intensity##c.fsize"   "export_ind export_intensity va_pw" "export_ind##c.va_pw c.export_intensity##c.va_pw"   "export_ind va_pw" "export_ind##c.va_pw"   "va_pw vbp_pw fsize export_ind export_intensity" "va_pw fsize export_ind export_intensity"   "vbp_pw c.va_pw##c.fsize c.va_pw##export_ind c.va_pw##c.export_intensity" "c.va_pw##c.fsize c.va_pw##export_ind c.va_pw##c.export_intensity" "c.va_pw##c.fsize c.va_pw##export_ind" {
		foreach sec_num in 0 1 {
			foreach state_num in 0 1 {
				foreach balance in 0 1 {
					if !`sec_num' {
						local sec_lab = ""
						local sec_reg = ""
					}
					else if `sec_num' {
						local sec_lab = "_sector"
						local sec_reg = "i.sec"
					}
					if !`state_num' {
						local state_lab = ""
						local state_reg = ""
					}
					else if `state_num' {
						local state_lab = "_region"
						local state_reg = "i.region"
					}
					disp "* reg FE `indepvar' by period (sector=`sec_num', state=`state_num', balance=`balance')"
					disp " :  :  :  :  : EXERCISE 1: regression by period"
					qui use period empresa_fic firm fsize va_pw vbp_pw export_intensity pia_cnae region weight using "$SAVE_CLEANED/lset_PIA_firmlevel_${with_age}${with_hours}_1996(${periodlength})2012", clear
					qui gen export_ind = (export_intensity > 0) if export_intensity < .
					if `balance' {
						qui bys empresa_fic: gen balanced = (_N == 4)
						qui keep if balanced == 1
					}
					if `sec_num' {
						qui gen sec2 = floor(pia_cnae/100)
						qui egen sec = group(sec2)
						drop sec2
					}
					forvalues p = 3/6 {
						//disp "*** PERIOD `p'"
						qui preserve
						qui keep if period == `p'
						qui reg firm `indepvar' `sec_reg' `state_reg' [fw = weight]
						if `i' == 1 qui outreg2 using "$OUTREGPATH/secondstage_firms_reg", replace stats(coef se Var sum_w) ctitle("period `p', balanced >= `balance'") excel
						else qui outreg2 using "$OUTREGPATH/secondstage_firms_reg", stats(coef se Var sum_w) ctitle("period `p', balanced >= `balance'") excel
						qui restore
						local i = `i' + 1	
					}
					//disp "*** PERIODS 3-6"
					if `sec_num' == 0 & `state_num' == 0 qui reg firm i.period i.period#c.va_pw i.period#c.fsize c.va_pw#c.fsize [fw = weight]
					else if `sec_num' == 1 & `state_num' == 0 qui areg firm i.period i.period#c.va_pw i.period#c.fsize c.va_pw#c.fsize [fw = weight], a(sec)
					else if `sec_num' == 0 & `state_num' == 1 qui areg firm i.period i.period#c.va_pw i.period#c.fsize c.va_pw#c.fsize [fw = weight], a(region)
					else if `sec_num' == 1 & `state_num' == 1 {
						qui egen sec_state = group(sec region)
						qui areg firm i.period i.period#c.va_pw i.period#c.fsize c.va_pw#c.fsize [fw = weight], a(sec_state)
					}
					qui outreg2 using "$OUTREGPATH/secondstage_firms_reg", stats(coef se Var sum_w) ctitle("pooled, balanced >= `balance'") excel
					
					disp "EXERCISE 2: changes in returns vs characteristics"
					cap postclose ex
					qui postfile ex period sector region balanced var_constdist var_constcoef var_expl var_tot n sumw using "$SAVE_SUMMARYSTATS/secondstage_firms`sec_lab'`state_lab'_`indepvar'_var", replace
					qui use "$SAVE_CLEANED/lset_PIA_firmlevel_${with_age}${with_hours}_1996(${periodlength})2012", clear
					qui gen export_ind = (export_intensity > 0) if export_intensity < .
					if `balance' {
						qui bys empresa_fic: gen balanced = (_N == 4)
						qui keep if balanced >= `balance'
					}
					if `sec_num' {
						qui gen sec2 = floor(pia_cnae/100)
						qui egen sec = group(sec2)
						drop sec2
					}		
					qui reg firm `indepvar' `sec_reg' `state_reg' [fw = weight] if period == 3
					qui predict xb_constcoef, xb
					qui gen xb_tot = .
					forvalues p = 3/6 {
						qui reg firm `indepvar' `sec_reg' `state_reg' [fw = weight] if period == `p'
						qui predict temp, xb
						qui replace xb_tot = temp if period == `p'
						qui drop temp
						qui reg firm `indepvar' `sec_reg' `state_reg' [fw = weight] if period == `p'
						qui predict xb_constdist`p' if period == 3, xb
					}
					forvalues p = 3/6 {
						//disp "*** PERIOD `p'"
						qui sum xb_constdist`p' [fw=weight]
						scalar xb_constdist_s = r(Var)
						global list = "(xb_constdist_s)"
						foreach var in xb_constcoef xb_tot firm {
							qui sum `var' [fw = weight] if period == `p'
							scalar `var'_s = r(Var)
							scalar n = r(N)
							scalar sumw = r(sum_w)
							global list = "$list (`var'_s)"
						}
						qui post ex (`p') (`sec_num') (`state_num') (`balance') ${list} (n) (sumw)
					}
					cap postclose ex
					qui use "$SAVE_SUMMARYSTATS/secondstage_firms`sec_lab'`state_lab'_`indepvar'_var", clear
					local sheet = `sheet' + 1
					qui gen spec = "`indepvar'"
					if `j' == 1 qui export excel "$OUTREGPATH/secondstage_firms_var.xls", firstrow(variables) sheet("s`sheet'") replace
					else qui export excel "$OUTREGPATH/secondstage_firms_var.xls", firstrow(variables) sheet("s`sheet'_`sec_num'_`state_num'_`balance'") sheetmodify
					qui save "$OUTREGPATH/secondstage_firms_var_s`sheet'_`sec_num'_`state_num'_`balance'.dta", replace
					local j = `j' + 1
				}
			}
		}
	}
	local k = 1
	local sheet = 0
	foreach indepvar in "fsize" "c.fsize##c.fsize"   "va_pw" "c.va_pw##c.va_pw" "va_pw fsize" "c.va_pw##c.fsize"   "vbp_pw" "c.vbp_pw##c.vbp_pw" "vbp_pw fsize" "c.vbp_pw##c.fsize"   "export_ind" "export_intensity" "export_ind export_intensity" "export_ind c.export_intensity##c.export_intensity" "export_ind export_intensity fsize" "export_ind fsize" "export_ind##c.fsize" "export_ind#c.fsize c.export_intensity##c.fsize"   "export_ind export_intensity va_pw" "export_ind##c.va_pw c.export_intensity##c.va_pw"   "export_ind va_pw" "export_ind##c.va_pw"   "va_pw vbp_pw fsize export_ind export_intensity" "va_pw fsize export_ind export_intensity"   "vbp_pw c.va_pw##c.fsize c.va_pw##export_ind c.va_pw##c.export_intensity" "c.va_pw##c.fsize c.va_pw##export_ind c.va_pw##c.export_intensity" "c.va_pw##c.fsize c.va_pw##export_ind" { 
		foreach sec_num in 0 1 {
			foreach state_num in 0 1 {
				foreach balance in 0 1 {
					local sheet = `sheet' + 1
					if `k' == 1 qui use "$OUTREGPATH/secondstage_firms_var_s`sheet'_`sec_num'_`state_num'_`balance'.dta", clear
					else qui append using "$OUTREGPATH/secondstage_firms_var_s`sheet'_`sec_num'_`state_num'_`balance'.dta"
					local k = 0
				}
			}
		}
	}
	qui save "$OUTREGPATH/secondstage_firms_var.dta", replace
	qui export excel "$OUTREGPATH/secondstage_firms_var.xls", firstrow(variables) sheet("var_decomposition") replace
}


if $binscatter {
	disp "*** binscatters"
	* binscatter for firms
	use "$SAVE_CLEANED/lset_PIA_firmlevel_${with_age}${with_hours}_1996(${periodlength})2012", clear
	qui gen sec2 = floor(pia_cnae/100)
	qui egen sec = group(sec2)
	drop sec2
	qui binscatter firm va_pw, n(${binpoints}) savedata("$OUTREGPATH/binscatter_firms") replace
	qui binscatter firm va_pw, n(${binpoints}) by(period) savedata("$OUTREGPATH/binscatter_firms_p") replace
	qui binscatter firm va_pw, n(${binpoints}) absorb(sec) savedata("$OUTREGPATH/binscatter_firms_sec") replace
	qui binscatter firm va_pw, n(${binpoints}) absorb(sec) by(period) savedata("$OUTREGPATH/binscatter_firms_p_sec") replace
	qui binscatter firm va_pw, n(${binpoints}) absorb(region) savedata("$OUTREGPATH/binscatter_firms_region") replace
	qui binscatter firm va_pw, n(${binpoints}) absorb(region) by(period) savedata("$OUTREGPATH/binscatter_firms_p_region") replace

	forval p = 3/6 {
		fastxtile fsize_q`p' = fsize if period == `p', n(4)
	}
	qui egen fsize_q = rowtotal(fsize_q?)
	drop fsize_q?
	forval f_q = 1/4 {
		qui binscatter firm va_pw if fsize_q == `f_q', n(${binpoints}) by(period) savedata("$OUTREGPATH/binscatter_firms_p_byfsize_q`f_q'") replace
	}

	qui binscatter firm va_pw if export_intensity == 0, n(${binpoints}) by(period) savedata("$OUTREGPATH/binscatter_firms_p_byexport0") replace
	qui binscatter firm va_pw if export_intensity > 0, n(${binpoints}) by(period) savedata("$OUTREGPATH/binscatter_firms_p_byexport1") replace


	* binscatter for workers
	disp "Combining worker effect decomposition from each subperiod"
	global akm_start = $minyear
	global akm_end = $akm_start + $periodlength
	while $akm_end <= $maxyear {
		disp "Period ${akm_start}-${akm_end}"
		qui use person wage age edu occup loc using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", clear
		qui bys occup: egen mean_wage = mean(wage)
		qui egen occup_rank = rank(mean_wage)
		qui sum occup_rank
		local occup_max = r(max)
		local occup_min = r(min)
		qui replace occup_rank = (occup_rank - `occup_min')/(`occup_max' - `occup_min')
		drop occup
		rename occup_rank occup
		qui recode edu (0/6.99 = 1) (7/11.99 = 2) (12/15.99 = 3) (16/999 = 4), generate(edu4)
		qui egen region = group(loc)
		qui binscatter person age, savedata("$OUTREGPATH/binscatter_workers_age_${akm_start}_${akm_end}") replace
		qui binscatter person edu, savedata("$OUTREGPATH/binscatter_workers_edu_${akm_start}_${akm_end}") replace
		qui binscatter person edu4, savedata("$OUTREGPATH/binscatter_workers_edu4_${akm_start}_${akm_end}") replace
		qui binscatter person occup, savedata("$OUTREGPATH/binscatter_workers_occup_${akm_start}_${akm_end}") replace
		
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
	}
	global f_list = "firms firms_p firms_sec firms_p_sec firms_region firms_p_region firms_p_byfsize_q1 firms_p_byfsize_q2 firms_p_byfsize_q3 firms_p_byfsize_q4 firms_p_byexport0 firms_p_byexport1 workers_age workers_edu workers_edu4 workers_occup"
	foreach f of global f_list {
		global akm_start = $minyear
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			if substr("`f'",1,7) == "workers" {
				qui insheet using "$OUTREGPATH/binscatter_`f'_${akm_start}_${akm_end}.csv", clear
				qui save "$OUTREGPATH/binscatter_`f'_${akm_start}_${akm_end}.dta", replace
			}
			else if $akm_start == $minyear {
				qui insheet using "$OUTREGPATH/binscatter_`f'.csv", clear
				qui save "$OUTREGPATH/binscatter_`f'.dta", replace
			}
			
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
	}
	foreach f of global f_list {
		global akm_start = $minyear
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			if $akm_start == $minyear {
				if substr("`f'",1,7) == "workers" {
					qui use "$OUTREGPATH/binscatter_`f'_${akm_start}_${akm_end}.dta", clear
					qui gen period = ${akm_start}/4 - 496
				}
				else {
					qui use "$OUTREGPATH/binscatter_`f'.dta", clear
					qui gen period = .
				}
			}
			else {
				if substr("`f'",1,7) == "workers" {
					qui append using "$OUTREGPATH/binscatter_`f'_${akm_start}_${akm_end}.dta"
					qui replace period = ${akm_start}/4 - 496 if period == .
				}
			}
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		qui save "$OUTREGPATH/binscatter_`f'_${minyear}_${maxyear}.dta", replace
	}
	local k = 1
	foreach f of global f_list {
		if `k' == 1 {
			qui use "$OUTREGPATH/binscatter_`f'_${minyear}_${maxyear}.dta", clear
			qui gen spec = "`f'"
		}
		else {
			qui append using "$OUTREGPATH/binscatter_`f'_${minyear}_${maxyear}.dta"
			qui replace spec = "`f'" if spec == ""
		}
		local k = 0
	}
	order period spec firm va_pw firm_* va_pw_* person age edu edu4 occup
	sort period spec firm va_pw firm_* va_pw_* person age edu edu4 occup
	qui save "$OUTREGPATH/binscatter.dta", replace
	qui export excel "$OUTREGPATH/binscatter.xls", firstrow(variables) replace
}


*** final housekeeping
clear
