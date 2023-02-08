clear all

global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files"
global code "$main\\code"
global output "$main\\output"
cd "$code"

run clean_data.do

cd"$output"

xtset ID roundNum

/*
If they are random, they should happen in the same frequency as the rounds do
*/
set scheme plotplain

hist lag_cum_win if techn ==1, name(Distribution1) discrete xlabel(1(1)20) ylabel(,nolabel) ytitle("")
hist lag_cum_win if techn ==0, name(Distribution0) discrete xlabel(1(1)20)

hist roundN if techn ==1, name(Distributiona) discrete xlabel(1(1)51)
hist roundN if techn ==0, name(Distributionb) discrete xlabel(1(1)51)


************ Dropping rounds affected by technical and tactical timeouts ************

sort matchID roundNum

bysort matchID: tab tech
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after_tto


egen after_tac_to = min(cond(ctTimeOut > 0 |tTimeOut > 0, roundNum, .)), by(matchID)
bysort matchID: keep if roundNum <= after_tac_to
*tab technicalTimeOut

* Checking that most observations where nonDefinedTimeOut = 1 are just because of usual breaks in matches
gen a = ((roundNum == 16 | roundNum == 31 | roundNum == 34 | roundNum == 37 | roundNum == 40 | roundNum == 43 | roundNum == 46 | roundNum == 49) & freezeTimeTotal > 2562 & nonDefinedTimeOut == 1)
tab a nonD

sort matchID roundNum


