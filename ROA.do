/**
 * This code is used to generate firm-level ROA volatility
 * Author: Frank Zheng
 * Required data: 02_firm 
 * Required code: Fin_Index
 * Required ssc : rangestat
 */

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:\rumor"
cd "`location'"
capt log close _all
log using logs/ROA, name("ROA") text replace


use statadata\02_firm.dta, clear
keep stkcd accper year indcd f050201b
keep if month(accper) == 12
egen id = group(stkcd)
rename f050201b ROA
rangestat (sd) ROA, interval(year -3 -1) by(id)
order id accper year, after(stkcd)
order ROA_sd, after(ROA)
sort stkcd accper
save "statadata\02_firm_ROA.dta", replace

log close ROA
