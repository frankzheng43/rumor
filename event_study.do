/**
 * This code is used to conduct event study
 * Author: Frank Zheng
 * Required data: 02_trddta.dta 01_rumor.dta hs300.dta 
 * Required code: -
 * Required ssc : -
 * ref: https://dss.princeton.edu/online_help/stats_packages/stata/eventstudy.html 
 * ref:http://www.sunwoohwang.com/Event_Study_STATA.pdf */

//setups
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/event_study, text replace

use statadata/01_rumor.dta, clear
keep stkcd
bysort stkcd:gen eventcount = _N
bysort stkcd:keep if _n == 1
tempfile eventcount
//一个指示一支股票在区间内发生了多少次事件的数据
save `eventcount'

use statadata/02_trddta.dta, clear
keep stkcd trddt dretwd
merge m:1 stkcd using `eventcount'
keep if _merge == 3
drop _merge
merge m:1 trddt using statadata/hs300.dta 
keep if _merge == 3
drop _merge hs300
drop if missing(hsreturn)
expand eventcount
bysort stkcd trddt:gen set = _n
sort stkcd set trddt
//比如一个公司发生了三次事件，则set有为1/2/3，每个set当作独立的一支“股票”
tempfile stockdata2
save `stockdata2'

use statadata/01_rumor.dta, clear
keep stkcd Evntdate Evntdate_workday Evtday nature attitute
bysort stkcd: gen set = _n
sort stkcd set
tempfile eventdates2
save `eventdates2'

use `stockdata2', clear
merge m:1 stkcd set using `eventdates2'
keep if _merge == 3
drop _merge
egen group_id = group(stkcd set)

bysort group_id:gen datenum = _n
bysort group_id:gen target = datenum if trddt == Evtday //标记事件发生当日 evbtdate是传闻出现时，可以换成澄清出现时
egen td = max(target), by(group_id)
drop target
gen dif = datenum - td
by group_id:gen event_window = 1 if dif >= -3 & dif <= 3 //事件窗口
by group_id:gen estimation_window = 1 if dif < -30 & dif >= -180 //估计窗口
//删除事件窗口内样本不足的样本
egen count_event_obs = count(event_window), by(group_id)
egen count_est_obs = count(estimation_window), by(group_id)
drop if count_event_obs < 7 //其实不知道为什么要删掉
drop if count_est_obs < 150
replace event_window = 0 if event_window == .
replace estimation_window = 0 if estimation_window == .

set more off
egen id = group(group_id)

gen predicted_return = .
quietly summ id
local mx = r(max)
forvalues i = 1(1)`mx'{
    //l id stkcd if id == `i' & dif == 0
    quietly reg dretwd hsreturn if id == `i' & estimation_window == 1
    predict p if id == `i'
    replace predicted_return = p if id == `i' & event_window == 1
    drop p
}

//AR & CAR
sort id trddt
gen AR = dretwd - predicted_return if event_window == 1
bysort id: egen CAR = sum(AR)

//t-test
sort id trddt
by id: egen ar_sd = sd(AR) 
gen test =(1/sqrt(7))*(CAR/ar_sd) 
list stkcd group_id CAR test if dif == 0
reg CAR if dif==0, robust

save statadata/eventstudy1.dta, replace
log close
//t检验
keep if event_window == 1
bysort dif: ttest AR = 0
//好像事前的很显著，事后不显著
//画图
sort stkcd Evtday
keep if !missing(AR)
sort stkcd group_id trddt
collapse (mean) AR, by(dif)
graph twoway connected AR dif
graph save Graph F:/rumor/graph/澄清后1.gph
save f:/rumor/statadata/car1.dta

//误差图
keep if event_window == 1
collapse (mean) mean_AR = AR (sd) sd_AR = AR, by(dif)
serrbar mean_AR sd_AR dif

//
logit attitute AR if dif == 0 & AR < 0.4 //检验当日超额收益是不是传闻最终成真的有效预测变量

