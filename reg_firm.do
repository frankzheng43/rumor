/**
 * This code is used to regress firm-level regressions
 * Author: Frank Zheng
 * Required data: -
 * Required code: -
 * Required ssc : -
 */

 // install missing ssc
 local sscname estout winsor2 
 foreach pkg of local sscname{
  cap which `pkg'
  if _rc!=0{
        ssc install `pkg'
        }
 }
//TODO 将collapse的过程全部当作tempfile过程
// setups
clear all
set more off
eststo clear
capture version 14
local location "F:/rumor"
cd "`location'"
capt log close _all
log using logs/firm_reg, name("firm_reg") text replace

*2.1.1ROA回归（公司年）
use statadata/formerge_y.dta, clear
local keyvalue stkcd year 
merge 1:1 `keyvalue' using statadata/01_rumor_yf.dta, gen(_mrumor)
merge 1:1 `keyvalue' using statadata/02_firm_ROA.dta, gen(_mroa)
merge 1:1 `keyvalue' using statadata/05_cv_y.dta, gen(_mcv)
merge 1:1 `keyvalue' using statadata/kz_index.dta, gen(_mkz)
sort stkcd year 

drop _m* id accper
replace vio_count = 0 if missing(vio_count)
replace NO = 0 if missing(NO)
recode NO (1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
order NO_dum, after(NO)

local winsorvar ROA_sd lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', replace cuts(5 95) label

egen id = group(stkcd)
tsset id year

eststo clear
local CV lnasset tobinq rdspendsumratio lev SA
eststo: reghdfe l1.NO ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: logit l1.NO_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
esttab using results/firm_y.rtf, replace
save statadata/03_firm_ROA_reg.dta, replace

*2.1.2ROA回归（公司月）
use statadata/formerge_m.dta, clear
local keyvalue stkcd year 
merge 1:1 `keyvalue' month using statadata/01_rumor_mf.dta, gen(_mrumor)
merge m:1 `keyvalue' using statadata/02_firm_ROA.dta, gen(_mroa)
merge 1:1 `keyvalue' month using statadata/05_cv_m.dta, gen(_mcv)
merge 1:1 `keyvalue' month using statadata/02_firm_turnover_mf.dta, gen(_mturnover)

drop _m* id accper enddate
rename edca count_turnover
replace count_turnover = 0 if missing(count_turnover)
replace vio_count = 0 if missing(vio_count)
replace NO = 0 if missing(NO)
recode NO (1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
order NO_dum, after(NO)

local winsorvar ROA_sd lnasset tobinq rdspendsumratio lev
winsor2 `winsorvar', replace cuts(5 95) label

egen id = group(stkcd)
egen idmonth = group(year month)
tsset id idmonth

eststo clear
local CV lnasset tobinq rdspendsumratio lev
eststo: reghdfe l1.NO ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: reghdfe l1.NO count_turnover `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: logit l1.NO_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
esttab using results/firm_mf.rtf, replace
save statadata/03_firm_ROA_mf_reg.dta, replace

*2.1.3ROA回归（公司季度）
use statadata/formerge_q.dta, clear
local keyvalue stkcd year
merge 1:1 `keyvalue' quarter using statadata/01_rumor_qf.dta, gen(_mrumor)
merge m:1 `keyvalue' using statadata/02_firm_ROA.dta, gen(_mroa)
merge 1:1 `keyvalue' quarter using statadata/05_cv_q.dta, gen(_mcv)

drop _m* id accper enddate
replace vio_count = 0 if missing(vio_count)
replace NO = 0 if missing(NO)
recode NO (1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
order NO_dum, after(NO)

local winsorvar ROA_sd lnasset tobinq rdspendsumratio lev
winsor2 `winsorvar', replace cuts(5 95) label

egen id = group(stkcd)
egen idquarter = group(year quarter)
egen idind = group(indcd)
tsset id idquarter

eststo clear
local CV lnasset tobinq rdspendsumratio lev
eststo: reghdfe l1.NO ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: logit l1.NO_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
esttab using results/firm_qf.rtf, replace
save statadata/03_firm_ROA_qf_reg.dta, replace

//随意测试
//replace attitute = 0 if missing(attitute)
//replace wording1 = 0 if missing(wording1)
//replace wording2 = 0 if missing(wording2)
//replace wording3 = 0 if missing(wording3)
//大多不显著
local CV lnasset tobinq rdspendsumratio lev
reghdfe l1.attitute ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
reghdfe l1.wording1 ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
reghdfe l1.wording2 ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
reghdfe l1.wording3 ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)

*2.2高管更替回归
use statadata/02_firm_turnover.dta, clear
collapse (count) edca, by(year stkcd month)
save statadata/03_firm_turnover_mf.dta, replace
