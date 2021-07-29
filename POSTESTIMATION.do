********************************************************************************
* Post-estimation summary statistics
*
* "Firms and the Decline in Earnings Inequality in Brazil"
*
* by Jorge Alvarez (International Monetary Fund),
* Benguria Benguria (University of Kentucky),
* Niklas Engbom (Princeton University), and
* Christian Moser (Columbia University)
*
*
* This file produces summary stats that can be used to reproduce figures 5 and 11 
* and tables 3, 4, 5, D1 and D2.
*
* First created: 10/09/2014
* Last edited: 06/24/2017
********************************************************************************
clear all
set more off
set rmsg on

global sumys = 0 // (1) SUMMARY STATISTICS FOR `sample' FOR PERIOD $akm_start - $akm_end"
global dens = 0 // (2) DENSITY ESTIMATION FOR `sample' FOR PERIOD $akm_start - $akm_end"
global residualanalysis = 0 // (3) PLOT OF RESIDUAL FOR `sample' FOR PERIOD $akm_start - $akm_end"
global sectoranalysis = 0 // (4) DIFFERENCES BETWEEN AND WITHIN SECTORS
global switcherstats = 0 // (5) SWITCHER STATISTICS

if $sumys == 1 {
	if $dataset == 1 { 
		foreach sample in "lset" "pia" {
			if "`sample'" == "lset" global akm_start = $minyear
			else global akm_start = 1996
			global akm_end = $akm_start + $periodlength
			
			foreach var in wage person firm xb_year xb_age resid {
				global `var' = ""
				foreach var2 in sd p10 p50 p90 {
					global `var' = "$`var' `var'_`var2'"
				}
			}
			postfile covariance period num_worker_years num_firms r2 ${wage} ${person} ${firm} ${xb_year} ${xb_age} ${resid} person_firm person_xb_year person_xb_age firm_xb_year firm_xb_age xb_year_xb_age using "$SAVE_SUMMARYSTATS/covariance_`sample'_${with_age}${with_hours}_${akm_start}(${periodlength})${maxyear}", replace	
			while $akm_end <= $maxyear {
			* Summary statistics 
				disp "**********************************************************************"	
				disp "* (1) SUMMARY STATISTICS FOR `sample' FOR PERIOD $akm_start - $akm_end"
				disp "**********************************************************************"				
				if "`sample'" == "pia" use wage empresa_fic person firm xb_year xb_age resid using "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
				else use wage empresa_fic person firm xb_year xb_age resid using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear

				disp "* Calculate number of firms and worker-years"
				qui count if wage < .
				qui scalar workeryears = r(N)
				qui bys empresa_fic: gen num = 1 if _n == 1
				qui count if num != .
				qui scalar firms = r(N)
				
				disp "* Calculate the R^2 value"
				qui egen barwage = mean(wage)
				qui gen dev = (wage-barwage)^2
				qui sum dev
				scalar totalsum = r(sum)
				qui gen res2 = resid^2
				qui sum res2
				scalar totalres = r(sum)
				scalar R2 = 1-totalres/totalsum
				
				disp "* Dispersion in estimated effects"
				foreach var in wage person firm xb_year xb_age resid {
					qui sum `var', d
					scalar `var'_sd = r(sd)
					scalar `var'_p10 = r(p10)
					scalar `var'_p50 = r(p50)
					scalar `var'_p90 = r(p90)
				}
				disp "* Covariance between estimated effects"
				foreach var in person firm xb_year xb_age {
					foreach var2 in firm xb_year xb_age {
						qui cor `var' `var2', covariance
						scalar `var'_`var2' = r(cov_12)
					}
				}
				
				scalar period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
				
				disp "* post"
				foreach var in wage person firm xb_year xb_age resid {
					global `var' = ""
					foreach var2 in sd p10 p50 p90 {
						global `var' = "$`var' (`var'_`var2')"
					}
				}
				post covariance (period) (workeryears) (firms) (R2) ${wage} ${person} ${firm} ${xb_year} ${xb_age} ${resid} (person_firm) (person_xb_year) (person_xb_age) (firm_xb_year) (firm_xb_age) (xb_year_xb_age)
				global akm_start = $akm_start + $periodlength
				global akm_end = $akm_end + $periodlength
			}
			qui postclose covariance
			
			if "`sample'" == "lset" global akm_start = $minyear
			else global akm_start = 1996
			qui use "$SAVE_SUMMARYSTATS/covariance_`sample'_${with_age}${with_hours}_${akm_start}(${periodlength})${maxyear}", clear
			qui export excel "$SAVE_SUMMARYSTATS/covariance_`sample'_${with_age}${with_hours}_${akm_start}(${periodlength})${maxyear}", firstrow(variables) replace
		}
	}
	else {
		global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		foreach var in wage person firm xb_year xb_age xb_va resid {
			global `var' = ""
			foreach var2 in sd p10 p50 p90 {
				global `var' = "$`var' `var'_`var2'"
			}
		}
		postfile covariance period num_worker_years num_firms r2 ${wage} ${person} ${firm} ${xb_year} ${xb_age} ${xb_va} ${resid} person_firm person_xb_year person_xb_age person_xb_va firm_xb_year firm_xb_age firm_xb_va xb_year_xb_age xb_year_xb_va xb_age_xb_va using "$SAVE_SUMMARYSTATS/covariance_allpia_${with_age}${with_va}_${akm_start}(${periodlength})${maxyear}", replace
		while $akm_end <= $maxyear {
		* Summary statistics 
			disp "**********************************************************************"	
			disp "* (1) SUMMARY STATISTICS FOR ALL PIA FOR PERIOD $akm_start - $akm_end"
			disp "**********************************************************************"
			use wage person empresa_fic firm xb_year xb_age xb_va resid using "$SAVE_CLEANED/lset_allpia_${with_age}${with_va}_${akm_start}_${akm_end}", clear
			
			disp "* Calculate number of firms and worker-years"
			qui count if wage < .
			qui scalar workeryears = r(N)
			
			qui bys empresa_fic: gen num = (_n == 1)
			qui count if num != .
			qui scalar firms = r(N)
			
			disp "* Calculate the R^2 value"
			qui egen barwage = mean(wage)
			qui gen dev = (wage-barwage)^2
			qui sum dev
			scalar totalsum = r(sum)
			qui gen res2 = resid^2
			qui sum res2
			scalar totalres = r(sum)
			scalar R2 = 1-totalres/totalsum
			
			disp "* Summary statistics on estimated fixed and time-varying effects"
			foreach var in wage person firm xb_year xb_age xb_va resid {
				qui sum `var', d
				scalar `var'_sd = r(sd)
				scalar `var'_p10 = r(p10)
				scalar `var'_p50 = r(p50)
				scalar `var'_p90 = r(p90)
			}
			foreach var in person firm xb_year xb_age xb_va {
				foreach var2 in person firm xb_year xb_age xb_va {
					qui cor `var' `var2', covariance
					scalar `var'_`var2' = r(cov_12)
				}
			}
			
			scalar period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
			
			disp "* post"
			foreach var in wage person firm xb_year xb_age xb_va resid {
				global `var' = ""
				foreach var2 in sd p10 p50 p90 {
					global `var' = "$`var' (`var'_`var2')"
				}
			}
			post covariance (period) (workeryears) (firms) (R2) ${wage} ${person} ${firm} ${xb_year} ${xb_age} ${xb_va} ${resid} (person_firm) (person_xb_year) (person_xb_age) (person_xb_va) (firm_xb_year) (firm_xb_age) (firm_xb_va) (xb_year_xb_age) (xb_year_xb_va) (xb_age_xb_va)
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		qui postclose covariance
		
		global akm_start = 1996
		qui use "$SAVE_SUMMARYSTATS/covariance_allpia_${with_age}${with_va}_${akm_start}(${periodlength})${maxyear}", clear
		qui export excel "$SAVE_SUMMARYSTATS/covariance_allpia_${with_age}${with_va}_${akm_start}(${periodlength})${maxyear}", firstrow(variables) replace
	}
}

