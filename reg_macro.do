/* 宏观层面回归： RUMOR=UNCERTAINTY+CV */

// setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/macro_reg, name("macro_reg") text replace

// reg by month
*  can't add CVs
/* 02_macro 政治不确定性 */
use statadata/02_macro.dta, clear 
/* 01_rumor 传闻*/
merge 1:1 year month using statadata/01_rumor_m.dta

winsor ChinaNewsBasedEPU, gen(ChinaNewsBasedEPU_wins) p(0.05)
gen lgChinaNewsBasedEPU_wins = log( ChinaNewsBasedEPU_wins)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
label var NO "Rumor"
label var NO_dum "Rumor_dum"
drop if missing(NO)
recode NO (0 = 0) (else = 1), gen(NO_dum)
egen idmonth = group(year month)
tsset idmonth

/* 按月回歸 */
eststo clear
forvalues i = 1/4{
  eststo: reg l`i'.NO lgChinaNewsBasedEPU_wins if year > 2006 & year < 2016
}
esttab using results/macro_m.rtf, label replace
//esttab using results/macro_m.xls, label replace
save statadata/03_macro_reg.dta, replace

/* t檢驗 */
egen median = median(lgChinaNewsBasedEPU_wins)
gen group_uncertainty = cond(lgChinaNewsBasedEPU_wins > median, 1, 0)
ttest NO, by(group_uncertainty)
egen mean = mean(lgChinaNewsBasedEPU_wins)
gen group_uncertainty_mean = cond(lgChinaNewsBasedEPU_wins > mean, 1, 0)
ttest NO, by(group_uncertainty_mean)
/* NO有显著的极端值 */
gen lgNO=log(NO)
scatter lgNO lgChinaNewsBasedEPU_wins if lgNO > 3

/* 按季度回歸 */
use "statadata/02_macro_q.dta", clear
merge 1:1 year quarter using statadata/01_rumor_q.dta
winsor ChinaNewsBasedEPU, gen(ChinaNewsBasedEPU_wins) p(0.05)
gen lgChinaNewsBasedEPU_wins = log(ChinaNewsBasedEPU_wins)
drop if missing(NO)
recode NO (0 = 0) (else = 1), gen(NO_dum)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
label var NO "Rumor"
label var NO_dum "Rumor_dum"
egen idquarter = group(year quarter)
tsset idquarter
*并不显著，为负
eststo clear
forvalues i = 1/4{
  eststo: reg l`i'.NO lgChinaNewsBasedEPU_wins if year > 2006 & year < 2016
}
esttab using results/macro_q.rtf, label replace
//esttab using results/macro_q.xls, label replace
save statadata/03_macro_q_reg.dta, replace

gen lgNO=log(NO)
scatter lgNO lgChinaNewsBasedEPU_wins if lgNO > 3

// reg by firm-month
use statadata/formerge_m.dta, clear
merge m:1 year month using statadata/02_macro.dta, gen(_mmacro)
keep if _mmacro == 3
local keyvalue stkcd year month
merge m:1  `keyvalue' using statadata/01_rumor_mf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata/05_cv_m.dta, gen(_mcv)
//replace vio_count = 0 if missing(vio_count)
replace NO = 0 if missing(NO)
recode NO (0 = 0) (else = 1), gen(NO_dum)
drop _m*

local winsorvar ChinaNewsBasedEPU lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', suffix(_wins) cuts(5 95) 
gen lgChinaNewsBasedEPU_wins = log(ChinaNewsBasedEPU_wins)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
label var NO "Rumor"
label var NO_dum "Rumor_dum"
label var tobinq_wins "TobinQ"

egen idmonth = group(year month)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idmonth

eststo clear
local CV_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins SA 
eststo: reghdfe l1.NO lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, absorb(id year) cluster(id)
eststo: logit l1.NO_dum lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
esttab using results/macro_mf.rtf, label replace
save "statadata/03_macro_reg_mf.dta", replace 

// TODO firm-month and firm-quarter can be combined together
/* 按季度-公司回归 */
use "statadata/formerge_q.dta", clear
merge m:1 year quarter using "statadata/02_macro_q.dta", gen(_mmacro)
keep if _mmacro == 3
local keyvalue stkcd year quarter
merge m:1  `keyvalue' using statadata/01_rumor_qf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata/05_cv_q.dta, gen(_mcv)
replace NO = 0 if missing(NO)
recode NO (0 = 0) (else = 1), gen(NO_dum)
drop _m*

local winsorvar ChinaNewsBasedEPU lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', suffix(_wins) cuts(5 95) 
gen lgChinaNewsBasedEPU_wins = log( ChinaNewsBasedEPU_wins)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
label var NO "Rumor"
label var NO_dum "Rumor_dum"
label var tobinq_wins "TobinQ"

*generating composite categorical variables
egen idquarter = group(year quarter)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idquarter
local CV_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins SA
eststo clear
eststo: reghdfe l1.NO lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, absorb(id year) cluster(id)
eststo: logit l1.NO_dum lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
// eststo: mlogit l1.NO_dum lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
esttab using results/macro_qf.rtf, replace
eststo clear
save "statadata/03_macro_reg_qf.dta", replace

log close macro_reg
// eststo: xtreg l1.NO lgChinaNewsBasedEPU_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, fe cluster(id)
// eststo: areg l1.NO lgChinaNewsBasedEPU_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, absorb(id) cluster(id)
// eststo: reghdfe l1.NO lgChinaNewsBasedEPU_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, absorb(id) cluster(id)
// eststo: reghdfe l1.NO lgChinaNewsBasedEPU_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins if year > 2006 & year < 2016, absorb(id year) cluster(id)

/** 
 * These three cmdlines are almost the same: xtreg areg reghdfe
 * xtset panalvar timevar
 * xtreg y x CV i.timevar, fe cluster(panelvar)
 * areg y x CV i.timevar, absorb(panelvar) cluster(panelvar)
 * reghdfe y x CV i.timevar, absorb(panelvar) cluster(panelvar)
 * or reghdfe y x CV , absorb(panelvar timevar) cluster(panelvar)
 * Within Stata, reghdfe can be viewed as a generalization of areg/xtreg, 
 * with several additional features:
 */
