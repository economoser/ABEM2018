********************************************************************************
* Summary statistics
*
* "Firms and the Decline in Earnings Inequality in Brazil"
*
* by Jorge Alvarez (International Monetary Fund),
* Benguria Benguria (University of Kentucky),
* Niklas Engbom (Princeton University), and
* Christian Moser (Columbia University)
*
* This file may be used to reproduce figures 1-4, B1, C1-C3, and tables 1, 2 and
* F1.
*
* First created: 10/09/2014
* Last edited: 06/24/2017
********************************************************************************

* Program summary:
* ( 1) LSET by period;
* ( 2) LSET by year;
* ( 3) CLEANED by period;
* ( 4) CLEANED by year;
* ( 5) SELECTION by period;
* ( 6) SELECTION by year;
* ( 7) SELECTION IN PIA by period;
* ( 8) SELECTION IN PIA by year;
* ( 9) PIA firm characteristics by period;
* (10) PIA firm characteristics by year;
* (11) Between and within firms/sectors/occupations/individuals by period;
* (12) Between and within firms/sectors/occupations/individuals by year;
* (13) Densities of raw wages by period;
* (14) Densities of raw wages by year;
* (15) Basic summary stats by education and sector
* (16) Between and within firms, subgroup analysis

set more off
set rmsg on
cap log c

* set LSET source file
global debug = 0 // 0 = do not debug; 1 = debug using small samples

* set parts to run
global lsetbyperiod = 0 // (1)
global lsetbyyear = 0 // (2)
global cleanedbyperiod = 0 // (3)
global cleanedbyyear = 0 // (4)
global selectionbyperiod = 0 // (5)
global selectionbyyear = 0 // (6)
global selectionPIAbyperiod = 0 // (7)
global selectionPIAbyyear = 0 // (8)
global piafirmcharsbyperiod = 0 // (9)
global piafirmcharsbyyear = 0 // (10)
global betweenwithinbyperiod = 0 // (11)
global betweenwithinbyyear = 0 // (12)
global densitiesbyperiod = 0 // (13)
global densitiesbyyear = 0 // (14)
global edusectorstats = 0 // (15)

if "$minyear" == "" | "$maxyear" == "" {
	global minyear = 1988
	global maxyear = 2012
}




**************************************************
*** (1) LSET by period
**************************************************
if $lsetbyperiod == 1 {
	if $minyear > 1988 global akm_start = $minyear
	else global akm_start = 1988
	global akm_end = $akm_start + $periodlength
	global akm = 1
	cap postclose lset_periodstats
	postfile lset_periodstats period nworkerys nworkers nfirmys nfirms me std var gini skew kurt p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/lset_periodstats", replace
	while $akm <= $nperiods {
		if $akm_end <= 2012 {
			disp "*** PERIOD $akm_start - $akm_end ***"
			use ano wage persid empresa_fic fsize age edu using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", clear
			if $debug == 1 keep if _n <= 1000
			scalar period = ($akm_start - 1984)/4
			
			* number of worker-years
			qui count if wage != .
			scalar nworkerys = log(r(N))
			
			* number of workers
			qui bys persid: gen nworker = 1 if _n==_N
			qui count if nworker == 1
			scalar nworkers = log(r(N))
			qui drop nworker
			
			* number of firm-years
			qui bys empresa_fic ano: gen nfirmy = 1 if _n==_N
			qui count if nfirmy == 1
			scalar nfirmys = log(r(N))
			qui drop nfirmy
			
			* number of firms
			qui bys empresa_fic: gen nfirm = 1 if _n==_N
			qui count if nfirm == 1
			scalar nfirms = log(r(N))
			qui drop nfirm
			
			* population
			qui sum wage
			scalar me = r(mean)
			qui bys ano: egen wage_mean = mean(wage)
			qui gen wage_demeaned = wage - wage_mean
			qui sum wage_demeaned, d
			scalar std = r(sd)
			scalar var = r(Var)
			foreach num in 1 5 10 25 50 75 90 95 99 {
				scalar p`num'00 = r(p`num')
			}
			scalar skew = r(skewness)
			scalar kurt = r(kurtosis)
			scalar gini = .
				
			* Size of firms
			qui sum fsize
			scalar me_fsize = r(mean)
			scalar sd_fsize = r(sd)
			scalar var_fsize = r(Var)
			
			* number of individuals close to minimum wage
			qui count if (wage > .95 & wage < 1.05) 
			scalar minwfrac = r(N)/exp(nworkerys)
			
			* demographics
			qui gen age_n = 14*(age == 0) ///
					+ 21*(age == 1) ///
					+ 27*(age == 2) ///
					+ 34*(age == 3) ///
					+ 44*(age == 4) ///
					+ 57*(age == 5) ///
					+ 70*(age == 6)
			qui sum age_n
			scalar me_age = r(mean)
			scalar sd_age = r(sd)
			qui sum edu
			scalar me_edu = r(mean)
			scalar sd_edu = r(sd)
			
			post lset_periodstats (period) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
		}
		
		* loop
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		global akm = $akm + 1
	}
	postclose lset_periodstats
	qui use "$SAVE_SUMMARYSTATS/lset_periodstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/lset_periodstats.xls", replace firstrow(variables)
}




**************************************************
*** (2) LSET by year
**************************************************
if $lsetbyyear == 1 {
	if $minyear > 1988 global akm_start = $minyear
	else global akm_start = 1988
	global akm_end = $akm_start + $periodlength
	global akm = 1
	cap postclose lset_yearstats
	postfile lset_yearstats year nworkerys nworkers nfirmys nfirms me std var gini skew kurt p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/lset_yearstats", replace
	while $akm <= $nperiods {
		if $akm == 1 local loop_start = $akm_start
		if $akm > 1 local loop_start = $akm_start + 1
		foreach yyyy of numlist `loop_start'/$akm_end {
			disp "*** YEAR `yyyy' ***"
			use ano wage persid empresa_fic fsize age edu if ano == `yyyy' using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", clear
			if $debug == 1 keep if _n <= 1000
			scalar year = `yyyy'
			
			* number of worker-years
			qui count if wage != .
			scalar nworkerys = log(r(N))
			
			* number of workers
			qui bys persid: gen nworker = 1 if _n==_N
			qui count if nworker == 1
			scalar nworkers = log(r(N))
			qui drop nworker
			
			* number of firm-years
			qui bys empresa_fic ano: gen nfirmy = 1 if _n==_N
			qui count if nfirmy == 1
			scalar nfirmys = log(r(N))
			qui drop nfirmy
			
			* number of firms
			qui bys empresa_fic: gen nfirm = 1 if _n==_N
			qui count if nfirm == 1
			scalar nfirms = log(r(N))
			qui drop nfirm
			
			* population
			qui sum wage, d
			scalar me = r(mean)
			scalar std = r(sd)
			scalar var = r(Var)
			foreach num in 1 5 10 25 50 75 90 95 99 {
				scalar p`num'00 = r(p`num')
			}
			scalar skew = r(skewness)
			scalar kurt = r(kurtosis)
			qui gen wagelevel = exp(wage)
			qui ineqdeco wagelevel
			scalar gini = r(gini)
				
			* Size of firms
			qui sum fsize
			scalar me_fsize = r(mean)
			scalar sd_fsize = r(sd)
			scalar var_fsize = r(Var)
			
			* number of individuals close to minimum wage
			qui count if (wage > .95 & wage < 1.05) 
			scalar minwfrac = r(N)/exp(nworkerys)
			
			* demographics
			qui gen age_n = 14*(age == 0) ///
					+ 21*(age == 1) ///
					+ 27*(age == 2) ///
					+ 34*(age == 3) ///
					+ 44*(age == 4) ///
					+ 57*(age == 5) ///
					+ 70*(age == 6)
			qui sum age_n
			scalar me_age = r(mean)
			scalar sd_age = r(sd)
			qui sum edu
			scalar me_edu = r(mean)
			scalar sd_edu = r(sd)
			
			post lset_yearstats (year) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
		}
		
		* loop
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		global akm = $akm + 1
	}
	postclose lset_yearstats
	qui use "$SAVE_SUMMARYSTATS/lset_yearstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/lset_yearstats.xls", replace firstrow(variables)
}


**************************************************
*** (3) CLEANED by period
**************************************************
if $cleanedbyperiod == 1 {
	if $minyear > 1988 global akm_start = $minyear
	else global akm_start = 1988
	global akm_end = $akm_start + $periodlength
	global akm = 1
	disp "CLEANED FOR PERIOD $akm_start - $akm_end_start - $akm_end"
	cap postclose cleaned_periodstats
	postfile cleaned_periodstats period nworkerys nworkers nfirmys nfirms me std var gini skew kurt p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/cleaned_periodstats", replace
	while $akm <= $nperiods & $akm_start <= 2012 {
		disp "*** PERIOD $akm_start - $akm_end ***"
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' == $akm_start use ano wage persid empresa_fic fsize_fte idade educ_year using "$SAVE_CLEANED/cleaned`yyyy'", clear
			else if $debug == 0 append using "$SAVE_CLEANED/cleaned`yyyy'", keep(ano wage persid empresa_fic fsize_fte idade educ_year)
			if $debug == 1 {
				if `yyyy' == $minyear local numobsi = 1000
				else local numobsi = `numobsi' + 1000
				keep if _n <= `numobsi'
			}
		}
		scalar period = ($akm_start - 1984)/4
		
		* number of worker-years
		qui count if wage != .
		scalar nworkerys = log(r(N))
		
		* number of workers
		qui bys persid: gen nworker = 1 if _n==_N
		qui count if nworker == 1
		scalar nworkers = log(r(N))
		qui drop nworker
		
		* number of firm-years
		qui bys empresa_fic ano: gen nfirmy = 1 if _n==_N
		qui count if nfirmy == 1
		scalar nfirmys = log(r(N))
		qui drop nfirmy
		
		* number of firms
		qui bys empresa_fic: gen nfirm = 1 if _n==_N
		qui count if nfirm == 1
		scalar nfirms = log(r(N))
		qui drop nfirm
		
		* population
		qui sum wage
		scalar me = r(mean)
		qui bys ano: egen wage_mean = mean(wage)
		qui gen wage_demeaned = wage - wage_mean
		qui sum wage_demeaned, d
		scalar std = r(sd)
		scalar var = r(Var)
		foreach num in 1 5 10 25 50 75 90 95 99 {
			scalar p`num'00 = r(p`num')
		}
		scalar skew = r(skewness)
		scalar kurt = r(kurtosis)
		scalar gini = .
			
		* Size of firms
		qui sum fsize_fte
		scalar me_fsize = r(mean)
		scalar sd_fsize = r(sd)
		scalar var_fsize = r(Var)
		
		* number of individuals close to minimum wage
		qui count if (wage >.95 & wage <1.05) 
		scalar minwfrac = r(N)/exp(nworkerys)
		
		* demographics
		qui gen age_n = 14*(idade == 0) ///
				+ 21*(idade == 1) ///
				+ 27*(idade == 2) ///
				+ 34*(idade == 3) ///
				+ 44*(idade == 4) ///
				+ 57*(idade == 5) ///
				+ 70*(idade == 6)
		qui sum age_n
		scalar me_age = r(mean)
		scalar sd_age = r(sd)
		qui sum educ_year
		scalar me_edu = r(mean)
		scalar sd_edu = r(sd)
		
		post cleaned_periodstats (period) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
		
		* loop
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		global akm = $akm + 1
	}
	postclose cleaned_periodstats
	qui use "$SAVE_SUMMARYSTATS/cleaned_periodstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/cleaned_periodstats.xls", replace firstrow(variables)
}


