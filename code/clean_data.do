global main "C:\\Users\\Matias\\Documents\\UDESA\\Tesis_maestria\\Replication files\\output"
cd "$main"

* Import dataset
import excel "final.xlsx", firstrow clear

* Panel
encode matchID, gen(ID)
xtset ID roundNum

* Summary statistics
summ

********* Generate lagged cummulative wins for team who won last round ********

gen ct_win = (winningSide == "CT")
label var ct_win "Team A won previous round"

gen t_win = (ct_win ~= 1)
label var t_win "Team B won previous round"

sort matchID roundNum

gen cum_win = 1
bysort matchID: replace cum_win = cum_win + cum_win[_n - 1] if ct_win == ct_win[_n - 1]

gen tec_in_row= 0
bysort matchID: replace tec_in_row = 1 if techn[_n]==1 & techn[_n+1]==1

xtset ID roundN
gen lag_cum_win = L.cum_win
label var lag_cum_win "Wins in a row"
gen lag_lag_cum_win = L.lag_cum_win


************** Replace missing values in timeout variables *************
destring ctTimeOut, replace
destring tTimeOut, replace
local varlist ctTimeOut tTimeOut technicalTimeOut
foreach var in `varlist'{
	qui recode `var' (.=0)
}


************************** Generating controls *************************

* Alive, Hp, Armor, Helmet, Eq, Utility, EqValStart, Cash and defusers are all measured at the last moment of the previous round. So to create the controls, I need to use the previous round winner but use the "current round" values of these controls.
gen lag_ct_win = L.ct_win
gen lag_t_win = L.t_win

*local winprob Alive Hp Armor Helmet Eq Utility EqValStart Cash Buy
*foreach var in `winprob'{
*	gen win_`var' = (ct`var' * lag_ct_win) + (t`var' * lag_t_win)
*	gen loss_`var' = (ct`var' * lag_t_win) + (t`var' * lag_ct_win)
*}
local winprob Alive Hp Armor Helmet Eq Utility EqValStart Cash
foreach var in `winprob'{
	gen lag_ct`var' = L.ct`var'
	gen lag_t`var' = L.t`var'
	gen win_`var' = (lag_ct`var' * lag_ct_win) + (lag_t`var' * lag_t_win)
	gen loss_`var' = (lag_ct`var' * lag_t_win) + (lag_t`var' * lag_ct_win)
}


gen win_defusers = (defusers * lag_ct_win)
gen loss_defusers = (defusers * lag_t_win)

gen win_score = (lag_ct_win * (ctScore - tScore)) + (lag_t_win * (tScore - ctScore))
label var win_score "Score differential (winner - loser)"

* There's high correlation between Equipment value and Helmet, Armor, and Utility. Plus Equipment value includes the value of weapons, so I'll be using this instead of Helmet, Armor and Utility. This also makes it unecessary to determine the weapons.
corr win_Eq win_He win_Ar win_U win_d
corr loss_Eq loss_He loss_Ar loss_U loss_d

* Generating tactical timeouts controls

gen win_time_out = (ctTimeOut * lag_ct_win) + (tTimeOut * lag_t_win)
label var win_time_out "Winner timeout"
gen loss_time_out = (ctTimeOut * lag_t_win) + (tTimeOut * lag_ct_win)
label var loss_time_out "Loser timeout"

* For robustness table
bysort matchID: gen ct_eqvalstart = ctEqValStart[_n + 1]
bysort matchID: gen t_eqvalstart = tEqValStart[_n + 1]
bysort matchID: gen ct_cash = ctCash[_n + 1]
bysort matchID: gen t_cash = tCash[_n + 1]

label var ct_eqvalstart "Team A Equipment value at start of round"
label var t_eqvalstart "Team B Equipment value at start of round"
label var ct_cash "Team A Cash at start of round"
label var t_cash "Team B Cash at start of round"


************************* Creating outcome vars ************************
gen y = (cum_win == 1 )
label var y "0 if team that won last round also wins current round"


drop if secondsSincePhaseStart == . | ctNone == 1 | tNone == 1 | start == . | roundNum == 1


/*
drop if secondsSincePhaseStart == .
drop if start == .
drop if ctNone == 1
drop if tNone == 1
drop if roundNum == 1
*/


/*
Get median time
Duration (in ticks) of the break in between rounds - median time
By dividing by 128, I get it measured in seconds
*/

bysort matchID: egen median_time_between_rounds = median(freezeTimeTotal)

gen tto_time = technicalTimeOut * (freezeTimeTotal - median_time_between_rounds)/128 if (freezeTimeTotal != median_time_between_rounds)
label var tto_time "Duration (s) of technical timeout"

recode tto_time (. = 0)


*************** Correlation matrix for control variables ***************

corr technicalTimeOut lag_cum_win win_time_out loss_time_out win_score win_Eq loss_Eq win_Cash loss_Cash


**************************** Labels ****************************
label var technicalTimeOut "Technical timeout"
label var win_Eq "Winner's equipment value"
label var loss_Eq "Loser's equipment value"
label var win_Cash "Winner's cash"
label var loss_Cash "Loser's cash"
label var win_Armor "Winner's armor"
label var loss_Armor "Loser's armor"
label var win_defusers "Winner's defusers"
label var loss_defusers "Loser's defusers"
label var win_Helmet "Winner's helmet"
label var loss_Helmet "Loser's helmet"
label var ct_tto "Team A tactical timeout"
label var t_tto "Team B tactical timeout"

