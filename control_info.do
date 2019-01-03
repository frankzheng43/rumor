* 上市公司控制人文件

clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/control_info, name("control_info") text replace

import delimited raw/HLD_Contrshr.txt, encoding(UTF-8) varnames(1) clear
drop v*

foreach var of varlist * {
  label variable `var' "`=`var'[1]'"
}
drop in 1/2

drop if inlist(substr(stkcd,1,1),"2","3","9")

capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
local lab: variable label `1'
label var `1'1 `lab'
drop `1' 
rename `1'1 `1' 
end

str_to_numeric reptdt
drop if missing(reptdt)