**************************************************
*** (4) CLEANED by year
**************************************************
if $cleanedbyyear == 1 {
	clear all
	cap postclose cleaned_yearstats
	postfile cleaned_yearstats year nworkerys nworkers nfirmys nfirms me std var gini skew kurt p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/cleaned_yearstats", replace
	forvalues yyyy = $minyear/$maxyear {
		disp "*** YEAR `yyyy' ***"
		use ano wage persid empresa_fic fsize_fte idade educ_year using "$SAVE_CLEANED/cleaned`yyyy'", clear
		if $debug == 1 keep if _n <= 1000
		scalar year = `yyyy'
		
		* number of worker-years
		qui count if wage != .
		scalar nworkerys = log(r(N))
		
		* number of workers
		qui bys persid: gen nworker = 1 if _n==_N
		qui count if nworker == 1
		scalar nworkers = log(r(N))
		qui drop nworker
		
		* number of firm-years
		qui bys empresa_fic ano: gen nfirmy = 1 if _n==_N
		qui count if nfirmy == 1
		scalar nfirmys = log(r(N))
		qui drop nfirmy
		
		* number of firms
		qui bys empresa_fic: gen nfirm = 1 if _n==_N
		qui count if nfirm == 1
		scalar nfirms = log(r(N))
		qui drop nfirm
		
		* population
		qui sum wage, d
		scalar me = r(mean)
		scalar std = r(sd)
		scalar var = r(Var)
		foreach num in 1 5 10 25 50 75 90 95 99 {
			scalar p`num'00 = r(p`num')
		}
		scalar skew = r(skewness)
		scalar kurt = r(kurtosis)
		qui gen wagelevel = exp(wage)
		qui ineqdeco wagelevel
		scalar gini = r(gini)
			
		* Size of firms
		qui sum fsize_fte
		scalar me_fsize = r(mean)
		scalar sd_fsize = r(sd)
		scalar var_fsize = r(Var)
		
		* number of individuals close to minimum wage
		qui count if (wage >.95 & wage <1.05)
		scalar minwfrac = r(N)/exp(nworkerys)
		
		* demographics
		qui gen age_n = 14*(idade == 0) ///
				+ 21*(idade == 1) ///
				+ 27*(idade == 2) ///
				+ 34*(idade == 3) ///
				+ 44*(idade == 4) ///
				+ 57*(idade == 5) ///
				+ 70*(idade == 6)
		qui sum age_n
		scalar me_age = r(mean)
		scalar sd_age = r(sd)
		qui sum educ_year
		scalar me_edu = r(mean)
		scalar sd_edu = r(sd)
		
		post cleaned_yearstats (year) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
	}
	postclose cleaned_yearstats
	qui use "$SAVE_SUMMARYSTATS/cleaned_yearstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/cleaned_yearstats.xls", replace firstrow(variables)
}




**************************************************
*** (5) SELECTION by period
**************************************************
if $selectionbyperiod == 1 {
	if $minyear > 1988 global akm_start = $minyear
	else global akm_start = 1988
	global akm_end = $akm_start + $periodlength
	global akm = 1
	cap postclose selection_periodstats
	postfile selection_periodstats period nworkerys nworkers nfirmys nfirms me std var gini skew kurt p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/selection_periodstats", replace
	while $akm <= $nperiods & $akm_end <= 2012 {
		disp "*** PERIOD $akm_start - $akm_end ***"
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' == $akm_start use ano wage persid empresa_fic fsize age edu using "$SAVE_CLEANED/selection`yyyy'", clear
			else if $debug == 0 append using "$SAVE_CLEANED/selection`yyyy'", keep(ano wage persid empresa_fic fsize age edu)
			if $debug == 1 {
				if `yyyy' == $minyear local numobsi = 1000
				else local numobsi = `numobsi' + 1000
				keep if _n <= `numobsi'
			}
		}
		scalar period = ($akm_start - 1984)/4
		
		* number of worker-years
		qui count if wage != .
		scalar nworkerys = log(r(N))
		
		* number of workers
		qui bys persid: gen nworker = 1 if _n==_N
		qui count if nworker == 1
		scalar nworkers = log(r(N))
		qui drop nworker
		
		* number of firm-years
		qui bys empresa_fic ano: gen nfirmy = 1 if _n==_N
		qui count if nfirmy == 1
		scalar nfirmys = log(r(N))
		qui drop nfirmy
		
		* number of firms
		qui bys empresa_fic: gen nfirm = 1 if _n==_N
		qui count if nfirm == 1
		scalar nfirms = log(r(N))
		qui drop nfirm
		
		* population
		qui sum wage
		scalar me = r(mean)
		qui bys ano: egen wage_mean = mean(wage)
		qui gen wage_demeaned = wage - wage_mean
		qui sum wage_demeaned, d
		scalar std = r(sd)
		scalar var = r(Var)
		foreach num in 1 5 10 25 50 75 90 95 99 {
			scalar p`num'00 = r(p`num')
		}
		scalar skew = r(skewness)
		scalar kurt = r(kurtosis)
		scalar gini = .
			
		* Size of firms
		qui sum fsize
		scalar me_fsize = r(mean)
		scalar sd_fsize = r(sd)
		scalar var_fsize = r(Var)
		
		* number of individuals close to minimum wage
		qui count if (wage >.95 & wage <1.05) 
		scalar minwfrac = r(N)/exp(nworkerys)
		
		* demographics
		qui gen age_n = 14*(age == 0) ///
				+ 21*(age == 1) ///
				+ 27*(age == 2) ///
				+ 34*(age == 3) ///
				+ 44*(age == 4) ///
				+ 57*(age == 5) ///
				+ 70*(age == 6)
		qui sum age_n
		scalar me_age = r(mean)
		scalar sd_age = r(sd)
		qui sum edu
		scalar me_edu = r(mean)
		scalar sd_edu = r(sd)
		
		post selection_periodstats (period) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
		
		* loop
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		global akm = $akm + 1
	}
	postclose selection_periodstats
	qui use "$SAVE_SUMMARYSTATS/selection_periodstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/selection_periodstats.xls", replace firstrow(variables)
}




**************************************************
*** (6) SELECTION by year
**************************************************
if $selectionbyyear == 1 {
	cap postclose selection_yearstats
	//postfile selection_yearstats year nworkers nfirms me std p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/selection_yearstats", replace
	postfile selection_yearstats year nworkers nfirms me std var gini skew kurt p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/selection_yearstats", replace
	forvalues yyyy = $minyear/$maxyear {
		disp "*** YEAR `yyyy' ***"
		use wage persid empresa_fic fsize age edu using "$SAVE_CLEANED/selection`yyyy'", clear
		if $debug == 1 keep if _n <= 1000
		scalar year=`yyyy'
		
		* number of worker
		qui count if wage != .
		scalar nworkerys = log(r(N))
		
		/* number of workers
		qui bys persid: gen nworker = 1 if _n==_N
		qui count if nworker == 1
		scalar nworkers = log(r(N))
		qui drop nworker*/
		
		* number of firms
		qui bys empresa_fic: gen nfirmy = 1 if _n==_N
		qui count if nfirmy == 1
		scalar nfirmys = log(r(N))
		qui drop nfirmy
		
		/* number of firms
		qui bys empresa_fic: gen nfirm = 1 if _n==_N
		qui count if nfirm == 1
		scalar nfirms = log(r(N))
		qui drop nfirm */
		
		* population
		qui sum wage
		scalar me = r(mean)
		qui egen wage_mean = mean(wage)
		qui gen wage_demeaned = wage - wage_mean
		qui sum wage_demeaned, d
		scalar std = r(sd)
		scalar var = r(Var)
		foreach num in 1 5 10 25 50 75 90 95 99 {
			scalar p`num'00 = r(p`num')
		}
		scalar skew = r(skewness)
		scalar kurt = r(kurtosis)
		qui gen wagelevel = exp(wage)
		qui ineqdeco wagelevel
		scalar gini = r(gini)
		
		/* Don't do this because of issues with small bins
		* lowest 10%
		qui sum wage_demeaned if wage_demeaned <= p1000, d
		foreach num in 1 5 {
			scalar p`num'0 = r(p`num')
		}
		
		* lowest 1%
		qui sum wage_demeaned if wage_demeaned <= p100, d
		foreach num in 1 5 {
			scalar p`num' = r(p`num')
		}
		
		* highest 10%
		qui sum wage_demeaned if wage_demeaned > p9000, d
		foreach num in 95 99 {
			local num2 = 9000 + `num'*10
			scalar p`num2' = r(p`num')
		}
		
		* highest 1%
		qui sum wage_demeaned if wage_demeaned > p9900, d
		foreach num in 95 99 {
			local num2 = 9900 + `num'
			scalar p`num2' = r(p`num')
		} */
			
		* Size of firms
		qui sum fsize
		scalar me_fsize = r(mean)
		scalar sd_fsize = r(sd)
		scalar var_fsize = r(Var)
		
		* number of individuals close to minimum wage
		qui count if (wage >.95 & wage <1.05) 
		scalar minwfrac = r(N)/exp(nworkerys)
		
		* demographics
		qui gen age_n = 14*(age == 0) ///
				+ 21*(age == 1) ///
				+ 27*(age == 2) ///
				+ 34*(age == 3) ///
				+ 44*(age == 4) ///
				+ 57*(age == 5) ///
				+ 70*(age == 6)
		qui sum age_n
		scalar me_age = r(mean)
		scalar sd_age = r(sd)
		qui sum edu
		scalar me_edu = r(mean)
		scalar sd_edu = r(sd)
		
		* post
		//post selection_yearstats (year) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
		post selection_yearstats (year) (nworkerys) (nfirmys) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
	}
	postclose selection_yearstats
	qui use "$SAVE_SUMMARYSTATS/selection_yearstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/selection_yearstats.xls", replace firstrow(variables)
}




