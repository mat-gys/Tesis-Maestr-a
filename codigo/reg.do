global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\output"
cd "$main"

* Import dataset
import excel "final.xlsx", firstrow clear

* Panel
encode matchID, gen(ID)
xtset ID roundNum

* Summary statistics
summ

********* Generate cummulative wins for team who won last round ********

gen ct_win = (winningSide == "CT")
label var ct_win "Counter terrorists won previous round"

gen t_win = (ct_win ~= 1)
label var t_win "Terrorists won previous round"

sort matchID roundNum

gen cum_win = 1
replace cum_win = cum_win + cum_win[_n - 1] if ct_win == ct_win[_n - 1]

gen lag_cum_win = cum_win[_n - 1]
label var lag_cum_win "Wins in a row"


************** Replace missing values in timeout variables *************

local varlist ctTimeOut tTimeOut technicalTimeOut
foreach var in `varlist'{
qui recode `var' (.=0)
}


************************** Generating controls *************************

local winprob Alive Hp Armor Helmet Eq Utility EqValStart Cash
foreach var in `winprob'{
gen win_`var' = (ct`var' * ct_win) + (t`var' * t_win)
gen loss_`var' = (ct`var' * t_win) + (t`var' * ct_win)
}

gen win_defusers = (defusers * ct_win)
gen loss_defusers = (defusers * t_win)

gen win_time_out = (ctTimeOut * ct_win) + (tTimeOut * t_win)
label var win_time_out "Winner timeout"
gen loss_time_out = (ctTimeOut * t_win) + (tTimeOut * ct_win)
label var loss_time_out "Loser timeout"

gen win_score = (ct_win * (tScore - ctScore)) + (t_win * (tScore - ctScore))
label var win_score "Score differential (winner - loser)"


************************* Creating outcome vars ************************
gen y = (cum_win == 1 )
label var y "0 if team that won last round also wins current round"

drop if secondsSincePhaseStart == . | ctNone == 1 | tNone == 1 | start == . | roundNum == 1 | ctTimeOut == 2 | tTimeOut == 2
/*
drop if secondsSincePhaseStart == .
drop if start == .
drop if ctNone == 1
drop if tNone == 1
drop if roundNum == 1
drop if ctTimeOut == 2
drop if tTimeOut == 2
*/

* drop if time_tto_long == 1
bysort matchID: egen median_time_between_rounds = median(freezeTimeTotal)

gen tto_time = technicalTimeOut *(freezeTimeTotal - median_time_between_rounds)/128.21 if (freezeTimeTotal != median_time_between_rounds)
label var tto_time "Duration (s) of technical timeout"

recode tto_time (. = 0)


* Checking that most observations where nonDefinedTimeOut = 1 are just because of usual breaks in matches
gen a = ((roundNum == 16 | roundNum == 31 | roundNum == 34 | roundNum == 37 | roundNum == 40 | roundNum == 43 | roundNum == 46 | roundNum == 49) & freezeTimeTotal > 2562)
tab a nonD

drop if nonDefinedTimeOut == 1


*************** Correlation matrix for control variables ***************

* corr technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_Alive win_Hp win_Armor win_Helmet win_Eq win_Utility win_Cash loss_Alive loss_Hp loss_Armor loss_Helmet loss_Eq loss_Utility win_defusers loss_defusers loss_Cash
* Equipment value contains Helmet, Utility, defusers and weapons
corr technicalTimeOut lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash


**************************** Labels ****************************
label var win_Eq "Winner's equipment value"
label var loss_Eq "Loser's equipment value"
label var win_Cash "Winner's cash"
label var loss_Cash "Loser's cash"
label var ct_tto "Counter terrorist tactical timeout"
label var t_tto "Terrorist tactical timeout"


********* Testing for cheating and frustration (Tables 1 to 4) *********

qui tabstat ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if t_tto == 0, save statistics(mean) columns(statistics)
matrix A=r(StatTotal)

qui tabstat ct_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if t_tto == 1, save statistics(mean) columns(statistics)
matrix B=r(StatTotal)

matrix C = A',B'
matrix list C

summ t_tto
frmttable using tabla1, varlabels statmat(C) sdec(2,2,0,0) ctitles("Variable name","Mean terrorist timeout = 0", "Mean terrorist timeout = 1") replace tex note("Number of terrorist tactical timeouts: `r(sum)'")


qui tabstat t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if ct_tto == 0, save statistics(mean) columns(statistics)
matrix D=r(StatTotal)

qui tabstat t_win lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash if ct_tto == 1, save statistics(mean) columns(statistics)
matrix E=r(StatTotal)

matrix F = D',E'
matrix list F
summ ct_tto
frmttable using tabla2, varlabels statmat(F) sdec(2,2,0,0) ctitles("Variable name","Mean counter terrorist timeout = 0", "Mean counter terrorist timeout = 1") replace tex note("Number of counter terrorist tactical timeouts: `r(sum)'")

ttest ct_win, by(t_tto)
matrix G = r(p)
ttest t_win, by(ct_tto)
matrix H = r(p)

matrix I = C[1,1..2], G
frmttable using tabla3, varlabels statmat(I) sdec(3,3,3) ctitles("","Mean terrorist timeout = 0", "Mean terrorist timeout = 1", "P-value of mean-comparison test") replace tex

matrix J = F[1,1..2], H
frmttable using tabla4, varlabels statmat(J) sdec(3,3,3) ctitles("","Mean counter terrorist timeout = 0", "Mean counter terrorist timeout = 1", "P-value of mean-comparison test") replace tex


************ Dropping rounds affected by technical timeouts ************

sort matchID roundNum

bysort matchID: tab tech
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after


****************** Creating tactical timeout controls ******************

local varlist win loss
foreach var in `varlist'{

* Agarrar al ganador/perdedor en cada timeout, y trackear si está como ganador o perdedor en cada ronda.
egen after_`var'_to = min(cond(`var'_time_out == 1, roundNum, .)), by(matchID)

