



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

*1.4公司地址变更数据
import delimited "raw\STK_ListedCoInfoChg.txt", varnames(1) encoding(UTF-16) stringcols(1) clear
drop securityid listedcoid v9 v10
rename symbol stkcd

local datevar announcementdate implementdate
foreach x of local datevar{
	gen `x'1 = date(`x',"YMD")
	format `x'1 %td
	drop `x'
	rename `x'1 `x'
	order `x',after(stkcd)
}
// keep if changeditem == "办公地址"
save "statadata\02_firm_loc.dta", replace

*1.5研发投入的数据
import delimited  "F:\rumor\raw\PT_LCRDSpending.txt" , varnames(1) encoding(UTF-8) clear
drop in 1/2
gen enddate1 = date( enddate ,"YMD")
format enddate1 %td
drop enddate 
rename enddate1 enddate 
keep if month( enddate ) == 12
rename symbol stkcd
order enddate ,after(stkcd)
drop if statetypecode == "2"
drop statetypecode
ds stkcd enddate currency explanation , not
foreach x of var `r(varlist)'{
capture confirm string var `x'
if _rc==0 {
destring `x', gen(`x'1)
drop `x'
rename `x'1 `x'
}
}

*1.6 ///违规数据（明细数据）
import delimited raw\STK_Violation_Son.txt, varnames(1) encoding(UTF-8) clear
drop in 1/2
drop if symbol == "刘凌云" | symbol == "吴翠华" | symbol == "黄学春"
rename symbol stkcd
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
drop `1' 
rename `1'1 `1' 
end
str_to_numeric disposaldate
drop if missing(stkcd)
*/// 去除string前后的空格
ds, has(type string)
foreach x of var `r(varlist)'{
	gen `x'1 = strltrim(`x')
	order `x'1, after(`x')
	drop `x'
	rename `x'1 `x'
}
*///字符格式转化为数值格式
destring penalty, gen(penalty1)
order penalty1, after(penalty)
drop penalty
rename penalty1 penalty
save statadata\02_firm_violation.dta, replace 

*///将明细表转化为总表（同义词处罚的合并成一条）
use statadata\02_firm_violation.dta, clear
sort violationid
egen violationidid = group(violationid)
bysort violationidid: gen seq = _n
keep if seq == 1
drop violationidid seq
save statadata\02_firm_violation_main.dta, replace

*2回归分析
*2.1.1ROA回归（公司年）
use "statadata\02_firm_ROA", clear
*/和rumor的数据进行合并
merge 1:1 stkcd year using "statadata\01_rumor_yf.dta"
replace NO = 0 if missing(NO)
recode NO ( 1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
*/构造是否出现丑闻的虚拟变量
winsor ROA_sd , gen(ROA_sd_wins) p(0.05)
*/显著，为正
reg NO ROA_sd_wins if year > 2006 & year < 2016
logit NO_dum ROA_sd_wins if year > 2006 & year < 2016

save "statadata\03_firm_ROA_reg.dta", replace

*2.1.2ROA回归（公司月）
use "statadata\02_firm_ROA.dta", clear
*/扩充样本，补间
*/https://www.statalist.org/forums/forum/general-stata-discussion/general/115594-expand-observations-and-assign-values-to-the-dupliates
expand 12
sort stkcd year
egen month=fill(1[1]12 1[1]12)
merge 1:1 stkcd year month using "statadata\01_rumor_mf.dta"
replace NO = 0 if missing(NO)
recode NO ( 1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
winsor ROA_sd , gen(ROA_sd_wins) p(0.05)
*/显著，为正
reg NO ROA_sd_wins if year > 2006 & year < 2016
logit NO_dum ROA_sd_wins if year > 2006 & year < 2016

save "statadata\03_firm_ROA_mf_reg.dta", replace

*2.1.3ROA回归（公司季度）
use "statadata\02_firm_ROA.dta", clear
expand 4
sort stkcd year
egen quarter=fill(1 2 3 4 1 2 3 4)
merge 1:1 stkcd year quarter using "statadata\01_rumor_qf.dta"
replace NO = 0 if missing(NO)
recode NO ( 1 2 3 4 5 6 7 8 = 1), gen(NO_dum)
winsor ROA_sd , gen(ROA_sd_wins) p(0.05)
*/显著，为正
reg NO ROA_sd_wins if year > 2006 & year < 2016
logit NO_dum ROA_sd_wins if year > 2006 & year < 2016
save "statadata\03_firm_ROA_qf_reg.dta", replace

*2.2高管更替回归
use "statadata\02_firm_turnover.dta", clear
collapse (count) edca, by(year stkcd month)
merge 1:1 stkcd year month using "statadata\01_rumor_mf.dta" //FIXME 配对的样本量太少，基本上无法回归
sort stkcd year month
save "statadata\03_firm_turnover_reg.dta", replace
