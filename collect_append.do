clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all

forvalues i = 1/11{
    import excel "F:\rumor\collect\collect_result\rumor (`i').xlsx", sheet("Sheet1") firstrow clear
    tempfile rumor`i'
    save `rumor`i''
}

use `rumor1', clear
forvalues i=2/11{
	append using `rumor`i'',force
	}

drop A N O P Q R

export excel using "F:\rumor\collect\collect_result\collect_full.xls", sheetreplace firstrow(variables)
save "F:\rumor\collect\collect_result\collect_full.dta"