if $dens == 1 {
	foreach sample in lset pia {
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			disp "* (2) DENSITY ESTIMATION FOR `sample' FOR PERIOD $akm_start - $akm_end"
			disp "**********************************************************************"
				
			if "`sample'" == "pia" qui use firm empresa_fic using "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			else qui use firm empresa_fic using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear

			* keep only nonmissing
			qui keep if firm < .
							
			* collapse to firm level for speed
			qui collapse (first) firm (count) weight = firm, by(empresa_fic)				
				
			foreach type in unweighted weighted {
				preserve
				
				qui gen newweight = weight
				
				if "`type'" == "unweighted" qui replace weight = 1
				
				qui sum firm [fw=weight]
				qui replace firm = firm-r(mean)
				
				* estimate density
				qui fastxtile bin = firm [fw=weight], n(${binpoints})
				qui collapse (min) minpoint = firm (max) cutoff = firm (sum) n_inds = newweight (count) n_firms = firm, by(bin)
	
				* midpoint
				qui gen firm = (minpoint+cutoff)/2
			
				* density
				qui gen density = 1/${binpoints} * 1/(cutoff-minpoint)
			
				qui keep bin density firm n_inds n_firms
	
				qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
				qui gen weighted = "`type'"
				
				qui save "$SAVE_SUMMARYSTATS/fedensities_`sample'_${with_age}${with_hours}_`type'_${akm_start}_${akm_end}", replace
				
				restore
			}
			
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		
		* combine to one file and store in excel
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		qui use "$SAVE_SUMMARYSTATS/fedensities_`sample'_${with_age}${with_hours}_unweighted_${akm_start}_${akm_end}", clear
		qui append using "$SAVE_SUMMARYSTATS/fedensities_`sample'_${with_age}${with_hours}_weighted_${akm_start}_${akm_end}"
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		while $akm_end <= $maxyear {
			foreach type in unweighted weighted {
				qui append using "$SAVE_SUMMARYSTATS/fedensities_`sample'_${with_age}${with_hours}_`type'_${akm_start}_${akm_end}"
			}
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		if "`sample'" == "pia" qui export excel "$SAVE_SUMMARYSTATS/fedensities_`sample'_${with_age}${with_hours}_1996_${maxyear}.xls", firstrow(variables) replace
		else qui export excel "$SAVE_SUMMARYSTATS/fedensities_`sample'_${with_age}${with_hours}_${minyear}_${maxyear}.xls", firstrow(variables) replace
		
	}
}
		
if $residualanalysis == 1 {
	foreach sample in lset pia {
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			disp "**********************************************************************"	
			disp "* (3) PLOT OF RESIDUAL FOR `sample' FOR PERIOD $akm_start - $akm_end"
			disp "**********************************************************************"	
			if "`sample'" == "pia" qui use firm person resid empresa_fic using "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			else qui use firm person resid empresa_fic using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			
			qui fastxtile firm_q = firm, nquantiles(10)
			qui fastxtile person_q = person, nquantiles(10)
			
			qui bys empresa_fic: gen num = _n == 1
			
			qui collapse (mean) resid (count) num_firms = num num_worker_years = resid, by(firm_q person_q)
			
			qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
			
			qui save "$SAVE_SUMMARYSTATS/3dresidual_`sample'_${with_age}${with_hours}_${akm_start}_${akm_end}", replace
						
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		
		* combine to one file and store in excel
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		qui use "$SAVE_SUMMARYSTATS/3dresidual_`sample'_${with_age}${with_hours}_${akm_start}_${akm_end}", replace
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		while $akm_end <= $maxyear {
			qui append using "$SAVE_SUMMARYSTATS/3dresidual_`sample'_${with_age}${with_hours}_${akm_start}_${akm_end}"
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		if "`sample'" == "pia" qui export excel "$SAVE_SUMMARYSTATS/3dresidual_`sample'_${with_age}${with_hours}_1996_${maxyear}.xls", firstrow(variables) replace
		else qui export excel "$SAVE_SUMMARYSTATS/3dresidual_`sample'_${with_age}${with_hours}_${minyear}_${maxyear}.xls", firstrow(variables) replace
		
	}
}
		
		
if $sectoranalysis == 1 {
	foreach sample in lset pia {
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			disp "******************************************************************************"	
			disp "* (4) BETWEEN AND ACROSS SECTORS FOR `sample' FOR PERIOD $akm_start - $akm_end"
			disp "******************************************************************************"	
			if "`sample'" == "pia" qui use firm clascnae95 using "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			else qui use firm clascnae95 using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			
			* normalize firm effects
			qui sum firm
			qui local m = r(mean)
			qui gen totvar = r(Var)
			qui replace firm = firm-`m'
			
			* within and across variance
			qui bys clascnae95: egen across = mean(firm)
			qui replace across = across^2
			qui bys clascnae95: egen within = sd(firm)
			qui replace within = within^2
			
			* calculate the number of workers in each sector
			qui bys clascnae95: egen n_sec = count(firm)
			qui egen num = count(firm)
			qui gen frac = n_sec/num
			
			* collapse to sector level
			qui collapse (first) frac across within totvar, by(clascnae95)
			
			gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
				
			qui save "$SAVE_SUMMARYSTATS/sectors_`sample'_${with_age}${with_hours}_${akm_start}_${akm_end}", replace
					
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		
		* combine to one file and store in excel
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		qui use "$SAVE_SUMMARYSTATS/sectors_`sample'_${with_age}${with_hours}_${akm_start}_${akm_end}", replace
		qui gen ofrac = frac
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		while $akm_end <= $maxyear {
			qui append using "$SAVE_SUMMARYSTATS/sectors_`sample'_${with_age}${with_hours}_${akm_start}_${akm_end}"
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		qui bys clascnae95: egen orig_frac = mean(ofrac)
		qui drop ofrac
		
		qui gen orig_within = orig_frac*within
		qui gen orig_across = orig_frac*across
		qui replace within = frac*within
		qui replace across = frac*across
		
		qui collapse (sum) orig_within orig_across within across, by(period)
		
		if "`sample'" == "pia" qui export excel "$SAVE_SUMMARYSTATS/sectors_`sample'_${with_age}${with_hours}_1996_${maxyear}.xls", firstrow(variables) replace
		else qui export excel "$SAVE_SUMMARYSTATS/sectors_`sample'_${with_age}${with_hours}_${minyear}_${maxyear}.xls", firstrow(variables) replace

	}
}
		

if $switcherstats == 1 {
	foreach sample in lset pia {
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			disp "************************************************************"
			disp "* (5) SWITCHER STATISTICS `sample' FOR PERIOD $akm_start - $akm_end"
			disp "************************************************************"
			if "`sample'" == "pia" qui use ano persid empresa_fic using "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			else qui use ano persid empresa_fic using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			qui egen firmid = group(empresa_fic)
			drop empresa_fic
			rename firmid empresa_fic
			qui xtset persid ano
			qui gen jobspell = 1
			qui replace jobspell = cond(empresa_fic == l.empresa_fic,l.jobspell,l.jobspell+1) if l.empresa_fic < .

			* collapse to individual-period level
			qui collapse (count) nrobs = empresa_fic (max) nremployers = jobspell, by(persid)

			* outsheet results
			local pp = $periodlength + 1
			postfile file period nobs nemployers nind using "$SAVE_SUMMARYSTATS/switcherstats_`sample'_${with_age}${with_hours}_${akm_start}_${akm_end}", replace
			scalar period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
			forvalues i = 1/`pp' {
				forvalues j = 1/`i' {
					qui count if nrobs == `i' & nremployers == `j'
					qui local nrinds = r(N)
					post file (period) (`i') (`j') (`nrinds')
				}
			}
			postclose file
			
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}	
	}
}
