/* 传闻的具体数据，比如字数，是否包含数字等 */

import excel "F:\rumor\collect\20181121rumor_check.xlsx", sheet("sample2.1（整理完澄清部分）") firstrow allstring

drop A*
drop time1 target2 number1

/* 有多少样本是被同一个人做了两次的？*/
count if sample1 != sample2
count

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"DMY")
format `1'1 %td
order `1'1, after(`1')
local lab: variable label `1'
label var `1'1 `lab'
drop `1' 
rename `1'1 `1' 
end

str_to_numeric date_cla
str_to_numeric date_rumor

gen year = year(date_rumor)
gen quarter = quarter(date_rumor)
gen month = month(date_rumor)

*全部的字符串变量都去掉空格
quietly ds, has(type string)
foreach x of var `r(varlist)'{
    replace `x' = usubinstr(`x', " ","",.)
}

*全部tab一下看分布
ds 
foreach x of var `r(varlist)'{
    tab `x'
}

quietly ds No sample1 sample2 nature time target number expertise fs analyst manager worker survey single focus background stock
foreach x of var `r(varlist)'{
    * count if missing(`x')
    destring `x', replace
}

* 有多少的传闻没有找到
* edit if missing( article_rumor )

save "F:\rumor\statadata\creditworth.dta"

drop if missing( article_rumor )&(missing(time)|missing( target)|missing( number)|missing( expertise)|missing( analyst)|missing( fs)|missing(manager)|missing(worker)|missing(survey)|missing(single)|missing(focus)|missing(background)|missing(stock))

save "F:\rumor\statadata\creditworth_nmiss.dta"


quietly ds time target number expertise analyst fs manager worker survey single focus background stock 
foreach x of var `r(varlist)'{
    replace `x' = 0 if missing(`x')
}

gen year = year(date_rumor)
gen month = month(date_rumor)
gen quarter = quarter(date_rumor)

* 生成 trustworthiness 的三个维度
gen detail_score = time + target + number
gen authority_score = expertise + analyst + fs + manager + worker + survey
gen completeness_score = single + focus + background + stock


save "F:\rumor\statadata\creditworth_nmiss_r.dta", replace

collapse (mean) detail_score (mean) authority_score (mean) completeness_score, by(stkcd year)
save "F:\rumor\statadata\score_y.dta", replace

collapse (mean) detail_score (mean) authority_score (mean) completeness_score, by(stkcd year quarter)
save "F:\rumor\statadata\score_q.dta", replace

collapse (mean) detail_score (mean) authority_score (mean) completeness_score, by(stkcd year month)
save "F:\rumor\statadata\score_m.dta", replace

* 只包含时间下标
collapse (mean) detail_score (mean) authority_score (mean) completeness_score, by(year quarter)
drop _merge
egen idquarter = group(year quarter)
tsset idquarter
twoway line detail_score authority_score completeness_score idquarter
merge 1:1 year quarter using F:\rumor\statadata\02_macro_q_w.dta

twoway (line detail_score authority_score completeness_score idquarter ,yaxis(1)) (line ChinaNewsBasedEPU idquarter ,yaxis(2)) 
reg detail_score ChinaNewsBasedEPU
reg authority_score ChinaNewsBasedEPU
reg completeness_score ChinaNewsBasedEPU

tempvar median mean
egen `median' = median(ChinaNewsBasedEPU)
egen `mean' = mean(ChinaNewsBasedEPU)
tempvar group_ChinaNewsBasedEPU group_ChinaNewsBasedEPU_mean
gen `group_ChinaNewsBasedEPU' = cond(ChinaNewsBasedEPU> `median', 1, 0)
gen `group_ChinaNewsBasedEPU_mean' = cond(ChinaNewsBasedEPU > `mean', 1, 0)
ttest detail_score, by(`group_ChinaNewsBasedEPU')
ttest detail_score, by(`group_ChinaNewsBasedEPU_mean')
ttest authority_score, by(`group_ChinaNewsBasedEPU')
ttest authority_score, by(`group_ChinaNewsBasedEPU_mean') 
ttest completeness_score, by(`group_ChinaNewsBasedEPU')
ttest completeness_score, by(`group_ChinaNewsBasedEPU_mean')

save "F:\rumor\statadata\score_1.dta", replace