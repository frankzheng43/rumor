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
duplicates drop stkcd trddt, force
recast str6 stkcd
tempfile rumor
save `rumor'

use `std', clear
gen year = year(trddt)
merge 1:1 stkcd trddt using `rumor',gen(_mrumor)
merge m:1 stkcd year using statadata/05_cv_y.dta, gen(_mcv)
merge m:1 stkcd year using statadata/kz_index.dta, gen(_mkz)

replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)
order rumor_dum, after(rumor)

local winsorvar lnasset tobinq rdspendsumratio lev SA 
winsor2 `winsorvar', replace cuts(5 95)

gen rumor = cond(_mrumor == 1, 0, 1)
egen idind = group(indcd)
drop if inlist(substr(stkcd,1,1),"2","3","9")

label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq "TobinQ"

keep if inrange(year, 2007, 2015)

xtset id iddate

eststo clear
local CV lnasset tobinq rdspendsumratio lev SA
eststo: reghdfe l1.rumor stds31 `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: reghdfe l1.rumor stds31 `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.rumor stds31 `CV' if inrange(year,2007,2015), absorb(year) cluster(id)

eststo: logit l1.rumor_dum stds31 `CV' if inrange(year,2007,2015), cluster(id)
eststo: tobit l1.rumor_dum stds31 `CV' if inrange(year,2007,2015), ll(0)
eststo: probit l1.rumor_dum stds31 `CV' if inrange(year,2007,2015), cluster(id)


eststo: reghdfe l1.rumor stds31 stds51 stds101 stds301 stds1001 `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: tobit l1.rumor_dum stds31 stds51 stds101 stds301 stds1001 `CV' if inrange(year,2007,2015), ll(0)

import delimited F:\rumor\statadata\std_hs.txt, encoding(UTF-8) varnames(1) stringcols(1) clear
format trddt %td

