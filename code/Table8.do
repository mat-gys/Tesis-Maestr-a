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



drop if tto_time_a < 30 & tto_time_a > 0

************************* Table 8 *************************
gen tto_time_actual_sq = tto_time_actual ^2
label var tto_time_actual_sq "Duration (s) of technical timeout ^2"
gen tto_time_actual_three = tto_time_actual ^3
label var tto_time_actual_three "Duration (s) of technical timeout ^3"

preserve
local replace replace
local techs tto_time_actual tto_time_actual_sq
local Yes Yes
forval j = 1/4{

	****************** Number of matches and observations ******************
	
	codebook ID
	di _N
	
	
	if `j' == 2 | `j' == 4{
		local replace append
		local techs tto_time_actual tto_time_actual_sq tto_time_actual_three
	}
	
	if `j' == 3{
		restore
		local techs tto_time_actual tto_time_actual_sq
		drop if tto_time_actual > 300
		local Yes No
	}

	
************************* Extensive regression *************************
xtreg y `techs' win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
outreg2 using Table8, tex `replace' dec(4) ctitle("`title' `time'") keep(tto_time_actual tto_time_actual_sq tto_time_actual_three) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, Yes, Includes duration outlier, `Yes') nocons nor stats(coef se pval) par(se) bracket(pval) sortvar(tto_time_actual tto_time_actual_sq tto_time_actual_three)

}