* *****************************************************************************************
* Second stage, workers
*
* "Firms and the Decline in Earnings Inequality in Brazil"
*
* by Jorge Alvarez (International Monetary Fund),
* Benguria Benguria (University of Kentucky),
* Niklas Engbom (Princeton University), and
* Christian Moser (Columbia University)
*
* This file may be used to reproduce figure 9 and table 8.
*
* First created: 10/09/2014
* Last edited: 06/24/2017
********************************************************************************
% store summary stats
global OUTREGPATH = "F:\ipea\projetos\2015\Projetos IBGE\03605000998_2014_35 - Princeton\7_EXTRACT_0305000998_2014_35\1_Tabelas de saida"

% switch to combine data
global combine = 1
global varlist = "age" 
disp "second stage"
disp "${minyear} to ${maxyear}"
disp "varlist $varlist"
disp "nperiods ${nperiods}"

if $combine == 0 {
	local i = 1
	foreach control in "" "occup" "region" "occup region" {
		local varlist = "$varlist `control'"
		local p = 1
		global akm_start = $minyear
		global akm_end = $akm_start + $periodlength
		local akm = 1
		while `akm' <= $nperiods {
			use person age edu occup persid loc using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
			egen region = group(loc)
			replace occup = floor(occup/10)
			qui egen ed = cut(edu), at(0,7,12,16,30) icodes
			qui drop edu
			qui rename ed edu
			* collapse to period level
			qui collapse (first) person (median) `varlist' (count) weight = person, by(persid) fast
			foreach var in `varlist' {
				qui replace `var' = round(`var')
			}
			* regress to get coefficients
			local list = ""
			foreach va in `varlist' {
				local list = "`list' i.`va'"
			}
			reg person `list' [fw=weight]
			if `i' == 1 {
				qui outreg2 using "$OUTREGPATH/secondstage_workers_${varlist}_reg", replace stats(coef se Var sum_w) ctitle("period `p'") excel
			}
			else {
				qui outreg2 using "$OUTREGPATH/secondstage_workers_${varlist}_reg", stats(coef se Var sum_w) ctitle("period `p'") excel
			}
			* assign the coefficients of each group
			foreach var in `varlist' {
				qui sum `var'
				qui local e1 = r(min)
				qui local e2 = r(max)
				qui gen b_`var' = .
				forvalues ee = `e1'/`e2' {
					qui count if `var' == `ee'
					if r(N) > 0 qui replace b_`var' = _b[`ee'.`var'] if `var' == `ee'
				}
			}
			qui gen b = 0
			foreach var in `varlist'{
				qui replace b = b + b_`var'
			}
			collapse (first) b (sum) num = weight, by(`varlist') fast

			qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
			
			save "$SAVE_SUMMARYSTATS/workereffect_decomposition_`varlist'_${akm_start}_${akm_end}", replace
			
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
			local p = `p'+1
			local i = `i'+1
			local akm = `akm'+1
		}
	}
}
else {
	local i = 1
	foreach varlist in "age" "edu" "age edu" {
		foreach control in "" "occup" "region" "occup region" {
			local var = "`varlist' `control'"
			disp "Combining worker effect decomposition for `var' from each subperiod"
			global akm_start = $minyear
			global akm_end = $akm_start + $periodlength
			while $akm_end <= $maxyear {
				if $akm_start == $minyear qui use "$SAVE_SUMMARYSTATS/workereffect_decomposition_`var'_${akm_start}_${akm_end}", clear
				else qui append using "$SAVE_SUMMARYSTATS/workereffect_decomposition_`var'_${akm_start}_${akm_end}"
				global akm_start = $akm_start + $periodlength
				global akm_end = $akm_end + $periodlength
			}

			* evaluate the impact of changing coefficients vs changing composition
			qui egen id = group(`var')
			drop if id == .
			reshape wide b `list' num, i(id) j(period)
			qui drop id
			
			* store for extraction
			if `i' == 1 {
				qui export excel "$OUTREGPATH/secondstage_workers_var.xls", firstrow(variables) sheet("`var'") replace
			}
			else {
				qui export excel "$OUTREGPATH/secondstage_workers_var.xls", firstrow(variables) sheet("`var'")
			}
			local i = `i'+1
		}
	}
}
