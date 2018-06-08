// TODO: reading in labels from external file

clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/rumor, text replace

/*在导入之前，先将数字中的文字删除更改格式，将错误放置的列更改，空缺的列名填上。*/
/*导入数据*/

forvalues i=2007/2015{
	import excel raw/clarification.xls, sheet(`i') firstrow clear
	save statadata/00raw_`i'.dta, replace
	}

use statadata/00raw_2007.dta
drop U - X
save statadata/00raw_2007.dta, replace

use statadata/00raw_2008.dta
save statadata/00raw_2008.dta, replace

use statadata/00raw_2009.dta
drop S T
save statadata/00raw_2009.dta, replace

use statadata/00raw_2010.dta
drop T - IN
save statadata/00raw_2010.dta, replace

use statadata/00raw_2011.dta
drop T
save statadata/00raw_2011.dta, replace

use statadata/00raw_2012.dta
drop T - IS
save statadata/00raw_2012.dta, replace

use statadata/00raw_2013.dta
drop Q
save statadata/00raw_2013.dta, replace

use statadata/00raw_2014.dta
drop R - IL
save statadata/00raw_2014.dta, replace

use statadata/00raw_2015.dta
drop S
save statadata/00raw_2015.dta, replace

use statadata/00raw_2007.dta
forvalues i=2008/2015{
	append using statadata/00raw_`i'.dta,force
	}
	
rename D Evntdate_workday	
	
drop if missing(Firm)

/** 去掉SZ SH的后缀*/ 
gen Firm_new = substr(Firm,1,6)
drop Firm
rename Firm_new stkcd

egen id = group(stkcd)
order stkcd, after(NO)
order Evtday, after(Evntdate_workday)
drop result industry
rename altitute attitute
replace stop = 0 if missing(stop)
replace evidence = 0 if missing(evidence)

forvalues i = 1/3{
replace wording`i' = 0 if missing(wording`i')
}

gen year = year(Evtday)
gen month = month(Evtday)
// 对传闻的内容进行再分类
// gen content_r = "其他" if regexm(content,"其他") == 1
save statadata/01_rumor.dta, replace


*-------按季度
use statadata/01_rumor.dta,clear
gen quarter = quarter(Evtday)
collapse (count) NO (mean) attitute wording1 wording2 wording3, by(year quarter)
save statadata/01_rumor_q.dta, replace

*----- 按月份
use statadata/01_rumor.dta
collapse (count) NO, by(year month)
drop if missing(year)
save statadata/01_rumor_m.dta, replace

*--------按年份公司
use statadata/01_rumor.dta, clear
collapse (count) NO, by(year stkcd)
drop if missing(year)
save statadata/01_rumor_yf.dta, replace

*-------按季度公司
use statadata/01_rumor.dta, clear
gen quarter = quarter(Evtday)
collapse (count) NO (mean) attitute wording1 wording2 wording3, by(year quarter stkcd)
sort stkcd year quarter
save statadata/01_rumor_qf.dta, replace

*------按月份公司
use statadata/01_rumor.dta, clear
collapse (count) NO (mean) attitute wording1 wording2 wording3, by(year month stkcd)
drop if missing(year)
save statadata/01_rumor_mf.dta, replace

*--------按年份行业
use statadata/03_firm_ROA_reg.dta, clear
sort indcd stkcd year
collapse (count) NO, by(year indcd)
save statadata/01_rumor_yi.dta, replace

*--------按季度行业
use statadata/formerge_q.dta, clear
merge 1:1 stkcd year month using statadata/01_rumor_qf.dta
collapse (count) NO, by(year month indcd)
save statadata/01_rumor_qi.dta, replace

*--------按月份行业
use statadata/formerge_m.dta, clear
merge 1:1 stkcd year month using statadata/01_rumor_mf.dta
collapse (count) NO, by(year month indcd)
save statadata/01_rumor_mi.dta, replace

log rumor close
