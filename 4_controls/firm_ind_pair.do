/* 公司-行业对照表 */
use "F:\rumor\statadata\02_firm.dta", replace
keep year stkcd indcd
save "F:\rumor\statadata\firm_ind_pair.dta"