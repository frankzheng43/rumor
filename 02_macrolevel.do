/**
 * This code is used to regress macro-level regressions
 * Author: Frank Zheng
 * Required data: 02_macro.dta 02_macro_q.dta 01_rumor_m 01_rumor_q 05_cv_m 05_cv_q
 * Required code: policy uncertainty.do
 * Required ssc : winsor setout
 */

 // install missing ssc
 local sscname estout winsor2 
 foreach pkg of local sscname{
  cap which  `pkg'
  if _rc!=0{
        ssc install `pkg'
        }
 }

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:\rumor"
cd "`location'"
capt log close _all
log using logs\macro_reg, name("macro_reg") text replace

// reg by month
*  can't add CVs
use "statadata\02_macro.dta", clear
merge 1:1 year month using "statadata\01_rumor_m.dta"
winsor ChinaNewsBasedEPU, gen(ChinaNewsBasedEPU_wins) p(0.05)
gen lgChinaNewsBasedEPU_wins = log( ChinaNewsBasedEPU_wins)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
drop if missing(NO)
recode NO (1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
egen idmonth = group(year month)
tsset idmonth
*均不显著
eststo clear
local yvar NO NO_dum
forvalues i = 1/4{
  foreach x of local yvar{
    eststo: quietly reg l`i'.`x' lgChinaNewsBasedEPU_wins if year > 2006 & year < 2016
  }
}
esttab using results\macro_m.rtf, label replace
esttab using results\macro_m.xls, label replace
save statadata\03_macro_reg.dta, replace

// reg by quarter
*  can't add CVs
use "statadata\02_macro_q.dta", clear
merge 1:1 year quarter using "statadata\01_rumor_q.dta"
winsor ChinaNewsBasedEPU, gen(ChinaNewsBasedEPU_wins) p(0.05)
gen lgChinaNewsBasedEPU_wins = log(ChinaNewsBasedEPU_wins)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
drop if missing(NO)
recode NO ( 1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
egen idquarter = group(year quarter)
tsset idquarter
*并不显著，为负
eststo clear
local yvar NO NO_dum
forvalues i = 1/4{
  foreach x of local yvar{
    eststo: quietly reg l`i'.`x' lgChinaNewsBasedEPU_wins  i.quarter if year > 2006 & year < 2016
  }
}
esttab using results\macro_q.rtf, label replace
esttab using results\macro_q.xls, label replace
save statadata\03_macro_q_reg.dta, replace

// reg by firm-month
use statadata\formerge_m.dta, clear
merge m:1 year month using statadata\02_macro.dta, gen(_mmacro)
keep if _mmacro == 3
local keyvalue stkcd year month
merge m:1  `keyvalue' using statadata\01_rumor_mf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata\05_cv_m.dta, gen(_mcv)
replace vio_count = 0 if missing(vio_count)
replace NO = 0 if missing(NO)
recode NO ( 1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
drop _m*
local winsorvar ChinaNewsBasedEPU lnasset tobinq rdspendsumratio lev vio_count
winsor2 `winsorvar', suffix(_wins) cuts(5 95) label
gen lgChinaNewsBasedEPU_wins = log(ChinaNewsBasedEPU_wins)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
egen idmonth = group(year month)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idmonth
local CV_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins 
eststo clear
eststo: reghdfe l1.NO lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, absorb(id year) cluster(id)
eststo: logit l1.NO_dum lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
esttab using results\macro_mf.rtf, replace
save "statadata\03_macro_reg_mf.dta", replace 

// TODO firm-month and firm-quarter can be combined together
// reg by firm-quarter
use "statadata\formerge_q.dta", clear
merge m:1 year quarter using "statadata\02_macro_q.dta", gen(_mmacro)
keep if _mmacro == 3
local keyvalue stkcd year quarter
merge m:1  `keyvalue' using statadata\01_rumor_qf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata\05_cv_q.dta, gen(_mcv)
replace NO = 0 if missing(NO)
recode NO ( 1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
drop _m*
local winsorvar ChinaNewsBasedEPU lnasset tobinq rdspendsumratio lev vio_count
winsor2 `winsorvar', suffix(_wins) cuts(5 95) label
gen lgChinaNewsBasedEPU_wins = log( ChinaNewsBasedEPU_wins)
label var lgChinaNewsBasedEPU_wins "Policy Uncertainty"
*generating composite categorical variables
egen idquarter = group(year quarter)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idquarter
local CV_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins 
eststo clear
eststo: reghdfe l1.NO lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, absorb(id year) cluster(id)
eststo: logit l1.NO_dum lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
// eststo: mlogit l1.NO_dum lgChinaNewsBasedEPU_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
esttab using results\macro_qf.rtf, replace
eststo clear
save "statadata\03_macro_reg_qf.dta", replace

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

