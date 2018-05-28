/**
 * This code is used to import and clean financial index data
 * Author: Frank Zheng
 * Required data: -
 * Required code: -
 * Required ssc : -
 */

// install missing ssc
 local sscname estout  
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
local location "F:/rumor"
cd "`location'"
capt log close _all
log using logs/financial_index, name("financial_index") text replace

import delimited raw/FI_T5.txt, varnames(1) clear ///比率数据

drop in 1/2
drop if typrep == "B"
drop typrep

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

str_to_numeric accper
gen year = year(accper)
order year, after(accper)

/**convert string to numeric, source: https://www.stata.com/statalist/archive/2004-05/msg00297.html*/
ds stkcd accper typrep indcd, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		order `x'1, after(`x')
		drop `x'
		rename `x'1 `x'
		}
	}

save statadata/02_firm.dta, replace 
log close
