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

* Correlation matrix for control variables
corr technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_Alive win_Hp win_Armor win_Helmet win_Eq win_Utility win_Cash loss_Alive loss_Hp loss_Armor loss_Helmet loss_Eq loss_Utility win_defusers loss_defusers loss_Cash
* Alta correlación entre alive y vide, armadura. Tiene sentido
* Equipment value ya está metida en el resto
* Equipment value start es parte un outcome tmb
corr technicalTimeOut fin_rounds lag_cum_win win_time_out win_Cash loss_Cash loss_time_out win_Armor win_Helmet win_Utility loss_Armor loss_Helmet loss_Utility win_defusers loss_defusers 

* TENGO MAS DE UN TTO POR MATCH EN 7 CASOS
bysort matchID: tab tech
* ADEMAS, ES POSIBLE QUE LAS RONDAS DSP DE UN TTO TMB SE VEN AFECTADAS
egen after_tto = min(cond(technicalTimeOut == 1, roundNum, .)), by(matchID)  
bysort matchID: keep if roundNum <= after
*replace after_tto = 1 if after_tto != .
*replace after_tto = 0 if after_tto ==. 

egen after_win_to = min(cond(win_time_out == 1, roundNum, .)), by(matchID)
bysort matchID: replace after_win_to = 0 if (after_win_to == . | roundNum < after_win_to)
replace after_win_to = 1 if after_win_to != 0

egen after_loss_to = min(cond(loss_time_out == 1, roundNum, .)), by(matchID)
bysort matchID: replace after_loss_to = 0 if (after_loss_to == . | roundNum < after_loss_to)
replace after_loss_to = 1 if after_loss_to != 0

reg y technicalTimeOut
reg y win_time_out loss_time_out

* Extensive Regression
reg y technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out after_loss_to after_win_to win_Armor win_Helmet win_Utility loss_Armor loss_Helmet loss_Utility win_defusers loss_defusers win_Cash loss_Cash after_tto, cluster(matchID)
outreg2 using extensive_reg, tex replace dec(3) ctitle(Extensive)

* Intensive Regression
gen tto_time = (technicalTimeOut * freezeTimeTotal * 0.0078 * 128.2)
label var tto_time "Duration in (approximately) seconds of the technical timeout"

reg y tto_time fin_rounds lag_cum_win win_time_out loss_time_out win_Armor win_Helmet win_Utility loss_Armor loss_Helmet loss_Utility win_defusers loss_defusers win_Cash loss_Cash after_tto, cluster(matchID)
outreg2 using extensive_reg, tex append dec(3) ctitle(Intensive)

* Creating score differential between team that won last round and the team that lost last round
gen win_score = (ct_win * (endCTScore - endTScore)) + (t_win * (endTScore - endCTScore))
label var win_score "Score differential between team who won last round and team who didnt"

corr technicalTimeOut fin_rounds lag_cum_win win_time_out win_Cash loss_Cash loss_time_out win_Armor win_Helmet win_Utility loss_Armor loss_Helmet loss_Utility win_defusers loss_defusers win_score

* Regressions with score differential
reg y technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Armor win_Helmet win_Utility loss_Armor loss_Helmet loss_Utility win_defusers loss_defusers win_Cash loss_Cash after_tto, cluster(matchID)
outreg2 using reg_sd, tex replace dec(3) ctitle(Extensive)

reg y tto_time fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Armor win_Helmet win_Utility loss_Armor loss_Helmet loss_Utility win_defusers loss_defusers win_Cash loss_Cash after_tto, cluster(matchID)
outreg2 using reg_sd, tex append dec(3) ctitle(Intensive)

* With Eq instead of utilities, armor, helmet and defusers
corr technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash
reg y technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash after_tto, cluster(matchID)

reg y tto_time fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash after_tto, cluster(matchID)

gen inter = tech * lag_cum
reg y technicalTimeOut inter fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash after_tto , cluster(matchID)




*** PANEL
encode matchID, gen(ID)
xtset ID roundNum

* Extensive regression
xtreg y technicalTimeOut fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash, i(ID) fe cluster(ID) robust

* Intensive regression 
xtreg y tto_time fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash, i(ID) fe cluster(ID) robust

* Interaction
xtreg y technicalTimeOut inter fin_rounds lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash, i(ID) fe cluster(ID) robust