global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\codigo"
global output "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\output"
cd "$main"

run clean_data.do

cd"$output"

sort matchID roundNum

bysort matchID: tab tech
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after_tto

gen a = ((roundNum == 16 | roundNum == 31 | roundNum == 34 | roundNum == 37 | roundNum == 40 | roundNum == 43 | roundNum == 46 | roundNum == 49) & freezeTimeTotal > 2562 & nonDefinedTimeOut == 1)


local sample 4_full
forval j = 1/2 {

qui tabstat lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if tech == 0, save statistics(mean sd) columns(statistics)
matrix A=r(StatTotal)

qui tabstat lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if tech == 1, save statistics(mean sd) columns(statistics)
matrix B=r(StatTotal)

matrix C = A',B'
matrix list C

local list lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash
local i 1
matrix D = J(8, 1, 0)
foreach var in `list'{
	ttest `var', by(tech)
	matrix D[`i', 1] = r(p)
	local i = `i' + 1
}

matrix C = C, D

frmttable using Table`sample', varlabels statmat(C) sdec(2,2,2,2, 3) ctitles("Variable name", "Technical timeout = 0", "Standard deviation" , "Technical timeout = 1", "Standard deviation", "P-value mean-comparison test") replace tex 

if `j' == 1{
	egen after_tac_to = min(cond(ctTimeOut > 0 |tTimeOut > 0, roundNum, .)), by(matchID)
	bysort matchID: keep if roundNum <= after_tac_to
	tab technicalTimeOut
	
	* Dropping observations after non defined timeouts that weren't usual breaks
	bysort matchID: tab tech
	egen after_nond_to = min(cond(a == 0 & nonD ==1, roundNum, .)), by(matchID)  
	bysort matchID: keep if roundNum < after_nond_to
}

local sample 5_restricted

}

qui tabstat ct_eqvalstart t_eqvalstart if tech == 0, save statistics(mean sd) columns(statistics)
matrix A=r(StatTotal)

qui tabstat ct_eqvalstart t_eqvalstart if tech == 1, save statistics(mean sd) columns(statistics)
matrix B=r(StatTotal)

matrix C = A',B'
matrix list C

local list ct_eqvalstart t_eqvalstart
local i 1
matrix D = J(2, 1, 0)
foreach var in `list'{
	ttest `var', by(tech)
	matrix D[`i', 1] = r(p)
	local i = `i' + 1
}

matrix C = C, D

frmttable using Table6, varlabels statmat(C) sdec(2,2,2,2, 3) ctitles("Variable name", "Technical timeout = 0", "Standard deviation" , "Technical timeout = 1", "Standard deviation", "P-value mean-comparison test") replace tex 