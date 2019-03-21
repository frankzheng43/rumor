/* 宏观层面回归： RUMOR=UNCERTAINTY+CV */
/* t = month
   t = quarter
   t = month, i = firm
   t = quarter, i = firm  */

// setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/macro_reg, name("macro_reg") text replace

/* 按月回归 */
/* 02_macro 政治不确定性 */
use statadata/02_macro.dta, clear 
/* 01_rumor 传闻*/
merge 1:1 year month using statadata/01_rumor_m.dta
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty
drop if missing(rumor)
drop _m*
winsor2 policy_uncertainty rumor, suffix(_wins) cuts(5 95)
gen lgpolicy_uncertainty_wins = log(policy_uncertainty_wins)
gen lgrumor=log(rumor_wins)
/* 所有区间内均存在rumor所以rumor_dum构造的意义不存在 */

label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"

egen idmonth = group(year month)
tsset idmonth

eststo clear
forvalues i = 1/8{
  eststo: reg l`i'.lgrumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016
}
esttab using results/macro_m.rtf, label replace
 
//esttab using results/macro_m.xls, label replace
save statadata/03_macro_reg.dta, replace

/* t檢驗 */
tempvar median mean
egen `median' = median(lgpolicy_uncertainty_wins)
egen `mean' = mean(lgpolicy_uncertainty_wins)
tempvar group_uncertainty group_uncertainty_mean
gen `group_uncertainty' = cond(lgpolicy_uncertainty_wins > `median', 1, 0)
gen `group_uncertainty_mean' = cond(lgpolicy_uncertainty_wins > `mean', 1, 0)
ttest rumor, by(`group_uncertainty')
ttest rumor, by(`group_uncertainty_mean')


/* 按季度回歸 */
use "statadata/02_macro_q.dta", clear
merge 1:1 year quarter using statadata/01_rumor_q.dta
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty

winsor2 policy_uncertainty rumor, suffix(_wins) cuts(5 95)
gen lgpolicy_uncertainty_wins = log(policy_uncertainty_wins)
gen lgrumor=log(rumor_wins)
drop if missing(rumor)
drop _m*

label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"

egen idquarter = group(year quarter)
tsset idquarter
*并不显著，为负
eststo clear
forvalues i = 1/4{
  eststo: reg l`i'.lgrumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016
  eststo: reg l`i'.rumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016
  eststo: tobit l`i'.rumor lgpolicy_uncertainty_wins if year > 2006 & year < 2016, ll(0)

}
esttab using results/macro_q.rtf, label replace
//esttab using results/macro_q.xls, label replace
save statadata/03_macro_q_reg.dta, replace

/* 按公司-月回归 */
use statadata/formerge_m.dta, clear
merge m:1 year month using statadata/02_macro.dta, gen(_mmacro)
keep if _mmacro == 3


local keyvalue stkcd year month
merge m:1  `keyvalue' using statadata/01_rumor_mf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata/05_cv_m.dta, gen(_mcv)
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty
drop _m*
//replace vio_count = 0 if missing(vio_count)
replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)


local winsorvar policy_uncertainty lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', suffix(_wins) cuts(5 95)

gen lgpolicy_uncertainty_wins = log(policy_uncertainty_wins)

label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq_wins "TobinQ"

egen idmonth = group(year month)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idmonth

eststo clear
local CV_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins SA 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, absorb(id year) cluster(id)
eststo: probit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
*0 和 3 之间的差距显著为负
eststo: mlogit rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)

eststo: logit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: probit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id)
eststo: tobit l1.rumor_dum lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id) ll(0)
eststo: tobit l1.rumor lgpolicy_uncertainty_wins `CV_wins' if year > 2006 & year < 2016, cluster(id) ll(0)

esttab using results/macro_mf.rtf, label replace
save "statadata/03_macro_reg_mf.dta", replace 

/* 主回归：按公司-季度回归 √ */ 
/* Gulen H, Ion M，. Policy Uncertainty and Corporate Investment[J]. 
The Review of Financial Studies, 2016, 29(3): 523–564.
季度回归，1-4期滞后
 */
//TODO 采用Gulen and lon（2016）年的权重方法，根据在每季度中各月的前后顺序，
//对越靠后的月份赋值越高（1/6，1/3，1/2），作为稳健性检验。
use "statadata/formerge_q.dta", clear
merge m:1 year quarter using "statadata/02_macro_q_w.dta", gen(_mmacro)
keep if _mmacro == 3
local keyvalue stkcd year quarter
merge m:1  `keyvalue' using statadata/01_rumor_qf.dta, gen(_mrumor)
merge 1:1  `keyvalue' using statadata/05_cv_q.dta, gen(_mcv)
rename NO rumor
rename ChinaNewsBasedEPU policy_uncertainty
rename ChinaNewsBasedEPU_w policy_uncertainty_w
replace rumor = 0 if missing(rumor)
recode rumor (0 = 0) (else = 1), gen(rumor_dum)
drop _m*

local winsorvar policy_uncertainty policy_uncertainty_w lnasset tobinq rdspendsumratio lev SA
winsor2 `winsorvar', suffix(_wins) cuts(5 95) 
gen lgpolicy_uncertainty_wins = log(policy_uncertainty_wins)
gen lgpolicy_uncertainty_w_wins = log(policy_uncertainty_w_wins)

