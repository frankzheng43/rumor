* 公司治理情况
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/governance, name("governance") text replace

import delimited raw/CG_Ybasic.txt, encoding(UTF-8) varnames(1) stringcols(_all) clear
