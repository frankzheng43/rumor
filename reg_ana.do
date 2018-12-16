/* 分析师预测偏离 回归 */
// setups
clear all
set more off
eststo clear
capture version 14
local location "F:/rumor"
cd "`location'"
capt log close _all
log using logs/ana_reg, name("ana_reg") text replace

use statadata/formerge_y.dta, clear
egen idind = group(indcd)
local keyvalue stkcd year 
merge 1:1 `keyvalue' using statadata/ana_forecast_formerge.dta, gen(_mana)
merge 1:1 `keyvalue' using statadata/01_rumor_yf.dta, gen(_mrumor)
merge 1:1 `keyvalue' using statadata/02_firm_ROA.dta, gen(_mroa)
merge 1:1 `keyvalue' using statadata/05_cv_y.dta, gen(_mcv)
merge 1:1 `keyvalue' using statadata/kz_index.dta, gen(_mkz)
sort stkcd year 
drop _m* id accper
rename NO rumor

replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)
order rumor_dum, after(rumor)

local winsorvar ROA_sd lnasset tobinq rdspendsumratio lev SA dispersion_a
winsor2 `winsorvar', replace cuts(5 95) 
label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq "TobinQ"
egen id = group(stkcd)
tsset id year

eststo clear
local CV lnasset tobinq rdspendsumratio lev SA
eststo: reghdfe l1.rumor dispersion_a `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: reghdfe l1.rumor dispersion_a `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.rumor dispersion_a `CV' if inrange(year,2007,2015), absorb(year) cluster(id)

eststo: logit l1.rumor_dum dispersion_a `CV' if inrange(year,2007,2015), cluster(id)
eststo: tobit l1.rumor_dum dispersion_a if inrange(year,2007,2015), ll(0)
*eststo: mlogit rumor_dum dispersion_a `CV' if inrange(year,2007,2015), cluster(id)
*factor variables and time-series operators not allowed
eststo: probit l1.rumor_dum dispersion_a `CV' if inrange(year,2007,2015), cluster(id)

esttab using results/ana_y.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
save statadata/03_firm_ana_reg.dta, replace