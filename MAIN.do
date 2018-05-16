/**
 *
 * This code is the control panel of other codes
 *
 */

 // install missing ssc
 local sscname estout winsor2 rangstat
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

