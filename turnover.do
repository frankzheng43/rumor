// TODO 如果可以补间的话可以试试
*1.2高管更替数据（无用）
import delimited "raw\TMT_Position.txt", varnames(1) encoding(UTF-8) clear

local datevar reptdt startdate //改为日期格式
foreach x of local datevar{
	gen `x'1 = date(`x',"YMD")
	format `x'1 %td
	drop `x'
	rename `x'1 `x'
	order `x',after(stkcd)
}
gen year_string = substr(enddate,1,4)
destring year_string, gen(endyear) force
drop year_string
save "statadata\02_firm_board.dta", replace

*1.3高管更替数据
import delimited raw\CG_Ceo.csv, varnames(1) encoding(UTF-16) stringcols(1) clear
drop v19 v20 v21
local datevar annodt chgdt
foreach x of local datevar{
	gen `x'1 = date(`x',"YMD")
	format `x'1 %td
	drop `x'
	rename `x'1 `x'
	order `x',after(stkcd)
}
destring years, replace force
gen month = month(annodt)
gen year = year(annodt)
save "statadata\02_firm_turnover.dta", replace
