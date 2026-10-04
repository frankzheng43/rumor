* 把所有的有用的回归都放在这里
set more off
local location F:/rumor
cd "`location'"

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor policy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
esttab using results/macro_宏观季度年份固定.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id) 
eststo: reghdfe l1.rumor policy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id)
esttab using results/macro_宏观季度无年份固定1.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)


*表5-4 宏观不确定性
local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
esttab using results/macro_宏观季度年份固定对数1.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id) 
eststo: reghdfe l2.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id) 
eststo: reghdfe l2.rumor lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind ) cluster(id)
esttab using results/macro_宏观季度无年份固定对数.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
save "F:\rumor\statadata\reg_for_macro_new.dta", replace

use "F:\rumor\statadata\reg_for_macro_new.dta", clear
merge m:1 stkcd year using F:\rumor\statadata\DA_d.dta
tempvar median mean
bysort year: egen `median' = median(abs_DA_Winsor)
bysort year: egen `mean' = mean(abs_DA_Winsor)
tempvar group_abs_DA_Winsor group_abs_DA_Winsor_mean
gen group_abs_DA_Winsor = cond(abs_DA_Winsor > `median', 1, 0)
gen group_abs_DA_Winsor_mean = cond(abs_DA_Winsor > `mean', 1, 0)
replace group_abs_DA_Winsor = . if missing(abs_DA_Winsor)
replace group_abs_DA_Winsor_mean = . if missing(abs_DA_Winsor)

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
sort id idquarter


eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor == 1, absorb(idind year) cluster(id) 

eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor_mean == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor_mean == 1, absorb(idind year) cluster(id) 

esttab using results/按DA分组对数.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
save "F:\rumor\statadata\reg_for_DA.dta"

use "F:\rumor\statadata\reg_for_macro_new.dta", clear
merge m:1 stkcd year using F:\rumor\statadata\ana_follow.dta

tempvar median mean
bysort year: egen `median' = median(analyst_follow)
bysort year: egen `mean' = mean(analyst_follow)
tempvar group_analyst_follow group_analyst_follow_mean
gen group_analyst_follow = cond(analyst_follow > `median', 1, 0)
gen group_analyst_follow_mean = cond(analyst_follow > `mean', 1, 0)
replace group_analyst_follow = . if missing(analyst_follow)
replace group_analyst_follow_mean = . if missing(analyst_follow)

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
sort id idquarter

eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow == 1, absorb(idind year) cluster(id) 

eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow_mean == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow_mean == 1, absorb(idind year) cluster(id) 

esttab using results/按分析报告均值分组对数.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)

tempvar median mean
bysort year: egen `mean' = mean(numanalyst)
bysort year: egen `median' = median(numanalyst)
tempvar group_numanalyst group_numanalyst_mean
gen group_numanalyst = cond(numanalyst > `median', 1, 0)
gen group_numanalyst_mean = cond(numanalyst > `mean', 1, 0)
replace group_numanalyst = . if missing(numanalyst)
replace group_numanalyst_mean = . if missing(numanalyst)

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
sort id idquarter

eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst == 1, absorb(idind year) cluster(id) 

eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst_mean == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst_mean == 1, absorb(idind year) cluster(id) 

esttab using results/按分析师分组.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
save "F:\rumor\statadata\reg_for_ana.dta", replace

use "F:\rumor\statadata\reg_for_macro_new.dta", clear
merge m:1 stkcd year using F:\rumor\statadata\seperation.dta

tempvar median mean
bysort year: egen `median' = median(seperation)
bysort year: egen `mean' = mean(seperation)
tempvar group_seperation group_seperation_mean
gen group_seperation = cond(seperation > `median', 1, 0)
gen group_seperation_mean = cond(seperation > `mean', 1, 0)
replace group_seperation = . if missing(seperation)
replace group_seperation_mean = . if missing(seperation)

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
sort id idquarter

*表5-9
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation == 1, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_mean == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_mean == 1, absorb(idind year) cluster(id) 
esttab using results/按两权分离度分组对数.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
save "F:\rumor\statadata\reg_for_sep.dta", replace

use "F:\rumor\statadata\reg_for_macro_new.dta", clear
merge 1:1 stkcd year quarter using F:\rumor\statadata\score_q.dta

eststo clear
sort id idquarter
local CV lnasset_wins tobinq_wins lev_wins SA_wins

eststo: reghdfe l1.detail_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.detail_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe l1.authority_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.authority_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe l1.completeness_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.completeness_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

esttab using results/可信度与宏观不确定性.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)

*表5-8
eststo clear
sort id idquarter
local CV lnasset_wins tobinq_wins lev_wins SA_wins

eststo: reghdfe l1.detail_score lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
*eststo: reghdfe l1.detail_score lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe l1.authority_score lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
*eststo: reghdfe l1.authority_score policy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe l1.completeness_score lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
*eststo: reghdfe l1.completeness_score lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

esttab using results/可信度与宏观不确定性对数.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
save "F:\rumor\statadata\reg_for_score.dta", replace
