/* 控制变量：资金约束 */

// setups
clear all
set more off
eststo clear
capture version 14
local location "F:/rumor"
cd "`location'"
capt log close _all
log using logs/kz_index, name("kz_index") text replace

use statadata/02_firm_FS.dta, clear
tempfile firm_FS
save `firm_FS'

use statadata/02_firm_IS.dta, clear
tempfile firm_IS 
save `firm_IS'

use statadata/02_firm_CF.dta, clear
tempfile firm_CF
save `firm_CF'

use statadata/02_firm_TB.dta, clear
keep stkcd accper indcd f100902a
tempfile tobinq
save `tobinq'

use statadata/02_firm_info.dta,clear
keep stkcd estbdt
tempfile firm_info
save `firm_info'

use `firm_FS', clear
merge 1:1 stkcd accper using `firm_IS', gen(_mis)
merge 1:1 stkcd accper using `firm_CF', gen(_mcf)
merge 1:1 stkcd accper using `tobinq', gen(_mtb)
merge m:1 stkcd using `firm_info', gen(_minfo)
drop _m*
gen year = year(accper), after(accper)

gen cashflow = d000100000
gen k = a001212000
gen debt = a002100000 + a002206000
gen asset = a001000000
gen lnasset = log(asset)
gen total_capital = a002100000 + a002206000 + a001100000
gen dividend = a002115000
replace dividend = 0 if missing(dividend)
winsor2 dividend, replace cuts(5 95) label
recode dividend (0 = 0) (* = 1), gen(dividend_dum)
gen cash = a001101000 
gen tobinq = f100902a
gen age = (accper - estbdt)/365

gen sales = b001100000
egen id = group(stkcd)
xtset id year
gen sales_growth = (sales-l1.sales)/l1.sales
winsor2 sales_growth, replace cuts(5 95) label
bysort indcd: egen sales_growth_ind = mean(sales_growth)

// kz index
// Kaplan, S. N., and L. Zingales. “Do Investment-Cash Flow Sensitivities Provide Useful Measures of Financing Constraints?” 
// The Quarterly Journal of Economics 112, no. 1 (February 1, 1997): 169–215. https://doi.org/10.1162/003355397555163.
gen KZ = -1.001909 * cashflow/k + 0.2826389 * tobinq + 3.139193 * debt/total_capital - 39.3678 * dividend/k - 1.314759 * cash/k
// sa index 
// Hadlock, Charles J., and Joshua R. Pierce. “New Evidence on Measuring Financial Constraints: Moving Beyond the KZ Index.” 
// The Review of Financial Studies 23, no. 5 (May 1, 2010): 1909–40. https://doi.org/10.1093/rfs/hhq009.

gen SA = -0.737 * lnasset + 0.043 * lnasset^2 - 0.040 * age
//ww index 
//Whited, Toni M., and Guojun Wu. “Financial Constraints Risk.” 
//The Review of Financial Studies 19, no. 2 (July 1, 2006): 531–59. https://doi.org/10.1093/rfs/hhj012.

gen WW = -0.091 * cashflow/asset - 0.062 * dividend_dum + 0.021 * a002206000/asset - 0.044 * lnasset + 0.102 * sales_growth_ind - 0.035 * sales_growth

keep stkcd accper year age lnasset KZ SA WW 
local Constraints KZ SA WW 
foreach x of local Constraints {
	bysort year: egen median`x' = median(`x')
	gen `x'_dum = cond(`x' > median`x', 1, 0)
	replace `x'_dum = . if missing(`x')
	drop median`x'
}

sort stkcd year
drop if missing(accper)

label data "KZ_Index"

save statadata/kz_index.dta, replace

log close kz_index

