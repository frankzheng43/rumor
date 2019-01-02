* 分年份和分行业的传闻数目统计图
tab year
tab indcd
logout, save(mfile) word replace: tab indcd
logout, save(mfile) word replace: tab year


* 季度的政策不确定性和传闻数量的图
use "F:\rumor\statadata\01_rumor_q.dta" 
merge 1:1 year quarter using  "F:\rumor\statadata\02_macro_q_w.dta"
keep if _merge ==3
egen idquarter = group(year quarter)
tsset idquarter
twoway line ChinaNewsBasedEPU ChinaNewsBasedEPU_w NO idquarter
twoway line ChinaNewsBasedEPU  NO idquarter