*分析师跟踪数量 ==>衡量信息透明度
use "F:\rumor\statadata\ana_forcast.dta", clear
* 用报告公布日的年份而不是预测终止日的年份作为跟踪数量的年份
gen year1 = year(rptdt)
gen count1 = 1
collapse (count) numforecast = count1, by(stkcd year1)
tempfile numforecast
save `numforecast'

use "F:\rumor\statadata\ana_forcast.dta", clear
gen year1 = year(rptdt)
gen count1 = 1
collapse (count) numanalyst = count1, by(stkcd year1 ananmid)
collapse (count) numanalyst = numanalyst, by(stkcd year1)
tempfile numanalyst
save `numanalyst'

use `numforecast', clear
merge 1:1 stkcd year1 using `numanalyst', gen(_mnum)

drop _m*

gen analyst_follow = log(numforecast/numanalyst + 1)
rename year1 year
save "F:\rumor\statadata\ana_follow.dta", replace