**************************************************
*** (7) SELECTION IN PIA by period
**************************************************
if $selectionPIAbyperiod == 1 {
	if $minyear > 1996 global akm_start = $minyear
	else global akm_start = 1996
	global akm_end = $akm_start + $periodlength
	global akm = 1
	cap postclose selection_PIA_periodstats
	postfile selection_PIA_periodstats period nworkerys nworkers nfirmys nfirms me std var gini skew kurt p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu using "$SAVE_SUMMARYSTATS/selection_PIA_periodstats", replace
	while $akm <= $nperiods & $akm_end <= 2012 {
		disp "*** PERIOD $akm_start - $akm_end ***"
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' == $akm_start use ano wage persid empresa_fic fsize age edu using "$SAVE_CLEANED/selection_PIA_`yyyy'", clear
			else if $debug == 0 append using "$SAVE_CLEANED/selection_PIA_`yyyy'", keep(ano wage persid empresa_fic fsize age edu)
			if $debug == 1 {
				if `yyyy' == $minyear local numobsi = 1000
				else local numobsi = `numobsi' + 1000
				keep if _n <= `numobsi'
			}
		}
		scalar period = ($akm_start - 1984)/4
		
		* number of worker-years
		qui count if wage != .
		scalar nworkerys = log(r(N))
		
		* number of workers
		qui bys persid: gen nworker = 1 if _n==_N
		qui count if nworker == 1
		scalar nworkers = log(r(N))
		qui drop nworker
		
		* number of firm-years
		qui bys empresa_fic ano: gen nfirmy = 1 if _n==_N
		qui count if nfirmy == 1
		scalar nfirmys = log(r(N))
		qui drop nfirmy
		
		* number of firms
		qui bys empresa_fic: gen nfirm = 1 if _n==_N
		qui count if nfirm == 1
		scalar nfirms = log(r(N))
		qui drop nfirm
		
		* population
		qui sum wage
		scalar me = r(mean)
		qui bys ano: egen wage_mean = mean(wage)
		qui gen wage_demeaned = wage - wage_mean
		qui sum wage_demeaned, d
		scalar std = r(sd)
		scalar var = r(Var)
		foreach num in 1 5 10 25 50 75 90 95 99 {
			scalar p`num'00 = r(p`num')
		}
		scalar skew = r(skewness)
		scalar kurt = r(kurtosis)
		scalar gini = .
			
		* Size of firms
		qui sum fsize
		scalar me_fsize = r(mean)
		scalar sd_fsize = r(sd)
		scalar var_fsize = r(Var)
		
		* number of individuals close to minimum wage
		qui count if (wage >.95 & wage <1.05) 
		scalar minwfrac = r(N)/exp(nworkerys)
		
		* demographics
		qui gen age_n = 14*(age == 0) ///
				+ 21*(age == 1) ///
				+ 27*(age == 2) ///
				+ 34*(age == 3) ///
				+ 44*(age == 4) ///
				+ 57*(age == 5) ///
				+ 70*(age == 6)
		qui sum age_n
		scalar me_age = r(mean)
		scalar sd_age = r(sd)
		qui sum edu
		scalar me_edu = r(mean)
		scalar sd_edu = r(sd)
		
		post selection_PIA_periodstats (period) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) (p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) (me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
		
		* loop
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		global akm = $akm + 1
	}
	postclose selection_PIA_periodstats
	qui use "$SAVE_SUMMARYSTATS/selection_PIA_periodstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/selection_PIA_periodstats.xls", replace firstrow(variables)
}




**************************************************
*** (8) SELECTION IN PIA by year
**************************************************
if $selectionPIAbyyear == 1 {
	cap postclose selection_PIA_yearstats
	postfile selection_PIA_yearstats year nworkerys nworkers nfirmys nfirms me std var gini skew kurt ///
		p100 p500 p1000 p2500 p5000 p7500 p9000 p9500 p9900 ///
		me_fsize sd_fsize var_fsize minwfrac me_age sd_age me_edu sd_edu ///
		using "$SAVE_SUMMARYSTATS/selection_PIA_yearstats", replace
	forvalues yyyy = $minyear/$maxyear {
		if `yyyy' >= 1996 & `yyyy' <= 2012 {
			disp "*** YEAR `yyyy' ***"
			use ano wage persid empresa_fic fsize age edu using "$SAVE_CLEANED/selection_PIA_`yyyy'", clear
			if $debug == 1 keep if _n <= 1000
			scalar year=`yyyy'
			
			* number of worker-years
			qui count if wage != .
			scalar nworkerys = log(r(N))
			
			* number of workers
			qui bys persid: gen nworker = 1 if _n==_N
			qui count if nworker == 1
			scalar nworkers = log(r(N))
			qui drop nworker
			
			* number of firm-years
			qui bys empresa_fic ano: gen nfirmy = 1 if _n==_N
			qui count if nfirmy == 1
			scalar nfirmys = log(r(N))
			qui drop nfirmy
			
			* number of firms
			qui bys empresa_fic: gen nfirm = 1 if _n==_N
			qui count if nfirm == 1
			scalar nfirms = log(r(N))
			qui drop nfirm
			
			* Summarize variables for all observations
			qui sum wage, d
			scalar me = r(mean)
			scalar std = r(sd)
			scalar var = r(Var)
			foreach num in 1 5 10 25 50 75 90 95 99 {
				scalar p`num'00 = r(p`num')
			}
			scalar skew = r(skewness)
			scalar kurt = r(kurtosis)

			qui gen wagelevel = exp(wage)
			qui ineqdeco wagelevel
			scalar gini = r(gini)
			
			* Size of firms
			qui sum fsize
			scalar me_fsize = r(mean)
			scalar sd_fsize = r(sd)
			scalar var_fsize = r(Var)
			
			* Minimum wage and number of individuals
			qui count if (wage >.95 & wage <1.05) 
			scalar minwfrac = r(N) / nworkerys
			
			* demographics
			qui gen age_n = 14*(age == 0) ///
					+ 21*(age == 1) ///
					+ 27*(age == 2) ///
					+ 34*(age == 3) ///
					+ 44*(age == 4) ///
					+ 57*(age == 5) ///
					+ 70*(age == 6)
			qui sum age_n
			scalar me_age = r(mean)
			scalar sd_age = r(sd)
			qui sum edu
			scalar me_edu = r(mean)
			scalar sd_edu = r(sd)
			
			* post
			post selection_PIA_yearstats (year) (nworkerys) (nworkers) (nfirmys) (nfirms) (me) (std) (var) (gini) (skew) (kurt) ///
				(p100) (p500) (p1000) (p2500) (p5000) (p7500) (p9000) (p9500) (p9900) ///
				(me_fsize) (sd_fsize) (var_fsize) (minwfrac) (me_age) (sd_age) (me_edu) (sd_edu)
		}
	}
	postclose selection_PIA_yearstats
	qui use "$SAVE_SUMMARYSTATS/selection_PIA_yearstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/selection_PIA_yearstats.xls", replace firstrow(variables)
}




