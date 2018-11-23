/* 交易数据 */
// setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/trade, name("trade") text replace

import delimited raw/TRD_Dalyr.txt, varnames(1) clear

// https://www.stata.com/statalist/archive/2011-09/msg01109.html
// label variables with the first row
//foreach var of varlist * {
  //label variable `var' "`=`var'[1]'"
//}
drop in 1/2

/** This program is used to convert string date to numeric date*/
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

local datevar trddt capchgdt
foreach x of local datevar{
	str_to_numeric `x'
}
gen year = year(trddt)

quietly ds stkcd trddt capchgdt, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		drop `x'
		rename `x'1 `x'
		}
	}
	
drop if inlist(substr(stkcd,1,1),"2","3","9")
keep if markettype == 1 | markettype == 4
keep if year > 2000 & year < 2018

label data "日交易数据"

save statadata/02_trddta.dta, replace

log close trade
