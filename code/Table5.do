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

* Dropping rounds in which a technical timeout happened but I couldn't determine which team (previous round winner or loser) called it
drop if technicalTimeOut == 1 & (win_tech_timeout == 0 & loss_tech_timeout == 0)

************************************* Table 4 *************************************

local replace replace
local placebo placebo
local Yes Yes
local tacticals win_time_out loss_time_out

forval j = 1/2{
	
	if `j' == 2{
		local replace append
		local Yes No
		local tacticals
	}
	
	************************* Extensive regression *************************
	xtreg y win_tech_timeout loss_tech_timeout lag_cum_win `tacticals' win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	outreg2 using Table5, tex `replace' dec(4) ctitle(Extensive) keep(win_tech_timeout loss_tech_timeout win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval) sortvar(win_tech_timeout loss_tech_timeout win_tech_timeout_time loss_tech_timeout_time win_time_out loss_time_out)
	
	
	************************* Intensive regression *************************
	
	xtreg y win_tech_timeout_time loss_tech_timeout_time lag_cum_win `tacticals' win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	outreg2 using Table5, tex append dec(4) ctitle(Intensive) keep(win_tech_timeout_time loss_tech_timeout_time win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval) sortvar(win_tech_timeout loss_tech_timeout win_tech_timeout_time loss_tech_timeout_time win_time_out loss_time_out)
	
	
	************** Dropping round afected by tactical timeouts *************
	
	if `j' == 1{
		bysort matchID: keep if roundNum < after_tac_to
	}

}