**************************************************
*** (9) PIA firm characteristics by period
**************************************************
if $piafirmcharsbyperiod == 1 {
	if $minyear > 1996 global akm_start = $minyear
	else global akm_start = 1996
	global akm_end = $akm_start + $periodlength
	global akm = 1
	cap postclose PIA_firm_periodstats
	postfile PIA_firm_periodstats period Nfirms Nfirmys ///
		N_va_pw_unw me_va_pw_unw sd_va_pw_unw N_va_pw_w me_va_pw_w sd_va_pw_w ///
		N_va_pw_resid_unw me_va_pw_resid_unw sd_va_pw_resid_unw N_va_pw_resid_w me_va_pw_resid_w sd_va_pw_resid_w ///
		N_va_pw_resid2_unw me_va_pw_resid2_unw sd_va_pw_resid2_unw N_va_pw_resid2_w me_va_pw_resid2_w sd_va_pw_resid2_w ///
		N_vbp_pw_unw me_vbp_pw_unw sd_vbp_pw_unw N_vbp_pw_w me_vbp_pw_w sd_vbp_pw_w ///
		N_vbp_pw_resid_unw me_vbp_pw_resid_unw sd_vbp_pw_resid_unw N_vbp_pw_resid_w me_vbp_pw_resid_w sd_vbp_pw_resid_w ///
		N_vbp_pw_resid2_unw me_vbp_pw_resid2_unw sd_vbp_pw_resid2_unw N_vbp_pw_resid2_w me_vbp_pw_resid2_w sd_vbp_pw_resid2_w ///
		N_capital_pw_unw me_capital_pw_unw sd_capital_pw_unw N_capital_pw_w me_capital_pw_w sd_capital_pw_w ///
		N_inv_v_pw_unw me_inv_v_pw_unw sd_inv_v_pw_unw N_inv_v_pw_w me_inv_v_pw_w sd_inv_v_pw_w ///
		N_export_intensity_unw me_export_intensity_unw sd_export_intensity_unw N_export_intensity_w me_export_intensity_w sd_export_intensity_w ///
		using "$SAVE_SUMMARYSTATS/PIA_firm_periodstats", replace
	while $akm <= $nperiods & $akm_end <= 2012 {
		disp "*** PERIOD $akm_start - $akm_end ***"
		forvalues yyyy = $akm_start/$akm_end {
			if `yyyy' == $akm_start use ano empresa_fic fsize capital_pw inv_v_pw va_pw va_pw_resid va_pw_resid2 vbp_pw vbp_pw_resid vbp_pw_resid2 export_intensity using "$SAVE_CLEANED/selection_PIA_`yyyy'", clear
			else if $debug == 0 append using "$SAVE_CLEANED/selection_PIA_`yyyy'", keep(ano empresa_fic fsize capital_pw inv_v_pw va_pw va_pw_resid va_pw_resid2 vbp_pw vbp_pw_resid vbp_pw_resid2 export_intensity)
			if $debug == 1 {
				if `yyyy' == $minyear local numobsi = 1000
				else local numobsi = `numobsi' + 1000
				keep if _n <= `numobsi'
			}
		}
		scalar period = ($akm_start - 1984)/4
		
		qui bys empresa_fic ano: gen firmind = 1 if _n == 1
		collapse (first) fsize capital_pw inv_v_pw va_pw va_pw_resid va_pw_resid2 vbp_pw vbp_pw_resid vbp_pw_resid2 export_intensity (count) N = ano Nfirmy = firmind, by(empresa_fic) fast
		
		scalar Nfirms = _N
		qui sum Nfirmy
		scalar Nfirmys = r(sum)
		
		foreach tag in "_w" "_unw" {
			foreach var of varlist fsize capital_pw inv_v_pw va_pw va_pw_resid va_pw_resid2 vbp_pw vbp_pw_resid vbp_pw_resid2 export_intensity {
				if "`tag'" == "_w" qui sum `var' [fw = N]
				else if "`tag'" == "_unw" qui sum `var'
				scalar N_`var'`tag' = r(N)
				scalar me_`var'`tag' = r(mean)
				scalar sd_`var'`tag' = r(sd)
			}
		}
		
		* post
		post PIA_firm_periodstats (period) (Nfirms) (Nfirmys) ///
			(N_va_pw_unw) (me_va_pw_unw) (sd_va_pw_unw) (N_va_pw_w) (me_va_pw_w) (sd_va_pw_w) ///
			(N_va_pw_resid_unw) (me_va_pw_resid_unw) (sd_va_pw_resid_unw) (N_va_pw_resid_w) (me_va_pw_resid_w) (sd_va_pw_resid_w) ///
			(N_va_pw_resid2_unw) (me_va_pw_resid2_unw) (sd_va_pw_resid2_unw) (N_va_pw_resid2_w) (me_va_pw_resid2_w) (sd_va_pw_resid2_w) ///
			(N_vbp_pw_unw) (me_vbp_pw_unw) (sd_vbp_pw_unw) (N_vbp_pw_w) (me_vbp_pw_w) (sd_vbp_pw_w) ///
			(N_vbp_pw_resid_unw) (me_vbp_pw_resid_unw) (sd_vbp_pw_resid_unw) (N_vbp_pw_resid_w) (me_vbp_pw_resid_w) (sd_vbp_pw_resid_w) ///
			(N_vbp_pw_resid2_unw) (me_vbp_pw_resid2_unw) (sd_vbp_pw_resid2_unw) (N_vbp_pw_resid2_w) (me_vbp_pw_resid2_w) (sd_vbp_pw_resid2_w) ///
			(N_capital_pw_unw) (me_capital_pw_unw) (sd_capital_pw_unw) (N_capital_pw_w) (me_capital_pw_w) (sd_capital_pw_w) ///
			(N_inv_v_pw_unw) (me_inv_v_pw_unw) (sd_inv_v_pw_unw) (N_inv_v_pw_w) (me_inv_v_pw_w) (sd_inv_v_pw_w) ///
			(N_export_intensity_unw) (me_export_intensity_unw) (sd_export_intensity_unw) (N_export_intensity_w) (me_export_intensity_w) (sd_export_intensity_w)
		
		* loop
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		global akm = $akm + 1
	}
	postclose PIA_firm_periodstats
	qui use "$SAVE_SUMMARYSTATS/PIA_firm_periodstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/PIA_firm_periodstats.xls", replace firstrow(variables)
}




**************************************************
*** (10) PIA firm characteristics by year
**************************************************
if $piafirmcharsbyyear == 1 {
	cap postclose PIA_firm_yearstats
	postfile PIA_firm_yearstats year Nfirms Nfirmys ///
		N_va_pw_unw me_va_pw_unw sd_va_pw_unw N_va_pw_w me_va_pw_w sd_va_pw_w ///
		N_va_pw_resid_unw me_va_pw_resid_unw sd_va_pw_resid_unw N_va_pw_resid_w me_va_pw_resid_w sd_va_pw_resid_w ///
		N_va_pw_resid2_unw me_va_pw_resid2_unw sd_va_pw_resid2_unw N_va_pw_resid2_w me_va_pw_resid2_w sd_va_pw_resid2_w ///
		N_vbp_pw_unw me_vbp_pw_unw sd_vbp_pw_unw N_vbp_pw_w me_vbp_pw_w sd_vbp_pw_w ///
		N_vbp_pw_resid_unw me_vbp_pw_resid_unw sd_vbp_pw_resid_unw N_vbp_pw_resid_w me_vbp_pw_resid_w sd_vbp_pw_resid_w ///
		N_vbp_pw_resid2_unw me_vbp_pw_resid2_unw sd_vbp_pw_resid2_unw N_vbp_pw_resid2_w me_vbp_pw_resid2_w sd_vbp_pw_resid2_w ///
		N_capital_pw_unw me_capital_pw_unw sd_capital_pw_unw N_capital_pw_w me_capital_pw_w sd_capital_pw_w ///
		N_inv_v_pw_unw me_inv_v_pw_unw sd_inv_v_pw_unw N_inv_v_pw_w me_inv_v_pw_w sd_inv_v_pw_w ///
		N_export_intensity_unw me_export_intensity_unw sd_export_intensity_unw N_export_intensity_w me_export_intensity_w sd_export_intensity_w ///
		using "$SAVE_SUMMARYSTATS/PIA_firm_yearstats", replace
	forvalues yyyy = $minyear/$maxyear {
		if `yyyy' >= 1996 & `yyyy' <= 2012 {
			disp "*** YEAR `yyyy' ***"
			use ano empresa_fic fsize capital_pw inv_v_pw va_pw va_pw_resid va_pw_resid2 vbp_pw vbp_pw_resid vbp_pw_resid2 export_intensity using "$SAVE_CLEANED/selection_PIA_`yyyy'", clear
			if $debug == 1 keep if _n <= 1000
			scalar year=`yyyy'
			
			qui bys empresa_fic ano: gen firmind = 1 if _n == 1
			collapse (mean) fsize va_pw va_pw_resid va_pw_resid2 vbp_pw vbp_pw_resid vbp_pw_resid2 inv_v_pw capital_pw export_intensity (count) N = ano Nfirmy = firmind, by(empresa_fic) fast
		
			scalar Nfirms = _N
			qui sum Nfirmy
			scalar Nfirmys = r(sum)
			
			local poster1_w = ""
			local poster1_unw = ""
			local poster2_w = ""
			local poster2_unw = ""
			local poster3_w = ""
			local poster3_unw = ""
			foreach tag in "_w" "_unw" {
				foreach var of varlist fsize capital_pw inv_v_pw va_pw va_pw_resid va_pw_resid2 vbp_pw vbp_pw_resid vbp_pw_resid2 export_intensity {
					if "`tag'" == "_w" qui sum `var' [fw = N]
					else if "`tag'" == "_unw" qui sum `var'
					scalar N_`var'`tag' = r(N)
					scalar me_`var'`tag' = r(mean)
					scalar sd_`var'`tag' = r(sd)
				}
			}
			
			* post
			post PIA_firm_yearstats (year) (Nfirms) (Nfirmys) ///
			(N_va_pw_unw) (me_va_pw_unw) (sd_va_pw_unw) (N_va_pw_w) (me_va_pw_w) (sd_va_pw_w) ///
			(N_va_pw_resid_unw) (me_va_pw_resid_unw) (sd_va_pw_resid_unw) (N_va_pw_resid_w) (me_va_pw_resid_w) (sd_va_pw_resid_w) ///
			(N_va_pw_resid2_unw) (me_va_pw_resid2_unw) (sd_va_pw_resid2_unw) (N_va_pw_resid2_w) (me_va_pw_resid2_w) (sd_va_pw_resid2_w) ///
			(N_vbp_pw_unw) (me_vbp_pw_unw) (sd_vbp_pw_unw) (N_vbp_pw_w) (me_vbp_pw_w) (sd_vbp_pw_w) ///
			(N_vbp_pw_resid_unw) (me_vbp_pw_resid_unw) (sd_vbp_pw_resid_unw) (N_vbp_pw_resid_w) (me_vbp_pw_resid_w) (sd_vbp_pw_resid_w) ///
			(N_vbp_pw_resid2_unw) (me_vbp_pw_resid2_unw) (sd_vbp_pw_resid2_unw) (N_vbp_pw_resid2_w) (me_vbp_pw_resid2_w) (sd_vbp_pw_resid2_w) ///
			(N_capital_pw_unw) (me_capital_pw_unw) (sd_capital_pw_unw) (N_capital_pw_w) (me_capital_pw_w) (sd_capital_pw_w) ///
			(N_inv_v_pw_unw) (me_inv_v_pw_unw) (sd_inv_v_pw_unw) (N_inv_v_pw_w) (me_inv_v_pw_w) (sd_inv_v_pw_w) ///
			(N_export_intensity_unw) (me_export_intensity_unw) (sd_export_intensity_unw) (N_export_intensity_w) (me_export_intensity_w) (sd_export_intensity_w)
		}
	}
	postclose PIA_firm_yearstats
	qui use "$SAVE_SUMMARYSTATS/PIA_firm_yearstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/PIA_firm_yearstats.xls", replace firstrow(variables)
}




