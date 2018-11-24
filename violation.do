/**
 * This code is used to import and clean company violation data 
 * Author: Frank Zheng
 * Required data: STK_Violation_Son.txt
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
local location "F:\rumor"
cd "`location'"
capt log close _all
log using logs/violation, name("violation") text replace

//违规数据（明细数据）
import delimited raw\STK_Violation_Son.txt, varnames(1) encoding(UTF-8) clear

rename symbol stkcd
drop if missing(stkcd)
drop in 1/2
drop if inlist(stkcd, "刘凌云", "吴翠华", "黄学春")

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
str_to_numeric disposaldate

//字符格式转化为数值格式
destring penalty, replace

quietly ds, has(type string)
foreach x of var `r(varlist)'{
	gen `x'1 = strltrim(`x')
	order `x'1, after(`x')
	drop `x'
	rename `x'1 `x'
}

save statadata\02_firm_violation.dta, replace 

//将明细表转化为总表（同义词处罚的合并成一条）
use statadata\02_firm_violation.dta, clear
sort violationid
egen violationidid = group(violationid)
bysort violationidid: gen seq = _n
keep if seq == 1
drop violationidid seq
save statadata\02_firm_violation_main.dta, replace

log close violation
