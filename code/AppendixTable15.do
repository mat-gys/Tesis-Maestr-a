global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\code"
global output "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\output"
cd "$main"

run clean_data.do

************ Dropping rounds affected by technical timeouts ************

sort matchID roundNum

bysort matchID: tab tech
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after_tto

egen after_tac_to = min(cond(ctTimeOut > 0 |tTimeOut > 0, roundNum, .)), by(matchID)
bysort matchID: keep if roundNum < after_tac_to
tab technicalTimeOut

* Dropping observations after non defined timeouts that weren't usual breaks
bysort matchID: tab tech
gen a = ((roundNum == 16 | roundNum == 31 | roundNum == 34 | roundNum == 37 | roundNum == 40 | roundNum == 43 | roundNum == 46 | roundNum == 49) & freezeTimeTotal > 2562 & nonDefinedTimeOut == 1)
egen after_nond_to = min(cond(a == 0 & nonD ==1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum < after_nond_to


set seed 9302022

gen indicator = (tech ==1)
local replace replace

foreach numb of numlist 1/9{
	gen random = runiform()
	sort indicator random
	generate insample = indicator & (_N - _n) <1
	
	preserve 
	
	keep if insample ~= 1
	
	xtreg y tto_time_actual lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	outreg2 using AppendixTable15, tex `replace' dec(4) ctitle("`title' `time'") keep(tto_time_actual win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, No) nocons nor stats(coef se pval) par(se) bracket(pval)
	
	restore
	
	replace indicator = 0 if insample == 1
	
	drop insample
	drop random
	local replace append
}