**************************************************
*** (11) BETWEEN AND WITHIN FIRMS/SECTORS/OCCUPATIONS/INDIVIDUALS/EMPLOYER AGE/INVESTMENT STATUS/EXPORT STATUS by period
**************************************************
if $betweenwithinbyperiod == 1 {
	cap postclose betweenwithin_periodstats
	postfile betweenwithin_periodstats str9 source period ///
		var_between_persid p99p50_between_persid p95p50_between_persid p90p50_between_persid p75p50_between_persid p50p25_between_persid p50p10_between_persid p50p5_between_persid p50p1_between_persid var_within_persid p99p50_within_persid p95p50_within_persid p90p50_within_persid p75p50_within_persid p50p25_within_persid p50p10_within_persid p50p5_within_persid p50p1_within_persid ///
		var_between_empresa_fic p99p50_between_empresa_fic p95p50_between_empresa_fic p90p50_between_empresa_fic p75p50_between_empresa_fic p50p25_between_empresa_fic p50p10_between_empresa_fic p50p5_between_empresa_fic p50p1_between_empresa_fic var_within_empresa_fic p99p50_within_empresa_fic p95p50_within_empresa_fic p90p50_within_empresa_fic p75p50_within_empresa_fic p50p25_within_empresa_fic p50p10_within_empresa_fic p50p5_within_empresa_fic p50p1_within_empresa_fic ///
		var_between_genero var_within_genero ///
		var_between_idade_g var_within_idade_g ///
		var_between_idade_y var_within_idade_y ///
		var_between_edu var_within_edu ///
		var_between_clascnae95 var_within_clascnae95 ///
		var_between_occup var_within_occup ///
		var_between_fsize var_within_fsize ///
		var_between_exenstempage var_within_exenstempage ///
		var_between_fsize_fte var_within_fsize_fte ///
		var_between_rev_g var_within_rev_g ///
		var_between_va_g var_within_va_g ///
		var_between_inv_v_pw_g var_within_inv_v_pw_g ///
		var_between_capital_pw_g var_within_capital_pw_g ///
		var_between_export_intensity_g var_within_export_intensity_g ///
		using "$SAVE_SUMMARYSTATS/betweenwithin_periodstats", replace
	
	foreach source in "cleaned" "selection" {
		if $minyear > 1988 global akm_start = $minyear
		else global akm_start = 1988
		global akm_end = $akm_start + $periodlength
		global akm = 1
		while $akm <= $nperiods & $akm_end <= 2012 {
			disp "*** PERIOD $akm_start - $akm_end ***"
			
			disp "* open data"
			if "`source'" == "cleaned" local vars = "ano empresa_fic persid wage genero idade_y educ_year cnae cbo fsize_fte"
			else if "`source'" == "selection" local vars = "ano empresa_fic persid wage genero idade_y edu clascnae95 occup fsize"
			forvalues yyyy = $akm_start/$akm_end {
				if `yyyy' == $akm_start use `vars' using "$SAVE_CLEANED/`source'`yyyy'", clear
				else if $debug == 0 append using "$SAVE_CLEANED/`source'`yyyy'", keep(`vars')
				if $debug == 1 {
					if `yyyy' == $minyear local numobsi = 1000
					else local numobsi = `numobsi' + 1000
					qui keep if _n <= `numobsi'
				}
			}
			if "`source'" == "cleaned" {
				rename educ_year edu
				rename cnae clascnae95
				rename cbo occup
				rename fsize_fte fsize
			}
			
			disp "* firm entry, exit, and age"
			merge m:1 empresa_fic ano using "$SAVE_CLEANED/exenst", keep(match match_update master) keepusing(entry exit empage) nogen // add update option?
			qui replace empage = round(empage)
			qui egen exenstempage = group(empage entry exit)
			
			disp "* firm characteristics"
			if $akm_start >= 1996 {
				rename ano year
				merge m:1 empresa_fic year using "//Servidor2/f/ipea/projetos/2015/Projetos IBGE\03605000601_2015_96 - Princeton\9_Chris_JMP/PIA_composition", keep(match master) keepusing(fsize_fte revnet_pw vanet_pw inv_v_pw capital_pw export_intensity) nogen
				rename year ano
				qui bys empresa_fic: egen inv_v_pw_mean = mean(inv_v_pw)
				qui replace inv_v_pw = inv_v_pw_mean
				qui drop inv_v_pw_mean
				qui bys empresa_fic: egen export_intensity_mean = mean(export_intensity)
				qui replace export_intensity = export_intensity_mean
				qui drop export_intensity_mean
			}
			else {
				qui gen fsize_fte = .
				qui gen revnet_pw = .
				qui gen vanet_pw = .
				qui gen inv_v_pw = .
				qui gen capital_pw = .
				qui gen export_intensity = .
			}
			
			disp "* basic definitions"
			scalar period = ($akm_start - 1984)/4
			qui gen idade_g = idade_y
			qui recode idade_g (18/24.99 = 1) (25/29.99 = 2) (30/39.99 = 3) (40/49.99 = 4)
			qui replace fsize = exp(fsize)
			qui recode fsize (0/1 = 1) (1.00001/5 = 2) (5.00001/10 = 3) (10.00001/25 = 4) (25.00001/50 = 5) (50.00001/100 = 6) (100.00001/250 = 7) (250.00001/500 = 8) (500.00001/1000 = 9) (1000.00001/. = 10)
			qui replace fsize_fte = exp(fsize_fte)
			qui recode fsize_fte (0/1 = 1) (1.00001/5 = 2) (5.00001/10 = 3) (10.00001/25 = 4) (25.00001/50 = 5) (50.00001/100 = 6) (100.00001/250 = 7) (250.00001/500 = 8) (500.00001/1000 = 9) (1000.00001/. = 10)
			qui replace inv_v_pw = 0 if inv_v_pw == .
			qui replace capital_pw = 0 if capital_pw == .
			if $akm_start >= 1996 {
				fastxtile rev_g = revnet_pw, n(100)
				fastxtile va_g = vanet_pw, n(100)
				fastxtile inv_v_pw_g = inv_v_pw, n(100)
				fastxtile capital_pw_g = capital_pw, n(100)
				fastxtile export_intensity_g = export_intensity, n(100)
			}
			else {
				foreach var in rev_g va_g inv_v_pw_g capital_pw_g export_intensity_g {
					qui gen `var' = .
				}
			}
			drop revnet_pw vanet_pw inv_v_pw capital_pw export_intensity
			
			disp "* between and within inequality"
			foreach var of varlist persid genero idade_g idade_y edu empresa_fic clascnae95 occup fsize exenstempage fsize_fte rev_g va_g inv_v_pw_g capital_pw_g export_intensity_g {
				if inlist("`var'","empresa_fic","persid") local det = ", d"
				else local det = ""
				qui bys `var': egen between`var' = mean(wage)
				qui sum between`var'`det'
				scalar var_between_`var' = r(Var)
				if inlist("`var'","empresa_fic","persid") {
					scalar p99p50_between_`var' = r(p99) - r(p50)
					scalar p95p50_between_`var' = r(p95) - r(p50)
					scalar p90p50_between_`var' = r(p90) - r(p50)
					scalar p75p50_between_`var' = r(p75) - r(p50)
					scalar p50p25_between_`var' = r(p50) - r(p25)
					scalar p50p10_between_`var' = r(p50) - r(p10)
					scalar p50p5_between_`var' = r(p50) - r(p5)
					scalar p50p1_between_`var' = r(p50) - r(p1)
				}
				qui gen within`var' = wage - between`var'
				qui sum within`var'`det'
				qui scalar var_within_`var' = r(Var)
				if inlist("`var'","empresa_fic","persid") {
					scalar p99p50_within_`var' = r(p99) - r(p50)
					scalar p95p50_within_`var' = r(p95) - r(p50)
					scalar p90p50_within_`var' = r(p90) - r(p50)
					scalar p75p50_within_`var' = r(p75) - r(p50)
					scalar p50p25_within_`var' = r(p50) - r(p25)
					scalar p50p10_within_`var' = r(p50) - r(p10)
					scalar p50p5_within_`var' = r(p50) - r(p5)
					scalar p50p1_within_`var' = r(p50) - r(p1)
				}
				drop between`var' within`var'
			}
			
			disp "* post"
			post betweenwithin_periodstats ("`source'") (period) ///
				(var_between_persid) (p99p50_between_persid) (p95p50_between_persid) (p90p50_between_persid) (p75p50_between_persid) (p50p25_between_persid) (p50p10_between_persid) (p50p5_between_persid) (p50p1_between_persid) (var_within_persid) (p99p50_within_persid) (p95p50_within_persid) (p90p50_within_persid) (p75p50_within_persid) (p50p25_within_persid) (p50p10_within_persid) (p50p5_within_persid) (p50p1_within_persid) ///
				(var_between_empresa_fic) (p99p50_between_empresa_fic) (p95p50_between_empresa_fic) (p90p50_between_empresa_fic) (p75p50_between_empresa_fic) (p50p25_between_empresa_fic) (p50p10_between_empresa_fic) (p50p5_between_empresa_fic) (p50p1_between_empresa_fic) (var_within_empresa_fic) (p99p50_within_empresa_fic) (p95p50_within_empresa_fic) (p90p50_within_empresa_fic) (p75p50_within_empresa_fic) (p50p25_within_empresa_fic) (p50p10_within_empresa_fic) (p50p5_within_empresa_fic) (p50p1_within_empresa_fic) ///
				(var_between_genero) (var_within_genero) ///
				(var_between_idade_g) (var_within_idade_g) ///
				(var_between_idade_y) (var_within_idade_y) ///
				(var_between_edu) (var_within_edu) ///
				(var_between_clascnae95) (var_within_clascnae95) ///
				(var_between_occup) (var_within_occup) ///
				(var_between_fsize) (var_within_fsize) ///
				(var_between_exenstempage) (var_within_exenstempage) ///
				(var_between_fsize_fte) (var_within_fsize_fte) ///
				(var_between_rev_g) (var_within_rev_g) ///
				(var_between_va_g) (var_within_va_g) ///
				(var_between_inv_v_pw_g) (var_within_inv_v_pw_g) ///
				(var_between_capital_pw_g) (var_within_capital_pw_g) ///
				(var_between_export_intensity_g) (var_within_export_intensity_g)
			
			disp "* loop"
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
			global akm = $akm + 1
		}
	}
	postclose betweenwithin_periodstats
	qui use "$SAVE_SUMMARYSTATS/betweenwithin_periodstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/betweenwithin_periodstats.xls", replace firstrow(variables)
}




