/* RD数据 */

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:\rumor"
cd "`location'"
capt log close _all
log using logs\rd, name("rd") text replace

// 研发投入的数据
import delimited F:\rumor\raw\PT_LCRDSpending.txt, varnames(1) encoding(UTF-8) clear
drop in 1/2
rename symbol stkcd

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
str_to_numeric enddate

keep if month(enddate) == 12
drop if statetypecode == "2"
drop statetypecode

quietly ds stkcd enddate currency explanation, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		drop `x'
		rename `x'1 `x'
		}
	}

save statadata/02_firm_RD.dta, replace

log close rd
