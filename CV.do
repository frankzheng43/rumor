/**
 *This code is used to merge different control variables and construct a whole dataset
 *Author : Frank Zheng
 * Required data: 02_firm_asset.dta 02_firm_RD.dta 02_firm_TB.dta 02_firm_violation_main formerge_m.dta
 * Required code: too many
 * Required ssc : -
 */

 // install missing ssc
 local sscname estout winsor2 
 foreach pkg of local sscname{
  cap which  `pkg'
  if _rc!=0{
        ssc install `pkg'
        }
 }

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:/rumor"
cd "`location'"
capt log close _all
log using control_variables, name("control variables") text replace

// save all datasets to tempfile
use statadata\02_firm_asset.dta, clear
gen year = year(accper)
order year, after(stkcd)
tempfile asset
save  `asset'

use statadata\02_firm_RD.dta, clear
gen year = year(enddate)
order year, after(stkcd)
keep stkcd year enddate rdspendsumratio
tempfile RD 
save `RD'

use statadata\02_firm_TB.dta, clear
gen year = year(accper)
order year, after(stkcd)
// 使用的是TobinQ B值：市值A/（资产总计—无形资产净额—商誉净额）
keep stkcd year accper indcd f100902a 
rename f100902a tobinq
tempfile TobinQ
save `TobinQ'

use statadata\02_firm_violation_main.dta, clear
gen year = year(disposaldate)
gen month = month(disposaldate)
gen quarter = quarter(disposaldate)
order year month quarter, after(stkcd)
// 由于是月度数据，可以合并到年/季度/月份，因此先保存等后续使用
tempfile violation
save `violation'
// 月度数据
use `violation'
collapse (count) penalty, by(stkcd year quarter month)
sort stkcd year quarter month
rename penalty vio_count
label var vio_count "the number of violation"
tempfile violation_m
save `violation_m'
//季度数据
use `violation'
collapse (count) penalty, by(stkcd year quarter)
sort stkcd year quarter 
rename penalty vio_count
label var vio_count "the number of violation"
tempfile violation_q
save `violation_q'
//年度数据
use `violation'
collapse (count) penalty, by(stkcd year)
sort stkcd year
rename penalty vio_count
label var vio_count "the number of violation"
tempfile violation_y
save `violation_y'

// merge together 
use statadata\formerge_m.dta, clear
local keyvalue stkcd year
merge m:1 `keyvalue' using `asset', gen(_masset)
merge m:1 `keyvalue' using `RD', gen (_mRD)
merge m:1 `keyvalue' using `TobinQ', gen (_mTobinQ)
merge 1:1 `keyvalue' month using `violation_m', gen (_mviolationm)
save statadata/05_cv_m.dta, replace

// use `ex_vio'
// merge m:1 `keyvalue' quarter using `violation_q', gen (_mviolationq)
// save statadata/05_cv_q.dta, replace

// use `ex_vio'
// merge m:1 `keyvalue' using `violation_y', gen (_mviolationq)
// save statadata/05_cv_q.dta, replace

// TODO: need cleaning
use statadata\formerge_q.dta, clear
local keyvalue stkcd year 
merge m:1 `keyvalue' using `asset', gen(_masset)
merge m:1 `keyvalue' using `RD', gen (_mRD)
merge m:1 `keyvalue' using `TobinQ', gen (_mTobinQ)
merge 1:1 `keyvalue' quarter using `violation_q', gen (_mviolationm)
save statadata/05_cv_q.dta, replace

use `asset', clear
local keyvalue stkcd year 
merge 1:1 `keyvalue' using `violation_y', gen(_mviolationy)
merge 1:1 `keyvalue' using `RD', gen (_mRD)
merge 1:1 `keyvalue' using `TobinQ', gen (_mTobinQ)
// some cleaning 
drop accper enddate
order indcd, after(stkcd)
drop _m*
drop if year < 2000
// fill missing industry
egen id =  group(stkcd)
bysort  id : replace indcd = indcd[_n-1] if missing(indcd)
bysort  id : replace indcd = indcd[_n+1] if missing(indcd)
save statadata/05_cv_y.dta, replace
