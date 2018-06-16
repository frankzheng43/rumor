import delimited F:\rumor\statadata\std.txt, encoding(UTF-8) varnames(1) stringcols(1) clear
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
str_to_numeric trddt
tempfile std
save `std'

use F:\rumor\statadata\01_rumor.dta, clear
keep stkcd Evntdate Evntdate_workday Evtday nature
rename Evtday trddt
duplicates list stkcd trddt
recast str6 stkcd
tempfile rumor
save `rumor'

use `std', clear
merge 1:1 stkcd trddt using `rumor',gen(_mrumor)

gen year = year(trddt)
keep if inrange(year,  2007, 2015)
gen NO = cond(_mrumor == 1, 0, 1)
xtset id iddate

reghdfe l1.NO stds31 if inrange(year,2007,2015), absorb(id year) cluster(id)
reghdfe NO stds31 stds51 stds101 stds301 stds1001 lnasset lev tobinq age SA if inrange(year,2007,2015), absorb(id year) cluster(id)

import delimited F:\rumor\statadata\std_hs.txt, encoding(UTF-8) varnames(1) stringcols(1) clear
format trddt %td

