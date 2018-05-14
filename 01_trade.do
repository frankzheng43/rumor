/**
   交易数据的处理
 */
 import delimited "raw\TRD_Dalyr.txt", varnames(1) clear
 drop in 1/2
 gen trddt1 = date(trddt,"YMD")
 format trddt1 %td
 drop trddt
 rename trddt1 trddt
 order trddt, after(stkcd)
 gen year = year(trddt)
 keep if year > 2000 & year < 2018
 gen capchgdt1 = date(capchgdt,"YMD")
 format capchgdt1 %td
 drop capchgdt
 rename capchgdt1 capchgdt
 ds stkcd trddt capchgdt, not
 foreach x of var `r(varlist)'{
 	capture confirm string var `x'
 	if _rc==0 {
 destring `x', gen(`x'1)
 drop `x'
 rename `x'1 `x'
 }
 }
keep if markettype == 1 | markettype ==4
save statadata\02_trddta.dta, replace