bysort matchID: replace after_`var'_to = 0 if (after_`var'_to == . | roundNum < after_`var'_to)

replace after_`var'_to = 1 if after_`var'_to != 0

bysort matchID: replace after_`var'_to = (after_`var'_to + after_`var'_to[_n-1]) if (after_`var'_to[_n-1] != 0 & `var'_time_out != 1)

replace after_`var'_to = after_`var'_to * (-1)

}

br win_time loss_time_out roundNum after_win_to after_loss_to


************** Dropping round afected by tactical timeouts *************

egen after_tac_to = min(cond(ctTimeOut == 1 |tTimeOut == 1, roundNum, .)), by(matchID)
bysort matchID: keep if roundNum <= after_tac_to
tab technicalTimeOut


****************** Number of matches and observations ******************

codebook ID
di _N


************************** Vanilla regressions *************************

reg y technicalTimeOut
reg y win_time_out loss_time_out


************************* Extensive regression *************************

xtreg y technicalTimeOut lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
outreg2 using main_reg, tex replace dec(3) ctitle(Extensive) keep(technicalTimeOut win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se pval) par(se) bracket(pval)
*outreg2 using main_reg, tex replace dec(3) ctitle(Extensive) keep(technicalTimeOut lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash) label addtext(Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se pval) par(se) bracket(pval)


************************* Intensive regression *************************

xtreg y tto_time lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
display _b[tto_time] * 30
* a round after a 30 second timeout is 1.5 percentage points more likely to revert the previous round winner
outreg2 using main_reg, tex append dec(3) ctitle(Intensive) keep(tto_time win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se pval) par(se) bracket(pval)
*outreg2 using main_reg, tex append dec(3) ctitle(Intensive) keep(tto_time lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash) label addtext(Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se pval) par(se) bracket(pval)


*************** Placebo test with previous rounds ***************

local replace replace
forval i = 1/3{
* Dropping rounds that whould make the timeout change game
drop if technicalTimeOut ==1 & roundNum == `i' + 1
* Al no dejar ninguna rondas antes, eso no me afecta lo que toma como control?

gen tech_time_out_neg_`i' = technicalTimeOut[_n - `i']
label var tech_time_out_neg_`i' "`i' round lead technical timeout"

xtreg y tech_time_out_neg_`i' lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust

outreg2 using placebo_reg, tex `replace' dec(3) ctitle(Extensive) keep(tech_time_out_neg_`i' win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se pval) par(se) bracket(pval)

gen tech_time_out_time_neg_`i' = tto_time[_n - `i']
label var tech_time_out_time_neg_`i' "`i' round lead technical timeout time"

xtreg y tech_time_out_time_neg_`i' lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust

outreg2 using placebo_reg, tex append dec(3) ctitle(Intensive) keep(tech_time_out_time_neg_`i' win_time_out loss_time_out) label addtext(Controls, Yes, Match fixed effects, Yes, Round fixed effects, Yes) nocons nor stats(coef se pval) par(se) bracket(pval)
local replace append
}


********* Dropping timeouts with single observation per match *********

drop if technicalTimeOut == 1 & (roundNum == 2 | roundNum == 3 | roundNum == 4)
drop if matchID == "xStarLadder-CIS-RMR-2021-jul4-gambit-vs-natus-vincere-m3-mirage" | matchID == "xIEM-Beijing-Haidian-2020-Europe-heroic-vs-vitality-m1-overpass"
