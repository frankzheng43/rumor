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

save "F:\rumor\statadata\creditworth_nmiss_r.dta"