**************************************************
*** (12) BETWEEN AND WITHIN FIRMS/SECTORS/OCCUPATIONS/INDIVIDUALS/EMPLOYER AGE/INVESTMENT STATUS/EXPORT STATUS by year
**************************************************
if $betweenwithinbyyear == 1 {
	cap postclose betweenwithin_yearstats
	postfile betweenwithin_yearstats str9 source year ///
		var_between_persid p99p50_between_persid p95p50_between_persid p90p50_between_persid p75p50_between_persid p50p25_between_persid p50p10_between_persid p50p5_between_persid p50p1_between_persid var_within_persid p99p50_within_persid p95p50_within_persid p90p50_within_persid p75p50_within_persid p50p25_within_persid p50p10_within_persid p50p5_within_persid p50p1_within_persid ///
		var_between_empresa_fic p99p50_between_empresa_fic p95p50_between_empresa_fic p90p50_between_empresa_fic p75p50_between_empresa_fic p50p25_between_empresa_fic p50p10_between_empresa_fic p50p5_between_empresa_fic p50p1_between_empresa_fic var_within_empresa_fic p99p50_within_empresa_fic p95p50_within_empresa_fic p90p50_within_empresa_fic p75p50_within_empresa_fic p50p25_within_empresa_fic p50p10_within_empresa_fic p50p5_within_empresa_fic p50p1_within_empresa_fic ///
		var_between_genero var_within_genero ///
		var_between_idade_g var_within_idade_g ///
		var_between_idade_y var_within_idade_y ///
		var_between_edu var_within_edu ///
		var_between_clascnae95 var_within_clascnae95 ///
		var_between_occup var_within_occup ///
		var_between_fsize var_within_fsize ///
		var_between_exenstempage var_within_exenstempage ///
		var_between_fsize_fte var_within_fsize_fte ///
		var_between_rev_g var_within_rev_g ///
		var_between_va_g var_within_va_g ///
		var_between_inv_v_pw_g var_within_inv_v_pw_g ///
		var_between_capital_pw_g var_within_capital_pw_g ///
		var_between_export_intensity_g var_within_export_intensity_g ///
		using "$SAVE_SUMMARYSTATS/betweenwithin_yearstats", replace
	cap postclose edugroups
	postfile edugroups year educ_group mean variance num_ppl mean_totpop var_totpop num_ppl_totpop using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_educ", replace
	cap postclose sectors
	postfile sectors year sector mean variance num_ppl mean_totpop var_totpop num_totpop  using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_sector", replace

	foreach source in "cleaned" "selection" {
		forvalues yyyy = $minyear/$maxyear {
			disp "*** YEAR `yyyy' ***"
			
			disp "* open data"
			if "`source'" == "cleaned" {
				use ano empresa_fic persid wage genero idade_y educ_year cnae cbo fsize_fte using "$SAVE_CLEANED/`source'`yyyy'", clear
				rename educ_year edu
				rename cnae clascnae95
				rename cbo occup
				rename fsize_fte fsize
			}
			else if "`source'" == "selection" use ano empresa_fic persid wage genero idade_y edu clascnae95 occup fsize using "$SAVE_CLEANED/`source'`yyyy'", clear
			
			disp "* firm entry, exit, and age"
			if `yyyy' > 1986 merge m:1 empresa_fic using "$SAVE_CLEANED/exenst`yyyy'", keep(match master) keepusing(entry exit empage) nogen
			else {
				qui gen entry = .
				qui gen exit = .
				qui gen empage = .
			}
			if $debug == 1 keep if _n <= 1000
			qui replace empage = round(empage)
			qui egen exenstempage = group(empage entry exit)
			
			disp "* firm characteristics"
			if `yyyy' >= 1996 {
				rename ano year
				merge m:1 empresa_fic year using "//Servidor2/f/ipea/projetos/2015/Projetos IBGE\03605000601_2015_96 - Princeton\9_Chris_JMP/PIA_composition", keep(match master) keepusing(fsize_fte revnet_pw vanet_pw inv_v_pw capital_pw export_intensity) nogen
				rename year ano
				qui bys empresa_fic: egen inv_v_pw_mean = mean(inv_v_pw)
				qui replace inv_v_pw = inv_v_pw_mean
				qui drop inv_v_pw_mean
				qui bys empresa_fic: egen export_intensity_mean = mean(export_intensity)
				qui replace export_intensity = export_intensity_mean
				qui drop export_intensity_mean
			}
			else {
				qui gen fsize_fte = .
				qui gen revnet_pw = .
				qui gen vanet_pw = .
				qui gen inv_v_pw = .
				qui gen capital_pw = .
				qui gen export_intensity = .
			}
			
			disp "* basic definitions"
			scalar year = `yyyy'
			qui gen idade_g = idade_y
			qui recode idade_g (18/24.99 = 1) (25/29.99 = 2) (30/39.99 = 3) (40/49.99 = 4)
			qui replace fsize = exp(fsize)
			qui recode fsize (0/1 = 1) (1.00001/5 = 2) (5.00001/10 = 3) (10.00001/25 = 4) (25.00001/50 = 5) (50.00001/100 = 6) (100.00001/250 = 7) (250.00001/500 = 8) (500.00001/1000 = 9) (1000.00001/. = 10)
			qui replace fsize_fte = exp(fsize_fte)
			qui recode fsize_fte (0/1 = 1) (1.00001/5 = 2) (5.00001/10 = 3) (10.00001/25 = 4) (25.00001/50 = 5) (50.00001/100 = 6) (100.00001/250 = 7) (250.00001/500 = 8) (500.00001/1000 = 9) (1000.00001/. = 10)
			qui replace inv_v_pw = 0 if inv_v_pw == .
			qui replace capital_pw = 0 if capital_pw == .
			if `yyyy' >= 1996 {
				fastxtile rev_g = revnet_pw, n(100)
				fastxtile va_g = vanet_pw, n(100)
				fastxtile inv_v_pw_g = inv_v_pw, n(100)
				fastxtile capital_pw_g = capital_pw, n(100)
				fastxtile export_intensity_g = export_intensity, n(100)
			}
			else {
				foreach var in rev_g va_g inv_v_pw_g capital_pw_g export_intensity_g {
					qui gen `var' = .
				}
			}
			drop revnet_pw vanet_pw inv_v_pw capital_pw export_intensity

			disp "* between and within inequality"
			foreach var of varlist persid genero idade_g idade_y edu empresa_fic clascnae95 occup fsize exenstempage fsize_fte rev_g va_g inv_v_pw_g capital_pw_g export_intensity_g {
				if inlist("`var'","empresa_fic","persid") local det = ", d"
				else local det = ""
				qui bys `var': egen between`var' = mean(wage)
				qui sum between`var'`det'
				scalar var_between_`var' = r(Var)
				if inlist("`var'","empresa_fic","persid") {
					scalar p99p50_between_`var' = r(p99) - r(p50)
					scalar p95p50_between_`var' = r(p95) - r(p50)
					scalar p90p50_between_`var' = r(p90) - r(p50)
					scalar p75p50_between_`var' = r(p75) - r(p50)
					scalar p50p25_between_`var' = r(p50) - r(p25)
					scalar p50p10_between_`var' = r(p50) - r(p10)
					scalar p50p5_between_`var' = r(p50) - r(p5)
					scalar p50p1_between_`var' = r(p50) - r(p1)
				}
				qui gen within`var' = wage - between`var'
				qui sum within`var'`det'
				qui scalar var_within_`var' = r(Var)
				if inlist("`var'","empresa_fic","persid") {
					scalar p99p50_within_`var' = r(p99) - r(p50)
					scalar p95p50_within_`var' = r(p95) - r(p50)
					scalar p90p50_within_`var' = r(p90) - r(p50)
					scalar p75p50_within_`var' = r(p75) - r(p50)
					scalar p50p25_within_`var' = r(p50) - r(p25)
					scalar p50p10_within_`var' = r(p50) - r(p10)
					scalar p50p5_within_`var' = r(p50) - r(p5)
					scalar p50p1_within_`var' = r(p50) - r(p1)
				}
				drop between`var' within`var'
			}
			
			disp "* post"
			post betweenwithin_yearstats ("`source'") (year) ///
				(var_between_persid) (p99p50_between_persid) (p95p50_between_persid) (p90p50_between_persid) (p75p50_between_persid) (p50p25_between_persid) (p50p10_between_persid) (p50p5_between_persid) (p50p1_between_persid) (var_within_persid) (p99p50_within_persid) (p95p50_within_persid) (p90p50_within_persid) (p75p50_within_persid) (p50p25_within_persid) (p50p10_within_persid) (p50p5_within_persid) (p50p1_within_persid) ///
				(var_between_empresa_fic) (p99p50_between_empresa_fic) (p95p50_between_empresa_fic) (p90p50_between_empresa_fic) (p75p50_between_empresa_fic) (p50p25_between_empresa_fic) (p50p10_between_empresa_fic) (p50p5_between_empresa_fic) (p50p1_between_empresa_fic) (var_within_empresa_fic) (p99p50_within_empresa_fic) (p95p50_within_empresa_fic) (p90p50_within_empresa_fic) (p75p50_within_empresa_fic) (p50p25_within_empresa_fic) (p50p10_within_empresa_fic) (p50p5_within_empresa_fic) (p50p1_within_empresa_fic) ///
				(var_between_genero) (var_within_genero) ///
				(var_between_idade_g) (var_within_idade_g) ///
				(var_between_idade_y) (var_within_idade_y) ///
				(var_between_edu) (var_within_edu) ///
				(var_between_clascnae95) (var_within_clascnae95) ///
				(var_between_occup) (var_within_occup) ///
				(var_between_fsize) (var_within_fsize) ///
				(var_between_exenstempage) (var_within_exenstempage) ///
				(var_between_fsize_fte) (var_within_fsize_fte) ///
				(var_between_rev_g) (var_within_rev_g) ///
				(var_between_va_g) (var_within_va_g) ///
				(var_between_inv_v_pw_g) (var_within_inv_v_pw_g) ///
				(var_between_capital_pw_g) (var_within_capital_pw_g) ///
				(var_between_export_intensity_g) (var_within_export_intensity_g)
		}
	}
	
	postclose betweenwithin_yearstats
	postclose edugroups
	postclose sectors
	
	* export to right format
	qui use "$SAVE_SUMMARYSTATS/betweenwithin_yearstats", clear
	qui export excel using "$SAVE_SUMMARYSTATS/betweenwithin_yearstats.xls", firstrow(variables) replace	
	
	qui use "$SAVE_SUMMARYSTATS/Mean_var_wage_by_educ", clear
	qui export excel using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_educ.xls", firstrow(variables) replace

	use "$SAVE_SUMMARYSTATS/Mean_var_wage_by_sector", clear
	export excel using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_sector.xls", firstrow(variables) replace
}