label var lgpolicy_uncertainty_wins "Policy Uncertainty"
label var rumor "Rumor"
label var rumor_dum "Rumor_dum"
label var tobinq_wins "TobinQ"

*generating composite categorical variables
egen idquarter = group(year quarter)
egen id = group(stkcd)
egen idind = group(indcd)
tsset id idquarter

local CV lnasset_wins tobinq_wins lev_wins SA_wins
* local CV lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins SA_wins
eststo clear
*正式
eststo clear
eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor policy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
esttab using results/macro_季度加权滞后.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
*正式
eststo clear
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor lgpolicy_uncertainty_w_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
esttab using results/macro_季度加权滞后对数.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)
*正式
eststo clear
eststo: reghdfe l1.rumor policy_uncertainty_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l2.rumor policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
esttab using results/macro_季度加权滞后无RD.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)


eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(id year) cluster(id) //√
eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) //√
eststo: reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(year) cluster(id) //√

eststo: logit l1.rumor_dum policy_uncertainty_wins `CV' if inrange(year,2007,2015), cluster(id)
eststo: tobit l1.rumor_dum policy_uncertainty_wins if inrange(year,2007,2015), ll(0)
eststo: mlogit rumor_dum policy_uncertainty_wins `CV' if inrange(year,2007,2015), cluster(id)
eststo: probit l1.rumor_dum policy_uncertainty_wins `CV' if inrange(year,2007,2015), cluster(id)

eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(id year) cluster(id)
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(year) cluster(id)

eststo: logit l1.rumor_dum lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), cluster(id)
eststo: tobit l1.rumor_dum lgpolicy_uncertainty_wins if inrange(year,2007,2015), ll(0)
eststo: mlogit rumor_dum lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), cluster(id)
eststo: probit l1.rumor_dum lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), cluster(id)

esttab using results/macro_qf.rtf, replace
eststo clear
save "statadata/03_macro_reg_qf.dta", replace

* 可信度分数与BBD指数的回归
eststo clear
sort id idquarter
local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo: reghdfe l1.detail_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.detail_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe l1.authority_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.authority_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe l1.completeness_score policy_uncertainty `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.completeness_score policy_uncertainty_w `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
esttab using results/可信度与BBD.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)

* 可信度的t检验
tempvar median mean
egen `median' = median(policy_uncertainty)
egen `mean' = mean(policy_uncertainty)
tempvar group_policy_uncertainty group_policy_uncertainty_mean
gen `group_policy_uncertainty' = cond(policy_uncertainty > `median', 1, 0)
gen `group_policy_uncertainty_mean' = cond(policy_uncertainty > `mean', 1, 0)
* detail显著
ttest detail_score, by(`group_policy_uncertainty') 
ttest detail_score, by(`group_policy_uncertainty_mean')
ttest authority_score, by(`group_policy_uncertainty')
ttest authority_score, by(`group_policy_uncertainty_mean') 
ttest completeness_score, by(`group_policy_uncertainty')
ttest completeness_score, by(`group_policy_uncertainty_mean')

recode authority_score (0=0)(else = 1), gen(authority_score_dum)
recode detail_score (0=0)(else = 1), gen(detail_score_dum)
recode completeness_score (0=0)(else = 1), gen(completeness_score_dum)

reg authority_score_dum policy_uncertainty if !missing(authority_score)
reg detail_score_dum policy_uncertainty if !missing(detail_score)
reg completeness_score_dum policy_uncertainty if !missing(completeness_score_dum)

logit authority_score_dum policy_uncertainty if !missing(authority_score)

*分组检验 DA => DA越小，传闻越多
merge m:1 stkcd year using F:\rumor\statadata\DA_d.dta

tempvar median mean
bysort year: egen `median' = median(abs_DA_Winsor)
bysort year: egen `mean' = mean(abs_DA_Winsor)
tempvar group_abs_DA_Winsor group_abs_DA_Winsor_mean
gen group_abs_DA_Winsor = cond(abs_DA_Winsor > `median', 1, 0)
gen group_abs_DA_Winsor_mean = cond(abs_DA_Winsor > `mean', 1, 0)
replace group_abs_DA_Winsor = . if missing(abs_DA_Winsor)
replace group_abs_DA_Winsor_mean = . if missing(abs_DA_Winsor)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor_mean == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_abs_DA_Winsor_mean == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor c.policy_uncertainty_wins#i.group_abs_DA_Winsor `CV' if inrange(year,2007,2015) , absorb(idind year) cluster(id)

* 分组检验 分析师跟踪 => 跟踪数越多，传闻越多
merge m:1 stkcd year using F:\rumor\statadata\ana_follow.dta

* 分析师平均研报
tempvar median mean
bysort year: egen `median' = median(analyst_follow)
bysort year: egen `mean' = mean(analyst_follow)
tempvar group_analyst_follow group_analyst_follow_mean
gen group_analyst_follow = cond(analyst_follow > `median', 1, 0)
gen group_analyst_follow_mean = cond(analyst_follow > `mean', 1, 0)
replace group_analyst_follow = . if missing(analyst_follow)
replace group_analyst_follow_mean = . if missing(analyst_follow)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow_mean == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_analyst_follow_mean == 1, absorb(idind year) cluster(id) 

* 研报数
tempvar median mean
bysort year: egen `mean' = mean(numforecast)
bysort year: egen `median' = median(numforecast)
tempvar group_numforecast group_numforecast_mean
gen group_numforecast = cond(numforecast > `median', 1, 0)
gen group_numforecast_mean = cond(numforecast > `mean', 1, 0)
replace group_numforecast = . if missing(numforecast)
replace group_numforecast_mean = . if missing(numforecast)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numforecast == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numforecast == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numforecast_mean == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numforecast_mean == 1, absorb(idind year) cluster(id) 

* 分析师数
tempvar median mean
bysort year: egen `mean' = mean(numanalyst)
bysort year: egen `median' = median(numanalyst)
tempvar group_numanalyst group_numanalyst_mean
gen group_numanalyst = cond(numanalyst > `median', 1, 0)
gen group_numanalyst_mean = cond(numanalyst > `mean', 1, 0)
replace group_numanalyst = . if missing(numanalyst)
replace group_numanalyst_mean = . if missing(numanalyst)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst_mean == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_numanalyst_mean == 1, absorb(idind year) cluster(id) 


* 分组检验 两权分离度 => 两权分离度越高，传闻越多 √
merge m:1 stkcd year using F:\rumor\statadata\seperation.dta

tempvar median mean
bysort year: egen `median' = median(seperation)
bysort year: egen `mean' = mean(seperation)
tempvar group_seperation group_seperation_mean
gen group_seperation = cond(seperation > `median', 1, 0)
gen group_seperation_mean = cond(seperation > `mean', 1, 0)
replace group_seperation = . if missing(seperation)
replace group_seperation_mean = . if missing(seperation)

local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
sort id idquarter
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation == 1, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_mean == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_mean == 1, absorb(idind year) cluster(id) 
esttab using results/按两权分离度分组.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)


tempvar median mean
bysort year: egen `median' = median(seperation_wins)
bysort year: egen `mean' = mean(seperation_wins)
tempvar group_seperation_wins group_seperation__wins_mean
gen group_seperation_wins = cond(seperation_wins > `median', 1, 0)
gen group_seperation_wins_mean = cond(seperation_wins > `mean', 1, 0)
replace group_seperation_wins = . if missing(seperation_wins)
replace group_seperation_wins_mean = . if missing(seperation_wins)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_wins == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_wins == 1, absorb(idind year) cluster(id) 

* 分组检验 机构投资者持股比例 => 中位数分组，持股比例越多的传闻越多 均值分组，两组均显著
merge m:1 stkcd year using F:\rumor\statadata\ins_share.dta
* 未winsor
tempvar median mean
bysort year: egen `median' = median(ins_share)
bysort year: egen `mean' = mean(ins_share)
tempvar group_ins_share group_ins_share_mean
gen group_ins_share = cond(ins_share > `median', 1, 0)
gen group_ins_share_mean = cond(ins_share > `mean', 1, 0)
replace group_ins_share = . if missing(ins_share)
replace group_ins_share_mean = . if missing(ins_share)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_mean == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_mean == 1, absorb(idind year) cluster(id) 
* winsor
tempvar median mean
bysort year: egen `median' = median(ins_share_wins)
bysort year: egen `mean' = mean(ins_share_wins)
tempvar group_ins_share_wins group_ins_share_wins_mean
gen group_ins_share_wins = cond(ins_share_wins > `median', 1, 0)
gen group_ins_share_wins_mean = cond(ins_share_wins > `mean', 1, 0)
replace group_ins_share_wins = . if missing(ins_share_wins)
replace group_ins_share_wins_mean = . if missing(ins_share_wins)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins_mean == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins_mean == 1, absorb(idind year) cluster(id) 

* winsor1
tempvar median mean
bysort year: egen `median' = median(ins_share_wins1)
bysort year: egen `mean' = mean(ins_share_wins1)
tempvar group_ins_share_wins1 group_ins_share_wins1_mean
gen group_ins_share_wins1 = cond(ins_share_wins1 > `median', 1, 0)
gen group_ins_share_wins1_mean = cond(ins_share_wins1 > `mean', 1, 0)
replace group_ins_share_wins1 = . if missing(ins_share_wins1)
replace group_ins_share_wins1_mean = . if missing(ins_share_wins1)

sort id idquarter
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins1 == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins1 == 1, absorb(idind year) cluster(id) 

reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins1_mean == 0, absorb(idind year) cluster(id) 
reghdfe l1.rumor policy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_ins_share_wins1_mean == 1, absorb(idind year) cluster(id) 

*分年份
local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
sort id idquarter
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation == 1, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_mean == 0, absorb(idind year) cluster(id) 
eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015) &  group_seperation_mean == 1, absorb(idind year) cluster(id) 
esttab using results/按两权分离度分组.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)


* 股吧帖子与不确定性 => 不确定性增加时，贴子数增加（传播信息的意愿增强），阅读数增加（搜寻信息的意愿增强）
drop if inlist(substr(stkcd,1,1),"2","3","9")
local winsorvar Tpostnum Readnum
winsor2 `winsorvar', suffix(_wins) cuts(5 95) 
winsor2 `winsorvar', suffix(_wins1) cuts(1 99) 
gen lgReadnum = log(Readnum)
gen lgTpostnum = log(Tpostnum)
gen lgReadnum_wins = log(Readnum_wins)
gen lgTpostnum_wins = log(Tpostnum_wins)


local CV lnasset_wins tobinq_wins lev_wins SA_wins
eststo clear
sort id idquarter
*eststo: reghdfe l1.Commentnum lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.Tpostnum_wins lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
eststo: reghdfe l1.Readnum_wins lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
* eststo: reghdfe Tpostnum lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
* eststo: reghdfe Readnum lgpolicy_uncertainty_wins `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id) 
esttab using results/股吧帖子.rtf, replace starlevels(* 0.10 ** 0.05 *** 0.01)



log close macro_reg
// eststo: xtreg l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, fe cluster(id)
// eststo: areg l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, absorb(id) cluster(id)
// eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins  i.year if year > 2006 & year < 2016, absorb(id) cluster(id)
// eststo: reghdfe l1.rumor lgpolicy_uncertainty_wins lnasset_wins tobinq_wins rdspendsumratio_wins lev_wins if year > 2006 & year < 2016, absorb(id year) cluster(id)

/** 
 * These three cmdlines are almost the same: xtreg areg reghdfe
 * xtset panalvar timevar
 * xtreg y x CV i.timevar, fe cluster(panelvar)
 * areg y x CV i.timevar, absorb(panelvar) cluster(panelvar)
 * reghdfe y x CV i.timevar, absorb(panelvar) cluster(panelvar)
 * or reghdfe y x CV , absorb(panelvar timevar) cluster(panelvar)
 * Within Stata, reghdfe can be viewed as a generalization of areg/xtreg, 
 * with several additional features:
 */


//TODO 
/* Schwert（1989）的文章中使用包含时间固定效应的自回归模型对不同的宏观变量进行建模，并提取出残差项。
将残差项的平方作为该变量的不确定性的度量。一般是使用工业生产指数的增长率的波动率作为宏观经济不确定性的度量。 */
//TODO 
/* 交易量 */
//TODO
/* PSM配对 */



estpost summarize rumor policy_uncertainty_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins lgpolicy_uncertainty_wins lgpolicy_uncertainty_w_wins
esttab using miaoshu.rtf, cells("count mean sd min max")

logout, save(BDD回归描述性统计) word replace:summarize rumor policy_uncertainty_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins lgpolicy_uncertainty_wins lgpolicy_uncertainty_w_wins
