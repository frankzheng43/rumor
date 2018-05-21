/**
 * This code if used to import and clean financial statement data
 * Author : Frank Zheng
 * Required data: 02_firm_asset.dta 02_firm_RD.dta 02_firm_TB.dta 02_firm_violation_main formerge_m.dta
 * Required code: too many
 * Required ssc : -
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
log using Fin_Sheet, name("Fin_Sheet") text replace

import delimited raw/FS_Combas.txt, encoding(UTF-8) varnames(1) clear

// https://www.stata.com/statalist/archive/2011-09/msg01109.html
// label variables with the first row
foreach var of varlist * {
  label variable `var' "`=`var'[1]'"
}
drop in 1/2
drop if typrep == "B"
drop if inlist(substr(stkcd,1,1),"2","3","9")

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
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

label data "资产负债表"
save "statadata/02_firm_FS.dta", replace

log close Fin_Sheet
