/* 沪深300指数 */
clear all
set more off
eststo clear
capture version 14
local location "F:/rumor"
cd "`location'"
capt log close _all
log using logs/hs300, name("hs300") text replace

import delimited raw/IDX_Idxtrd.txt, encoding(UTF-8) varnames(1) clear
keep if indexcd == "000300"
rename indexcd hs300
rename idxtrd01 trddt 
rename idxtrd08 hsreturn
keep hs300 trddt hsdate

/** This program is used to convert string date to numeric date*/
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

str_to_numeric hsdate
destring hsreturn, replace
save statadata/hs300, replace