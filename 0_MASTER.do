********************************************************************************
* Master code file
*
* "Firms and the Decline in Earnings Inequality in Brazil"
*
* by Jorge Alvarez (International Monetary Fund),
* Benguria Benguria (University of Kentucky),
* Niklas Engbom (Princeton University), and
* Christian Moser (Columbia University)
*
* First created: 10/09/2014
* Last edited: 06/24/2017
********************************************************************************
clear all
timer clear 1
timer on 1
set more off
set rmsg on
cap log close


********************************************************************************
* SET USER AND PATH
********************************************************************************
global dataset = 1 // Data set used in AKM estimation: 1 = RAIS; 2 = PIA
global with_age = 0 // Include age effects in AKM
global with_va = 0 // Include value added in AKM
global with_hours = 0 // Use hourly wage rates


********************************************************************************
* SELECT PARTS TO RUN
********************************************************************************
global read = 0					// ( 1) READ: describe and summarize variables
global clean = 0				// ( 2) CLEAN: clean and prepare data for analysis
global selection = 1 			// ( 3) SELECTION: makes relevant sample selections
global akm = 1					// ( 4) AKM: prepares data and estimates AKM in subperiods
global akm2 = 1					// ( 5)	AKM2: analyzes output from Movers.m
global mincer = 1 				// ( 6) MINCER: conduct Mincer analysis
global postestimation = 1 		// ( 7) POSTESTIMATION: output from AKM estimation
global summarystats = 1 		// ( 8) SUMMARYSTATS: output for population, connected workers and nonconnected workers
global wagegains_switchers = 1	// (9) WAGEGAINS_SWITCHERS: wage gains of switchers by quartile
global pia = 0					// (11)	PIA firm characteristics
global minyear = 1988 			// (12) first year of data
global maxyear = 2012 			// (13) last year of data
global globallog = "master_${read}${clean}${selection}${akm}${akm2}${mincer}${postestimation}${summarystats}${nonparametrics}${wagegains_switchers}${pia}${firmdynamics}_${dataset}${with_age}${with_va}_${minyear}_${maxyear}"


********************************************************************************
* SAMPLE SELECTION
********************************************************************************
* person characteristics
global mingender = 1 // 1 = male; 2 = female
global maxgender = 1 // 1 = male; 2 = female
global minagebin = 1 // 0 = ages <18; 1 = 18-24; 2 = 25-30; 3 = 30-39; 4 = 40-49; 5 = 50 - 64; 6 = >65
global maxagebin = 4 // 0 = ages <18; 1 = 18-24; 2 = 25-30; 3 = 30-39; 4 = 40-49; 5 = 50 - 64; 6 = >65

* work contract
global minhours = 0
global maxhours = . // to exclude missing observations, set this to e.g. 999

* define periods properties
global periodlength = 4		// period length - 1 (i.e. if there are 5 years in a period then set this to 4)
global nperiods = 6			// number of periods

* definition switches
global wageconcept = 1 // 1 = multiples of minimum wage; 2 = real wage
global cboconcept = 2 // 1 = CBO1994; 2 = CBO2002
global cbonum = 2 // number of digits for CBO classifications
global cnaeconcept = 0 // 0 = IBGE Subsector; 1 = CNAE 1.0; 2 = CNAE 2.0
global ageconcept = 2 // 1 = exact age (when available); 2 = age bins

* industry selection
if $cnaeconcept == 0 { // (2-digits IBGE Subsetores)
	global ind_min = 0 // manufacturing & mining starts at ?
	global ind_max = . // manufacturing & mining ends at ?
}
if $cnaeconcept == 1 { // (3-digits CNAE 1.0)
	global ind_min = 0 // manufacturing & mining starts at ?
	global ind_max = . // manufacturing & mining ends at 370
}
if $cnaeconcept == 2 { //  (3-digits CNAE 2.0)
	global ind_min = 0 // manufacturing & mining starts at ?
	global ind_max = . // manufacturing & mining ends at 330
}


********************************************************************************
* DEMOGRAPHIC CONTROLS
********************************************************************************
* Number of grid points for density estimation of fixed effects
global binpoints = 90
global nquantiles = 500


********************************************************************************
* DIRECTORY OF RAW DATA FILES AND WHERE TO SAVE CREATED FILES
********************************************************************************
global MAINPATH = "//Servidor2/f/ipea/projetos/2015/Projetos IBGE/03605000998_2014_35 - Princeton"
sysdir set PERSONAL "$MAINPATH/4_packages/stata/personal"
sysdir set PLUS "$MAINPATH/4_packages/stata/plus"

