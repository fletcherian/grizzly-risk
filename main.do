**********Load Cleaned and Merged Data and Rename Variables
import delimited "/Users/chandlerhubbard/Hochard Res. Group Dropbox/Chandler Hubbard/EPSCOR (Chandler + Ian)/Survey_Results/cleaned_data/total_success_gis.csv", clear


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


*********************************1Q versus 2Q Treatment*************************
*** Test to see if the two treatments 1Q v 2Q are statistically different ***

* For each treatment run a censored poisson regression to estimate the number of
* encounters, have different checks if necessary. Then run a censored poisson
* regression to estimate just the number of relocations, while having different
* checks if necessary. Finish with summary statistics.

foreach condition in bel des {
    if "`condition'" == "bel" {
        gen `condition'_treatment = (q2_bel_remove_prop != "NA")
    }
    else if "`condition'" == "des" {
        gen `condition'_treatment = (q2_des_remove_prop != "NA")
    }
    replace `condition'_treatment = 0 if missing(q2_`condition'_remove_prop)

    foreach var in prop threat inj {
        * Generate and analyze encounters
        gen `var'_`condition'_encounters = ""
        replace `var'_`condition'_encounters = q1_`condition'_remove_`var' if `condition'_treatment == 0
        replace `var'_`condition'_encounters = q2_`condition'_remove_`var' if `condition'_treatment == 1
        replace `var'_`condition'_encounters = "5" if `var'_`condition'_encounters == "5+"
        
        if "`condition'" == "des" {
            replace `var'_`condition'_encounters = "." if `var'_`condition'_encounters == "Unlimited (never remove)"
        }

        destring `var'_`condition'_encounters, replace
        cpoisson `var'_`condition'_encounters `condition'_treatment, ul(5) nolog
		* Lines to activate for further checks
		*glm `var'_`condition'_encounters `condition'_treatment, fam(poi) nolog
		*ologit `var'_`condition'_encounters `condition'_treatment, nolog

        * Generate and analyze relocation
        gen `var'_`condition'_relocation = ""
        replace `var'_`condition'_relocation = q2_`condition'_relocate_`var' if `condition'_treatment == 1
        replace `var'_`condition'_relocation = q1_`condition'_remove_`var' if `condition'_treatment == 0
        replace `var'_`condition'_relocation = "5" if `var'_`condition'_relocation == "5+"

        if "`condition'" == "des" {
            replace `var'_`condition'_relocation = "." if `var'_`condition'_relocation == "Unlimited (never relocate)" | `var'_`condition'_relocation == "Unlimited (never remove)"
        }

        destring `var'_`condition'_relocation, replace

        * Compute number of relocations
        gen `var'_`condition'_number = `var'_`condition'_encounters - `var'_`condition'_relocation if `condition'_treatment == 1
        replace `var'_`condition'_number = `var'_`condition'_relocation - 1 if `condition'_treatment == 0
        cpoisson `var'_`condition'_number `condition'_treatment, ul(4) nolog
		* Lines to activate for further checks
		*glm `var'_`condition'_encounters `condition'_treatment, fam(poi) nolog
		*ologit `var'_`condition'_encounters `condition'_treatment, nolog


        * Basic stat testing
        summarize `var'_`condition'_number
        summarize `var'_`condition'_number if `condition'_treatment == 1 
        summarize `var'_`condition'_number if `condition'_treatment == 0
    }
}


*** Confirm analysis holds for combination instead of dropping ***

* Drop the variables we are going to over ride 
drop prop_des_relocation prop_des_number threat_des_number threat_des_relocation inj_des_number inj_des_relocation

