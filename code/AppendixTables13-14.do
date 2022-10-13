global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\codigo"
cd "$main"

run clean_data.do

cd "$output"

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


******************************** Appendix Tables 12 - 13 ******************************

preserve
local replace replace
local tacticals win_time_out loss_time_out
local Yes Yes

forval j = 1/2{

	****************** Number of matches and observations ******************
	
	codebook ID
	di _N

	************************* Intensive regression *************************
	
	xtreg y tto_time lag_cum_win `tacticals' win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	display _b[tto_time] * 30
	* a round after a 30 second timeout is 1.5 percentage points more likely to revert the previous round winner
	outreg2 using AppendixTable13, tex `replace' dec(4) ctitle(Intensive) keep(technicalTimeOut tto_time win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval) sortvar(technicalTimeOut tto_time win_time_out loss_time_out)
	*outreg2 using main_reg, tex append dec(3) ctitle(Intensive) keep(tto_time lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash) label addtext(Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se pval) par(se) bracket(pval)
	
	
	bysort matchID: keep if roundNum < after_tac_to
	local tacticals
	local Yes No
	local replace append

}

restore


local replace replace
local placebo placebo
local time "time > 0"
local title "Timeout = 1 if"
local tacticals win_time_out loss_time_out
local Yes Yes
preserve
forval j = 1/4{

	****************** Number of matches and observations ******************
	
	codebook ID
	di _N
	
	
	if `j' == 2 | `j' == 4{
		local replace append
		replace technicalTimeOut = 0 if tto_time < 30 & tto_time > 0
		local time "time > 30"
	}

	if `j' == 3{
		local time "time > 0"
		restore
		bysort matchID: keep if roundN < after_tac_to
		bysort matchID: keep if roundNum < after_tac_to
		local tacticals
		local Yes No
	}
	
************************* Extensive regression *************************
xtreg y technicalTimeOut lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
outreg2 using AppendixTable14, tex `replace' dec(4) ctitle("`title' `time'") keep(technicalTimeOut win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval)


local title ""


}