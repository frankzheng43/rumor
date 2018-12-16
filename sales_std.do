 /* 销售收入波动率 */
 /* 申慧慧，. 环境不确定性对盈余管理的影响[J]. 审计研究, 2010(01): 89–96.
    林钟高, 郑军, 卜继栓，. 环境不确定性、多元化经营与资本成本[J]. 会计研究, 2015(02): 36-43+93.
    申慧慧, 吴联生, 肖泽忠. 环境不确定性与审计意见:基于股权结构的考察[J]. 会计研究, 2010(12): 57–64.
 */

use "F:\rumor\statadata\02_firm_IS.dta", clear
keep b001100000 accper stkcd
rename b001100000 sales
gen year = year(accper)
drop accper
save "F:\rumor\statadata\sale_std.dta"

merge 1:1 year stkcd using "F:\rumor\statadata\firm_ind_pair.dta"

egen id =  group(stkcd)
bysort  id : replace indcd = indcd[_n-1] if missing(indcd)
bysort  id : replace indcd = indcd[_n+1] if missing(indcd)

drop if _merge != 3
drop _m*

/* 主要参考 申慧慧, 吴联生, 肖泽忠. 环境不确定性与审计意见:基于股权结构的考察[J]. 会计研究, 2010(12): 57–64.
 */
rangestat (sd) sales (mean) sales, interval(year -4 0) by(stkcd)
tempvar cv_z median 
gen `cv_z' = sales_sd/sales_mean
bysort indcd: egen `median' = median(`cv_z')
gen sales_std = `cv_z'/`median'
winsor2 sales_std, cuts(1 99) label
sort stkcd year

save "F:\rumor\statadata\sale_std.dta"