**************************************************
*** (13) Densities of raw wages by period
**************************************************
if $densitiesbyperiod == 1 {
	foreach sample in lset pia {
		if "`sample'" == "pia" global akm_start = 1996
		else global akm_start = $minyear
		global akm_end = $akm_start + $periodlength
		while $akm_end <= $maxyear {
			disp "*** Estimating densities for `sample' in period $akm_start - $akm_end ***"
			if "`sample'" == "pia" use ano wage using "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", clear
			else use ano wage using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", clear
			
			* remove year effects
			qui sum wage
			qui local M = r(mean)
			forvalues yyyy = $akm_start/$akm_end {
				qui sum wage if ano == `yyyy'
				qui replace wage = wage - r(mean) if ano == `yyyy'
			}
			qui replace wage = wage + `M'
			
			* estimate density
			qui drop if wage == .
			qui fastxtile bin = wage, n(${binpoints})
			qui collapse (min) minpoint = wage (max) cutoff = wage (count) n_ind = wage, by(bin) fast
			
			* midpoint
			qui gen wage = (minpoint + cutoff)/2
			
			* density
			qui gen density = 1/${binpoints} * 1/(cutoff - minpoint)
			qui keep density wage bin n_ind
			qui gen period = ($akm_start >= 1988)+($akm_start >= 1992)+($akm_start >= 1996)+($akm_start >= 2000)+($akm_start >= 2004)+($akm_start >= 2008)
			qui save "$SAVE_SUMMARYSTATS/wagedensities_byperiod_`sample'_${akm_start}_${akm_end}", replace
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		* combine to one file and store in excel
		if "`sample'" == "lset" global akm_start = $minyear
		else global akm_start = 1996
		global akm_end = $akm_start + $periodlength
		qui use "$SAVE_SUMMARYSTATS/wagedensities_byperiod_`sample'_${akm_start}_${akm_end}", replace
		global akm_start = $akm_start + $periodlength
		global akm_end = $akm_end + $periodlength
		while $akm_end <= $maxyear {
			qui append using "$SAVE_SUMMARYSTATS/wagedensities_byperiod_`sample'_${akm_start}_${akm_end}"
			global akm_start = $akm_start + $periodlength
			global akm_end = $akm_end + $periodlength
		}
		if "`sample'" == "pia" {
			qui export excel "$SAVE_SUMMARYSTATS/wagedensities_byperiod_`sample'_1996_${maxyear}.xls", firstrow(variables) replace
		}
		else {
			qui export excel "$SAVE_SUMMARYSTATS/wagedensities_byperiod_`sample'_${minyear}_${maxyear}.xls", firstrow(variables) replace
		}
	}
}




**************************************************
*** (14) Densities of raw wages by year
**************************************************
if $densitiesbyyear == 1 {
	foreach sample in lset pia {
	//foreach sample in lset {
		forvalues yyyy = $minyear/$maxyear {
			if inrange(`yyyy',1988,1991) global akm_start = 1988
			else if inrange(`yyyy',1992,1995) global akm_start = 1992
			else if inrange(`yyyy',1996,1999) global akm_start = 1996
			else if inrange(`yyyy',2000,2003) global akm_start = 2000
			else if inrange(`yyyy',2004,2007) global akm_start = 2004
			else if inrange(`yyyy',2008,2012) global akm_start = 2008
			global akm_end = ${akm_start} + 4
			
			foreach concept in wage firm person {
				disp "*** Estimating densities for `sample' in year `yyyy' (concept=`concept') ***"
				if "`concept'" == "wage" & "`sample'" == "pia" use ano wage if ano == `yyyy' & wage < . using "$SAVE_CLEANED/lset_PIA_${with_age}${with_hours}_${akm_start}_${akm_end}.dta", clear
				else if "`concept'" == "wage" & "`sample'" == "lset" use ano wage if wage < . using "$SAVE_CLEANED/selection`yyyy'", clear
				else if inlist("`concept'","firm","person") {
					use ano `concept' if `concept' < . & ano == `yyyy' using "$SAVE_CLEANED/lset_${with_age}${with_hours}_${akm_start}_${akm_end}", clear
					rename `concept' wage
				}
				drop ano
				if ("`sample'" == "pia" & `yyyy' >= 1996) | "`sample'" == "lset" {
					* estimate density
					qui fastxtile bin = wage, n(${binpoints})
					qui collapse (min) minpoint = wage (max) cutoff = wage (count) n_ind = wage, by(bin) fast
					
					* midpoint
					qui gen wage = (minpoint + cutoff)/2
					
					* density
					qui gen density = 1/${binpoints} * 1/(cutoff - minpoint)
					drop minpoint cutoff
					qui gen year = `yyyy'
					qui gen concept = "`concept'"
					qui save "$SAVE_SUMMARYSTATS/wagedensities_byyear_`sample'_`concept'_`yyyy'", replace
				}
			}
		}
		* combine to one file and store in excel
		local sample = "lset"
		if "`sample'" == "lset" local minyyyy = $minyear
		else if "`sample'" == "pia" local minyyyy = max($minyear,1996)
		forvalues yyyy = `minyyyy'/$maxyear {
			foreach concept in wage firm person {
				if `yyyy' == `minyyyy' & "`concept'" == "wage" use "$SAVE_SUMMARYSTATS/wagedensities_byyear_`sample'_`concept'_`minyyyy'", clear
				else append using "$SAVE_SUMMARYSTATS/wagedensities_byyear_`sample'_`concept'_`yyyy'"
			}
		}
		if "`sample'" == "pia" {
			qui export excel "$SAVE_SUMMARYSTATS/wagedensities_byyear_`sample'_`minyyyy'_${maxyear}.xls", firstrow(variables) replace
		}
		else if "`sample'" == "lset" {
			qui export excel "$SAVE_SUMMARYSTATS/wagedensities_byyear_`sample'_`minyyyy'_${maxyear}.xls", firstrow(variables) replace
		}
	}
}


****************************************************
*** (15) BASIC STATS BY EDUCATION, SECTOR, AND STATE
****************************************************
if $edusectorstats {
	cap postclose edugroups
	postfile edugroups year educ_group mean variance num_ppl mean_totpop var_totpop num_ppl_totpop using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_educ", replace
	cap postclose sectors
	postfile sectors year sector mean variance num_ppl mean_totpop var_totpop num_totpop using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_sector", replace
	cap postclose states
	postfile states year state mean variance num_ppl mean_totpop var_totpop num_totpop using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_state", replace

	forvalues yyyy = $minyear/$maxyear {
		disp "*** YEAR `yyyy' ***"
		disp "* open data"
		use wage edu clascnae95 loc using "$SAVE_CLEANED/selection`yyyy'", clear

		disp "* post"
		qui sum wage 
		scalar m = r(mean)
		scalar v = r(Var)
		scalar n = r(N)
		
		*** by education group		
		qui sum wage if edu < 7
		scalar m1 = r(mean)
		scalar v1 = r(Var)
		scalar n1 = r(N)
		
		qui sum wage if edu >= 7 & edu < 12
		scalar m2 = r(mean)
		scalar v2 = r(Var)
		scalar n2 = r(N)
		
		qui sum wage if edu >= 12 & edu < 16
		scalar m3 = r(mean)
		scalar v3 = r(Var)
		scalar n3 = r(N)
		
		qui sum wage if edu == 16
		scalar m4 = r(mean)
		scalar v4 = r(Var)
		scalar n4 = r(N)
			
		forvalues i = 1/4 {
			post edugroups (`yyyy') (`i') (m`i') (v`i') (n`i') (m) (v) (n)
		}	
		
		*** by sector
		* Oil, Mining, and Metals
		qui sum wage if inlist(clascnae95,1,2,3)
		scalar m1 = r(mean)
		scalar v1 = r(Var)
		scalar n1 = r(N)
		
		* Manufacturing
		qui sum wage if inlist(clascnae95,4,5,6,7,8,9,10,11,12,13,14)
		scalar m2 = r(mean)
		scalar v2 = r(Var)
		scalar n2 = r(N)
		
		* Construction
		qui sum wage if inlist(clascnae95,15)
		scalar m3 = r(mean)
		scalar v3 = r(Var)
		scalar n3 = r(N)

		* Other Services 
		qui sum wage if inlist(clascnae95,16,17,18,19,20,21,22,23)
		scalar m4 = r(mean)
		scalar v4 = r(Var)
		scalar n4 = r(N)
			
		* Government	
		qui sum wage if inlist(clascnae95,24)
		scalar m5 = r(mean)
		scalar v5 = r(Var)
		scalar n5 = r(N)
		
		* Agriculture
		qui sum wage if inlist(clascnae95,25)
		scalar m6 = r(mean)
		scalar v6 = r(Var)
		scalar n6 = r(N)
		
		forvalues i = 1/6 {
			post sectors (`yyyy') (`i') (m`i') (v`i') (n`i') (m) (v) (n)
		}
		
		*** by state
		qui gen loc_g = 1*(loc=="AC") + 2*(loc=="AL") + 3*(loc=="AM") + 4*(loc=="AP") + 5*(loc=="BA") + 6*(loc=="CE") + 7*(loc=="DF") + 8*(loc=="ES") + 9*(loc=="GO") + 10*(loc=="IG") + 11*(loc=="MA") + 12*(loc=="MG") + 13*(loc=="MS") ///
			+ 14*(loc=="MT") + 15*(loc=="PA") + 16*(loc=="PB") + 17*(loc=="PE") + 18*(loc=="PI") + 19*(loc=="PR") + 20*(loc=="RJ") + 21*(loc=="RN") + 22*(loc=="RO") + 23*(loc=="RR") + 24*(loc=="RS") + 25*(loc=="SC") + 26*(loc=="SE") ///
			+ 27*(loc=="SP") + 28*(loc=="TO")
		drop loc
		rename loc_g loc
		label define loc_l 1 "AC" 2 "AL" 3 "AM" 4 "AP" 5 "BA" 6 "CE" 7 "DF" 8 "ES" 9 "GO" 10 "IG" 11 "MA" 12 "MG" 13 "MS" ///
			14 "MT" 15 "PA" 16 "PB" 17 "PE" 18 "PI" 19 "PR" 20 "RJ" 21 "RN" 22 "RO" 23 "RR" 24 "RS" 25 "SC" 26 "SE" ///
			27 "SP" 28 "TO"
		label values loc loc_l
		forvalues s = 1/28 {
			qui sum wage if loc == `s'
			scalar ms = r(mean)
			scalar vs = r(Var)
			scalar ns = r(N)
			post states (`yyyy') (`s') (ms) (vs) (ns) (m) (v) (n)
		}
	}

	postclose edugroups
	postclose sectors
	postclose states
	
	foreach indi in educ sector state {
		qui use "$SAVE_SUMMARYSTATS/Mean_var_wage_by_`indi'", clear
		qui export excel using "$SAVE_SUMMARYSTATS/Mean_var_wage_by_`indi'.xls", firstrow(variables) replace
	}
}


***********************************************************
*** (16) BETWEEN AND WITHIN FIRMS, OVERALL AND BY SUBGROUPS
***********************************************************
global debug = 0 // 0 = normal run; 1 = use small sample

global nbins = 3 // number of bins to sort worker and firm characteristics into (3 = Hi, Med, Lo)
global useloc = 1 // use geographic variable (0 = do not use; 1 = use geo)

forvalues yyyy = $minyear/$maxyear {
	disp "*** YEAR `yyyy' ***"
	
	disp "* open data"
	if $debug == 1 local ifin "in 1/10000" 
	else local ifin ""
	
	if $debug == 1 use ano empresa_fic wage clascnae95 fsize using "/Users/cmoser/Dropbox/Brazil/4 Data/9_RAIS/RAIS_test.dta" if ano == `yyyy' `ifin', clear
	else {
		if $useloc == 1 use ano empresa_fic wage clascnae95 loc fsize using "$SAVE_CLEANED/selection`yyyy'" if ano == `yyyy' `ifin', clear
		else use ano empresa_fic wage clascnae95 fsize using "$SAVE_CLEANED/selection`yyyy'" if ano == `yyyy' `ifin', clear
	}
	
	disp "* firm characteristics"
	if `yyyy' >= 1996 {
		rename ano year
		if $debug == 1 qui merge m:1 empresa_fic year using "/Users/cmoser/Dropbox/Brazil/4 Data/10_PIA/PIA_test.dta", keep(match master) keepusing(fsize_fte vanet_pw) nogen
		else qui merge m:1 empresa_fic year using "//Servidor2/f/ipea/projetos/2015/Projetos IBGE\03605000601_2015_96 - Princeton\9_Chris_JMP/PIA_composition", keep(match master) keepusing(fsize_fte vanet_pw) nogen
		rename year ano
	}
	else {
		qui gen fsize_fte = .
		qui gen vanet_pw = .
	}
	drop ano
	rename empresa_fic firmid
	
	disp "* subgroup definitions"
	qui count
	local N = r(N)
	if `N' == 0 continue
	* industry
	qui recode clascnae95 (1 2 3 = 1) ///
		(4 5 6 7 8 9 10 11 12 13 14 = 2) ///
		(15 = 3) ///
		(16 17 18 19 20 21 22 23 = 4) ///
		(24 = 5) ///
		(25 = 6) ///
		(26 = .)
	rename clascnae95 sector_g
	label define sector_l 1 "Oil, Mining, Metals" 2 "Manufacturing" 3 "Construction" 4 "Services" 5 "Government" 6 "Agriculture"
	label values sector_g sector_l
	* location
	qui gen loc_g = 1*(loc=="AC") + 2*(loc=="AL") + 3*(loc=="AM") + 4*(loc=="AP") + 5*(loc=="BA") + 6*(loc=="CE") + 7*(loc=="DF") + 8*(loc=="ES") + 9*(loc=="GO") + 10*(loc=="IG") + 11*(loc=="MA") + 12*(loc=="MG") + 13*(loc=="MS") ///
		+ 14*(loc=="MT") + 15*(loc=="PA") + 16*(loc=="PB") + 17*(loc=="PE") + 18*(loc=="PI") + 19*(loc=="PR") + 20*(loc=="RJ") + 21*(loc=="RN") + 22*(loc=="RO") + 23*(loc=="RR") + 24*(loc=="RS") + 25*(loc=="SC") + 26*(loc=="SE") ///
		+ 27*(loc=="SP") + 28*(loc=="TO")
	label define loc_l 1 "AC" 2 "AL" 3 "AM" 4 "AP" 5 "BA" 6 "CE" 7 "DF" 8 "ES" 9 "GO" 10 "IG" 11 "MA" 12 "MG" 13 "MS" ///
		14 "MT" 15 "PA" 16 "PB" 17 "PE" 18 "PI" 19 "PR" 20 "RJ" 21 "RN" 22 "RO" 23 "RR" 24 "RS" 25 "SC" 26 "SE" ///
		27 "SP" 28 "TO"
	label values loc_g loc_l
	qui gen loc_g2 = 1*inlist(loc,"RO","AC","AM","RR","PA","AP","TO") + 2*inlist(loc,"MA","PI","RN","PB","PE","AL","SE","BA","CE") + 3*inlist(loc,"MG","ES","RJ","SP") + 4*inlist(loc,"PR","SC","RS") + 5*inlist(loc,"MS","MT","GO","DF")
	label define loc_l2 1 "Norte" 2 "Nordeste" 3 "Sudeste" 4 "Sul" 5 "Centro-Oeste"
	label values loc_g2 loc_l2
	* firm size
	foreach var of varlist fsize fsize_fte {
		qui replace `var' = exp(`var')
		if ("`var'" != "fsize_fte" | `yyyy' >= 1996) & `N' > 0 fastxtile `var'_g = `var', n($nbins)
		else qui gen `var'_g = .
		label define `var'_l 1 "Q1/{$nbins}" 2 "Q2/{$nbins}" 3 "Q3/{$nbins}" 4 "Q4/{$nbins}" 5 "Q5/{$nbins}" ///
			6 "Q6/{$nbins}" 7 "Q7/{$nbins}" 8 "Q8/{$nbins}" 9 "Q9/{$nbins}" 10 "Q10/{$nbins}"
		label values `var'_g `var'_l
		qui egen `var'_g2 = cut(`var'), at(0,10,100,1000,10000,999999999) icodes
		label define `var'_l2 1 "0-9" 2 "10-99" 3 "100-999" 4 "1000-9999" 5 "10000+"
		label values `var'_g2 `var'_l2
	}
	* value added per worker
	if `yyyy' >= 1996 & `N' > 0 fastxtile va_g = vanet_pw, n($nbins)
	else qui gen va_g = .
	label define va_l 1 "Q1/{$nbins}" 2 "Q2/{$nbins}" 3 "Q3/{$nbins}" 4 "Q4/{$nbins}" 5 "Q5/{$nbins}" ///
		6 "Q6/{$nbins}" 7 "Q7/{$nbins}" 8 "Q8/{$nbins}" 9 "Q9/{$nbins}" 10 "Q10/{$nbins}"
	label values va_g va_l
	
	if $useloc == 1 drop fsize fsize_fte loc vanet_pw
	else drop fsize fsize_fte vanet_pw	
	disp "* compute between and within inequality"
	qui bys firmid: egen between = mean(wage)
	drop firmid
	qui gen within = wage - between
	if `yyyy'>= 1996 {
		if $useloc == 1 local loci = "all sector_g loc_g loc_g2 fsize_g fsize_fte_g fsize_g2 fsize_fte_g2 va_g"
		else local loci = "all sector_g fsize_g fsize_fte_g fsize_g2 fsize_fte_g2 va_g"
	}
	else{
		if $useloc == 1 local loci = "all sector_g loc_g loc_g2 fsize_g "
		else local loci = "all sector_g fsize_g"
	}
	
	foreach selection in `loci' {
		disp "--> variable: `selection'"
		preserve
		qui gen groupname = "`selection'"
		if "`selection'" != "all" {
			qui gen groupid = `selection'
			drop if `selection' == . 
		}
		else qui gen groupid = 1
        
		
		cap drop `loci'
		
		qui bys groupid: egen var_between = sd(between)
		
		qui replace var_between = var_between^2
		qui bys groupid: egen var_within = sd(within)
		qui replace var_within = var_within^2
		drop between within
		collapse (first) var_between var_within (count) N=var_between, by(groupname groupid) fast
		if $debug == 1 qui save "/Users/cmoser/Dropbox/Brazil/4 Data/0_test/betweenwithin_subgroups_`yyyy'_`selection'", replace
		else qui save "$SAVE_SUMMARYSTATS/betweenwithin_subgroups_`yyyy'_`selection'", replace
		restore
	}
}

* append files
clear
forvalues yyyy = $minyear/$maxyear {

	if $useloc == 1 local loci = "all sector_g loc_g loc_g2 fsize_g fsize_fte_g fsize_g2 fsize_fte_g2 va_g"
	else local loci = "all sector_g fsize_g fsize_fte_g fsize_g2 fsize_fte_g2 va_g"
	foreach selection in `loci' {
		qui count
		local N = r(N)
		if $debug == 1 {
			if `N' == 0 cap use "/Users/cmoser/Dropbox/Brazil/4 Data/0_test/betweenwithin_subgroups_`yyyy'_`selection'", clear
			else cap append using "/Users/cmoser/Dropbox/Brazil/4 Data/0_test/betweenwithin_subgroups_`yyyy'_`selection'"
		}
		else {
			if `N' == 0 cap use "$SAVE_SUMMARYSTATS/betweenwithin_subgroups_`yyyy'_`selection'", clear
			else cap append using "$SAVE_SUMMARYSTATS/betweenwithin_subgroups_`yyyy'_`selection'"
		}
		cap replace ano = `yyyy' if ano == .
		cap gen ano = `yyyy'
	}
}
sort ano groupname groupid
drop if inlist(groupname,"fsize_fte_g","fsize_fte_g2","va_g") & ano < 1996
if $debug == 1 save "/Users/cmoser/Dropbox/Brazil/4 Data/0_test/betweenwithin_subgroups", replace
else save "$SAVE_SUMMARYSTATS/betweenwithin_subgroups", replace

* export to right format
if $debug == 1 {
	qui use "/Users/cmoser/Dropbox/Brazil/4 Data/0_test/betweenwithin_subgroups", clear
	qui export excel using "/Users/cmoser/Dropbox/Brazil/4 Data/0_test/betweenwithin_subgroups.xls", firstrow(variables) replace
}
else {
	qui use "$SAVE_SUMMARYSTATS/betweenwithin_subgroups", clear
	qui export excel using "$SAVE_SUMMARYSTATS/betweenwithin_subgroups.xls", firstrow(variables) replace
	qui export excel using "F:\ipea\projetos\2015\Projetos IBGE\03605000998_2014_35 - Princeton\7_EXTRACT_0305000998_2014_35_PIA2\Tabelas de saida/betweenwithin_subgroups.xls", firstrow(variables) replace
}


