* Individual Preference Elicitation Transforms 'Social Carrying Capacity' into a Pragmatic Management Tool
* Chandler Hubbard, Ian Fletcher, Todd Cherry, David Finnoff, Jacob Hochard

* Estimating Coefficients to Generate Predictive Maps
* Estimates correspond to Tables 9-15 in Appendix
* Tables are used to generate figures 3-5 in the main body and 6-11 in appendix

* Last Updated: July 14, 2025
********************************************************************************

* Initial Set Up
clear all
set more off

********************************************************************************

* Set Directory Paths
if "`c(username)'" == "ianfletcher" {
	cd "/Users/ianfletcher/projects/bears" 	        // General Project Folder
	gl raw = "./02 - input/raw" 					// Data Storage
	gl temp = "./02 - input/temp" 					// Temp/Intermediate File Storage
	gl clean = "./02 - input/clean" 				// Clean File Storage
	gl figs = "./03 - output/figures"				// Figure Storage
	gl tabs = "./03 - output/tables"				// Table Storage
	gl misc = "./03 - output/misc"					// Miscellaneous Output Storage
}

********************************************************************************
***********************   RAW DATA CLEANING   **********************************
********************************************************************************

import delimited "${raw}/total_success_gis.csv", clear

* Clean and Rename Variables
drop startdate enddate status ipaddress progress durationinseconds finished recordeddate recipientlastname recipientfirstname recipientemail externalreference locationlatitude locationlongitude distributionchannel userlanguage q_recaptchascore q_ballotboxstuffing svid rid risn q32 ls ps

rename q27 age
rename q29 sex
rename q1 park_importance
rename q2 wildlife_informed
rename q3 bear_informed

rename q54_1 q1_bel_remove_prop
rename q54_2 q1_bel_remove_threat
rename q54_3 q1_bel_remove_injury

rename q28_1 q1_des_remove_prop
rename q28_2 q1_des_remove_threat
rename q28_3 q1_des_remove_injury

rename q20 np_visit
rename q21 gt_visit
rename q22 bear_exp
rename q23 live_bear
rename q25 bear_nuisance
rename q24 farm_bear
rename q26 bear_actions
rename q3654 actions_effective

rename q30 education
rename q31 politics
rename geoid10 zipcode
rename q34 income

****************** Restructure Variables ********************
********* Income Change ***********
gen income_reg = .
replace income_reg = 1 if income == "Under $15,000"
replace income_reg = 2 if income == "Between $15,000 and $24,999" 
replace income_reg = 3 if income =="Between $25,000 and $34,999" 
replace income_reg = 4 if income == "Between $35,000 and $49,999"
replace income_reg = 5 if income == "Between $50,000 and $64,999"
replace income_reg = 6 if income == "Between $65,000 and $74,999"
replace income_reg = 7 if income == "Between $75,000 and $99,999"
replace income_reg = 8 if income == "Between $100,000 and $149,999"
replace income_reg = 9 if income == "Between $150,000 and $199,999"
replace income_reg = 10 if income == "$200,000 or more"

sort income_reg

label define income_label 1 "Under $15,000" 2 "Between $15,000 and $24,999" 3 "Between $25,000 and $34,999" 4 "Between $35,000 and $49,999" 5 "Between $50,000 and $64,999" 6 " Between $65,000 and $74,999" 7 "Between $75,000 and $99,999" 8 "Between $100,000 and $149,999" 9 "Between $150,000 and $199,999" 10 "$200,000 or more"
label values income_reg income_label

drop income
************** Age Change ************
gen age_reg = . 
replace age_reg =1 if age == "18 to 19 years"
replace age_reg =2 if age == "20 to 24 years"
replace age_reg =3 if age == "25 to 34 years"
replace age_reg =4 if age == "35 to 44 years"
replace age_reg =5 if age == "45 to 54 years"
replace age_reg =6 if age == "55 to 59 years"
replace age_reg =7 if age == "60 to 64 years"
replace age_reg =8 if age == "65 to 74 years"
replace age_reg =9 if age == "75 to 84 years"
replace age_reg =10 if age == "85 years or more"

sort age_reg

label define age_label 1 "18 to 19 years" 2 "20 to 24 years" 3 "25 to 34 years" 4 "35 to 44 years" 5 "45 to 54 years" 6 "55 to 59 years" 7 "60 to 64 years" 8 "65 to 74 years" 9 "75 to 84 years" 10 "85 years or more"

label values age_reg age_label

drop age

********* Sex Change ***********
drop if sex == "No Response"
gen sex_reg = .
replace sex_reg = 1 if sex == "Female"
replace sex_reg = 2 if sex == "Male"

sort sex_reg 

label define sex_label 1 "Female" 2 "Male"

label values sex_reg sex_label

drop sex

*********** Region Change **********
gen region_reg = .
replace region_reg = 1 if region == "Rocky Mountain"
replace region_reg = 2 if region == "National"

sort region_reg

label define region_label 1 "Rocky Mountain" 2 "National"

label values region_reg region_label

drop region

********* Politics Change *********
gen politics_reg = .
replace politics_reg = 1 if politics == "Very liberal"
replace politics_reg = 2 if politics == "Liberal"
replace politics_reg = 3 if politics == "Moderate"
replace politics_reg = 4 if politics == "Conservative"
replace politics_reg = 5 if politics == "Very conservative"

sort politics_reg 

label define politics_label 1 "Very liberal" 2 "Liberal" 3 "Moderate" 4 "Conservative" 5 "Very conservative"

