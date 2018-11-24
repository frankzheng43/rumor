/**
 * This code is used to calculate industry level ROA volitility
 * Author : Frank Zheng
 * Required data: 02_firm_FS.dta 02_firm_ROA
 * Required code: -
 * Required ssc : -
 */

 // install missing ssc
 local sscname estout winsor2 rangestat
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
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/ROA_i, name("ROA_i") text replace

*/权重数据
use statadata/02_firm_FS.dta, clear
keep stkcd accper a001000000 a002000000 a0b1103000
rename a001000000 asset
rename a002000000 liability
rename a0b1103000 cash
gen lnasset = log(asset)
gen lev = liability/asset
save statadata/02_firm_asset.dta, replace

use statadata/02_firm_ROA, clear
merge 1:1 stkcd accper using statadata/02_firm_asset.dta
*/不匹配的基本都是2开头的B股 以及不在时间范围内的
keep if _merge == 3
collapse (mean) ROA [w=asset] , by(indcd year)
rename ROA ROA_ind
*计算前三年的行业波动率
rangestat (sd) ROA_ind, interval(year -3 -1) by(indcd)
save statadata/02_industry_ROA.dta, replace