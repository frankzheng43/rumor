* 新的两权分离度

clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/seperation, name("seperation") text replace

import delimited raw/EN_EquityNatureAll.txt, encoding(UTF-8) varnames(1) stringcols(_all) clear

rename symbol stkcd

quietly ds, has(type string)
foreach x of var `r(varlist)'{
	gen `x'1 = strltrim(`x')
	order `x'1, after(`x')
	drop `x'
	rename `x'1 `x'
}

format stkcd %6s

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

gen year = year(enddate)
drop if missing(year)
drop if inlist(substr(stkcd,1,1),"2","3","9")
keep stkcd year seperation

quietly ds seperation
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		order `x'1, after(`x')
		drop `x'
		rename `x'1 `x'
		}
	}

order stkcd year seperation
sort stkcd year

*两权分离度小于0，不科学。而且数字极小，直接当作0
replace seperation = 0 if seperation <0
winsor2 seperation, suffix(_wins) cuts(5 95)
