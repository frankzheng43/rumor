clear all
set more off
eststo clear
capture version 14
local location "F:/rumor"
cd "`location'"
capt log close _all
log using logs/score_reg_q, name("score_reg_q") text replace

use statadata/formerge_q.dta, clear
local keyvalue stkcd year quarter
merge 1:1 `keyvalue' using statadata/05_cv_q.dta, gen(_mcv)
merge 1:1 `keyvalue' using statadata/kz_index.dta, gen(_mkz)
merge 1:1 `keyvalue' using statadata/score_q.dta, gen(_score)
local keyvalue year quarter
merge m:1  `keyvalue' using statadata/02_macro_q_w.dta

keep if inrange(year, 2007, 2015)
keep if inlist(substr(stkcd,1,1),"0","6")
drop if substr(stkcd,1,3) == "002"
drop if missing(indcd)
drop _m*

egen idind = group(indcd)
rename ChinaNewsBasedEPU policy_uncertainty
rename ChinaNewsBasedEPU_w policy_uncertainty_w
local winsorvar policy_uncertainty policy_uncertainty_w lnasset tobinq rdspendsumratio lev SA 

egen idquarter = group(year quarter)
egen id = group(stkcd)
tsset id idquarter

eststo clear
local CV lnasset tobinq  lev SA

eststo: reghdfe detail_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe detail_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe authority_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe authority_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe completeness_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe completeness_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

tempvar median mean
egen `median' = median(policy_uncertainty)
egen `mean' = mean(policy_uncertainty)
tempvar group_policy_uncertainty group_policy_uncertainty_mean
gen `group_policy_uncertainty' = cond(policy_uncertainty > `median', 1, 0)
gen `group_policy_uncertainty_mean' = cond(policy_uncertainty > `mean', 1, 0)
* detail显著
ttest detail_score, by(`group_policy_uncertainty') 
ttest detail_score, by(`group_policy_uncertainty_mean')
ttest authority_score, by(`group_policy_uncertainty')
ttest authority_score, by(`group_policy_uncertainty_mean') 
ttest completeness_score, by(`group_policy_uncertainty')
ttest completeness_score, by(`group_policy_uncertainty_mean')

recode authority_score (0=0)(else = 1), gen(authority_score_dum)
recode detail_score (0=0)(else = 1), gen(detail_score_dum)
recode completeness_score (0=0)(else = 1), gen(completeness_score_dum)

reg authority_score_dum policy_uncertainty if !missing(authority_score)
reg detail_score_dum policy_uncertainty if !missing(detail_score)
reg completeness_score_dum policy_uncertainty if !missing(completeness_score_dum)

logit authority_score_dum policy_uncertainty if !missing(authority_score)
