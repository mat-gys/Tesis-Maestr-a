global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files"
global code "$main\\code"
global output "$main\\output"
cd "$code"

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


************************************* Tables 6 and 7 *************************************


local replace replace
local placebo placebo
local time "time > 0"
local title "Timeout = 1 if"
local Yes Yes
local tacticals win_time_out loss_time_out
preserve
forval j = 1/4{

	****************** Number of matches and observations ******************
	
	codebook ID
	di _N
	
	
	if `j' == 2 | `j' == 4{
		drop if tto_time_a < 30 & tto_time_a > 0
		local time "time > 30"
	
		xtreg y technicalTimeOut#i.lag_cum_win i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
outreg2 using Table7, tex `replace' dec(4) ctitle("`title' `time'") keep(technicalTimeOut#lag_cum_win win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval)
	
		local replace append
		
	}

	if `j' == 3{
		local time "time > 0"
		restore
		bysort matchID: keep if roundNum < after_tac_to
		local Yes No
		local tacticals 
	}
	
************************* Extensive regression *************************
xtreg y technicalTimeOut i.lag_cum_win `tacticals' win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
outreg2 using Table6, tex `replace' dec(4) ctitle("`title' `time'") keep(technicalTimeOut win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval)


local title ""


}