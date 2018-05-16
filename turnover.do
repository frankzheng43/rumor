/**
 * This code is used to import and clean company executive turnover data 
 * Author: Frank Zheng
 * Required data: TMT_Position.txt 
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
log using logs\turnover, name("turnover") text replace

// TODO 如果可以补间的话可以试试(formerge)
// 高管更替数据1

import delimited raw\TMT_Position.txt, varnames(1) encoding(UTF-8) stringcols(1) clear

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
local datevar reptdt startdate //改为日期格式
foreach x of local datevar{
	str_to_numeric `x'
}
gen startyear = year(startdate)

// gen endyear 
gen year_string = substr(enddate,1,4)
destring year_string, gen(endyear) force
order endyear, after(enddate)
replace endyear = . if endyear == 0
drop year_string enddate

label var stkcd "证券代码"
label var reptdt "统计截止日期"
label var personid "人员ID" 
label var name "姓名"
label var position "职务"
label var startdate "任职开始日期"
label var startyear "任职开始年份"
label var endyear "任职结束年份"
label var servicestatus "是否在职"
label var tenure "任期"
label var toleavpost "距离离任剩余时期"

quietly ds
foreach x of var `r(varlist)'{
	rename `x' `x'_1
}

save statadata\02_firm_board.dta, replace

// 高管更替数据2
import delimited raw\CG_Ceo.csv, varnames(1) encoding(UTF-16) stringcols(1) clear

drop v19 v20 v21

local datevar annodt chgdt
foreach x of local datevar{
	str_to_numeric `x'
}

destring years, replace force
gen month = month(annodt)
gen year = year(annodt)
save statadata\02_firm_turnover.dta, replace

// 高管更替数据3


log close turnover
