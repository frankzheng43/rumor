/* 暂时不用 */
forvalues i=2007/2015{
	use "F:\rumor\00raw_`i'.dta", clear
	capture confirm string var Evtday
	if _rc==0 {
gen Evtday1 = date(Evtday,"DMY")
format Evtday1 %td
drop Evtday
rename Evtday1 Evtday
}
save "F:\rumor\00raw_`i'.dta", replace
	}
///暂时不用 取各三年的lag
local roa f050201b f050202b f050203b f050204c
foreach x of local roa{
	forvalues i = 1/3{
		gen `x'`i' = `x'[_n-`i']
	}
}

capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end

// 循环做各种回归
local yvar NO NO_dum
forvalues i = 1/4{
	foreach x of local yvar{
		eststo: quietly xtreg l`i'.`x' lgChinaNewsBasedEPU_wins `CV' i.year i.idind if year > 2006 & year < 2016, fe vce(robust)
	}
}


//violation的数据处理
use statadata/02_firm_violation_main.dta, clear
gen year = year(disposaldate)
gen month = month(disposaldate)
gen quarter = quarter(disposaldate)
order year month quarter, after(stkcd)
// 由于是月度数据，可以合并到年/季度/月份，因此先保存等后续使用
tempfile violation
save `violation'
// 月度数据
use `violation'
collapse (count) penalty, by(stkcd year quarter month)
sort stkcd year quarter month
rename penalty vio_count
label var vio_count "the number of violation"
tempfile violation_m
save `violation_m'
//季度数据
use `violation'
collapse (count) penalty, by(stkcd year quarter)
sort stkcd year quarter 
rename penalty vio_count
label var vio_count "the number of violation"
tempfile violation_q
save `violation_q'
//年度数据
use `violation'
collapse (count) penalty, by(stkcd year)
sort stkcd year
rename penalty vio_count
label var vio_count "the number of violation"
tempfile violation_y
save `violation_y'