**************** Hand-measured time between rounds ****************
gen tto_time_actual = tto_time
label var tto_time_a "Duration (s) of technical timeout"
replace tto_time_a = 72 - (2560 / 128)  if time_tto_long == 1 & matchID == "xBLAST-Premier-Fall-2020-Finals-vitality-vs-astralis-m2-dust2" & roundNum == 19
replace tto_time_a = 526 - (2560 / 128)  if time_tto_long == 1 & matchID == "xESL-Pro-League-Season11-Europe-astralis-vs-natus-vincere-m3-train" & roundNum == 19
replace tto_time_a = 148 - (2560 / 128)  if time_tto_long == 1 & matchID == "xIEM-Global-Challenge-2020-vitality-vs-astralis-m3-inferno" & roundNum == 10
replace tto_time_a = 157 - (2560 / 128)  if time_tto_long == 1 & matchID == "xIEM-Global-Challenge-2020-natus-vincere-vs-astralis-m2-nuke" & roundNum == 4
replace tto_time_a = 157 - (2560 / 128)  if time_tto_long == 1 & matchID == "xIEM-Global-Challenge-2020-natus-vincere-vs-astralis-m2-nuke" & roundNum == 4
replace tto_time_a = 190 - (2560 / 128)  if time_tto_long == 1 & matchID == "xBLAST-Premier-Spring-Groups-2021-og-vs-big-m1-inferno" & roundNum == 6
replace tto_time_a = 88 - (2560 / 128)  if time_tto_long == 1 & matchID == "xBLAST-Premier-Spring-Showdown-2021-gambit-vs-furia-m1-mirage" & roundNum == 3
replace tto_time_a = 130 - (2560 / 128)  if time_tto_long == 1 & matchID == "xcs-summit-7-og-vs-heroic-m1-nuke" & roundNum == 6
replace tto_time_a = (14115/128) - (6400 / 128)  if time_tto_long == 1 & matchID == "xIEM-Katowice-2021-g2-vs-big-m2-mirage" & roundNum == 7
replace tto_time_a = 418 - (2560 / 128)  if time_tto_long == 1 & matchID == "xPinnacle-Cup-2021-gambit-vs-spirit-m2-mirage" & roundNum == 8
replace tto_time_a = 181 - (2560 / 128)  if time_tto_long == 1 & matchID == "xPinnacle-Cup-2021-gambit-vs-spirit-m3-train" & roundNum == 3
replace tto_time_a = 117 - (2560 / 128)  if time_tto_long == 1 & matchID == "xcs-summit-6-Europe-25jun-faze-vs-big-m1-mirage" & roundNum == 8
replace tto_time_a = 85 - (2560 / 128)  if time_tto_long == 1 & matchID == "xESL-One-Cologne-2020-NorthAmerica-evil-geniuses-vs-liquid-m1-mirage-p1" & roundNum == 11
replace tto_time_a = 85 - (2560 / 128)  if time_tto_long == 1 & matchID == "xESL-One-Road-to-Rio-Europe-astralis-vs-faze-m1-dust2" & roundNum == 5
replace tto_time_a = 230 - (2560 / 128)  if time_tto_long == 1 & matchID == "xESL-One-Road-to-Rio-NorthAmerica-evil-geniuses-vs-100-thieves-m3-nuke" & roundNum == 4
replace tto_time_a = 260 - (2560 / 128)  if time_tto_long == 1 & matchID == "xBLAST-Premier-Spring-2020-Americas-Finals-furia-vs-liquid-m3-mirage" & roundNum == 9
replace tto_time_a = 237 - (2560 / 128)  if time_tto_long == 1 & matchID == "xESL-Pro-League-Season11-NorthAmerica-10apr-liquid-vs-evil-geniuses-m1-nuke" & roundNum == 13
replace tto_time_a = 139 - (2560 / 128)  if time_tto_long == 1 & matchID == "xESL-Pro-League-Season12-Europe-2oct-natus-vincere-vs-heroic-m2-mirage" & roundNum == 2
replace tto_time_a = 1657 - (2560 / 128)  if time_tto_long == 1 & matchID == "xESL-Pro-League-Season12-Europe-g2-vs-heroic-m3-inferno" & roundNum == 7
replace tto_time_a = 106 - (2560 / 128)  if time_tto_long == 1 & matchID == "xIEM-New-York-2020-NorthAmerica-furia-vs-liquid-m3-vertigo" & roundNum == 9
replace tto_time_a = 207 - (2560 / 128)  if time_tto_long == 1 & matchID == "xxBLAST-Premier-Fall-2020-Finals-mousesports-vs-astralis-m1-nuke" & roundNum == 4





**************** Technical timeouts by previous round winner or loser when possible ****************

gen win_tech_timeout = (ct_tto * lag_ct_win) + (t_tto * lag_t_win)
label var win_tech_timeout "Winner technical timeout"
gen loss_tech_timeout = (ct_tto * lag_t_win) + (t_tto * lag_ct_win)
label var loss_tech_timeout "Loser technical timeout"

gen win_tech_timeout_time = win_tech_timeout * tto_time_actual
gen loss_tech_timeout_time = loss_tech_timeout * tto_time_actual
label var win_tech_timeout_time "Duration (s) of winner technical timeout"
label var loss_tech_timeout_time "Duration (s) of loser technical timeout"

recode win_tech_timeout (.=0)
recode loss_tech_timeout (.=0)
recode win_tech_timeout_time (.=0)
recode loss_tech_timeout_time (.=0)