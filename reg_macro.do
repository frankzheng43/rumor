/* 宏观层面回归： RUMOR=UNCERTAINTY+CV */
/* t = month
   t = quarter
   t = month, i = firm
   t = quarter, i = firm  */

// setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/macro_reg, name("macro_reg") text replace

/* 按月回归 */
/* 02_macro 政治不确定性 */
use statadata/02_macro.dta, clear 
/* 01_rumor 传闻*/
merge 1:1 year month using statadata/01_rumor_m.dta
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty
drop if missing(rumor)
drop _m*
winsor2 policy_uncertainty rumor, suffix(_wins) cuts(5 95)
gen lgpolicy_uncertainty_wins = log(policy_uncertainty_wins)
gen lgrumor=log(rumor_wins)
/* 所有区间内均存在rumor所以rumor_dum构造的意义不存在 */

label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"

egen idmonth = group(year month)
tsset idmonth

eststo clear
forvalues i = 1/8{
  eststo: reg l`i'.lgrumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016
}
esttab using results/macro_m.rtf, label replace
 
//esttab using results/macro_m.xls, label replace
save statadata/03_macro_reg.dta, replace

/* t檢驗 */
tempvar median mean
egen `median' = median(lgpolicy_uncertainty_wins)
egen `mean' = mean(lgpolicy_uncertainty_wins)
tempvar group_uncertainty group_uncertainty_mean
gen `group_uncertainty' = cond(lgpolicy_uncertainty_wins > `median', 1, 0)
gen `group_uncertainty_mean' = cond(lgpolicy_uncertainty_wins > `mean', 1, 0)
ttest rumor, by(`group_uncertainty')
ttest rumor, by(`group_uncertainty_mean')


/* 按季度回歸 */
use "statadata/02_macro_q.dta", clear
merge 1:1 year quarter using statadata/01_rumor_q.dta
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty

winsor2 policy_uncertainty rumor, suffix(_wins) cuts(5 95)
gen lgpolicy_uncertainty_wins = log(policy_uncertainty_wins)
gen lgrumor=log(rumor_wins)
drop if missing(rumor)
drop _m*

label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"

egen idquarter = group(year quarter)
tsset idquarter
*并不显著，为负
eststo clear
forvalues i = 1/4{
  eststo: reg l`i'.lgrumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016
  eststo: reg l`i'.rumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016
  eststo: tobit l`i'.rumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016, ll(0)

}
esttab using results/macro_q.rtf, label replace
//esttab using results/macro_q.xls, label replace
save statadata/03_macro_q_reg.dta, replace

/* 按公司-月回归 */
use statadata/formerge_m.dta, clear
merge m:1 year month using statadata/02_macro.dta, gen(_mmacro)
keep if _mmacro == 3


local keyvalue stkcd year month
merge m:1  `keyvalue' using statadata/01_rumor_mf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata/05_cv_m.dta, gen(_mcv)
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty
drop _m*
//replace vio_count = 0 if missing(vio_count)
replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)


local winsorvar policy_uncertainty lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', suffix(_wins) cuts(5 95)

gen lgpolicy_uncertainty_wins = log(policy_uncertainty_wins)

label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq_wins "TobinQ"

egen idmonth = group(year month)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idmonth

eststo clear
local CV_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins SA 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, absorb(id year) cluster(id)
eststo: probit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
*0 和 3 之间的差距显著为负
eststo: mlogit rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)

eststo: logit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: probit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: tobit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id) ll(0)
eststo: tobit l1.rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id) ll(0)

esttab using results/macro_mf.rtf, label replace
save "statadata/03_macro_reg_mf.dta", replace 

/* 按公司-季度回归 */
/* Gulen H, Ion M，. Policy Uncertainty and Corporate Investment[J]. 
The Review of Financial Studies, 2016, 29(3): 523–564.
季度回归，1-4期滞后
 */
use "statadata/formerge_q.dta", clear
merge m:1 year quarter using "statadata/02_macro_q.dta", gen(_mmacro)
keep if _mmacro == 3
local keyvalue stkcd year quarter
merge m:1  `keyvalue' using statadata/01_rumor_qf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata/05_cv_q.dta, gen(_mcv)
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty
replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)
drop _m*

local winsorvar policy_uncertainty lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', suffix(_wins) cuts(5 95) 
gen lgpolicy_uncertainty_wins = log( policy_uncertainty_wins)
label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq_wins "TobinQ"

*generating composite categorical variables
egen idquarter = group(year quarter)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idquarter
local CV_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins SA

eststo clear
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, absorb(id year) cluster(id)
eststo: probit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: mlogit rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: logit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: probit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: tobit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id) ll(0)
eststo: tobit l1.rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id) ll(0)
esttab using results/macro_qf.rtf, replace
eststo clear
save "statadata/03_macro_reg_qf.dta", replace

log close macro_reg
// eststo: xtreg l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, fe cluster(id)
// eststo: areg l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, absorb(id) cluster(id)
// eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, absorb(id) cluster(id)
// eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins if year > 2006 & year < 2016, absorb(id year) cluster(id)

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


//TODO 
/* Schwert（1989）的文章中使用包含时间固定效应的自回归模型对不同的宏观变量进行建模，并提取出残差项。
将残差项的平方作为该变量的不确定性的度量。一般是使用工业生产指数的增长率的波动率作为宏观经济不确定性的度量。 */
//TODO 
/* 交易量 */
//TODO
/* PSM配对 */