label values politics_reg politics_label

drop politics

********* Degreee Change ***********
gen degree_reg = .
replace degree_reg = 1 if education == "Less than high school"
replace degree_reg = 2 if education == "High school graduate"
replace degree_reg = 3 if education == "Some college"
replace degree_reg = 4 if education == "Associate degree"
replace degree_reg = 5 if education == "Bachelor degree"
replace degree_reg = 6 if education == "Graduate Degree"

sort degree_reg

label define degree_label 1 "Less than high school" 2 "High school graduate" 3 "Some college" 4 "Associate degree" 5 "Bachelor Degree" 6 "Graduate Degree"

label values degree_reg degree_label

drop education


*** Regressions ****************************************************************

drop if q1_bel_remove_prop == "NA"
replace q1_bel_remove_prop = "5" if q1_bel_remove_prop == "5+"

drop if q1_bel_remove_threat == "NA"
replace q1_bel_remove_threat = "5" if q1_bel_remove_threat == "5+"

drop if q1_bel_remove_injury == "NA"
replace q1_bel_remove_injury = "5" if q1_bel_remove_injury == "5+"

destring(q1_bel_remove_prop), replace
destring(q1_bel_remove_threat), replace
destring(q1_bel_remove_injury), replace

*generate interactive effects*
gen disttocurrentgrizzlyrangem_2 = disttocurrentgrizzlyrangem^2
gen dist_crop = disttocurrentgrizzlyrangem * crop_share
gen dist_pasture = disttocurrentgrizzlyrangem * pasture_share
gen dist_grasslands = disttocurrentgrizzlyrangem * gasslands_share
gen dist_dev = disttocurrentgrizzlyrangem * dev_share
gen hist_crop = historicalgrizzlyrange * crop_share
gen hist_pasture = historicalgrizzlyrange * pasture_share
gen hist_grasslands = historicalgrizzlyrange * gasslands_share
gen hist_dev =  historicalgrizzlyrange * dev_share
 
*** Believed Analysis **********************************************************
 
cpoisson q1_bel_remove_prop i.income_reg i.age_reg i.sex_reg i.region_reg i.politics_reg i.degree_reg historicalgrizzlyrange disttocurrentgrizzlyrangem disttocurrentgrizzlyrangem_2 dev_share crop_share pasture_share gasslands_share dist_crop dist_pasture dist_grasslands dist_dev hist_crop hist_pasture hist_grasslands hist_dev, ul(4) nolog

cpoisson q1_bel_remove_threat i.income_reg i.age_reg i.sex_reg i.region_reg i.politics_reg i.degree_reg historicalgrizzlyrange disttocurrentgrizzlyrangem dev_share crop_share pasture_share gasslands_share dist_crop dist_pasture dist_grasslands dist_dev hist_crop hist_pasture hist_grasslands hist_dev, ul(4) nolog

cpoisson q1_bel_remove_injury i.income_reg i.age_reg i.sex_reg i.region_reg i.politics_reg i.degree_reg historicalgrizzlyrange disttocurrentgrizzlyrangem dev_share crop_share pasture_share gasslands_share dist_crop dist_pasture dist_grasslands dist_dev hist_crop hist_pasture hist_grasslands hist_dev, ul(4) nolog

*** Desired Analysis ***********************************************************

drop if q1_des_remove_prop == "NA"
replace q1_des_remove_prop = "5" if q1_des_remove_prop == "5+"
replace q1_des_remove_prop = "5" if q1_des_remove_prop == "Unlimited (never remove)"

drop if q1_des_remove_threat == "NA"
replace q1_des_remove_threat = "5" if q1_des_remove_threat == "5+"
replace q1_des_remove_threat = "5" if q1_des_remove_threat == "Unlimited (never remove)"

drop if q1_des_remove_injury == "NA"
replace q1_des_remove_injury = "5" if q1_des_remove_injury == "5+"
replace q1_des_remove_injury = "5" if q1_des_remove_injury == "Unlimited (never remove)"

destring(q1_des_remove_prop), replace
destring(q1_des_remove_threat), replace
destring(q1_des_remove_injury), replace

cpoisson q1_des_remove_prop i.income_reg i.age_reg i.sex_reg i.region_reg i.politics_reg i.degree_reg historicalgrizzlyrange disttocurrentgrizzlyrangem disttocurrentgrizzlyrangem_2 dev_share crop_share pasture_share gasslands_share dist_crop dist_pasture dist_grasslands dist_dev hist_crop hist_pasture hist_grasslands hist_dev, ul(4) nolog

cpoisson q1_des_remove_threat i.income_reg i.age_reg i.sex_reg i.region_reg i.politics_reg i.degree_reg historicalgrizzlyrange disttocurrentgrizzlyrangem disttocurrentgrizzlyrangem_2 dev_share crop_share pasture_share gasslands_share dist_crop dist_pasture dist_grasslands dist_dev hist_crop hist_pasture hist_grasslands hist_dev, ul(4) nolog

cpoisson q1_des_remove_injury i.income_reg i.age_reg i.sex_reg i.region_reg i.politics_reg i.degree_reg historicalgrizzlyrange disttocurrentgrizzlyrangem disttocurrentgrizzlyrangem_2 dev_share crop_share pasture_share gasslands_share dist_crop dist_pasture dist_grasslands dist_dev hist_crop hist_pasture hist_grasslands hist_dev, ul(4) nolog
