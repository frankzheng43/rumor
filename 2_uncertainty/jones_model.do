* 修正的琼斯模型计算
* https://stata-club.github.io/stata_article/2017-05-23.html
clear all
set more off
eststo clear
capture version 14
local location F:/rumor
cd "`location'"
capt log close _all
log using logs/jones, name("jones") text replace

* 资产负债表
use "F:\rumor\statadata\02_firm_FS.dta"
* 合并 利润表
merge 1:1 stkcd accper using "F:\rumor\statadata\02_firm_IS.dta", gen(_minc)
* 合并 现金流量表
merge 1:1 stkcd accper using "F:\rumor\statadata\02_firm_CF_d.dta", gen(_mcash)
drop _m*

gen year = year(accper)

egen id = group(stkcd)
order id year, after(stkcd)
tsset id year

rename b001100000 S
label var S "营业收入"  
rename a001111000 R
label var R "应收账款"
rename a001212000 PPE
label var PPE "固定资产"
rename a001000000 A
label var A "账面资产"
rename b002000000 NI
label var NI  "净收入"
rename c001000000 CFO
label var CFO "经营现金流量"



gen Delta_S=d.S
label var Delta_S "营业收入增量"
gen Lag_A=l.A
label var Lag_A "去年的账面资产"
gen Delta_R=d.R
label var Delta_R "应收账款增量"
gen TA=NI-CFO
label var TA "总应计项目"
gen A1=1/l.A 
replace TA=TA/l.A  
replace Delta_S=Delta_S/l.A
replace Delta_R=Delta_R/l.A
gen RVC=Delta_S-Delta_R
label var RVC "营业收入增量减去应收账款增量然后除以滞后一期的账面资产"
replace PPE=PPE/l.A

merge m:1 stkcd year using "F:\rumor\statadata\firm_ind_pair.dta",gen(_mind)
drop _m*
keep stkcd year indcd Delta_S PPE A Lag_A Delta_R TA A1 RVC
drop if missing(indcd)|TA==.|A1==.|Delta_S==.|PPE==.|RVC==.
save "F:\rumor\statadata\DA.dta", replace 

* 使用statsby命令进行公式1b的分组回归，并输出各年份行业的回归系数
statsby _b,by(year indcd) clear :reg  TA A1 Delta_S PPE
merge 1:m year ind using "F:\rumor\statadata\DA.dta"
drop _m* 
* 根据公式1a拟合出合理的应计项目规模
gen NDA=_b_cons+_b_A1*A1+_b_Delta_S*RVC+_b_PPE*PPE
* 根据公式1c计算可操控应计项目
gen DA=TA-NDA