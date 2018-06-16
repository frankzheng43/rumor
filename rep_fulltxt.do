/*

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
log using full_txt, name("full_txt") text replace

set excelxlsxlargefile on
import excel raw/ANN_SummaryInfo.xlsx, sheet("Sheet1") firstrow
drop FullDeclareDate
gen cq = 1 if ustrregexm(SummaryTitle,"澄清")
rename AnnouncementID announcementid
rename DeclareDate declaredate

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

tempfile ANN_SummaryInfo
save  `ANN_SummaryInfo'

import delimited raw/ANN_SumSecurity.txt, encoding(UTF-8) stringcols(1 3) varnames(1) clear

str_to_numeric declaredate
keep if securitytype == "A股"
tempfile ANN_SumSecurity
save `ANN_SumSecurity'

merge 1:1 announcementid declaredate using `ANN_SummaryInfo'
//keep if _merge == 3
drop _merge
rename symbol stkcd
rename declaredate Evntdate
keep if !missing(cq)
duplicates drop stkcd Evntdate, force
tempfile repfull
save `repfull'

use statadata/01_rumor.dta, clear
duplicates drop stkcd Evntdate, force

merge 1:1 stkcd Evntdate using `repfull' 
save statadata/full_rumor.dta replace


use statadata/full_rumor.dta, clear

drop NO Evntdate_workday lagtime evidence content stop id year month 
drop indcd_r announcementid  number title 
gen rumor_tittle = .
gen rumor_url = .
rename rumor_content rumor_content_b
gen rumor_content = .

rename *, lower
rename summarytitle summary_title
rename summarycontent summary_content
rename summarysize summary_size

order note, after (_merge)
order indcd,after(stkcd)
order summary_title summary_content summary_size attitute
order summary_title summary_content summary_size attitute, after(evntdate)
order rumor_tittle rumor_content_b rumor_content rumor_url nature, after(evtday)

label var stkcd "股票代码"
label var evntdate "澄清公告日"
label var evtday "传闻发生日"
label var source "传闻来源"
label var nature "传闻性质"
label var attitute "澄清语气"
label var indcd "行业代码"
label var rumor_content_b "传闻内容_简略"
label var summary_title "澄清公告标题"
label var summary_content "澄清公告内容"
label var note "备注"
label var rumor_tittle "传闻标题"
label var rumor_url "传闻链接"
label var rumor_content "传闻内容"
label var summary_size "澄清公告大小"


label define rumor_nature 1 "好消息" 0 "中性" -1 "坏消息"
label val nature rumor_nature

drop summary_title
sort stkcd evntdate

drop rumor_tittle
gen rumor_title = .
order rumor_title, after( evtday)
label var rumor_title "传闻标题"

order source, after( rumor_title)
rename source rumor_source

drop no lagtime evidence wording1 wording2 wording3 number stop title id year month indcd_r _merge
drop summary_size rumor_content_b announcementid
duplicates drop stkcd evntdate_workday, force

tempfile rumor
save `rumor'

clear

import excel "F:\rumor\raw\20180615Reputation-final.xlsx", sheet("sheet1") firstrow allstring
drop obs NO industry111 year Number
rename *, lower
rename rdatenew evtday_new
rename adatenew evntdate_workday
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"MDY")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
str_to_numeric evntdate_workday
str_to_numeric evtday_new
duplicates drop stkcd evntdate_workday, force
tempfile rumor_new
save `rumor_new'

use `rumor', clear
merge 1:1 stkcd evntdate_workday using `rumor_new'

sort stkcd evntdate_workday
order evtday_new, after( evtday)
order stknme, after( stkcd)
gen rumor_date = cond(evtday > evtday_new, evtday_new, evtday)
format rumor_date %td
drop evtday evtday_new
order content1 content2, after(content)
order strong, after(attitute)
rename content content3
drop attitute

rename rumor is_rumor
rename strong summary_attitude
label var summary_attitude "澄清语气"
rename evntdate summary_date
rename evntdate_workday summary_date_workday
label var summary_date_workday "澄清公告日_工作日"
rename authority rumor_authority
label var rumor_authority "传闻来源权威性"
label var is_rumor "是否为传闻"
label var rumor_date "传闻日"
order stkcd stknme indcd summary_date summary_date_workday summary_content is_rumor summary_attitude rumor_date rumor_source rumor_authority rumor_title rumor_content content1 content2 content3 nature rumor_url response note
sort id stknme indcd
bysort id : replace stknme = stknme[_n+1] if missing(stknme)
bysort id : replace indcd = indcd[_n+1] if missing(indcd)
tempfile rumor_full
save `rumor_full'
save statadata/rumor_full.dta, replace

import delimited F:\rumor\raw\lookatme.csv, encoding(UTF-8) clear 
replace stkcd = substr(stkcd,2,7)
tostring date, gen(date_str)
replace date = date(date_str,"YMD")
format date %td
drop date_str
sort stkcd date
rename date summary_date
drop if missing(stkcd)
tempfile summary 
save `summary'

use `rumor_full', replace
merge 1:1 stkcd summary_date using `summary', gen(_msummary)
drop _m*
order summary_size, after(summary_content)
label var summary_size "澄清公告大小"

rename text summary_content_full
order summary_content_full, after( summary_content)
label var summary_content_full "澄清公告全文"
drop id year

save statadata/full_rumor.dta, replace
export excel using statadata/full_rumor_20180617.xls, sheetreplace firstrow(varlabels) nolabel