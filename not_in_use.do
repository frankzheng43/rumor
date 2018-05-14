/*暂时不用*/
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