* Macro to streamline operations for different types of encounters (prop, threat, injury)
foreach var in prop threat inj {
    
    * Replace missing values and perform regression analysis
    replace `var'_des_encounters = 5 if missing(`var'_des_encounters)
    cpoisson `var'_des_encounters des_treatment, ul(5) nolog
	* Lines to activate for further checks
	*glm `var'_`condition'_encounters `condition'_treatment, fam(poi) nolog
	*ologit `var'_`condition'_encounters `condition'_treatment, nolog


    * Generate and analyze relocation
    gen `var'_des_relocation = ""
    replace `var'_des_relocation = q2_des_relocate_`var' if des_treatment == 1
    replace `var'_des_relocation = q1_des_remove_`var' if des_treatment == 0
    replace `var'_des_relocation = "5" if `var'_des_relocation == "5+" | `var'_des_relocation == "Unlimited (never relocate)" | `var'_des_relocation == "Unlimited (never remove)"
    destring `var'_des_relocation, replace

    * Compute number of relocations
    gen `var'_des_number = `var'_des_encounters - `var'_des_relocation if des_treatment == 1
    replace `var'_des_number = `var'_des_relocation - 1 if des_treatment == 0
    cpoisson `var'_des_number des_treatment, ul(4) nolog
	*Lines to activate for further checks
	*glm `var'_`condition'_encounters `condition'_treatment, fam(poi) nolog
	*ologit `var'_`condition'_encounters `condition'_treatment, nolog

    * Basic stat testing
    summarize `var'_des_number
    summarize `var'_des_number if des_treatment == 1 
    summarize `var'_des_number if des_treatment == 0
}



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
foreach q in 1 2 {
    foreach attr in prop threat injury {
        * Transform data
        gen `attr'_`q'q = q`q'_bel_remove_`attr' if situation == "believed"
        replace `attr'_`q'q = q`q'_des_remove_`attr' if situation == "desired"
        replace `attr'_`q'q = "5" if `attr'_`q'q == "5+"
        replace `attr'_`q'q = "5" if `attr'_`q'q == "Unlimited (never remove)"
        replace `attr'_`q'q = "." if `attr'_`q'q == "NA"
        destring `attr'_`q'q, replace

        * Run regression
        cpoisson `attr'_`q'q situation_num, ul(5) nolog
    }
}

* Believed versus Actual Analysis
foreach q in 1 2 {
    foreach attr in prop threat injury {
        * Data cleaning
        replace q`q'_bel_remove_`attr' = "5" if q`q'_bel_remove_`attr' == "5+"
        
        * Analyze using a temporary dataset
        tempfile tempdata
        save `tempdata'
        
        use `tempdata', clear
        drop if q`q'_bel_remove_`attr' == "NA"
        destring q`q'_bel_remove_`attr', replace
        
        * Calculate mean and run bootstrap
        sum q`q'_bel_remove_`attr'
        bootstrap mean`q'`attr'test=r(mean): sum q`q'_bel_remove_`attr'
        
        * Return to main data
        use `tempdata', clear
    }
}
restore 


*********************** Balanace Analysis ***************************
* Test to make sure each treatment is balanced in composition of respondents.
* Work through each demographic variable and do inverse probability weighting
* analysis.

preserve
* make total prop removal encounters
gen tot_bel_remove_prop = ""
replace tot_bel_remove_prop = q1_bel_remove_prop
replace tot_bel_remove_prop = q2_bel_remove_prop if tot_bel_remove_prop == "NA"
replace tot_bel_remove_prop = "5" if tot_bel_remove_prop == "5+"
destring tot_bel_remove_prop, replace

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

************* IPW Analysis ***********
teffects ipw (tot_bel_remove_prop) (question_treatment i.age_reg i.sex_reg i.degree_reg i.politics_reg i.income_reg)
tebalance summarize
*tebalance overid, nolog
restore



****************** Categorical Analysis ***************************
* Check to see if the different categories within each demographic variable have
* any signficant differences. Run 1Q believed and desired, 2Q believed and 
* desired using a censored poisson regression.

***************** Region Sections *****************
* Change region to dummy vars
replace region = "0" if region == "National"
replace region = "1" if region == "Rocky Mountain"
destring region, replace

* Function to perform transformations and regressions
capture program drop process_data
program process_data, rclass
    * Capture arguments using local macros
    local varname = "`1'"
    local regressor = "`2'"
    local response_label = "`3'"
    
    * Replace "5+" and "Unlimited (never ...)" with 5
    qui replace `varname' = "5" if inlist(`varname', "5+", "`response_label'")
    qui destring `varname', replace
    
    * Check if regressor is categorical (i.e., needs factor variable handling)
    * This is a simplistic check, replace with a more robust method if needed
    local is_categorical = strpos("`regressor'", "cat_") // assuming categorical variables have a prefix 'cat_'
    
    * Perform regression with or without categorical handling
    if `is_categorical' {
        cpoisson `varname' i.`regressor', ul(5) nolog
    }
    else {
        cpoisson `varname' `regressor', ul(5) nolog 
    }
