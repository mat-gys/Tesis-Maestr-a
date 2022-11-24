global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files"
global code "$main\\code"
global output "$main\\output"
cd "$code"

run clean_data.do

cd"$output"

// drop if tto_time > 600

************ Dropping rounds affected by technical and tactical timeouts ************

sort matchID roundNum

bysort matchID: tab tech
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after_tto

* Checking that most observations where nonDefinedTimeOut = 1 are just because of usual breaks in matches
gen a = ((roundNum == 16 | roundNum == 31 | roundNum == 34 | roundNum == 37 | roundNum == 40 | roundNum == 43 | roundNum == 46 | roundNum == 49) & freezeTimeTotal > 2562 & nonDefinedTimeOut == 1)
tab a nonD

sort matchID roundNum

drop if tto_time_a < 30 & tto_time_a > 0


egen after_tac_to = min(cond(ctTimeOut > 0 |tTimeOut > 0, roundNum, .)), by(matchID)
bysort matchID: keep if roundNum <= after_tac_to
tab technicalTimeOut

* Dropping observations after non defined timeouts that weren't usual breaks
bysort matchID: tab tech
egen after_nond_to = min(cond(a == 0 & nonD ==1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum < after_nond_to


************************************* Placebos *************************************

*************** Placebo test with previous rounds ***************

local replace replace
local placebo placebo
local tacticals win_time_out loss_time_out
local table Table11
local Yes Yes

forval j = 1/2{

	preserve
	local replace replace
	forval i = 1/3{
	* Dropping rounds that whould make the timeout change game
	drop if technicalTimeOut ==1 & roundNum == `i' + 1
	
	gen tech_time_out_neg_`i' = technicalTimeOut[_n + `i']
	label var tech_time_out_neg_`i' "`i' round lead technical timeout"
	
	xtreg y tech_time_out_neg_`i' `tacticals' i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	
	outreg2 using `table', tex `replace' dec(4) ctitle(Extensive (time > 30)) keep(tech_time_out_neg_`i' `tacticals') label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval) sortvar(tech_time_out_neg_1 tech_time_out_neg_2 tech_time_out_neg_3 win_time_out loss_time_out)
	
	local replace append
}
	restore
	
	if `j' == 1{
		bysort matchID: keep if roundNum < after_tac_to
		local Yes No
		local tacticals
		local table Table12
	}

}	