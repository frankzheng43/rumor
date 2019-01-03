* 直接法现金流量表 
/*
 * 现金流量表
 */

// setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/Cash_Flow, name("Cash_Flow") text replace

import delimited raw/FS_Comscfd.txt, encoding(UTF-8) varnames(1) clear

foreach var of varlist * {
  label variable `var' "`=`var'[1]'"
}
drop in 1/2

drop if typrep == "B"
drop if inlist(substr(stkcd,1,1),"2","3","9")

capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
local lab: variable label `1'
label var `1'1 `lab'
drop `1' 
rename `1'1 `1' 
end
str_to_numeric accper

keep if month(accper) == 12

quietly ds stkcd accper typrep, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		order `x'1, after(`x')
		drop `x'
		rename `x'1 `x'
		}
	}

label data "现金流量表（直接法）"
save statadata/02_firm_CF_d.dta, replace
log close Cash_Flow