end

* 1Q NATIONAL vs ROCKY MOUNTAIN BELIEVED
preserve
drop if question_treatment == 1

* Run function for 1Q Believed
process_data q1_bel_remove_prop region ""
process_data q1_bel_remove_threat region ""
process_data q1_bel_remove_injury region ""

restore

* 2Q NATIONAL vs ROCKY MOUNTAIN BELIEVED
preserve
drop if question_treatment == 0

* Run function for 2Q Believed
process_data q2_bel_relocate_prop region ""
process_data q2_bel_remove_prop region ""
process_data q2_bel_relocate_threat region ""
process_data q2_bel_remove_threat region ""
process_data q2_bel_relocate_injury region ""
process_data q2_bel_remove_injury region ""

restore

* 1Q NATIONAL vs ROCKY MOUNTAIN DESIRED
preserve
drop if question_treatment == 1

* Run function for 1Q Desired
process_data q1_des_remove_prop region "Unlimited (never remove)"
process_data q1_des_remove_threat region "Unlimited (never remove)"
process_data q1_des_remove_injury region "Unlimited (never remove)"

restore

* 2Q NATIONAL vs ROCKY MOUNTAIN DESIRED
preserve
drop if question_treatment == 0

* Run function for 2Q Desired
process_data q2_des_relocate_prop region "Unlimited (never relocate)"
process_data q2_des_remove_prop region "Unlimited (never remove)"
process_data q2_des_relocate_threat region "Unlimited (never relocate)"
process_data q2_des_remove_threat region "Unlimited (never remove)"
process_data q2_des_relocate_injury region "Unlimited (never relocate)"
process_data q2_des_remove_injury region "Unlimited (never remove)"

restore


***************** Sex Sections *****************
* Convert sex to dummy vars and drop "No Response"
replace sex = "1" if sex == "Male"
replace sex = "0" if sex == "Female"
drop if sex == "No Response"
destring sex, replace

* 1Q MALE vs FEMALE BELIEVED
preserve
drop if question_treatment == 1

* Run function for 1Q Believed with sex as a predictor
process_data q1_bel_remove_prop sex ""
process_data q1_bel_remove_threat sex ""
process_data q1_bel_remove_injury sex ""

restore

* 2Q MALE vs FEMALE BELIEVED
preserve
drop if question_treatment == 0

* Run function for 2Q Believed with sex as a predictor
process_data q2_bel_relocate_prop sex ""
process_data q2_bel_remove_prop sex ""
process_data q2_bel_relocate_threat sex ""
process_data q2_bel_remove_threat sex ""
process_data q2_bel_relocate_injury sex ""
process_data q2_bel_remove_injury sex ""

restore

* 1Q MALE vs FEMALE DESIRED
preserve
drop if question_treatment == 1

* Run function for 1Q Desired with sex as a predictor
process_data q1_des_remove_prop sex "Unlimited (never remove)"
process_data q1_des_remove_threat sex "Unlimited (never remove)"
process_data q1_des_remove_injury sex "Unlimited (never remove)"

restore

* 2Q MALE vs FEMALE DESIRED
preserve
drop if question_treatment == 0

* Run function for 2Q Desired with sex as a predictor
process_data q2_des_relocate_prop sex "Unlimited (never relocate)"
process_data q2_des_remove_prop sex "Unlimited (never remove)"
process_data q2_des_relocate_threat sex "Unlimited (never relocate)"
process_data q2_des_remove_threat sex "Unlimited (never remove)"
process_data q2_des_relocate_injury sex "Unlimited (never relocate)"
process_data q2_des_remove_injury sex "Unlimited (never remove)"

restore



***** Define Function for sections with 2 regressors 
* Function to perform transformations and regressions
capture program drop process_bigger_data

