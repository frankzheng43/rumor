/**
 * This code is used to perform industry-level regressions
 * Author: Frank Zheng
 * Required data: 02_firm_asset.dta 02_firm_RD.dta 02_firm_TB.dta 02_firm_violation_main formerge_m.dta
 * Required code: too many
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
use statadata/formerge_y.dta, clear
local keyvalue indcd year 
merge m:1 `keyvalue' using statadata/01_rumor_yi.dta, gen(_mrumor)
merge m:1 `keyvalue' using statadata/02_industry_ROA.dta, gen(_mroa)
merge m:1 `keyvalue' using statadata/05_cv_y.dta, gen(_mcv)

rename NO NO_ind
replace NO_ind = 0 if missing(NO_ind)
recode NO_ind ( 1 2 3 4 5 6 7 8 = 1), gen(NO_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgNO_ind = log(NO_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)
*/全部负向显著。。
reg lgNO_ind lgROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd_wins if year > 2006 & year < 2016
logit NO_ind_dum ROA_ind_sd if year > 2006 & year < 2016
save "statadata\03_industry_ROA_reg.dta", replace
// TODO here

*行业月
use "statadata/formerge_im.dta", clear
merge m:1 indcd year using "statadata\02_industry_ROA.dta"
drop _merge
merge 1:1 indcd year month using "statadata/01_rumor_mi.dta"
rename NO NO_ind
replace NO_ind = 0 if missing(NO_ind)
recode NO_ind ( 1 2 3 4 5 6 7 8 = 1), gen(NO_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgNO_ind = log(NO_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)
*/全部负向显著。。
reg lgNO_ind lgROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd_wins if year > 2006 & year < 2016
logit NO_ind_dum ROA_ind_sd if year > 2006 & year < 2016
save "statadata\03_industry_ROA_m_reg.dta", replace

*行业季度
use "statadata/formerge_iq.dta", clear
merge m:1 indcd year using "statadata\02_industry_ROA.dta"
drop _merge
merge 1:1 indcd year quarter using "statadata/01_rumor_qi.dta"
rename NO NO_ind
replace NO_ind = 0 if missing(NO_ind)
recode NO_ind ( 1 2 3 4 5 6 7 8 = 1), gen(NO_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgNO_ind = log(NO_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)
*/全部负向显著。。
reg lgNO_ind lgROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd_wins if year > 2006 & year < 2016
logit NO_ind_dum ROA_ind_sd if year > 2006 & year < 2016
save "statadata\03_industry_ROA_q_reg.dta", replace
