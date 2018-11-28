/*
公告全文数据库=>澄清公告数据
*/

// setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/full_txt, name("full_txt") text replace

set excelxlsxlargefile on
import excel raw/ANN_SummaryInfo.xlsx, sheet("Sheet1") firstrow clear
keep AnnouncementID DeclareDate SummaryContent SummaryTitle
gen cq = 1 if ustrregexm(SummaryTitle,"澄清")
rename *, lower
drop in 1/2

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
str_to_numeric declaredate

tempfile t1
save  `t1'

import delimited raw/ANN_SumSecurity.txt, encoding(UTF-8) stringcols(1 3) varnames(1) clear

str_to_numeric declaredate
keep if securitytype == "A股"
tempfile t2
save `t2'

merge 1:1 announcementid declaredate using `t1', gen(_m1)
//keep if _merge == 3
rename symbol stkcd
rename declaredate summary_date
keep if !missing(cq)
duplicates drop stkcd summary_date, force
drop announcementid securitytype summarytitle cq
drop if _m1 == 2

tempfile t3
save `t3'

use statadata/01_rumor.dta, clear
rename Evntdate summary_date
drop rumor_content title
duplicates drop stkcd summary_date, force

merge 1:1 stkcd summary_date using `t3', gen(_m2)

//drop rumor Evntdate_workday lagtime evidence content stop id year month 
//drop indcd_r announcementid  number title 

gen rumor_url = .
gen rumor_content = .

rename *, lower
rename summarycontent summary_content
rename source rumor_source
rename evntdate_workday summary_date_workday

duplicates drop stkcd summary_date_workday, force
tempfile t4
save `t4'

import excel raw/20180615Reputation-final.xlsx, sheet("sheet1") firstrow allstring clear
drop obs rumor industry111 year Number
rename *, lower

rename rdatenew rumor_date_new
rename adatenew summary_date_workday

capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"MDY")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
str_to_numeric summary_date_workday
str_to_numeric rumor_date_new

duplicates drop stkcd summary_date_workday, force

tempfile t5
save `t5'

use `t4', clear
merge 1:1 stkcd summary_date_workday using `t5', gen(_m3)

gen rumor_date = cond(evtday > rumor_date_new, rumor_date_new, evtday)
format rumor_date %td
drop evtday rumor_date_new

bysort id : replace stknme = stknme[_n+1] if missing(stknme)
bysort id : replace indcd = indcd[_n+1] if missing(indcd)
tempfile t6
save `t6'

import delimited F:\rumor\raw\lookatme.csv, encoding(UTF-8) clear 
replace stkcd = substr(stkcd,2,7)

tostring date, gen(date_str)
replace date = date(date_str,"YMD")
format date %td
drop date_str

sort stkcd date
rename date summary_date
drop if missing(stkcd)
tempfile t7 
save `t7'

use `t6', replace
merge 1:1 stkcd summary_date using `t7', gen(_m4)
duplicates drop stkcd summary_date_workday, force

tempfile t8
save `t8'

import excel "F:\rumor\raw\20180617澄清公告分年汇总(3078).xlsx", sheet("汇总") firstrow case(lower) clear
keep firm adate title
rename firm stkcd
rename title rumor_title
rename adate summary_date_workday
replace stkcd = substr( stkcd, 1, 6)
drop in 1 
/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"DMY")
format `1'1 %td
order `1'1, after(`1')
local lab: variable label `1'
label var `1'1 `lab'
drop `1' 
rename `1'1 `1' 
end
str_to_numeric summary_date_workday
duplicates drop stkcd summary_date_workday, force
//问题没有解决，一篇澄清公告里回应了多篇的传闻。
tempfile t9
save `t9'

use `t8'
merge 1:1 stkcd summary_date_workday using `t9'
drop if missing( summary_date)
keep stkcd summary_date summary_date_workday rumor_source attitute content note summary_content _m1 _m2 rumor_url rumor_content authority rumor response strong stknme content1 content2 _m3 rumor_date text summary_size _m4 rumor_title _merge
drop _m*
rename rumor rumor_nature
rename strong summary_strong

label var stkcd "股票代码"
label var summary_date "澄清公告日"
label var rumor_date "传闻发生日"
label var rumor_source "传闻来源"
label var rumor_nature "传闻性质"
label var summary_strong "澄清语气"
label var rumor_content "传闻内容"
label var summary_content "澄清公告摘要"
label var summary_date_workday "澄清公告全文"
label var note "备注"
label var rumor_title "传闻标题"
label var rumor_url "传闻链接"
label var summary_size "澄清公告大小"

rename attitute rumor_attitude
rename text summary_content_full
rename authority rumor_authority
rename response summary_response
order stkcd stknme summary_date summary_date_workday summary* rumor* content*
label var stknme  "证券名称"
label var summary_content_full "澄清公告全文"
label var summary_date_workday "澄清公告日_工作日"
label var summary_response "澄清回应"
drop rumor_attitude
label var rumor_authority "传闻来源权威性"
gen isrumor = .
order isrumor, after( summary_content_full)
label var isrumor "是否为传闻"
order stkcd stknme summary_date summary_date_workday summary_content summary_content_full isrumor summary_response summary_strong summary_size rumor_date rumor_source rumor_authority rumor_content rumor_nature rumor_url

save statadata/full_rumor.dta, replace
export excel using statadata/full_rumor_20180618.xls, sheetreplace firstrow(varlabels) nolabel