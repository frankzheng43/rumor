import delimited "raw\FS_Combas.txt", varnames(1) clear /// 财务报表数据
drop in 1/2
drop if typrep == "B"
**将会计期间改成日期格式
gen accper1 = date(accper,"YMD")
format accper1 %td
drop accper
rename accper1 accper
keep if month(accper) == 12
order accper, after(stkcd)
ds stkcd accper typrep, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
destring `x', gen(`x'1)
drop `x'
rename `x'1 `x'
}
}
save "statadata\02_firm_FS.dta", replace

*/权重数据
use "statadata\02_firm_FS.dta", clear
keep stkcd accper a001000000 a002000000 a0b1103000
rename a001000000 asset
rename a002000000 liability
rename a0b1103000 cash
gen lnasset = log(asset)
gen lev = liability/asset
save "statadata\02_firm_asset.dta", replace

use "statadata\02_firm_ROA", clear
merge 1:1 stkcd accper using "statadata\02_firm_asset.dta"
*/不匹配的基本都是2开头的B股 以及不在时间范围内的
keep if _merge == 3
collapse (mean) ROA [w=asset] , by(indcd year)
rename ROA ROA_ind
*计算前三年的行业波动率
rangestat (sd) ROA_ind, interval(year -3 -1) by(indcd)
save "statadata\02_industry_ROA.dta", replace

*行业年
use "statadata\02_industry_ROA.dta", clear
merge 1:1 indcd year using "statadata\01_rumor_yi.dta"
rename NO NO_ind
replace NO_ind = 0 if missing(NO_ind)
recode NO_ind ( 1 2 3 4 5 6 7 8 = 1), gen(NO_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgNO_ind = log(NO_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)
*/全部负向显著。。
reg lgNO_ind lgROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd_wins if year > 2006 & year < 2016
logit NO_ind_dum ROA_ind_sd if year > 2006 & year < 2016
save "statadata\03_industry_ROA_reg.dta", replace
// TODO here

*行业月
use "statadata/formerge_im.dta", clear
merge m:1 indcd year using "statadata\02_industry_ROA.dta"
drop _merge
merge 1:1 indcd year month using "statadata/01_rumor_mi.dta"
rename NO NO_ind
replace NO_ind = 0 if missing(NO_ind)
recode NO_ind ( 1 2 3 4 5 6 7 8 = 1), gen(NO_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgNO_ind = log(NO_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)
*/全部负向显著。。
reg lgNO_ind lgROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd_wins if year > 2006 & year < 2016
logit NO_ind_dum ROA_ind_sd if year > 2006 & year < 2016
save "statadata\03_industry_ROA_m_reg.dta", replace

*行业季度
use "statadata/formerge_iq.dta", clear
merge m:1 indcd year using "statadata\02_industry_ROA.dta"
drop _merge
merge 1:1 indcd year quarter using "statadata/01_rumor_qi.dta"
rename NO NO_ind
replace NO_ind = 0 if missing(NO_ind)
recode NO_ind ( 1 2 3 4 5 6 7 8 = 1), gen(NO_ind_dum)
winsor ROA_ind_sd, gen(ROA_ind_sd_wins) p(0.05)
gen lgNO_ind = log(NO_ind)
gen lgROA_ind_sd = log(ROA_ind_sd)
*/全部负向显著。。
reg lgNO_ind lgROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd if year > 2006 & year < 2016
reg NO_ind ROA_ind_sd_wins if year > 2006 & year < 2016
logit NO_ind_dum ROA_ind_sd if year > 2006 & year < 2016
save "statadata\03_industry_ROA_q_reg.dta", replace