* Input paths
global DATAPATH = "//Servidor2/f/ipea/Bases de dados/RAIS/Utilização/Brasil_novas"	
global MATLABBGLPATH = "$MAINPATH/4_packages/matlab_bgl/"
global MATLABPATH = "C:/Program Files/MATLAB/R2014b/bin"
global CPIDATA = "$MAINPATH/3_data/Converters/wagedeflator_IPCA.dta"
global MINWAGEDATA = "$MAINPATH/3_data/Converters/salario_minimo_periodo_1996a2013.dta"
global PIA_DATA = "$MAINPATH/3_data/PIA"
global CAPITAL_DATA="$MAINPATH/3_data/Capital/cris_curvature"
global TFP_DATA="$MAINPATH/3_data/TFP"
global OCCUP_CONV_1994_2002 = "$MAINPATH/3_data/Converters/CBO1994_CBO2002_3d.dta"
global OCCUP_CONV_2002_1994 = "$MAINPATH/3_data/Converters/CBO2002_CBO1994_3d.dta"
global SECT_CONV_CNAE_SUBSIBGE = "$MAINPATH/3_data/Converters/tradutor_novo_cnae_e_subsibge.dta"
global SECT_CONV_CNAE_CNAE10 = "$MAINPATH/3_data/Converters/tradutor_novo_cnae_para_cnae10_e_cnae10_para_cnae.dta"
global SECT_CONV_CNAE10_CNAE20 = "$MAINPATH/3_data/Converters/tradutor_novo_cnae10_para_cnae20.dta"
global SECT_CONV_CNAE20_CNAE10 = "$MAINPATH/3_data/Converters/tradutor_novo_cnae20_para_cnae10.dta"

* Output paths
global PERMPATH = "$MAINPATH/3_data"
global TEMPPATH = "$MAINPATH/2_output"
global READ_FILES = "$MAINPATH/"
global SAVE_SCANNED = "$TEMPPATH/1_scanned_data"
global SAVE_CLEANED = "$TEMPPATH/2_cleaned_data"
global SAVE_MATLAB = "$TEMPPATH/3_matlab"
global SAVE_SUMMARYSTATS = "$TEMPPATH/4_summary_statistics"
global SAVE_NONPARAMETRICS = "$TEMPPATH/9_nonparametrics"
global SAVE_GRAPHS = "$TEMPPATH/6_graphs"


********************************************************************************
* MAIN CODE
********************************************************************************
*log using "${MAINPATH}/${globallog}", replace
disp "********************************************************************************"
disp "********************************************************************************"
disp "* MASTER.do"
disp "********************************************************************************"
disp "********************************************************************************"
disp "STARTING ON $S_DATE AT $S_TIME."
display _newline(5)

if $read == 1 do "$READ_FILES/READ" 								// ( 1)	Read raw data
if $clean == 1 do "$MAINPATH/CLEAN" 								// ( 2)	Cleaning the raw data files
if $selection == 1 do "$MAINPATH/SELECTION" 						// ( 3)	Making sample selections and exporting the data on movers to MATLAB
if $akm == 1 do "$MAINPATH/AKM" 									// ( 4)	Runs MATLAB and combines estimates with data on stayers to generate the final file
if $akm2 == 1 do "$MAINPATH/AKM2"									// ( 5)	Analyzes output from AKM
if $mincer == 1 do "$MAINPATH/MINCER"								// ( 6)	Mincer regression
if $postestimation == 1 do "$MAINPATH/POSTESTIMATION" 				// ( 7)	Computing second moments for ind.-FE, establ.-FE, and demographic effects
if $summarystats == 1 do "$MAINPATH/SUMMARYSTATS" 					// ( 8)	Summary stats on connected set and all workers
if $nonparametrics == 1 do "$MAINPATH/NONPARAMETRICS" 				// ( 9)	Non-parametric Guvenen exercises
if $wagegains_switchers == 1 do "$MAINPATH/WAGEGAINS_SWITCHERS" 	// (10)	Wage gains for switchers by quartile
if $pia == 1 do "$MAINPATH/PIA"										// (11)	PIA firm characteristics


timer off 1
timer list 1

disp "FINISHED ON $S_DATE AT $S_TIME IN A TOTAL OF `r(t1)' SECONDS."

log close
