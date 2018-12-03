/* 分析师预测 */
import delimited F:\rumor\raw\AF_Forecast.txt, varnames(1) encoding(UTF-8)

// https://www.stata.com/statalist/archive/2011-09/msg01109.html
// label variables with the first row
foreach var of varlist * {
  label variable `var' "`=`var'[1]'"
}
drop in 1/2
drop if inlist(substr(stkcd,1,1),"2","3","9")

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

str_to_numeric rptdt fenddt


/**convert string to numeric, 
source: https://www.stata.com/statalist/archive/2004-05/msg00297.html*/
ds rptdt fenddt ananmid ananm reportid institutionid brokern stkcd, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		order `x'1, after(`x')
		drop `x'
		rename `x'1 `x'
		}
	}

save "F:\rumor\statadata\ana_forcast.dta"

gen year = year(fenddt)
label var year "年份"
order year stkcd reportid rptdt

/* 多个分析师共同撰写，仅取第一作者 */
/* 需要重复多次 */
replace ananmid = ustrregexrf(ananmid,", [0-9]*", "")
replace ananmid = ustrregexrf(ananmid,", [0-9]*", "")
replace ananmid = ustrregexrf(ananmid,", [0-9]*", "")
replace ananmid = ustrregexrf(ananmid,", [0-9]*", "")
replace ananmid = ustrregexrf(ananmid,", [0-9]*", "")

/* 分析师代码没有，名字也没用，没救了 */
drop if missing(ananmid)

gsort  stkcd year -rptdt ananmid

duplicates drop stkcd year ananmid, force

rangestat (sd) feps (mean) feps, interval(year 0 0) by(stkcd)
/* 分析师盈余预测分散程度 */
gen dispersion_a = feps_sd/abs(feps_mean)

/* 回归用分析师数据 */
duplicates drop stkcd year, force
keep stkcd year dispersion_a
save "F:\rumor\statadata\ana_forecast_formerge.dta"