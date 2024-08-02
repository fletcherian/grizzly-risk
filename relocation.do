**********Load Cleaned and Merged Data and Rename Variables
import delimited "/Users/ianfletcher/Hochard Res. Group Dropbox/Ian Fletcher/EPSCOR (Chandler + Ian)/Survey_Results/cleaned_data/total_success_gis.csv", clear

* Change raw variable names to something more intuitive
rename q27 age
rename q29 sex
rename q1 park_importance
rename q2 wildlife_informed
rename q3 bear_informed
rename q53_1 q2_bel_relocate_prop
rename q53_2 q2_bel_relocate_threat
rename q53_3 q2_bel_relocate_injury
rename q31_1 q2_bel_remove_prop
rename q31_2 q2_bel_remove_threat
rename q31_3 q2_bel_remove_injury
rename q59_1 q2_des_relocate_prop
rename q59_2 q2_des_relocate_threat
rename q59_3 q2_des_relocate_injury
rename q60_1 q2_des_remove_prop
rename q60_2 q2_des_remove_threat
rename q60_3 q2_des_remove_injury
rename q54_1 q1_bel_remove_prop
rename q54_2 q1_bel_remove_threat
rename q54_3 q1_bel_remove_injury
rename q28_1 q1_des_remove_prop
rename q28_2 q1_des_remove_threat
rename q28_3 q1_des_remove_injury
* Condense recovery variable prefence from two treatments into one variables
rename q35 q2_pref_recovered
rename q3645 pref_recovered
replace pref_recovered = (q2_pref_recovered) if pref_recovered == "NA"
drop q2_pref_recovered
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
rename q34 income
rename geoid10 zipcode

*** 1 if 2 question and 0 if 1 question treatment 
gen question_treatment = (q2_bel_remove_prop != "NA")
* Set the believed  to 0 if we are in the 1Q version, shouldnt make changes
replace question_treatment = 0 if missing(q2_bel_remove_prop)


******************** Believed versus Desired and Actual ************************
* Test to see if the believed results are statistically different from desired
* results, and if believed results are different from the actual policy. Using
* bootstrapped means and censored poission regressions.

preserve
* Believed v Desired Analysis
sort responseid
expand 2
sort responseid

* Label treatment
gen treatment = mod(_n, 2) + 1

* Define situation based on treatment
gen situation = cond(treatment == 1, "believed", "desired")
gen situation_num = (situation == "desired")

* Loop through questions and attributes for transformation and analysis
foreach q in 2{
    foreach attr in prop threat injury {
        * Transform data
        gen `attr'_`q'q = q`q'_bel_relocate_`attr' if situation == "believed"
        replace `attr'_`q'q = q`q'_des_relocate_`attr' if situation == "desired"
        replace `attr'_`q'q = "5" if `attr'_`q'q == "5+"
        replace `attr'_`q'q = "5" if `attr'_`q'q == "Unlimited (never relocate)"
        replace `attr'_`q'q = "." if `attr'_`q'q == "NA"
        destring `attr'_`q'q, replace

        * Run regression
        cpoisson `attr'_`q'q situation_num, ul(5) nolog
    }
}

* Believed versus Actual Analysis
foreach q in 2 {
    foreach attr in prop threat injury {
        * Data cleaning
        replace q`q'_bel_relocate_`attr' = "5" if q`q'_bel_relocate_`attr' == "5+"
        
        * Analyze using a temporary dataset
        tempfile tempdata
        save `tempdata'
        
        use `tempdata', clear
        drop if q`q'_bel_relocate_`attr' == "NA"
        destring q`q'_bel_relocate_`attr', replace
        
        * Calculate mean and run bootstrap
        sum q`q'_bel_relocate_`attr'
        bootstrap mean`q'`attr'test=r(mean): sum q`q'_bel_relocate_`attr'
        
        * Return to main data
        use `tempdata', clear
    }
}
restore 
