global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\code"
global output "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\output"
cd "$main"

run Table6.do

drop if tto_time_actual < 30 & tto_time_actual > 0

set seed 9302022

gen indicator = (tech ==1)
local replace replace

foreach numb of numlist 1/6{

	gen random = runiform()
	sort indicator random
	generate insample = indicator & (_N - _n) <1
	
	preserve 
	
	keep if insample ~= 1
	
	xtreg y tto_time_actual lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	outreg2 using Table11, tex `replace' dec(4) ctitle("`title' `time'") keep(tto_time_actual win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, No) nocons nor stats(coef se pval) par(se) bracket(pval)
	
	xtreg y technicalTimeOut lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
	outreg2 using Table12, tex `replace' dec(4) ctitle("`title' `time'") keep(technicalTimeOut win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes, Round after tactical timeout included, No) nocons nor stats(coef se pval) par(se) bracket(pval)
	
	restore
	
	replace indicator = 0 if insample == 1
	
	drop insample
	drop random
	local replace append
}
