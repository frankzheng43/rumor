/**
 控制变量整合成一个文件
 */

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
use statadata/02_firm_asset.dta, clear
gen year = year(accper)
order year, after(stkcd)
tempfile asset
save `asset'

use statadata/02_firm_RD.dta, clear
gen year = year(enddate)
order year, after(stkcd)
keep stkcd year enddate rdspendsumratio
tempfile RD 
save `RD'

use statadata/02_firm_TB.dta, clear
gen year = year(accper)
order year, after(stkcd)
*使用的是TobinQ B值：市值A/（资产总计—无形资产净额—商誉净额）
keep stkcd year accper indcd f100902a 
rename f100902a tobinq
tempfile TobinQ
save `TobinQ'

use statadata/kz_index.dta, clear
order year, after(stkcd)
tempfile kz_index
save `kz_index'

// merge together 
use statadata/formerge_m.dta, clear
local keyvalue stkcd year
merge m:1 `keyvalue' using `asset', gen(_masset)
merge m:1 `keyvalue' using `RD', gen (_mRD)
merge m:1 `keyvalue' using `TobinQ', gen (_mTobinQ)
merge m:1 `keyvalue' using `kz_index', gen (_mkz)
//merge 1:1 `keyvalue' month using `violation_m', gen (_mviolationm)
drop _m* enddate
sort stkcd year quarter month
save statadata/05_cv_m.dta, replace

// use `ex_vio'
// merge m:1 `keyvalue' quarter using `violation_q', gen (_mviolationq)
// save statadata/05_cv_q.dta, replace

// use `ex_vio'
// merge m:1 `keyvalue' using `violation_y', gen (_mviolationq)
// save statadata/05_cv_q.dta, replace

// TODO: need cleaning
use statadata/formerge_q.dta, clear
local keyvalue stkcd year 
merge m:1 `keyvalue' using `asset', gen(_masset)
merge m:1 `keyvalue' using `RD', gen (_mRD)
merge m:1 `keyvalue' using `TobinQ', gen (_mTobinQ)
merge m:1 `keyvalue' using `kz_index', gen (_mkz)
drop _m*
//merge 1:1 `keyvalue' quarter using `violation_q', gen (_mviolationm)
save statadata/05_cv_q.dta, replace

use `asset', clear
local keyvalue stkcd year 
merge 1:1 `keyvalue' using `RD', gen (_mRD)
merge 1:1 `keyvalue' using `TobinQ', gen (_mTobinQ)
merge 1:1 `keyvalue' using `kz_index', gen (_mkz)
// merge 1:1 `keyvalue' using `violation_y', gen(_mviolationy)
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
