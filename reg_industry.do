/* 行业层面回归 */

// setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/ind_reg, name("ind_reg") text replace

*行业年
use statadata/05_cv_y.dta, clear
qui ds stkcd indcd year id, not
collapse (mean) `r(varlist)', by(indcd year)
drop if missing(indcd)
tempfile cv_yi
save `cv_yi'

use statadata/formerge_y.dta, clear
local keyvalue indcd year 
merge m:1 `keyvalue' using statadata/01_rumor_yi.dta, gen(_mrumor)
merge m:1 `keyvalue' using statadata/02_industry_ROA.dta, gen(_mroa)
merge m:1 `keyvalue' using `cv_yi', gen(_mcv)
drop _m* stkcd 
duplicates drop indcd year, force

rename rumor rumor_ind
replace rumor_ind = 0 if missing(rumor_ind)
recode rumor_ind (0 = 0) (else = 1), gen(rumor_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgrumor_ind = log(rumor_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)

local winsorvar lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', replace cuts(5 95) 
label var rumor_ind "Rumor"
label var lgrumor_ind "lgRumor"
label var rumor_ind_dum "Rumor_dum"
label var tobinq "TobinQ"

egen idind = group(indcd)
tsset idind year
*/全部负向显著。。
local CV lnasset tobinq rdspendsumratio lev SA
eststo clear
eststo: reghdfe l1.rumor_ind ROA_ind_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(idind)
eststo: logit l1.rumor_ind_dum ROA_ind_sd `CV' if inrange(year,2007,2015), cluster(idind)
*esttab
*eststo clear
eststo: reghdfe l1.rumor_ind lgROA_ind_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(idind)
eststo: reghdfe l1.lgrumor_ind lgROA_ind_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(idind)

esttab using results/firm_yi.rtf, label replace
save "statadata/03_industry_ROA_reg.dta", replace
// TODO here
//TO HERE
*行业月
use "statadata/formerge_im.dta", clear
merge m:1 indcd year using statadata/02_industry_ROA.dta, gen(_mroa)
merge 1:1 indcd year month using "statadata/01_rumor_mi.dta", gen(_mrumor)
drop _m* 

rename rumor rumor_ind
replace rumor_ind = 0 if missing(rumor_ind)
recode rumor_ind (0 = 0) (else = 1), gen(rumor_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgrumor_ind = log(rumor_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)

*/全部负向显著。。
reg lgrumor_ind lgROA_ind_sd if year > 2006 & year < 2016
reg rumor_ind ROA_ind_sd if year > 2006 & year < 2016
reg rumor_ind ROA_ind_sd_wins if year > 2006 & year < 2016
logit rumor_ind_dum ROA_ind_sd if year > 2006 & year < 2016
save "statadata/03_industry_ROA_m_reg.dta", replace

*行业季度
//控制变量的tempfile
use statadata/05_cv_q.dta, clear
drop _m*
qui ds stkcd indcd year quarter accper, not
collapse (mean) `r(varlist)', by(indcd year quarter)
drop if missing(indcd)
tempfile cv_qi
save `cv_qi'

use "statadata/formerge_iq.dta", clear
merge m:1 indcd year using "statadata/02_industry_ROA.dta", gen(_mroa)
merge 1:1 indcd year quarter using "statadata/01_rumor_qi.dta", gen(_mrumor)
merge m:1 indcd year quarter using `cv_qi', gen(_mcv)

drop if missing(indcd)
drop _m* stkcd

rename rumor rumor_ind
replace rumor_ind = 0 if missing(rumor_ind)
recode rumor_ind (0 = 0) (else = 1), gen(rumor_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgrumor_ind = log(rumor_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)

local winsorvar lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', replace cuts(5 95) 
label var rumor_ind "Rumor"
label var lgrumor_ind "lgRumor"
label var rumor_ind_dum "Rumor_dum"
label var tobinq "TobinQ"

egen idind = group(indcd)
egen idquarter = group(year quarter)
tsset idind idquarter

*/全部负向显著。。
local CV lnasset tobinq rdspendsumratio lev SA
eststo clear
eststo: reghdfe l1.rumor_ind ROA_ind_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(idind)
eststo: logit l1.rumor_ind_dum ROA_ind_sd `CV' if inrange(year,2007,2015), cluster(idind)
esttab
*eststo clear
eststo: reghdfe l1.rumor_ind lgROA_ind_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(idind)
eststo: reghdfe l1.lgrumor_ind lgROA_ind_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(idind)
esttab
esttab using results/firm_qi.rtf, label replace
save "statadata/03_industry_ROA_q_reg.dta", replace
