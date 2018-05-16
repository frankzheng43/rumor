/**
 *
 * This code is used to templates in order that other datasets can be merged based on these templates
 * Author: Frank Zheng
 * Required data: 02_firm
 * Required code: Fin_Index
 * Required ssc : -
 */

// install missing ssc
 local sscname estout winsor2 
 foreach pkg of local sscname{
  cap which  `pkg'
  if _rc!=0{
        ssc install `pkg'
        }
 }

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:\rumor"
cd "`location'"
capt log close _all
log using logs\formerge, name("formerge") text replace

// import Fin_Index data 
use statadata\02_firm.dta, clear
tempfile Fin_Index
save `Fin_Index'

// firm-year
use `Fin_Index'
keep stkcd indcd year
sort stkcd indcd year
save statadata\formerge_y.dta, replace

// firm-quarter
use `Fin_Index'
keep stkcd indcd year
expand 4
sort stkcd year
egen quarter = fill(1[1]4 1[1]4)
save statadata\formerge_q.dta, replace

// firm-month
use `Fin_Index'
keep stkcd indcd year
// expand 12 times and generate month variable
expand 12
sort stkcd year
egen month = fill(1[1]12 1[1]12)
egen quarter = fill(1 1 1 2 2 2 3 3 3 4 4 4 1 1 1 2 2 2 3 3 3 4 4 4)
save statadata\formerge_m.dta, replace

// industry-year 的数据直接用firm-year的就可以。
// industry-quarter
use `Fin_Index'
keep stkcd indcd year
egen idindy = group(year indcd)
bysort idindy: gen seq = _n
keep if seq == 1
drop seq idindy
expand 4
sort indcd year
egen quarter = fill(1[1]4 1[1]4)
save statadata\formerge_iq.dta, replace
// industry-month
use `Fin_Index'
keep stkcd indcd year
// keep only one ovservation in every industry-year level
egen idindy = group(year indcd)
bysort idindy: gen seq = _n
keep if seq == 1
drop seq idindy
expand 12
sort indcd year
egen month = fill(1[1]12 1[1]12)
egen quarter = fill(1 1 1 2 2 2 3 3 3 4 4 4 1 1 1 2 2 2 3 3 3 4 4 4)
save statadata\formerge_im.dta, replace



log close formerge
