local files: dir "F:/rumor/raw/guba" files "*.xlsx"
dis `files'
foreach i in `files'{
    clear
    import excel "F:/rumor/raw/guba/`i'", firstrow allstring
    drop in 1 
    save "F:/rumor/raw/guba/`i'.dta", replace
}

foreach i in `files'{
    append using "F:/rumor/raw/guba/`i'.dta"
}

duplicates drop _all , force
rename Scode stkcd
/** This program is used to convert string date to numeric date*/
capture program drop str_to_numeric
program str_to_numeric
gen `1'1 = date( `1' ,"YMD")
format `1'1 %td
order `1'1, after(`1')
local lab: variable label `1'
label var `1'1 `lab'
drop `1' 
rename `1'1 `1' 
end

str_to_numeric Date

quietly ds Scode Date, not
foreach x of var `r(varlist)'{
	capture confirm string var `x'
	if _rc==0 {
		destring `x', gen(`x'1)
		order `x'1, after(`x')
		drop `x'
		rename `x'1 `x'
		}
	}

gen year = year(Date)
gen month = month(Date)
gen quarter = quarter(Date)

egen idquarter = group(year quarter)

save "F:\rumor\statadata\guba.dta"

collapse (mean) Tpostnum (mean) Pospostnum (mean) Negpostnum (mean) Neupostnum (mean) Readnum (mean) Commentnum, by (stkcd year quarter)
save "F:\rumor\statadata\guba_qm.dta"

collapse (mean) Tpostnum (mean) Pospostnum (mean) Negpostnum (mean) Neupostnum (mean) Readnum (mean) Commentnum, by (stkcd year quarter)
twoway line Readnum idquarter

merge 1:1 year quarter using F:\rumor\statadata\02_macro_q_w.dta
twoway (line l1.Readnum idquarter, yaxis(1)) (line ChinaNewsBasedEPU_w idquarter, yaxis(2))
gen lgChinaNewsBasedEPU = log(ChinaNewsBasedEPU)
gen lgReadnum = log(Readnum)

reg l1.Readnum ChinaNewsBasedEPU
save "F:\rumor\statadata\guba_q.dta"