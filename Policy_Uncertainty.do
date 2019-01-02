// TODO 使用其他的policy uncertainty度量
// Gulen, Huseyin, and Mihai Ion, 2016, Policy Uncertainty and Corporate Investment,
// The Review of Financial Studies 29, 523–564.

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:\rumor"
cd "`location'"
capt log close _all
log using logs/policy_uncertainty, name(policy_uncertainty) text replace

// import raw data 
import excel using "raw\China_Policy_Uncertainty_Data.xlsx", firstrow clear
destring year, gen(year1)
drop year
rename year1 year
recode month (1 2 3  = 1) (4 5 6 = 2) (7 8 9 = 3) (10 11 12 = 4), gen(quarter)
*graph bar (mean) policy_uncertainty , over(year)
save "statadata\02_macro.dta", replace

// collapse into quarterly data 
use "statadata\02_macro.dta", clear
collapse (mean) ChinaNewsBasedEPU, by(year quarter)
save "statadata\02_macro_q.dta", replace

* 按照不同的权重加权
gen div = 6
egen seq = fill(1/3 1/3)
gen weight = seq/div
drop seq div

collapse (mean) ChinaNewsBasedEPU [iweight = weight], by(year quarter)
rename ChinaNewsBasedEPU ChinaNewsBasedEPU_w
merge 1:1 year quarter using F:\rumor\statadata\02_macro_q.dta
drop _m*
save "statadata\02_macro_q_w.dta", replace


egen idquarter = group(year quarter)
tsset idquarter
twoway line ChinaNewsBasedEPU ChinaNewsBasedEPU_w idquarter

log close 

