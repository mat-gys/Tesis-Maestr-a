* Setting directory
global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Atpt\\output"
cd "$main"

* Import dataset
import excel "final.xlsx", firstrow clear

*
drop if secondsSincePhaseStart == . | ctNone == 1 |tNone == 1 | start == .

* Summary statistics
summ

* Creating amount of rounds finished variable
gen fin_rounds = roundNum[_n-1]
label var fin_rounds "Amount of rounds already finished"

* Generate cummulative wins for team who won last round
* i.e. # rounds won in a row by team who won last round
gen ct_win = (winningSide == "CT")
label var ct_win "1 if ct team won round"
gen t_win = (ct_win ~= 1)
label var t_win "1 if t team won round"

sort matchID roundNum

gen cum_win = 1
replace cum_win = cum_win + cum_win[_n - 1] if ct_win == ct_win[_n - 1]
gen lag_cum_win = cum_win[_n - 1]
label var lag_cum_win "Accumulated wins by team who won last round"

* Dropping first rounds
drop if roundNum == 1 | nonDefinedTimeOut == 1

* Replace missing values in timeout variables
local varlist ctTimeOut tTimeOut technicalTimeOut
foreach var in `varlist'{
qui recode `var' (.=0)
}

* Create win and loss variables for predictors
local winprob Alive Hp Armor Helmet Eq Utility EqValStart Cash
foreach var in `winprob'{
gen win_`var' = (ct`var' * ct_win) + (t`var' * t_win)
gen loss_`var' = (ct`var' * t_win) + (t`var' * ct_win)
}

gen win_defusers = (defusers * ct_win)
gen loss_defusers = (defusers * t_win)

* Creating outcome variable, takes value 0 if team that won last round also won current round
gen y = (cum_win == 1 )
label var y "0 if team that won last round also wins current round"

* Create interaction variables for team that won last round and asked timeout
* and team that lost and asked timeout
gen win_time_out = (ctTimeOut * ct_win) + (tTimeOut * t_win)
label var win_time_out "1 if timeout called by team who won last round"
gen loss_time_out = (ctTimeOut * t_win) + (tTimeOut * ct_win)
label var loss_time_out "1 if timeout called by team who lost last round"

* Creating score differential between team that won last round and the team that lost last round
gen win_score = (ct_win * (endCTScore - endTScore)) + (t_win * (endTScore - endCTScore))
label var win_score "Score differential between team who won last round and team who didnt"

* Correlation matrix for control variables
corr technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_Alive win_Hp win_Armor win_Helmet win_Eq win_Utility win_Cash loss_Alive loss_Hp loss_Armor loss_Helmet loss_Eq loss_Utility win_defusers loss_defusers loss_Cash
* Alta correlación entre alive y vide, armadura. Tiene sentido
* Equipment value ya está metida en el resto
* Equipment value start es parte un outcome tmb
corr technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash

* TENGO MAS DE UN TTO POR MATCH EN 7 CASOS
bysort matchID: tab tech
* ADEMAS, ES POSIBLE QUE LAS RONDAS DSP DE UN TTO TMB SE VEN AFECTADAS
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after
*replace after_tto = 1 if after_tto != .
*replace after_tto = 0 if after_tto ==. 

* Generating timeout controls
local varlist win loss
foreach var in `varlist'{

egen after_`var'_to = min(cond(`var'_time_out == 1, roundNum, .)), by(matchID)
bysort matchID: replace after_`var'_to = 0 if (after_`var'_to == . | roundNum < after_`var'_to)
replace after_`var'_to = 1 if after_`var'_to != 0

bysort matchID: replace after_`var'_to = (after_`var'_to + after_`var'_to[_n-1]) if (after_`var'_to[_n-1] != 0 & `var'_time_out != 1)
replace after_`var'_to = after_`var'_to * (-1)

* Agarrar al ganador/perdedor en cada timeout, y trackear si está como ganador o perdedor en cada ronda.
}

br win_time loss_time_out roundNum after_win_to after_loss_to


reg y technicalTimeOut
reg y win_time_out loss_time_out
reg y after_win_to after_loss_to

* Intensive Measure
bysort matchID: egen median_time_between_rounds = median(freezeTimeTotal)
gen tto_time = technicalTimeOut *(freezeTimeTotal - median_time_between_rounds)/128.21 if (freezeTimeTotal != median_time_between_rounds)
label var tto_time "Duration in (approximately) seconds of the technical timeout"
recode tto_time (. = 0)

* Checking if there's correlation between who won last round and who calls the technical timeout when observable
corr ct_win ct_tto t_win t_tto

* Generate series variable
split matchID, parse("vs") gen(series)
encode series1, gen(series)
drop series1 series2

*** PANEL
encode matchID, gen(ID)
xtset ID roundNum

* Revisar!
drop if matchID == "xStarLadder-CIS-RMR-2021-jul4-gambit-vs-natus-vincere-m3-mirage"

* Extensive regression
label var technicalTimeOut "Technical time out"
label var tto_time "Duration (s) of technical time out"
label var lag_cum_win "Wins in a row"
label var win_time_out "Winner time out"
label var loss_time_out "Loser time out"
label var win_score "Score differential (winner - loser)"
label var win_Eq "Winner's equipment value"
label var loss_Eq "Loser's equipment value"
label var win_Cash "Winner's cash"
label var loss_Cash "Loser's cash"

xtreg y technicalTimeOut lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
outreg2 using main_reg, tex replace dec(3) ctitle(Extensive) keep(technicalTimeOut lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash) label addtext(Match fixed effects, Yes, Round fixed effects, Yes) nocons noni nor

* Intensive regression 
xtreg y tto_time lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust
* 0.0004741*30 (usual timeout duration) = 0.014 increased change of previous round loser winning the current round
outreg2 using main_reg, tex append dec(3) ctitle(Intensive) keep(time_tto lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash) label addtext(Match fixed effects, Yes, Round fixed effects, Yes) nocons noni nor

xtreg y tto_time lag_cum_win time_tto_long win_time_out loss_time_out win_score i.roundNum, i(ID) fe cluster(ID) robust


* Interaction
gen inter = tech * lag_cum
xtreg y technicalTimeOut inter fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash, i(ID) fe cluster(ID) robust

xtreg y technicalTimeOut inter lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash i.roundNum, i(ID) fe cluster(ID) robust