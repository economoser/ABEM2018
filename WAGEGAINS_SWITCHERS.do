* *****************************************************************************************
* Wage gains of switchers
*
* "Firms and the Decline in Earnings Inequality in Brazil"
*
* by Jorge Alvarez (International Monetary Fund),
* Benguria Benguria (University of Kentucky),
* Niklas Engbom (Princeton University), and
* Christian Moser (Columbia University)
*
* This file may be used to reproduce figure 10
*
* First created: 10/09/2014
* Last edited: 06/24/2017
********************************************************************************
set more off
clear all

* start by constructing results conditioning on stable employees
global stableemployment = 1

global akm_start = $minyear
global akm_end = $akm_start + $periodlength
local akm = 1
while `akm' <= $nperiods {	

	* we need data on two years prior to separation and two years after, so these are the possible
	* years of separation
	local mm1 = $akm_start + 2
	local mm2 = $akm_end - 2
	* because potentially the same individual could end up in the group of separators twice (he could
	* for instance be displaced in both 1990 and 1993 if the akm subperiod is set to be sufficiently
	* long), we will need to generate a new ID to identify separate separations for the same individual
	local maxid = 0
	
	* loop over the possible years of separation
	forvalues yyyy = `mm1'/`mm2' {
		
		* Load the relevant data covering two years before and two years after the year of separation
		local yyyy1 = `yyyy'-2
		local yyyy2 = `yyyy'+2
		qui use wage firm empresa_fic persid ano if ano >= `yyyy1' & ano <= `yyyy2' using "$SAVE_CLEANED/lset_0_${akm_start}_${akm_end}.dta", clear
	
		* average log earnings of coworkers at the firm in the year of the potential switch and the 
		* consequtive year
		local mm = `yyyy'+1
		qui gen avgwage = .
		forvalues yy = `yyyy'/`mm' {
			* calculate the total wage bill of the firm in the relevant year
			qui bys empresa_fic: egen w = total(wage) if ano == `yy'
			* calculate the number of employees in the relevant year
			qui bys empresa_fic: egen nr = count(wage) if ano == `yy'
			* construct the average wage of coworkers
			qui replace avgwage = (w - wage)/(nr - 1) if ano == `yy'
			qui drop w nr
		}
		
		* quartile of firm effect and average earnings of coworkers in the year of the potential switch 
		* and the consequtive year
		foreach var in firm avgwage {
			qui gen quartile_`var' = .
			forvalues yy = `yyyy'/`mm' {
				qui fastxtile quar = `var' if ano == `yy', nquantiles(4)
				qui replace quartile_`var' = quar if ano == `yy'
				qui drop quar
			}
			qui drop `var'
		}
		
		* we focus on switchers who had been employed by the same employer two years prior to separation
		* and stays at the same employer for two years after separation. Hence we only need to consider those
		* with observations for the full time period
		if $stableemployment == 1 {
			qui bys persid: egen co = count(wage)
			qui keep if co == 5
			qui drop co
		}
		* restrict attention to only switchers in the year of consideration
		qui sort persid ano
		qui gen switch = 1 if empresa_fic != empresa_fic[_n+1] & persid == persid[_n+1] & ano == `yyyy' & ano[_n+1] == `yyyy'+1
		qui bys persid: egen sw = max(switch)
		qui drop switch
		keep if sw < .
		qui drop sw
		* normalize years
		qui replace ano = ano-`yyyy'
		
		if $stableemployment == 1 {
			* only those employed at the same firm for two consequtive years before and after
			qui sort persid ano
			* drop individuals who didn't stay for two years prior and post
			qui gen dr = 1 if empresa_fic[_n-2] != empresa_fic & ano == 0 & persid[_n-2] == persid
			qui replace dr = 1 if empresa_fic[_n-1] != empresa_fic & ano == 0 & persid[_n-1] == persid
			qui replace dr = 1 if empresa_fic[_n+1] != empresa_fic & ano == 1 & persid[_n+1] == persid
			qui bys persid: egen d = max(dr)
			drop if d == 1
			qui drop d dr
		}
		
		* Generate a new identifier
		qui egen id = group(persid)
		* update the identifier to be unique when appended with the previous year
		qui replace id = id+`maxid'
		qui sum id
		* update the maximum individual ID for the next iteration
		qui local maxid = r(max)
		
		disp "SAVE FOR THE FIRST TIME:"
		save "$SAVE_CLEANED/switchers_by_quartile_byperiod_`yyyy'", replace
		
	}
	
	* append the generated files for each of the years of this akm subperiod
	use "$SAVE_CLEANED/switchers_by_quartile_byperiod_`mm1'", clear
	local mm = `mm1'+1
	if `mm' <= `mm2' {
		forvalues yyyy = `mm'/`mm2' {
			append using "$SAVE_CLEANED/switchers_by_quartile_byperiod_`yyyy'"
		}
	}
	
	* switch by firm effect quartile
	preserve
	* quartile before switch
	qui gen q = quartile_firm if ano == 0
	qui bys id: egen quartile_before = max(q)
	qui drop q
	* quartile after switch
	qui gen q = quartile_firm if ano == 1
	qui bys id: egen quartile_after = max(q)
	qui drop q
	collapse (mean) wage (count) num_of_workers = wage, by(quartile_before quartile_after ano)
	qui rename ano year
	qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
	
	disp "SAVE FOR THE SECOND TIME:"
	save "$SAVE_CLEANED/switchers_by_firmeffects_byperiod_${akm_start}_${akm_end}", replace
	restore

	* switch by average coworker wage quartile
	* quartile before switch
	qui gen q = quartile_avgwage if ano == 0
	qui bys id: egen quartile_before = max(q)
	qui drop q
	* quartile after switch
	qui gen q = quartile_avgwage if ano == 1
	qui bys id: egen quartile_after = max(q)
	qui drop q
	collapse (mean) wage (count) num_of_workers = wage, by(quartile_before quartile_after ano)
	qui rename ano year
	qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
	disp "SAVE FOR THE THIRD TIME:"
	save "$SAVE_CLEANED/switchers_by_coworkerwage_byperiod_${akm_start}_${akm_end}", replace

	global akm_start = $akm_start + $periodlength
	global akm_end = $akm_end + $periodlength
	local akm = `akm' + 1
}

* combine the files for the different akm subperiods
global akm_start = $minyear
global akm_end = $akm_start + $periodlength
local akm = 1
while `akm' <= $nperiods {
	if `akm' == 1 qui use "$SAVE_CLEANED/switchers_by_firmeffects_byperiod_${akm_start}_${akm_end}", clear
	else qui append using "$SAVE_CLEANED/switchers_by_firmeffects_byperiod_${akm_start}_${akm_end}"
	global akm_start = $akm_start + $periodlength
	global akm_end = $akm_end + $periodlength
	local akm = `akm'+1
}
qui outsheet period quartile_before quartile_after year wage num_of_workers using "$SAVE_SUMMARYSTATS/switchers_by_firmeffects_stable_byperiod_${minyear}_${maxyear}.csv", delimiter(";") nolabel noquote replace