program process_bigger_data, rclass
    * Capture arguments using local macros
    local varname = "`1'"
    local regressor = "`2'"
	local regressor_2 = "`3'"
    local response_label = "`4'"
    
    * Replace "5+" and "Unlimited (never ...)" with 5
    qui replace `varname' = "5" if inlist(`varname', "5+", "`response_label'")
    qui destring `varname', replace
    
    * Perform regression
    cpoisson `varname' `regressor' `regressor_2', ul(5) nolog
end

*****************Income Sections************
generate middle_inc = 0 
generate high_inc = 0 
replace middle_inc = 1 if income == "Between $50,000 and $64,999" | income == "Between $65,000 and $74,999" | income == "Between $75,000 and $99,999"
replace high_inc = 1 if income == "Between $150,000 and $199,999" | income == "Between $100,000 and $149,999" | income == "$200,000 or more"

* 1Q BELIEVED
preserve
drop if question_treatment == 1

* Run function for 1Q Believed with income levels as a predictor
process_bigger_data q1_bel_remove_prop middle_inc high_inc ""
process_bigger_data q1_bel_remove_threat middle_inc high_inc ""
process_bigger_data q1_bel_remove_injury middle_inc high_inc ""

restore

* 2Q BELIEVED
preserve
drop if question_treatment == 0

* Run function for 2Q Believed with income levels as a predictor
process_bigger_data q2_bel_relocate_prop middle_inc high_inc ""
process_bigger_data q2_bel_remove_prop middle_inc high_inc ""
process_bigger_data q2_bel_relocate_threat middle_inc high_inc ""
process_bigger_data q2_bel_remove_threat middle_inc high_inc ""
process_bigger_data q2_bel_relocate_injury middle_inc high_inc ""
process_bigger_data q2_bel_remove_injury middle_inc high_inc ""

restore

* 1Q DESIRED
preserve
drop if question_treatment == 1

* Run function for 1Q Desired with income levels as a predictor
process_bigger_data q1_des_remove_prop middle_inc high_inc "Unlimited (never remove)"
process_bigger_data q1_des_remove_threat middle_inc high_inc "Unlimited (never remove)"
process_bigger_data q1_des_remove_injury middle_inc high_inc "Unlimited (never remove)"

restore

* 2Q DESIRED
preserve
drop if question_treatment == 0

* Run function for 2Q Desired with income levels as a predictor
process_bigger_data q2_des_relocate_prop middle_inc high_inc "Unlimited (never relocate)"
process_bigger_data q2_des_remove_prop middle_inc high_inc "Unlimited (never remove)"
process_bigger_data q2_des_relocate_threat middle_inc high_inc "Unlimited (never relocate)"
process_bigger_data q2_des_remove_threat middle_inc high_inc "Unlimited (never remove)"
process_bigger_data q2_des_relocate_injury middle_inc high_inc "Unlimited (never relocate)"
process_bigger_data q2_des_remove_injury middle_inc high_inc "Unlimited (never remove)"

restore


*****************Age Sections**************
gen middleage = 0
replace middleage = 1 if age == "35 to 44 years" | age == "45 to 54 years" | age == "55 to 59 years"
gen geriatric = 0
replace geriatric = 1 if age == "60 to 64 years" | age == "65 to 74 years" | age == "75 to 84 years" | age == "85 years or more"

* 1Q BELIEVED
preserve
drop if question_treatment == 1

* Run function for 1Q Believed with age levels as a predictor
process_bigger_data q1_bel_remove_prop middleage geriatric ""
process_bigger_data q1_bel_remove_threat middleage geriatric ""
process_bigger_data q1_bel_remove_injury middleage geriatric ""

restore

* 2Q BELIEVED
preserve
drop if question_treatment == 0

* Run function for 2Q Believed with age levels as a predictor
process_bigger_data q2_bel_relocate_prop middleage geriatric ""
process_bigger_data q2_bel_remove_prop middleage geriatric ""
process_bigger_data q2_bel_relocate_threat middleage geriatric ""
process_bigger_data q2_bel_remove_threat middleage geriatric ""
process_bigger_data q2_bel_relocate_injury middleage geriatric ""
process_bigger_data q2_bel_remove_injury middleage geriatric ""

restore

* 1Q DESIRED
preserve
drop if question_treatment == 1

* Run function for 1Q Desired with age levels as a predictor
process_bigger_data q1_des_remove_prop middleage geriatric "Unlimited (never remove)"
process_bigger_data q1_des_remove_threat middleage geriatric "Unlimited (never remove)"
process_bigger_data q1_des_remove_injury middleage geriatric "Unlimited (never remove)"

restore

* 2Q DESIRED
preserve
drop if question_treatment == 0

* Run function for 2Q Desired with age levels as a predictor
process_bigger_data q2_des_relocate_prop middleage geriatric "Unlimited (never relocate)"
process_bigger_data q2_des_remove_prop middleage geriatric "Unlimited (never remove)"
process_bigger_data q2_des_relocate_threat middleage geriatric "Unlimited (never relocate)"
process_bigger_data q2_des_remove_threat middleage geriatric "Unlimited (never remove)"
process_bigger_data q2_des_relocate_injury middleage geriatric "Unlimited (never relocate)"
process_bigger_data q2_des_remove_injury middleage geriatric "Unlimited (never remove)"

restore


*****************Politics Sections*************
gen conservative = 0
replace conservative = 1 if politics == "Very conservative" | politics == "Conservative"
gen liberal = 0
replace liberal = 1 if politics == "Very liberal" | politics == "Liberal"


* 1Q BELIEVED
preserve
drop if question_treatment == 1

* Run function for 1Q Believed with political levels as a predictor
process_bigger_data q1_bel_remove_prop conservative liberal ""
process_bigger_data q1_bel_remove_threat conservative liberal ""
process_bigger_data q1_bel_remove_injury conservative liberal ""

restore

* 2Q BELIEVED
preserve
drop if question_treatment == 0

* Run function for 2Q Believed with political levels as a predictor
process_bigger_data q2_bel_relocate_prop conservative liberal ""
process_bigger_data q2_bel_remove_prop conservative liberal ""
process_bigger_data q2_bel_relocate_threat conservative liberal ""
process_bigger_data q2_bel_remove_threat conservative liberal ""
process_bigger_data q2_bel_relocate_injury conservative liberal ""
process_bigger_data q2_bel_remove_injury conservative liberal ""

restore

* 1Q DESIRED
preserve
drop if question_treatment == 1

* Run function for 1Q Desired with political levels as a predictor
process_bigger_data q1_des_remove_prop conservative liberal "Unlimited (never remove)"
process_bigger_data q1_des_remove_threat conservative liberal "Unlimited (never remove)"
process_bigger_data q1_des_remove_injury conservative liberal "Unlimited (never remove)"

restore

* 2Q DESIRED
preserve
drop if question_treatment == 0

* Run function for 2Q Desired with political levels as a predictor
process_bigger_data q2_des_relocate_prop conservative liberal "Unlimited (never relocate)"
process_bigger_data q2_des_remove_prop conservative liberal "Unlimited (never remove)"
process_bigger_data q2_des_relocate_threat conservative liberal "Unlimited (never relocate)"
process_bigger_data q2_des_remove_threat conservative liberal "Unlimited (never remove)"
process_bigger_data q2_des_relocate_injury conservative liberal "Unlimited (never relocate)"
process_bigger_data q2_des_remove_injury conservative liberal "Unlimited (never remove)"

restore


*************** Education Sections ***************** 
* Encode 'education' into a numeric categorical variable
encode education, generate(cat_education)
recode cat_education (1=4) (2=5) (3=6) (4=2) (5=1) (6=3), generate(cat_educ_ord)
label define education_level 1 "Less than high school" 2 "High school graduate" 3 "Some college" 4 "Associate degree" 5 "Bachelor degree" 6 "Graduate degree"

* Assign the label to the variable
label values cat_educ_ord education_level



* 1Q eudcation BELIEVED
preserve
drop if question_treatment == 1

* Run function for 1Q Believed with education as a predictor
process_data q1_bel_remove_prop cat_educ_ord ""
process_data q1_bel_remove_threat cat_educ_ord ""
process_data q1_bel_remove_injury cat_educ_ord ""

restore

* 2Q education BELIEVED
preserve
drop if question_treatment == 0

* Run function for 2Q Believed with education as a predictor
process_data q2_bel_relocate_prop cat_educ_ord ""
process_data q2_bel_remove_prop cat_educ_ord ""
process_data q2_bel_relocate_threat cat_educ_ord ""
process_data q2_bel_remove_threat cat_educ_ord ""
process_data q2_bel_relocate_injury cat_educ_ord ""
process_data q2_bel_remove_injury cat_educ_ord ""

restore

* 1Q education DESIRED
preserve
drop if question_treatment == 1

* Run function for 1Q Desired with education as a predictor
process_data q1_des_remove_prop cat_educ_ord "Unlimited (never remove)"
process_data q1_des_remove_threat cat_educ_ord "Unlimited (never remove)"
process_data q1_des_remove_injury cat_educ_ord "Unlimited (never remove)"

restore

* 2Q education DESIRED
preserve
drop if question_treatment == 0

* Run function for 2Q Desired with educated as a predictor
process_data q2_des_relocate_prop cat_educ_ord "Unlimited (never relocate)"
process_data q2_des_remove_prop cat_educ_ord "Unlimited (never remove)"
process_data q2_des_relocate_threat cat_educ_ord "Unlimited (never relocate)"
process_data q2_des_remove_threat cat_educ_ord "Unlimited (never remove)"
process_data q2_des_relocate_injury cat_educ_ord "Unlimited (never relocate)"
process_data q2_des_remove_injury cat_educ_ord "Unlimited (never remove)"

restore




********************** Region Section ********** 
* Generate a new variable 'region' with default value as missing (.)
gen cat_region = .

* Assign value 1 to 'region' for states in the West
replace cat_region= 1 if state == "California" | state == "Oregon"| state ==  "Washington"| state == "Alaska"| state ==  "Hawaii"

replace cat_region = 2 if state ==  "Idaho"| state ==  "Nevada"| state ==  "New Mexico"| state ==  "Colorado"| state ==  "Arizona"| state == "Wyoming"| state ==  "Montana"| state == "Utah"

replace cat_region = 3 if state == "North Dakota" | state == "South Dakota" | state == "Nebraska" | state == "Kansas" | state == "Missouri" | state == "Iowa" | state == "Minnesota"

replace cat_region = 4 if state == "Michigan" | state == "Illinois" | state == "Indiana" | state == "Wisconsin" | state == "Ohio"

replace cat_region = 5 if state == "Pennsylvania" | state == "New Jersey" | state == "New York"

replace cat_region = 6 if state == "Delaware" | state == "Connecticut" | state == "Rhode Island" | state == "Massachusetts" | state == "New Hampshire" | state == "Vermont" | state == "Maine" 

replace cat_region = 7 if state == "Florida"| state ==  "Georgia"| state == "South Carolina" | state == "North Carolina" | state == "Virginia" | state == "West Virginia" | state == "Maryland" | state == "District of Columbia"

replace cat_region  = 8 if state ==  "Alabama"| state == "Mississippi"| state == "Tennessee" |  state == "Kentucky"

replace cat_region = 9 if  state == "Texas" | state == "Oklahoma" | state == "Arkansas" | state == "Louisiana" 



* Define labels for the 'region' variable
label define region_label 1 "Pacific" 2 "Mountain" 3 "West North Central" 4 "East North Central" 5 "Mid Atlantic" 6 "New England" 7 "South Atlantic" 8 "East South Central" 9 "West South Central"

* Assign the label to the 'region' variable
label values cat_region region_label

* 1Q eudcation BELIEVED
preserve
drop if question_treatment == 1

* Run function for 1Q Believed with education as a predictor
process_data q1_bel_remove_prop cat_region ""
process_data q1_bel_remove_threat cat_region ""
process_data q1_bel_remove_injury cat_region ""

restore

* 2Q education BELIEVED
preserve
drop if question_treatment == 0

* Run function for 2Q Believed with education as a predictor
process_data q2_bel_relocate_prop cat_region ""
process_data q2_bel_remove_prop cat_region ""
process_data q2_bel_relocate_threat cat_region ""
process_data q2_bel_remove_threat cat_region ""
process_data q2_bel_relocate_injury cat_region ""
process_data q2_bel_remove_injury cat_region ""

restore

* 1Q education DESIRED
preserve
drop if question_treatment == 1

* Run function for 1Q Desired with education as a predictor
process_data q1_des_remove_prop cat_region "Unlimited (never remove)"
process_data q1_des_remove_threat cat_region "Unlimited (never remove)"
process_data q1_des_remove_injury cat_region "Unlimited (never remove)"

restore

* 2Q education DESIRED
preserve
drop if question_treatment == 0

* Run function for 2Q Desired with educated as a predictor
process_data q2_des_relocate_prop cat_region "Unlimited (never relocate)"
process_data q2_des_remove_prop cat_region "Unlimited (never remove)"
process_data q2_des_relocate_threat cat_region "Unlimited (never relocate)"
process_data q2_des_remove_threat cat_region "Unlimited (never remove)"
process_data q2_des_relocate_injury cat_region "Unlimited (never relocate)"
process_data q2_des_remove_injury cat_region "Unlimited (never remove)"

restore




***** 2Q variance *****
preserve
	drop if question_treatment == 0

	replace q2_des_remove_prop = "5" if q2_des_remove_prop == "Unlimited (never remove)" | q2_des_remove_prop == "5+"
	replace q2_des_remove_threat = "5" if q2_des_remove_threat == "Unlimited (never remove)" | q2_des_remove_threat == "5+"
	replace q2_des_remove_injury = "5" if q2_des_remove_injury == "Unlimited (never remove)" | q2_des_remove_injury == "5+"
	destring(q2_des_remove_prop), replace
	destring(q2_des_remove_threat), replace
	destring(q2_des_remove_injury), replace
	
	replace q2_bel_remove_prop = "5" if q2_bel_remove_prop == "Unlimited (never remove)" | q2_bel_remove_prop == "5+"
	replace q2_bel_remove_threat = "5" if q2_bel_remove_threat == "Unlimited (never remove)" | q2_bel_remove_threat == "5+"
	replace q2_bel_remove_injury = "5" if q2_bel_remove_injury == "Unlimited (never remove)" | q2_bel_remove_injury == "5+"
	destring(q2_bel_remove_prop), replace
	destring(q2_bel_remove_threat), replace
	destring(q2_bel_remove_injury), replace

	gen diff_prop = q2_des_remove_prop - q2_bel_remove_prop
	gen diff_threat = q2_des_remove_threat - q2_bel_remove_threat
	gen diff_injury = q2_des_remove_injury - q2_bel_remove_injury
	tabstat diff_prop diff_threat diff_injury, stat(N mean sd var) by(region)
restore 

***** 1Q variance ******
preserve 
	drop if question_treatment == 1
	
	replace q1_des_remove_prop = "5" if q1_des_remove_prop == "Unlimited (never remove)" | q1_des_remove_prop == "5+"
	replace q1_des_remove_threat = "5" if q1_des_remove_threat == "Unlimited (never remove)" | q1_des_remove_threat == "5+"
	replace q1_des_remove_injury = "5" if q1_des_remove_injury == "Unlimited (never remove)" | q1_des_remove_injury == "5+"
	destring(q1_des_remove_prop), replace
	destring(q1_des_remove_threat), replace
	destring(q1_des_remove_injury), replace
	
	replace q1_bel_remove_prop = "5" if q1_bel_remove_prop == "Unlimited (never remove)" | q1_bel_remove_prop == "5+"
	replace q1_bel_remove_threat = "5" if q1_bel_remove_threat == "Unlimited (never remove)" | q1_bel_remove_threat == "5+"
	replace q1_bel_remove_injury = "5" if q1_bel_remove_injury == "Unlimited (never remove)" | q1_bel_remove_injury == "5+"
	destring(q1_bel_remove_prop), replace
	destring(q1_bel_remove_threat), replace
	destring(q1_bel_remove_injury), replace

	gen diff_prop = q1_des_remove_prop - q1_bel_remove_prop
	gen diff_threat = q1_des_remove_threat - q1_bel_remove_threat
	gen diff_injury = q1_des_remove_injury - q1_bel_remove_injury
	tabstat diff_prop diff_threat diff_injury, stat(N mean sd var) by(region)

restore 


