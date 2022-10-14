global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\code"
global output "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\output"
cd "$main"

run clean_data.do

cd"$output"

************ Dropping rounds affected by technical and tactical timeouts ************

sort matchID roundNum

bysort matchID: tab tech
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after_tto

* Checking that most observations where nonDefinedTimeOut = 1 are just because of usual breaks in matches
gen a = ((roundNum == 16 | roundNum == 31 | roundNum == 34 | roundNum == 37 | roundNum == 40 | roundNum == 43 | roundNum == 46 | roundNum == 49) & freezeTimeTotal > 2562 & nonDefinedTimeOut == 1)
tab a nonD

sort matchID roundNum

egen after_tac_to = min(cond(ctTimeOut > 0 |tTimeOut > 0, roundNum, .)), by(matchID)
bysort matchID: keep if roundNum <= after_tac_to
tab technicalTimeOut

* Dropping observations after non defined timeouts that weren't usual breaks
bysort matchID: tab tech
egen after_nond_to = min(cond(a == 0 & nonD ==1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum < after_nond_to


************************************* Table 4 *************************************

local replace replace
local placebo placebo
local Yes Yes
local tacticals win_time_out loss_time_out

forval j = 1/2{
	
	************************* Extensive regression *************************
	xtreg y technicalTimeOut lag_cum_win `tacticals' win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	outreg2 using Table4, tex `replace' dec(4) ctitle(Extensive) keep(technicalTimeOut win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval) sortvar(technicalTimeOut tto_time_a win_time_out loss_time_out)
	
	
	************************* Intensive regression *************************
	
	xtreg y tto_time_actual lag_cum_win `tacticals' win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	display _b[tto_time_a] * 30
	* a round after a 30 second timeout is 1.5 percentage points more likely to revert the previous round winner
	outreg2 using Table4, tex append dec(4) ctitle(Intensive) keep(tto_time_a win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval) sortvar(technicalTimeOut tto_time_a win_time_out loss_time_out)
	
	local replace append
	************** Dropping the round after tactical timeouts *************
	
	if `j' == 1{
		bysort matchID: keep if roundNum < after_tac_to
		local tacticals
	}

}