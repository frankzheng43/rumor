/**
 * This code is used to import and clean company location change data 
 * Author: Frank Zheng
 * Required data: STK_ListedCoInfoChg.txt
 * Required code: - 
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
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/locchange, name("locchange") text replace

// 公司地址变更数据
import delimited raw/STK_ListedCoInfoChg.txt, varnames(1) encoding(UTF-8) stringcols(3) clear
rename symbol stkcd
drop securityid listedcoid v9 v10
drop if missing(stkcd)

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date(`1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
local datevar announcementdate implementdate
foreach x of local datevar{
	str_to_numeric `x'
}

quietly tab changeditem, sort gen(changeditem)
// keep if changeditem == "办公地址"
save statadata/02_firm_loc.dta, replace

log close locchange
