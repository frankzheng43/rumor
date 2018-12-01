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