* Dropping observations after non defined timeouts
egen after_nond_to = min(cond(nonD ==1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum < after_nond_to

egen after_double = min(cond((techn == 1 & (ctTimeOut > 0 | tTimeOut > 0)) | ctTimeOut > 1 | tTimeOut > 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum < after_double

* Dropping rounds where there was a technical timeout on the next round, implying the issues could have reappeared and affected the round
drop if tec_in_row == 1
drop tec_in_row

* Not possible to use more wins in a row
*gen y2 = (cum_win == 1 & lag_cum_win ==2 )
* tab tech lag_cum_win

xtset ID roundNum


********* Testing for cheating and frustration (Tables 1 and 2) *********

qui tabstat t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet if ct_tto == 0, save statistics(mean sd) columns(statistics)
matrix A=r(StatTotal)

qui tabstat t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet if ct_tto == 1, save statistics(mean sd) columns(statistics)
matrix B=r(StatTotal)

matrix C = A',B'
matrix list C


local list t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet
local i 1
matrix D = J(15, 1, 0)
matrix E = J(15, 1, .)
foreach var in `list'{
	ttest `var', by(ct_tto)
	matrix D[`i', 1] = r(p)
	local i = `i' + 1
}

matrix C = C, D, E


summ ct_tto
frmttable using Table1, varlabels statmat(C) substat(1) sdec(2,2,2,2, 3) ctitles("Variable name", "Mean team A timeout = 0", "Mean team A timeout = 1", "P-value mean-comparison test") replace tex note("Notes: Number of team A technical timeouts recorded: `r(sum)'. Standard errors in parenthesis.")


qui tabstat ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet if t_tto == 0, save statistics(mean sd) columns(statistics)
matrix A=r(StatTotal)

qui tabstat ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet if t_tto == 1, save statistics(mean sd) columns(statistics)
matrix B=r(StatTotal)

matrix C = A',B'
matrix list C

local list ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet
local i 1
matrix D = J(15, 1, 0)
matrix E = J(15, 1, .)
foreach var in `list'{
	ttest `var', by(t_tto)
	matrix D[`i', 1] = r(p)
	local i = `i' + 1
}

matrix C = C, D, E

summ t_tto
frmttable using Table2, varlabels statmat(C) substat(1) sdec(2,2,2,2) ctitles("Variable name", "Mean team B timeout = 0", "Mean team B timeout = 1", "P-value mean-comparison test") replace tex note("Notes: Number of team B technical timeouts recorded: `r(sum)'. Standard errors in parenthesis.")



*Joint significance tests
xtreg ct_tto t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
test t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet

xtreg t_tto ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
test ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet




**************************** Summary statistic (Table 3) ****************************

tabstat technicalTimeOut tto_time_a lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, save statistics(mean sd min max) columns(statistics)
matrix stats = r(StatTotal)
matrix stats = stats'
frmttable using Table3, varlabels tex statmat(stats) sdec(3,3,3,3) ctitles("Variable name","Mean", "SD", "Minimum","Maximum") replace 


*** TWO OUTLIERS!
hist tto_time_actual if tech ==1, width(30)





**************************** No effect overall (Table 4) ****************************
	xtreg y technicalTimeOut i.lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
	outreg2 using Table4, tex replace dec(4) ctitle(Extensive) keep(technicalTimeOut win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se) sortvar(technicalTimeOut tto_time_a win_time_out loss_time_out)
	
/* 
No apparent effect overall
We would expect that the more wins in a row accumulated by the previous round winner, the more momentum they would have gained. Therefore, a timeout affecting a team that has won the previous 3 rounds would have a higher effect than one affecting a team that won just the previous round. 
*/

**************************** Accumulated momentum (Table 5) ****************************

gen under_three = (lag_cum_win <= 3 & techn == 1)
gen over_three = (lag_cum_win > 3 & techn == 1)
label var under_three "Technical Timeout * 1-3 Accumulated wins in a row"
label var over_three "Technical Timeout * 4-6 Accumulated wins in a row"


xtreg y i.under_three i.over_three win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using Table5, tex replace dec(4)  keep(i.under_three i.over_three win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)

/* 
We somehwat see this, although we are looking at timeouts of any duration. A small timeout might not be able to break momentum. 
*/
hist tto_time_actual if techn ==1, freq width(30) xticks(0(60)1680) xlabel(0(60)1680,ang(45))
tab techn lag_cum_win

/*
We would expect that only timeouts lasting a certain amount of time would be able to break momentum. We will use timeouts lasting at least 30 seconds, the usual duration of a tactical timeout.
*/

******************** Visible effect when momentum is high (Table 6) ********************

gen tech30 = (technicalTimeOut == 1 & tto_time_actual >= 30)
label var tech30 "Technical Timeout > 30 seconds"

drop if technicalTimeOut == 1 & tech30 == 0

xtreg y i.under_three i.over_three win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using Table6, tex replace dec(4)  keep(i.under_three i.over_three win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)


*************************** Further heterogeneity (Table 7) ***************************

gen tech_1 = (lag_cum_win == 1 & techn == 1)
label var tech_1 "Technical Timeout * 1 Win in a row"

forval numb = 2/6{
gen tech_`numb' = (lag_cum_win == `numb' & techn == 1)
label var tech_`numb' "Technical Timeout * `numb' Wins in a row"
}

xtreg y tech_* win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using Table7, tex replace dec(4)  keep(tech_1 tech_2 tech_3 tech_4 tech_5 tech_6 win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)

/*
This could be because I have a low number of observations in the high accumulated wins. I'll check if the results hold when dropping one of the timeouts when cummulative wins = 4
*/
hist lag_cum_win if techn ==1, freq width(1) xticks(1(1)6) xlabel(1(1)6) discrete addlabels name(Distribution30)


****************** Remains significant when leaving one out (Table 8) ******************


set seed 1222023
gen indicator4 = (over_three)
local replace replace

foreach numb of numlist 1/8{

	gen random = runiform()
	sort indicator4 random
	generate insample = indicator4 & (_N - _n) <1
	
	tab ID if insample == 1
	
	preserve 
	
	keep if insample ~= 1
	
	
xtreg y i.under_three i.over_three win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using Table8, tex `replace' dec(4)  keep(i.under_three i.over_three win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)
	
	restore
	
	replace indicator4 = 0 if insample == 1
	
	drop insample
	drop random
	local replace append
}
drop indicator*


************** So does Table 7's four wins in a row interaction (Table 9) **************

set seed 1222023
gen indicator4 = (tech_4)
local replace replace

foreach numb of numlist 1/6{

	gen random = runiform()
	sort indicator4 random
	generate insample = indicator4 & (_N - _n) <1
	
	tab ID if insample == 1
	
	preserve 
	
	keep if insample ~= 1
	
	
xtreg y tech_* win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using Table9, tex `replace' dec(4)  keep(tech_1 tech_2 tech_3 tech_4 tech_5 tech_6 win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)
	
	restore
	
	replace indicator4 = 0 if insample == 1
	
	drop insample
	drop random
	local replace append
}
drop indicator*


*************** Results can't be replicated with time placebos (Tables 10-11) ***************
xtset ID roundN
gen tech_lead_0 = techn
gen tech_time_lead_0 = tto_time_actual
forval j = 1/3{
	local i = `j' - 1
	gen tech_lead_`j' = F.tech_lead_`i'
	label var tech_lead_`j' "`j' round lead technical timeout"
	recode tech_lead_`j' (.=0)
	
	gen tech_time_lead_`j' = F.tech_time_lead_`i'
	label var tech_time_lead_`j' "`j' round lead technical timeout time"
	recode tech_time_lead_`j' (.=0)
}

preserve
local replace replace

forval lead = 1/3{
	drop under_three over_three
	local j = `lead' - 1
	drop if tech_lead_`j' ==1
	gen under_three = (lag_cum_win <= 3 & tech_lead_`lead' == 1)
	gen over_three = (lag_cum_win > 3 & tech_lead_`lead' == 1)
	label var under_three "Technical Timeout * 1-3 Accumulated wins in a row"
	label var over_three "Technical Timeout * 4-6 Accumulated wins in a row"

	xtreg y i.under_three i.over_three win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
	outreg2 using Table10, tex `replace' dec(4)  keep(i.under_three i.over_three win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)

	local replace append
	
	tab under_three over_three
	* 6 con 1 round lead, 5 con 2 round lead, 1 con 3 round lead
}
restore

preserve
local replace replace
forval lead = 1/3{

	gen tech_lead__1 = (lag_cum_win == 1 & tech_lead_`lead' == 1)
	label var tech_lead__1 "Technical Timeout * 1 Win in a row"

	forval numb = 2/6{
	
		gen tech_lead__`numb' = (lag_cum_win == `numb' & tech_lead_`lead' == 1)
		label var tech_lead__`numb' "Technical Timeout * `numb' Wins in a row"
		
	}
	
	local j = `lead' - 1
	drop if tech_lead_`j' ==1
	
	xtset ID roundN
	
	xtreg y tech_lead__1-tech_lead__6 win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using Table11, tex `replace' dec(4) ctitle(Extensive) keep(tech_lead__1-tech_lead__6) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se) sortvar(tech_lead_1#i.lag_cum_win tech_lead_2#i.lag_cum_win tech_lead_3#i.lag_cum_win)
	
	
	local replace append
	
	forval numb = 1/6{
		drop tech_lead__`numb'
	}

}
restore

forval j = 1/3{
	tab tech_lead_`j' lag_cum_win
}


************** Robust to using duration recorded in demofile (Appendix Tables 12-13) **************

gen tech30b = (technicalTimeOut == 1 & tto_time >= 30)
label var tech30 "Technical Timeout > 30 seconds"

drop if technicalTimeOut == 1 & tech30b == 0


xtreg y i.under_three i.over_three win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using AppendixTable12, tex replace dec(4)  keep(i.under_three i.over_three win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)

xtreg y tech_1-tech_6 win_time_out loss_time_out i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, i(ID) fe cluster(ID) robust
outreg2 using AppendixTable13, tex replace dec(4)  keep(tech_1-tech_6 win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se) par(se)