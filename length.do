clear
import excel "F:\rumor\code\12length.xlsx", sheet("file_name2") firstrow allstring

replace stkcd = substr(stkcd,2,7)

keep stkcd date_rumor length has_uncer

/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"MDY")
format `1'1 %td
order `1'1, after(`1')
local lab: variable label `1'
label var `1'1 `lab'
drop `1' 
rename `1'1 `1' 
end

str_to_numeric date_rumor 
gen year = year(date_rumor)
gen quarter = quarter(date_rumor)


ds length has_uncer
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		order `x'1, after(`x')
		drop `x'
		rename `x'1 `x'
		}
	}

collapse (mean) avelength = length (mean) aveuncer = has_uncer, by(stkcd year quarter)
gen lgavelength = log(avelength)
save "F:\rumor\statadata\length.dta", replace

use F:\rumor\statadata\03_macro_reg_qf.dta, clear
merge m:1 stkcd year quarter using "F:\rumor\statadata\length.dta", gen(_mlen)

sort id idquarter

eststo: reghdfe avelength policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.avelength policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe aveuncer policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.aveuncer policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
gen lgavelength = log(avelength)
gen lgaveuncer = log(aveuncer)

eststo: reghdfe l1.lgaveuncer policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.lgavelength policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)

winsor2  aveuncer avelength lgavelength lgaveuncer, suffix(_wins) cuts(5 95)
eststo: reghdfe l1.lgaveuncer_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.lgavelength_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.aveuncer_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)
eststo: reghdfe l1.avelength_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins if inrange(year,2007,2015), absorb(idind year) cluster(id)

reg l1.avelength_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins

scatter  lgavelength policy_uncertainty

* 不控制年份的话显著
reg l1.avelength_wins policy_uncertainty_w_wins lnasset_wins tobinq_wins lev_wins SA_wins i.idind

