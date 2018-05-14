/**
 * 本代码用于进行各类统计图的制作
 */

local location "F:/rumor"
cd "`location'"
clear all
set more off
capt log close
log using rumor, text replace
use statadata/01_rumor.dta, clear
gen year_Evntdate = year(Evntdate_workday)
gr bar (count), over(year_Evntdate ) title ("传闻样本的年代分布") ytitle ("样本数量")
//gr save graph/rumor_byyear
gr export graph/rumor_byyear.png

use statadata/02_firm.dta, clear
keep stkcd accper typrep indcd
egen id = group( stkcd)
bysort id: gen seq = _n
keep if seq == 1
keep stkcd indcd
save statadata/temp.dta, replace

use statadata/01_rumor.dta, clear
merge m:1 stkcd using statadata/temp.dta
drop if missing( Evntdate)
drop _merge
gen indcd_r = substr(indcd, 1, 1)
estpost tab indcd_r, sort
esttab . using tables/ex.rtf, cells("b pct(label("比例") fmt(2)) cumpct(fmt(2))") noobs replace

use statadata\02_firm_RD.dta, clear
hist rdspendsumratio, title("研发费用占总销售的分布") ytitle("样本数量")
gr export graph/rumor_RDratio.png
