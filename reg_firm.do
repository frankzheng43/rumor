* 公司年层面回归 包括 年ROA 年分析师预测分歧
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
merge 1:1 `keyvalue' using statadata/roa_sd_formerge.dta, gen(_mroa)
merge 1:1 `keyvalue' using statadata/ana_forecast_formerge.dta, gen (_mana)
merge 1:1 `keyvalue' using statadata/cv_y_formerge.dta, gen(_mcv)
drop _m*
keep if inrange(year, 2007, 2015)
sort stkcd year

rename NO rumor
replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)
order rumor_dum, after(rumor)

* 补全行业
bysort stkcd : replace indcd = indcd[_n-1] if missing(indcd)
bysort stkcd: replace indcd = indcd[_n+1] if missing(indcd)

egen idind = group(indcd)
egen id = group(stkcd)
tsset id year

local winsorvar ROA_sd dispersion_a lnasset tobinq lev SA
winsor2 `winsorvar', suffix(_wins) cuts(1 99)
winsor2 `winsorvar', suffix(_wins1) cuts(5 95)

eststo clear
local CV lnasset_wins1 tobinq_wins1 lev_wins1 SA_wins1
* local CV lnasset_wins tobinq_wins lev_wins SA_wins
*local CV lnasset tobinq rdspendsumratio lev SA

* 不确定性用ROA的波动率表示
eststo: reghdfe l1.rumor ROA_sd_wins1 `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
* 不确定性用分析师预测分歧表示
eststo: reghdfe l1.rumor dispersion_a_wins1 `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

esttab using results/公司年不确定性回归.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)


* 其他尝试
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(year) cluster(id)

eststo: logit l1.rumor_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
eststo: tobit l1.rumor ROA_sd if inrange(year,2007,2015), ll(0)
eststo: mlogit rumor_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
eststo: probit l1.rumor_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)

esttab using results/firm_y.rtf, replace
save statadata/03_firm_ROA_reg.dta, replace














































*2.1.2ROA回归（公司月） as robust
use statadata/formerge_m.dta, clear
egen idind = group(indcd)

local keyvalue stkcd year 
merge 1:1 `keyvalue' month using statadata/01_rumor_mf.dta, gen(_mrumor)
merge m:1 `keyvalue' using statadata/02_firm_ROA.dta, gen(_mroa)
merge 1:1 `keyvalue' month using statadata/05_cv_m.dta, gen(_mcv)
//merge 1:1 `keyvalue' month using statadata/02_firm_turnover_mf.dta, gen(_mturnover)
rename NO rumor

drop _m* id accper
//rename edca count_turnover
//replace count_turnover = 0 if missing(count_turnover)
//replace vio_count = 0 if missing(vio_count)
replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)
order rumor_dum, after(rumor)

local winsorvar ROA_sd lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', replace cuts(5 95) 
label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq "TobinQ"

egen id = group(stkcd)
egen idmonth = group(year month)
tsset id idmonth

eststo clear 
local CV lnasset tobinq rdspendsumratio lev SA
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(year) cluster(id)
//eststo: reghdfe l1.rumor count_turnover `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: logit l1.rumor_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
eststo: probit l1.rumor_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
eststo: tobit l1.rumor ROA_sd if inrange(year,2007,2015), ll(0)

esttab using results/firm_mf.rtf, label replace
save statadata/03_firm_ROA_mf_reg.dta, replace

*2.1.3ROA回归（公司季度） as robust
use statadata/formerge_q.dta, clear
local keyvalue stkcd year
merge 1:1 `keyvalue' quarter using statadata/01_rumor_qf.dta, gen(_mrumor)
merge m:1 `keyvalue' using statadata/02_firm_ROA.dta, gen(_mroa)
merge 1:1 `keyvalue' quarter using statadata/05_cv_q.dta, gen(_mcv)
rename NO rumor

drop _m* id accper enddate
//replace vio_count = 0 if missing(vio_count)
replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)
order rumor_dum, after(rumor)

local winsorvar ROA_sd lnasset tobinq rdspendsumratio lev SA 
winsor2 `winsorvar', replace cuts(5 95)

label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq "TobinQ"

egen id = group(stkcd)
egen idquarter = group(year quarter)
egen idind = group(indcd)
tsset id idquarter

eststo clear
local CV lnasset tobinq rdspendsumratio lev SA 
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: reghdfe l1.rumor ROA_sd `CV' if inrange(year,2007,2015), absorb(year) cluster(id)

eststo: logit l1.rumor_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
eststo: probit l1.rumor_dum ROA_sd `CV' if inrange(year,2007,2015), cluster(id)
eststo: tobit l1.rumor ROA_sd `CV' if inrange(year,2007,2015), ll(0)

esttab using results/firm_qf.rtf, label replace
save statadata/03_firm_ROA_qf_reg.dta, replace

local CV lnasset tobinq rdspendsumratio lev
reghdfe l1.attitute ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
reghdfe l1.wording1 ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
reghdfe l1.wording2 ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
reghdfe l1.wording3 ROA_sd `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)