global akm_start = $minyear
global akm_end = $akm_start + $periodlength
local akm = 1
while `akm' <= $nperiods {
	if `akm' == 1 qui use "$SAVE_CLEANED/switchers_by_coworkerwage_byperiod_${akm_start}_${akm_end}", clear
	else qui append using "$SAVE_CLEANED/switchers_by_coworkerwage_byperiod_${akm_start}_${akm_end}"
	global akm_start = $akm_start + $periodlength
	global akm_end = $akm_end + $periodlength
	local akm = `akm'+1
}
qui outsheet period quartile_before quartile_after year wage num_of_workers using "$SAVE_SUMMARYSTATS/switchers_by_coworkerwage_stable_byperiod_${minyear}_${maxyear}.csv", delimiter(";") nolabel noquote replace



* construct results for all workers
global stableemployment = 0
global akm_start = $minyear
global akm_end = $akm_start + $periodlength
local akm = 1
while `akm' <= $nperiods {

	* we need data on two years prior to separation and two years after, so these are the possible
	* years of separation
	local mm1 = $akm_start + 2
	local mm2 = $akm_end - 2
	* because potentially the same individual could end up in the group of separators twice (he could
	* for instance be displaced in both 1990 and 1993 if the akm subperiod is set to be sufficiently
	* long), we will need to generate a new ID to identify separate separations for the same individual
	local maxid = 0
	
	* loop over the possible years of separation
	forvalues yyyy = `mm1'/`mm2' {
		
		* Load the relevant data covering two years before and two years after the year of separation
		local yyyy1 = `yyyy'-2
		local yyyy2 = `yyyy'+2
		qui use wage firm empresa_fic persid ano if ano >= `yyyy1' & ano <= `yyyy2' using "$SAVE_CLEANED/lset_0_${akm_start}_${akm_end}.dta", clear
	
		* average log earnings of coworkers at the firm in the year of the potential switch and the 
		* consequtive year
		local mm = `yyyy'+1
		qui gen avgwage = .
		forvalues yy = `yyyy'/`mm' {
			* calculate the total wage bill of the firm in the relevant year
			qui bys empresa_fic: egen w = total(wage) if ano == `yy'
			* calculate the number of employees in the relevant year
			qui bys empresa_fic: egen nr = count(wage) if ano == `yy'
			* construct the average wage of coworkers
			qui replace avgwage = (w-wage)/(nr-1) if ano == `yy'
			qui drop w nr
		}
		
		* quartile of firm effect and average earnings of coworkers in the year of the potential switch 
		* and the consequtive year
		foreach var in firm avgwage {
			qui gen quartile_`var' = .
			forvalues yy = `yyyy'/`mm' {
				qui fastxtile quar = `var' if ano == `yy', nquantiles(4)
				qui replace quartile_`var' = quar if ano == `yy'
				qui drop quar
			}
			qui drop `var'
		}
		
		* we focus on switchers who had been employed by the same employer two years prior to separation
		* and stays at the same employer for two years after separation. Hence we only need to consider those
		* with observations for the full time period
		if $stableemployment == 1 {
			qui bys persid: egen co = count(wage)
			qui keep if co == 5
			qui drop co
		}
		* restrict attention to only switchers in the year of consideration
		qui sort persid ano
		qui gen switch = 1 if empresa_fic != empresa_fic[_n+1] & persid == persid[_n+1] & ano == `yyyy' & ano[_n+1] == `yyyy'+1
		qui bys persid: egen sw = max(switch)
		qui drop switch
		keep if sw < .
		qui drop sw
		* normalize years
		qui replace ano = ano-`yyyy'
		
		if $stableemployment == 1 {
			* only those employed at the same firm for two consequtive years before and after
			qui sort persid ano
			* drop individuals who didn't stay for two years prior and post
			qui gen dr = 1 if empresa_fic[_n-2] != empresa_fic & ano == 0 & persid[_n-2] == persid
			qui replace dr = 1 if empresa_fic[_n-1] != empresa_fic & ano == 0 & persid[_n-1] == persid
			qui replace dr = 1 if empresa_fic[_n+1] != empresa_fic & ano == 1 & persid[_n+1] == persid
			qui bys persid: egen d = max(dr)
			drop if d == 1
			qui drop d dr
		}
		
		* Generate a new identifier
		qui egen id = group(persid)
		* update the identifier to be unique when appended with the previous year
		qui replace id = id+`maxid'
		qui sum id
		* update the maximum individual ID for the next iteration
		qui local maxid = r(max)
		
		disp "SAVE FOR THE FOURTH TIME:"
		save "$SAVE_CLEANED/switchers_by_quartile_byperiod_`yyyy'", replace
		
	}
	
	* append the generated files for each of the years of this akm subperiod
	use "$SAVE_CLEANED/switchers_by_quartile_byperiod_`mm1'", clear
	local mm = `mm1'+1
	if `mm' <= `mm2' {
		forvalues yyyy = `mm'/`mm2' {
			append using "$SAVE_CLEANED/switchers_by_quartile_byperiod_`yyyy'"
		}
	}
	
	* switch by firm effect quartile
	preserve		
	* quartile before switch
	qui gen q = quartile_firm if ano == 0
	qui bys id: egen quartile_before = max(q)
	qui drop q
	* quartile after switch
	qui gen q = quartile_firm if ano == 1
	qui bys id: egen quartile_after = max(q)
	qui drop q
	collapse (mean) wage (count) num_of_workers = wage, by(quartile_before quartile_after ano)
	qui rename ano year
	qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)
	disp "SAVE FOR THE FIFTH TIME:"
	save "$SAVE_CLEANED/switchers_by_firmeffects_byperiod_${akm_start}_${akm_end}", replace
	restore

	* switch by average coworker wage quartile
	* quartile before switch
	qui gen q = quartile_avgwage if ano == 0
	qui bys id: egen quartile_before = max(q)
	qui drop q
	* quartile after switch
	qui gen q = quartile_avgwage if ano == 1
	qui bys id: egen quartile_after = max(q)
	qui drop q
	collapse (mean) wage (count) num_of_workers = wage, by(quartile_before quartile_after ano)
	qui rename ano year
	qui gen period = 1*($akm_start == 1988) + 2*($akm_start == 1992) + 3*($akm_start == 1996) + 4*($akm_start == 2000) + 5*($akm_start == 2004) + 6*($akm_start == 2008)	
	disp "SAVE FOR THE SIXTH TIME:"
	save "$SAVE_CLEANED/switchers_by_coworkerwage_byperiod_${akm_start}_${akm_end}", replace

	global akm_start = $akm_start + $periodlength
	global akm_end = $akm_end + $periodlength
	local akm = `akm'+1
	
}

* combine the files for the different akm subperiods
global akm_start = $minyear
global akm_end = $akm_start + $periodlength
local akm = 1
while `akm' <= $nperiods {
	if `akm' == 1 qui use "$SAVE_CLEANED/switchers_by_firmeffects_byperiod_${akm_start}_${akm_end}", clear
	else qui append using "$SAVE_CLEANED/switchers_by_firmeffects_byperiod_${akm_start}_${akm_end}"
	global akm_start = $akm_start + $periodlength
	global akm_end = $akm_end + $periodlength
	local akm = `akm'+1
}
qui outsheet period quartile_before quartile_after year wage num_of_workers using "$SAVE_SUMMARYSTATS/switchers_by_firmeffects_unstable_byperiod_${minyear}_${maxyear}.csv", delimiter(";") nolabel noquote replace

global akm_start = $minyear
global akm_end = $akm_start + $periodlength
local akm = 1
while `akm' <= $nperiods {
	if `akm' == 1 qui use "$SAVE_CLEANED/switchers_by_coworkerwage_byperiod_${akm_start}_${akm_end}", clear
	else qui append using "$SAVE_CLEANED/switchers_by_coworkerwage_byperiod_${akm_start}_${akm_end}"
	global akm_start = $akm_start + $periodlength
	global akm_end = $akm_end + $periodlength
	local akm = `akm'+1
}
qui outsheet period quartile_before quartile_after year wage num_of_workers using "$SAVE_SUMMARYSTATS/switchers_by_coworkerwage_unstable_byperiod_${minyear}_${maxyear}.csv", delimiter(";") nolabel noquote replace


