/* 可信度的回归 */

clear all
set more off
eststo clear
capture version 14
local location "F:/rumor"
cd "`location'"
capt log close _all
log using logs/score_reg, name("score_reg") text replace

use statadata/formerge_y.dta, clear
local keyvalue stkcd year 
merge 1:1 `keyvalue' using statadata/sale_std.dta, gen(_msale)
merge 1:1 `keyvalue' using statadata/02_firm_ROA.dta, gen(_mroa)
merge 1:1 `keyvalue' using statadata/05_cv_y.dta, gen(_mcv)
merge 1:1 `keyvalue' using statadata/kz_index.dta, gen(_mkz)
merge 1:1 `keyvalue' using statadata/score_y.dta, gen(_score)
merge 1:1 `keyvalue' using statadata/ana_forecast_formerge.dta, gen(_mana)

keep if inrange(year, 2007, 2015)
keep if inlist(substr(stkcd,1,1),"0","6")
drop if substr(stkcd,1,3) == "002"
drop if missing(indcd)
drop _m*

egen idind = group(indcd)

local winsorvar ROA_sd sales_std dispersion_a lnasset tobinq rdspendsumratio lev SA 
winsor2 `winsorvar', replace cuts(5 95) 

tsset id year

eststo clear
local CV lnasset tobinq rdspendsumratio lev SA

eststo: reghdfe detail_score dispersion_a ROA_sd sales_std `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe detail_score dispersion_a `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe detail_score ROA_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe detail_score sales_std `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe authority_score dispersion_a ROA_sd sales_std `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe authority_score dispersion_a `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe authority_score ROA_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe authority_score sales_std `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

eststo: reghdfe completeness_score dispersion_a ROA_sd sales_std `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe completeness_score dispersion_a `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe completeness_score ROA_sd `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe completeness_score sales_std `CV' if inrange(year,2007,2015), absorb(idind year) cluster(id)

tempvar median mean
egen `median' = median(dispersion_a)
egen `mean' = mean(dispersion_a)
tempvar group_dispersion_a group_dispersion_a_mean
gen `group_dispersion_a' = cond(dispersion_a > `median', 1, 0)
gen `group_dispersion_a_mean' = cond(dispersion_a > `mean', 1, 0)
ttest detail_score, by(`group_dispersion_a')
ttest detail_score, by(`group_dispersion_a_mean')
ttest authority_score, by(`group_dispersion_a')
ttest authority_score, by(`group_dispersion_a_mean') 
ttest completeness_score, by(`group_dispersion_a')
ttest completeness_score, by(`group_dispersion_a_mean')


tempvar median mean
egen `median' = median(ROA_sd)
egen `mean' = mean(ROA_sd)
tempvar group_ROA_sd group_ROA_sd_mean
gen `group_ROA_sd' = cond(ROA_sd > `median', 1, 0)
gen `group_ROA_sd_mean' = cond(ROA_sd > `mean', 1, 0)
ttest detail_score, by(`group_ROA_sd')
ttest detail_score, by(`group_ROA_sd_mean')
ttest authority_score, by(`group_ROA_sd')
ttest authority_score, by(`group_ROA_sd_mean') 
ttest completeness_score, by(`group_ROA_sd')
ttest completeness_score, by(`group_ROA_sd_mean')

tempvar median mean
egen `median' = median(sales_std)
egen `mean' = mean(sales_std)
tempvar group_sales_std group_sales_std_mean
gen `group_sales_std' = cond(sales_std > `median', 1, 0)
gen `group_sales_std_mean' = cond(sales_std > `mean', 1, 0)
ttest detail_score, by(`group_sales_std')
ttest detail_score, by(`group_sales_std_mean')
ttest authority_score, by(`group_sales_std')
ttest authority_score, by(`group_sales_std_mean') 
ttest completeness_score, by(`group_sales_std')
ttest completeness_score, by(`group_sales_std_mean')

