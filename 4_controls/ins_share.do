* 机构投资者持股
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/ins_share, name("ins_share") text replace

import delimited raw/INI_HolderSystematics.txt, encoding(UTF-8) varnames(1) stringcols(_all) clear

rename symbol stkcd

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
str_to_numeric enddate

keep if month(enddate) == 12
drop if inlist(substr(stkcd,1,1),"2","3","9")

quietly ds stkcd enddate, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		order `x'1, after(`x')
		drop `x'
		rename `x'1 `x'
		}
	}

quietly ds stkcd enddate, not
foreach x of var `r(varlist)'{
    replace `x' = 0 if missing(`x')
}
gen year = year(enddate)
drop if missing(year)
order year, after(stkcd)

gen ins_share = fundholdproportion + qfiiholdproportion + brokerholdproportion + insuranceholdproportion + securityfundholdproportion + entrustholdproportion + financeholdproportio + bankholdproportion + nonfinanceholdproportion
keep stkcd year ins_share
winsor2 ins_share, suffix(_wins) cuts(1 99)
winsor2 ins_share, suffix(_wins1) cuts(5 95)

save "F:\rumor\statadata\ins_share.dta", replace

