global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\code"
global output "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\output"
cd "$main"

run clean_data.do

cd"$output"



********* Testing for cheating and frustration (Tables 1 and 2) *********

qui tabstat t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if ct_tto == 0, save statistics(mean sd) columns(statistics)
matrix A=r(StatTotal)

qui tabstat t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if ct_tto == 1, save statistics(mean sd) columns(statistics)
matrix B=r(StatTotal)

matrix C = A',B'
matrix list C


local list t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash
local i 1
matrix D = J(9, 1, 0)
matrix E = J(9, 1, .)
foreach var in `list'{
	ttest `var', by(ct_tto)
	matrix D[`i', 1] = r(p)
	local i = `i' + 1
}

matrix C = C, D, E


summ ct_tto
frmttable using Table1, varlabels statmat(C) substat(1) sdec(2,2,2,2, 3) ctitles("Variable name", "Mean team A timeout = 0", "Mean team A timeout = 1", "P-value mean-comparison test") replace tex note("Notes: Number of team A technical timeouts recorded: `r(sum)'. Standard errors in parenthesis.")


qui tabstat ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if t_tto == 0, save statistics(mean sd) columns(statistics)
matrix A=r(StatTotal)

qui tabstat ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if t_tto == 1, save statistics(mean sd) columns(statistics)
matrix B=r(StatTotal)

matrix C = A',B'
matrix list C

local list ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash
local i 1
matrix D = J(9, 1, 0)
matrix E = J(9, 1, .)
foreach var in `list'{
	ttest `var', by(t_tto)
	matrix D[`i', 1] = r(p)
	local i = `i' + 1
}

matrix C = C, D, E

summ t_tto
frmttable using Table2, varlabels statmat(C) substat(1) sdec(2,2,2,2) ctitles("Variable name", "Mean team B timeout = 0", "Mean team B timeout = 1", "P-value mean-comparison test") replace tex note("Notes: Number of team B technical timeouts recorded: `r(sum)'. Standard errors in parenthesis.")


************ Dropping rounds affected by technical and tactical timeouts ************

sort matchID roundNum

bysort matchID: tab tech
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after_tto

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

**************************** Summary statistic (Table 3) ****************************

tabstat technicalTimeOut tto_time_a lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash, save statistics(mean sd min max) columns(statistics)
matrix stats = r(StatTotal)
matrix stats = stats'
frmttable using Table3, varlabels tex statmat(stats) sdec(3,3,3,3) ctitles("Variable name","Mean", "SD", "Minimum","Maximum") replace 