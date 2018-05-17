/**
 * This code is used to import and clean daily trading data
 * Author: Frank Zheng
 * Required data: TRD_Dalyr.txt
 * Required code: -
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
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/trade, name("trade") text replace

import delimited raw/TRD_Dalyr.txt, varnames(1) clear
drop in 1/2

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date(`1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
local datevar trddt capchgdt
foreach x of local datevar{
	str_to_numeric `x'
}

quietly ds stkcd trddt capchgdt, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		drop `x'
		rename `x'1 `x'
		}
	}

keep if markettype == 1 | markettype ==4
keep if year > 2000 & year < 2018
gen year = year(trddt)

save statadata/02_trddta.dta, replace

log close trade