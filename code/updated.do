	
	clear all
	cls
	
	if "`c(username)'" == "Matias" {
		
		global main "C:\Users\Matias\Documents\UDESA\Tesis_maestria\Replication files\output"
	
	}
	else {

		global main "C:\Users\SEEBERM\Dropbox\MaE\output"

	}
	cd "$main"

* Import dataset
	import excel "parsed.xlsx", firstrow clear

* Panel
	replace matchID = subinstr(matchID, ".", "", .)
	encode matchID, gen(ID)
	
	xtset ID roundNum
	
		* For nice charts
	set scheme s2color
	grstyle init
	grstyle color background white					// white background 
	grstyle anglestyle vertical_tick horizontal		// horizontal y-axis labels
	grstyle gsize axis_title_gap tiny				// add space between axis labels and title
	grstyle linestyle legend none 					// remove the legend frame
	grstyle color major_grid white					// change colour of grid lines 
	grstyle set ci
	grstyle set compact
	grstyle set plain, grid dotted		
	
	graph set window fontface "Times New Roman"

	
********* Generate lagged cummulative wins for team who won last round ********

	bysort matchID: egen median_freeze_time = median(freezeTimeTotal)

	gen ct_win = (winningSide == "CT")
	label var ct_win "Team A won this round"
	
	gen t_win = (ct_win ~= 1)
	label var t_win "Team B won this round"
	
	sort matchID roundNum
	
	gen cum_win = 1
	bysort matchID: replace cum_win = cum_win + cum_win[_n - 1] if ct_win == ct_win[_n - 1]
	
	gen tec_in_row= 0
	bysort matchID: replace tec_in_row = 1 if pause[_n]==1 & pause[_n+1]==1
	
	xtset ID roundN
	gen lag_cum_win = L.cum_win
	label var lag_cum_win "Wins in a row"
	
	tab lag_cum_win, gen(lag_cum_win_)
	

* Generating ct and t score
	sort matchID roundN
	bys matchID: gen ctScore = sum(ct_win)
	bys matchID: gen tScore = sum(t_win)

	
*-------------------------------------------------------------------------------
**# 						 Generating controls 
*-------------------------------------------------------------------------------

	* Alive, Hp, Armor, Helmet, Eq, Utility, EqValStart, Cash and defusers are all measured at the last moment of the current round. So to create the controls, I need to use the previous round winner and the previous round values of these controls.

	xtset ID roundN
	gen lag_ct_win = L.ct_win
	gen lag_t_win = L.t_win
	
	*local winprob Alive Hp Armor Helmet Eq Utility EqValStart Cash
	*foreach var in `winprob'{
	*	gen win_`var' = (ct`var' * lag_ct_win) + (t`var' * lag_t_win)
	*	gen loss_`var' = (ct`var' * lag_t_win) + (t`var' * lag_ct_win)
	*}
	local winprob Alive Hp Armor Helmet Eq Utility EqValStart Cash Score
	foreach var in `winprob'{
		gen lag_ct`var' = L.ct`var'
		gen lag_t`var' = L.t`var'
		gen win_`var' = (lag_ct`var' * lag_ct_win) + (lag_t`var' * lag_t_win)
		gen loss_`var' = (lag_ct`var' * lag_t_win) + (lag_t`var' * lag_ct_win)
	}
	
	gen lag_defusers = L.defusers
	gen win_defusers = (lag_defusers * lag_ct_win)
	gen loss_defusers = (lag_defusers * lag_t_win)
	
	gen win_score = (lag_ct_win * (lag_ctScore - lag_tScore)) + (lag_t_win * (lag_tScore - lag_ctScore))
	label var win_score "Score differential (winner - loser)"
	
	gen lag_ctTeam = ctTeam[_n - 1]
	gen lag_tTeam = tTeam[_n - 1]
	gen win_Team = (lag_ctTeam * lag_ct_win) + (lag_tTeam * lag_t_win)
	gen loss_Team = (lag_ctTeam * lag_t_win) + (lag_tTeam * lag_ct_win)
	
	foreach team in win loss {
	
	replace `team'_Team = "Vitality" if strpos(lower(`team'_Team), "vita") > 0
	replace `team'_Team = "100 Thieves" if strpos(lower(`team'_Team), "100") > 0
	replace `team'_Team = "paiN" if strpos(lower(`team'_Team), "pain") > 0
	replace `team'_Team = "mibr" if strpos(lower(`team'_Team), "mibr") > 0
	replace `team'_Team = "forZe" if strpos(lower(`team'_Team), "forze") > 0
	replace `team'_Team = "NRG" if strpos(lower(`team'_Team), "nrg") > 0
	replace `team'_Team = "NiP" if strpos(lower(`team'_Team), "nip") > 0 | strpos(lower(`team'_Team), "ninjas") > 0
	replace `team'_Team = "Astralis" if strpos(lower(`team'_Team), "astralis") > 0
	replace `team'_Team = "BIG" if strpos(lower(`team'_Team), "big") > 0
	replace `team'_Team = "CPH Flames" if strpos(lower(`team'_Team), "flames") > 0
	replace `team'_Team = "Complexity" if strpos(lower(`team'_Team), "complexity") > 0
	replace `team'_Team = "ENCE" if strpos(lower(`team'_Team), "ence") > 0
	replace `team'_Team = "EG" if strpos(lower(`team'_Team), "evil") > 0
	replace `team'_Team = "FURIA" if strpos(lower(`team'_Team), "furia") > 0
	replace `team'_Team = "FaZe" if strpos(lower(`team'_Team), "faze") > 0
	replace `team'_Team = "Fnatic" if strpos(lower(`team'_Team), "fnatic") > 0
	replace `team'_Team = "Gambit" if strpos(lower(`team'_Team), "gambit") > 0
	replace `team'_Team = "Heroic" if strpos(lower(`team'_Team), "heroic") > 0
	replace `team'_Team = "Imperial" if strpos(lower(`team'_Team), "imperial") > 0
	replace `team'_Team = "MOUZ" if strpos(lower(`team'_Team), "mouz") > 0 | strpos(lower(`team'_Team), "mouse") > 0
	replace `team'_Team = "Movistar Riders" if strpos(lower(`team'_Team), "movistar") > 0
	replace `team'_Team = "Natus Vincere" if strpos(lower(`team'_Team), "navi") > 0
	replace `team'_Team = "North" if strpos(lower(`team'_Team), "north") > 0
	replace `team'_Team = "OG" if strpos(lower(`team'_Team), "og") > 0
	replace `team'_Team = "Spirit" if strpos(lower(`team'_Team), "spirit") > 0
	replace `team'_Team = "Virus Pro" if strpos(lower(`team'_Team), "virtus") > 0 | strpos(lower(`team'_Team), "vp") > 0
	replace `team'_Team = "Team Liquid" if strpos(lower(`team'_Team), "liquid") > 0
	replace `team'_Team = "Eternal Fire" if strpos(lower(`team'_Team), "eternal") > 0
	replace `team'_Team = "Renegades" if strpos(lower(`team'_Team), "renegades") > 0
	
	}
	
	encode win_Team, gen(winTeam)
	encode loss_Team, gen(lossTeam)

	
	gen tto_time = pause * (freezeTimeTotal - median_freeze_time)/128
	label var tto_time "Duration (s) of technical timeout (recorded in demo)"
	
	replace tto_time = 0 if tto_time < 0
	
	gen y = (cum_win == 1 )
	label var y "0 if team that won last round also wins current round"
	
	* Dropping rounds with win_score >15
	drop if (ctScore >= 16 | tScore >= 16) & !missing(ctS, tS)
	
	**# Timeout's exogeneity
	gen tech = (strpos(msg, "tech") > 0)
	eststo clear
	eststo: reghdfe tech i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, abs(ID roundN winTeam) vce(cluster ID)
	summ y if e(sample)
	estadd local ctrls Yes
	estadd local mfe Yes
	estadd local rnfe Yes
	estadd scalar matches = floor(`e(N_clust1)')
	estadd scalar mean_outcome = round(`r(mean)', 0.01)
	estadd local wfe Yes
	
	test 1.lag_cum_win 2.lag_cum_win 3.lag_cum_win 4.lag_cum_win 5.lag_cum_win 6.lag_cum_win 7.lag_cum_win 8.lag_cum_win 9.lag_cum_win 10.lag_cum_win 11.lag_cum_win 12.lag_cum_win 13.lag_cum_win 14.lag_cum_win 15.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet
	estadd scalar F_stat = r(p)
	
	esttab using "${main}\\Table 6 - Exogeneity.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars("ctrls Controls" "mfe Match fixed effects" "rnfe Round fixed effects" "wfe Winner team fixed effects" "matches Number of matches" "mean_outcome Mean outcome" "F_stat F-statistic p-value") nobaselevels nogap sfmt(a2)

* Deleting rounds after contiguous technical issues
	
	egen after_tec_in_row = min(cond(tec_in_row == 1, roundNum, .)), by(matchID)  
	bysort matchID: keep if roundNum < after_tec_in_row
	drop tec_in_row after_tec_in_row
	

* Deleting rounds after a technical timeout
	bysort matchID: tab pause
	egen after_tto = min(cond(pause == 1 & roundN !=1, roundNum, .)), by(matchID)  
	bysort matchID: keep if roundNum <= after_tto

* Creating non-defined timeout rounds to drop
	gen nonDefinedTimeOut = ((freezeTimeTotal > median_freeze_time) & roundNum != 1 & pause == 0)
	
	egen after_nond_to = min(cond(nonD ==1, roundNum, .)), by(matchID)  
	bysort matchID: keep if roundNum < after_nond_to
	
	drop if secondsSincePhaseStart == . | ctNone == 1 | tNone == 1 | start == . | roundNum == 1
	
	unique ID if strpos(matchID, "p1") > 0
	drop if strpos(matchID,"p1")>0
	drop if strpos(matchID,"p2")>0
	drop if strpos(matchID,"p3")>0
	/*
	drop if secondsSincePhaseStart == .
	drop if ctNone == 1
	drop if tNone == 1
	drop if start == .
	drop if roundNum == 1
	*/
	
	drop if pause == 1 & (freezeTimeTotal == median_freeze_time)
	
	**************** Hand-measured time between rounds ****************
	
	gen tto_time_actual = tto_time
	label var tto_time_a "Duration (s) of technical timeout"
	
	replace tto_time_a = 819 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Fall-Final-2022-faze-vs-og-m1-ancient" & roundNum == 4
	replace tto_time_a = 1466 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Fall-Final-2022-ninjas-in-pyjamas-vs-natus-vincere-m1-inferno" & roundNum == 4
	replace tto_time_a = 295 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Fall-Groups-2022-g2-vs-big-m1-vertigo" & roundNum == 3
	replace tto_time_a = 265 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Spring-2020-Americas-Finals-furia-vs-liquid-m3-mirage" & roundNum == 9
	replace tto_time_a = 124 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Spring-Final-2022-faze-vs-g2-m2-ancient" & roundNum == 6
	replace tto_time_a = 166 - (2560 / 128)  if pause & matchID == "xBLAST-Pro-Series-Copenhagen-2018-faze-vs-astralis-overpass" & roundNum == 4
	replace tto_time_a = 575 - (2560 / 128)  if pause & matchID == "xBLAST-Pro-Series-Lisbon-2018-astralis-vs-faze-dust2" & roundNum == 2
	replace tto_time_a = 253 - (2560 / 128)  if pause & matchID == "xBLAST-Pro-Series-Madrid-2019-astralis-vs-ence-m1-nuke" & roundNum == 2
	replace tto_time_a = 234 - (2560 / 128)  if pause & matchID == "xBLAST-Pro-Series-Miami-2019-liquid-vs-faze-m1-mirage" & roundNum == 2
	replace tto_time_a = 209 - (2560 / 128)  if pause & matchID == "xBLAST-Pro-Series-Miami-2019-liquid-vs-faze-nuke" & roundNum == 2
	replace tto_time_a = 253 - (2560 / 128)  if pause & matchID == "xBLAST-Pro-Series-Moscow-2019-natus-vincere-vs-ence-train" & roundNum == 7
	replace tto_time_a = 271 - (1920 / 128)  if pause & matchID == "xDreamHack-Masters-Dallas-2019-liquid-vs-ence-m1-mirage" & roundNum == 4
	replace tto_time_a = 237 - (2560 / 128)  if pause & matchID == "xDreamHack-Masters-Spring-2021-extra-salt-vs-vitality-m3-nuke"
	replace tto_time_a = 304 - (2560 / 128)  if pause & matchID == "xDreamHack-Masters-Spring-2021-mousesports-vs-faze-m1-mirage"
	replace tto_time_a = 83 - (1920 / 128)  if pause & matchID == "xECS-Season-6-Finals-nip-vs-north-m1-inferno"
	replace tto_time_a = 85 - (2560 / 128) if pause & matchID == "xESL-One-Road-to-Rio-Europe-astralis-vs-faze-m1-dust2"
	replace tto_time_a = 230 - (2560 / 128) if pause & matchID == "xESL-One-Road-to-Rio-NorthAmerica-evil-geniuses-vs-100-thieves-m3-nuke"
	replace tto_time_a = 214 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season-15-entropiq-vs-astralis-m1-nuke"
	replace tto_time_a = 254 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season-15-nip-vs-mouz-m1-inferno"
	replace tto_time_a = 1176 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season-16-g2-vs-natus-vincere-m3-mirage"
	replace tto_time_a = 113 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season-16-liquid-vs-furia-m3-vertigo"
	replace tto_time_a = 126 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season-16-vitality-vs-spirit-m1-nuke"
	replace tto_time_a = 85 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season10-Europe-faze-vs-vitality-m1-inferno"
	replace tto_time_a = 139 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season12-Europe-2oct-natus-vincere-vs-heroic-m2-mirage"
	replace tto_time_a = 390 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season13-big-vs-funplus-phoenix-m1-inferno"
	replace tto_time_a = 191 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season13-fnatic-vs-virtus-pro-m1-train"
	replace tto_time_a = 1094 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season13-g2-vs-mousesports-m2-mirage"
	replace tto_time_a = 74 - (2560 / 128) if pause & matchID == "xESL-Pro-League-Season14-complexity-vs-forze-m3-ancient"
	replace tto_time_a = 103 - (2560 / 128) if pause & matchID == "xFunspark-ULTI-2021-Finals-entropiq-vs-ecstatic-m2-vertigo"
	replace tto_time_a = 863 - (2560 / 128) if pause & matchID == "xIEM-Cologne-2021-Play-In-nip-vs-mousesports-m2-ancient"
	replace tto_time_a = 341 - (2560 / 128) if pause & matchID == "xIEM-Cologne-2021-astralis-vs-heroic-m1-inferno"
	replace tto_time_a = 238 - (2560 / 128) if pause & matchID == "xIEM-Cologne-2021-liquid-vs-mousesports-m3-inferno"
	replace tto_time_a = 170 - (2560 / 128) if pause & matchID == "xIEM-Cologne-2021-liquid-vs-nip-m1-overpass"
	replace tto_time_a = 88 - (2560 / 128) if pause & matchID == "xIEM-Cologne-2021-vitality-vs-natus-vincere-m3-mirage"
	replace tto_time_a = 155 - (2560 / 128) if pause & matchID == "xIEM-Cologne-2022-heroic-vs-mouz-m2-nuke"
	replace tto_time_a = 139 - (2560 / 128) if pause & matchID == "xIEM-Cologne-2022-mouz-vs-astralis-m2-nuke"
	replace tto_time_a = 487 - (2560 / 128) if pause & matchID == "xIEM-Dallas-2022-ence-vs-cloud9-m1-mirage"
	replace tto_time_a = 77 - (2560 / 128) if pause & matchID == "xIEM-Dallas-2022-faze-vs-cloud9-m1-overpass"
	replace tto_time_a = 104 - (2560 / 128) if pause & matchID == "xIEM-Dallas-2022-g2-vs-movistar-riders-nuke"
	replace tto_time_a = 130 - (2560 / 128) if pause & matchID == "xIEM-Dallas-2022-nip-vs-cloud9-m1-vertigo"
	replace tto_time_a = 226 - (2560 / 128) if pause & matchID == "xIEM-Fall-2021-CIS-gambit-vs-entropiq-m2-vertigo"
	replace tto_time_a = 902 - (2560 / 128) if pause & matchID == "xIEM-Fall-2021-Europe-big-vs-faze-m1-mirage"
	replace tto_time_a = 535 - (2560 / 128) if pause & matchID == "xIEM-Fall-2021-Europe-big-vs-faze-m2-overpass"
	replace tto_time_a = 411 - (2560 / 128) if pause & matchID == "xIEM-Fall-2021-Europe-nip-vs-ence-m1-overpass"
	replace tto_time_a = 116 - (2560 / 128) if pause & matchID == "xIEM-Fall-2021-Europe-vitality-vs-astralis-m2-vertigo"
	replace tto_time_a = 158 - (2560 / 128) if pause & matchID == "xIEM-Global-Challenge-2020-natus-vincere-vs-astralis-m2-nuke"
	replace tto_time_a = 106 - (2560 / 128) if pause & matchID == "xIEM-New-York-2020-NorthAmerica-furia-vs-liquid-m3-vertigo"
	replace tto_time_a = 134 - (2560 / 128) if pause & matchID == "xIEM-Rio-Major-2022-Challengers-Stage-outsiders-vs-fnatic-m1-overpass"
	replace tto_time_a = 86 - (2560 / 128) if pause & matchID == "xIEM-Rio-Major-2022-heroic-vs-cloud9-m1-vertigo"
	replace tto_time_a = 210 - (2560 / 128) if pause & matchID == "xIEM-Summer-2021-ClosedQualifier-funplus-phoenix-vs-g2-m2-mirage"
	replace tto_time_a = 411 - (2560 / 128) if pause & matchID == "xIEM-Summer-2021-vitality-vs-gambit-m2-overpass"
	replace tto_time_a = 146 - (2560 / 128) if pause & matchID == "xIEM-Winter-2021-fnatic-vs-ence-m1-overpass"
	replace tto_time_a = 110 - (2560 / 128) if pause & matchID == "xIEM-Winter-2021-g2-vs-liquid-m1-vertigo"
	replace tto_time_a = 418 - (2560 / 128) if pause & matchID == "xPinnacle-Cup-2021-gambit-vs-spirit-m2-mirage"
	replace tto_time_a = 181 - (2560 / 128) if pause & matchID == "xPinnacle-Cup-2021-gambit-vs-spirit-m3-train"
	replace tto_time_a = 465 - (2560 / 128) if pause & matchID == "xStarSeries-i-League-Season7-renegades-vs-mibr-m2-cache"
	replace tto_time_a = 244 - (2560 / 128) if pause & matchID == "xStarSeries-i-League-Season8-fnatic-vs-evil-geniuses-m1-mirage"
	replace tto_time_a = 106 - (2560 / 128) if pause & matchID == "xblast-premier-world-final-2022-liquid-vs-faze-m1-mirage"
	replace tto_time_a = 117 - (2560 / 128) if pause & matchID == "xblast-premier-world-final-2022-outsiders-vs-liquid-m1-inferno"
	replace tto_time_a = 415 - (2560 / 128) if pause & matchID == "xcs-summit-4-liquid-vs-nrg-m2-overpass"
	replace tto_time_a = 117 - (2560 / 128) if pause & matchID == "xcs-summit-6-Europe-25jun-faze-vs-big-m1-mirage"
	replace tto_time_a = 133 - (2560 / 128) if pause & matchID == "xcs-summit-7-og-vs-heroic-m1-nuke"
	replace tto_time_a = 51 - (2560 / 128) if pause & matchID == "xcs-summit-8-extra-salt-vs-liquid-m1-nuke"
	replace tto_time_a = 213 - (2560 / 128) if pause & matchID == "xiem-dallas-2023-europe-closed-qualifier-spirit-vs-fnatic-m2-overpass"
	replace tto_time_a = 163 - (2560 / 128) if pause & matchID == "xiem-katowice-2023-fnatic-vs-complexity-m1-inferno"
	replace tto_time_a = 116 - (2560 / 128) if pause & matchID == "xiem-katowice-2023-natus-vincere-vs-liquid-m1-inferno"
	replace tto_time_a = 207 - (2560 / 128) if pause & matchID == "xxBLAST-Premier-Fall-2020-Finals-mousesports-vs-astralis-m1-nuke"
	replace tto_time_a = 1466 - (2560 / 128) if pause & matchID == "xBLAST-Premier-Fall-Final-2022-heroic-vs-ninjas-in-pyjamas-m1-inferno"
	replace tto_time_a = 1161 - (2560 / 128) if pause & matchID == "xBLAST-Premier-Global-Final-2020-evil-geniuses-vs-liquid-m1-inferno"
	replace tto_time_a = 202 - (2560 / 128) if pause & matchID == "xBLAST-Premier-Spring-Groups-2021-og-vs-big-m1-inferno"
	replace tto_time_a = 575 - (2560 / 128) if pause & matchID == "xBLAST-Pro-Series-Lisbon-2018-astralis-vs-faze-dust2"
	replace tto_time_a = 126 - (2560 / 128) if pause & matchID == "xblasttv-paris-major-2023-europe-rmr-b-astralis-vs-spirit-m1-mirage"
	replace tto_time_a = 157 - (2560 / 128) if pause & matchID == "xblasttv-paris-major-2023-europe-rmr-b-astralis-vs-spirit-m3-overpass"
	replace tto_time_a = 152 - (2560 / 128) if pause & matchID == "xblasttv-paris-major-2023-europe-rmr-b-big-vs-vitality-m2-nuke"
	replace tto_time_a = 128 - (2560 / 128) if pause & matchID == "xblasttv-paris-major-2023-europe-rmr-b-cloud9-vs-forze-inferno"
	replace tto_time_a = 66 - (2560 / 128) if pause & matchID == "xiem-rio-2023-vitality-vs-big-m1-nuke"
	
	gen tto_time_a_min = tto_time_a / 60
	lab var tto_time_a_min "Duration (min) of technical timeout"
	
	* LAST CHECKED: xcs-summit-7-virtus-pro-vs-furia-m2-overpass
	sort matchID roundN
	br matchID roundN player tto_time* median if pause

* Dropping rounds where a tactical timeout happened after / before the technical timeout
	drop if player == "Admin" & roundN == 16
	drop if matchID == "xBLAST-Premier-Fall-Final-2021-natus-vincere-vs-big-m2-nuke" & roundN == 4
	drop if matchID == "xBLAST-Premier-Fall-Series-2020-big-vs-faze-m1-mirage" & roundNum == 3
	drop if matchID == "xBLAST-Premier-Spring-Final-2021-g2-vs-big-m3-vertigo" & roundNum == 5
	drop if matchID == "xBLAST-Premier-Spring-Final-2022-ence-vs-big-m2-nuke" & roundNum == 6
	drop if matchID == "xBLAST-Premier-Spring-Groups-2021-faze-vs-liquid-m1-nuke" & roundNum == 16
	drop if matchID == "xBLAST-Premier-World-Final-2021-natus-vincere-vs-g2-m1-nuke" & roundNum == 10
	drop if matchID == "xBLAST-Pro-Series-Miami-2019-faze-vs-mibr-mirage" & roundNum == 7
	drop if matchID == "xBLAST-Pro-Series-Miami-2019-liquid-vs-faze-m2-dust2" & roundNum == 7
	drop if matchID == "xBLAST-Pro-Series-Sao-Paulo-2019-faze-vs-nip-mirage" & roundNum == 10
	drop if matchID == "xDreamHack-Masters-Dallas-2019-liquid-vs-faze-m1-dust2" & roundNum == 10
	drop if matchID == "xDreamHack-Masters-Malmo-2019-astralis-vs-vitality-m2-dust2" & pause
	drop if matchID == "xDreamHack-Masters-Spring-2020-Europe-astralis-vs-g2-m1-dust2" & pause
	drop if matchID == "xDreamHack-Masters-Winter-2020-Europe-faze-vs-complexity-m1-inferno" & pause
	drop if matchID == "xDreamHack-Masters-Winter-2020-Europe-furia-vs-complexity-m1-mirage" & pause
	drop if matchID == "xDreamHack-Masters-Winter-2020-Europe-heroic-vs-spirit-m1-mirage" & pause
	drop if matchID == "xDreamHack-Open-January-2021-Europe-big-vs-spirit-m3-dust2" & pause
	drop if matchID == "xDreamHack-Open-January-2021-Europe-evil-geniuses-vs-funplus-phoenix-m1-nuke" & pause
	drop if matchID == "xDreamHack-Open-January-2021-Europe-gambit-vs-spirit-m2-overpass" & pause
	drop if matchID == "xDreamHack-Open-January-2021-Europe-spirit-vs-funplus-phoenix-m3-mirage" & pause
	drop if matchID == "xDreamHack-Open-Summer-2020-NorthAmerica-furia-vs-liquid-m1-vertigo" & pause
	drop if matchID == "xECS-Season-6-Finals-liquid-vs-north-nuke" & pause
	drop if matchID == "xECS-Season-6-Finals-north-vs-nrg-m1-nuke" & pause
	drop if matchID == "xECS-Season8-Finals-astralis-vs-evil-geniuses-m2-nuke" & pause
	drop if matchID == "xESL-One-Cologne-2020-NorthAmerica-liquid-vs-evil-geniuses-m1-nuke" & pause
	drop if matchID == "xESL-Pro-League-Season11-Europe-faze-vs-natus-vincere-m2-train" & pause
	drop if matchID == "xESL-Pro-League-Season11-Europe-g2-vs-faze-m2-dust2" & pause
	drop if matchID == "xESL-Pro-League-Season13-g2-vs-nip-m1-inferno" & pause
	drop if matchID == "xESL-Pro-League-Season14-g2-vs-forze-m1-mirage" & pause
	drop if matchID == "xElisa-Invitational-Fall-2021-gambit-vs-copenhagen-flames-m2-mirage" & pause
	drop if matchID == "xElisa-Invitational-Winter-2021-ence-vs-entropiq-m2-mirage" & pause
	drop if matchID == "xFantasyExpo-EU-Champions-Spring-2022-ence-vs-fnatic-mirage" & pause
	drop if matchID == "xFlashpoint-3-ClosedQualifier-complexity-vs-mousesports-m1-nuke" & pause
	drop if matchID == "xFlashpoint-3-astralis-vs-og-m2-nuke" & pause
	drop if matchID == "xIEM-Chicago-2018-astralis-vs-liquid-m2-nuke" & pause
	drop if matchID == "xIEM-Cologne-2021-gambit-vs-mousesports-m1-inferno" & pause
	drop if matchID == "xIEM-Cologne-2021-nip-vs-gambit-m1-ancient" & pause
	drop if matchID == "xIEM-Cologne-2021-virtus-pro-vs-astralis-m1-overpass" & pause
	drop if matchID == "xIEM-Global-Challenge-2020-natus-vincere-vs-furia-m1-inferno" & pause
	drop if matchID == "xIEM-Katowice-2021-astralis-vs-spirit-m1-inferno" & pause
	drop if matchID == "xIEM-Katowice-2021-faze-vs-furia-m3-train" & pause
	drop if matchID == "xIEM-Katowice-2021-g2-vs-big-m2-mirage" & pause
	drop if matchID == "xIEM-Katowice-2022-Play-In-astralis-vs-big-m1-ancient" & pause
	drop if matchID == "xIEM-Rio-Major-2022-furia-vs-natus-vincere-m3-mirage" & pause
	drop if matchID == "xIEM-Rio-Major-2022-liquid-vs-spirit-m1-vertigo" & pause
	drop if matchID == "xIEM-Rio-Major-2022-outsiders-vs-mouz-m1-ancient" & pause
	drop if matchID == "xIEM-Road-to-Rio-2022-Europe-RMR-A-cloud9-vs-ninjas-in-pyjamas-m3-vertigo" & pause
	drop if matchID == "xIEM-Road-to-Rio-2022-Europe-RMR-A-fnatic-vs-eternal-fire-m1-vertigo" & pause
	drop if matchID == "xIEM-Winter-2021-faze-vs-gambit-m1-inferno" & pause
	drop if matchID == "xREPUBLEAGUE-TIPOS-Season2-entropiq-vs-fiend-m1-mirage" & pause
	drop if matchID == "xRoobet-Cup-2022-outsiders-vs-furia-m1-inferno" & pause
	drop if matchID == "xStarSeries-i-League-Season7-faze-vs-renegades-m3-inferno" & pause
	drop if matchID == "xStarSeries-i-League-Season7-faze-vs-renegades-m2-dust2" & pause
	drop if matchID == "xStarSeries-i-League-Season7-faze-vs-renegades-m1-train" & pause
	drop if matchID == "xStarSeries-i-League-Season7-natus-vincere-vs-ence-m1-train" & pause
	drop if matchID == "xStarSeries-i-League-Season7-natus-vincere-vs-ence-m2-inferno" & pause
	drop if matchID == "xStarSeries-i-League-Season7-natus-vincere-vs-nip-m1-dust2" & pause
	drop if matchID == "xStarSeries-i-League-Season7-natus-vincere-vs-nip-m3-mirage" & pause
	drop if matchID == "xStarSeries-i-League-Season7-nip-vs-north-m1-nuke" & pause
	drop if matchID == "xStarSeries-i-League-Season7-nip-vs-north-m3-mirage" & pause
	drop if matchID == "xStarSeries-i-League-Season7-north-vs-faze-m1-train" & pause
	drop if matchID == "xStarSeries-i-League-Season7-north-vs-faze-m2-dust2" & pause
	drop if matchID == "xStarSeries-i-League-Season7-north-vs-mibr-m1-overpass" & pause
	drop if matchID == "xStarSeries-i-League-Season7-north-vs-mibr-m2-inferno" & pause
	drop if matchID == "xStarSeries-i-League-Season7-renegades-vs-mibr-m1-train" & pause
	drop if matchID == "xStarSeries-i-League-Season7-renegades-vs-mibr-m3-mirage" & pause
	drop if matchID == "xStarSeries-i-League-Season7-renegades-vs-natus-vincere-m1-inferno" & pause
	drop if matchID == "xStarSeries-i-League-Season7-renegades-vs-natus-vincere-m2-mirage" & pause
	drop if matchID == "xSteelSeries-Nova-Invitational-2022-faze-vs-og-m2-train" & pause
	drop if matchID == "xSuperNova-CS-GO-Malta-liquid-vs-big-m1-inferno" & pause
	drop if matchID == "xSuperNova-CS-GO-Malta-nrg-vs-liquid-m1-overpass" & pause
	drop if matchID == "xSuperNova-CS-GO-Malta-nrg-vs-liquid-m2-inferno" & pause
	drop if matchID == "xSuperNova-CS-GO-Malta-nrg-vs-liquid-m3-mirage" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-big-vs-gambit-m2-dust2" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-entropiq-vs-fiend-m1-mirage" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-entropiq-vs-fiend-m2-ancient" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-fiend-vs-big-m1-mirage" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-gambit-vs-entropiq-m1-vertigo" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-gambit-vs-entropiq-m2-ancient" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-gambit-vs-entropiq-m5-dust2" & pause
	drop if matchID == "xV4-Future-Sports-Festival-2021-gambit-vs-entropiq-m5-dust2" & pause
	drop if matchID == "xblasttv-paris-major-2023-europe-rmr-a-virtuspro-vs-mouz-m1-mirage" & pause
	drop if matchID == "xcs-summit-4-ence-vs-liquid-dust2" & pause
	drop if matchID == "xcs-summit-4-ence-vs-nrg-overpass" & pause
	drop if matchID == "xcs-summit-4-liquid-vs-nrg-vertigo" & pause
	drop if matchID == "xcs-summit-4-nrg-vs-liquid-dust2" & pause
	drop if matchID == "xcs-summit-4-renegades-vs-liquid-dust2" & pause
	drop if matchID == "xcs-summit-4-renegades-vs-nrg-train" & pause
	drop if matchID == "xcs-summit-7-og-vs-heroic-m2-inferno" & pause
	drop if matchID == "xesl-pro-league-season-17-eternal-fire-vs-fnatic-m1-inferno" & pause
	drop if matchID == "xesl-pro-league-season-17-outsiders-vs-fnatic-m1-inferno" & pause
	drop if matchID == "xesl-pro-league-season-17-outsiders-vs-natus-vincere-m1-ancient" & pause
	drop if matchID == "xiem-katowice-2023-play-in-furia-vs-big-m3-ancient" & pause
	drop if matchID == "xBLAST-Premier-World-Final-2021-gambit-vs-heroic-m1-inferno" & pause
	drop if matchID == "xBLAST-Premier-World-Final-2021-liquid-vs-gambit-m1-inferno" & pause
	drop if matchID == "xblasttv-paris-major-2023-9ine-vs-liquid-inferno" & pause
	drop if matchID == "xblasttv-paris-major-2023-europe-rmr-a-virtuspro-vs-mouz-m1-mirage" & pause
	drop if matchID == "xblasttv-paris-major-2023-europe-rmr-b-astralis-vs-spirit-m2-ancient" & pause
	drop if matchID == "xblasttv-paris-major-2023-europe-rmr-b-cloud9-vs-ence-m2-vertigo" & pause
	drop if matchID == "xiem-rio-2023-furia-vs-cloud9-m1-inferno" & pause

	* Charity matches
	gen gwb = strpos(matchID, "Gamers-Without-Borders") > 1
	drop if gwb
	drop gwb
	
	
* Changing technical timeouts with "undefined" people who called it. This was done by manual verification and was not possible in every matchID
	replace player = ct_p1 if matchID == "xBLAST-Pro-Series-Sao-Paulo-2019-mibr-vs-ence-train" & pause
	replace player = "karrigan" if matchID == "xICE-Challenge-2020-mousesports-vs-natus-vincere-m1-dust2" & pause
	replace player = "Perfecto" if matchID == "xIEM-Cologne-2021-vitality-vs-natus-vincere-m3-mirage" & pause
	replace player = ct_p1 if matchID == "xblast-premier-spring-showdown-2023-europe-ninjas-in-pyjamas-vs-og-m1-mirage" & pause
	replace player = ct_p1 if matchID == "xcs-summit-7-og-vs-heroic-m1-nuke" & pause
	replace player = t_p1 if matchID == "xiem-dallas-2023-europe-closed-qualifier-spirit-vs-fnatic-m2-overpass" & pause
	replace player = "s1mple" if matchID == "xxBLAST-Premier-Fall-2020-Finals-astralis-vs-natus-vincere-m1-inferno" & pause
	replace player = t_p1 if matchID == "xBLAST-Premier-Fall-Final-2021-natus-vincere-vs-vitality-m2-nuke" & pause
	replace player = t_p1 if matchID == "xBLAST-Premier-Fall-Final-2022-heroic-vs-ninjas-in-pyjamas-m1-inferno" & pause
	replace player = t_p1 if matchID == "xBLAST-Premier-Global-Final-2020-evil-geniuses-vs-furia-m2-mirage" & pause
	replace player = ct_p1 if matchID == "xBLAST-Premier-Global-Final-2020-evil-geniuses-vs-liquid-m1-inferno" & pause
	replace player = ct_p1 if matchID == "xBLAST-Premier-Spring-Groups-2021-og-vs-big-m1-inferno" & pause
	replace player = t_p1 if matchID == "xBLAST-Premier-World-Final-2021-gambit-vs-heroic-m1-inferno" & pause
	replace player = t_p1 if matchID == "xBLAST-Pro-Series-Copenhagen-2019-natus-vincere-vs-liquid-dust2" & pause
	replace player = ct_p1 if matchID == "xBLAST-Pro-Series-Lisbon-2018-astralis-vs-faze-dust2" & pause
	replace player = ct_p1 if matchID == "xblasttv-paris-major-2023-europe-rmr-b-cloud9-vs-ence-m1-ancient" & pause
	replace player = "NiKo" if matchID == "xblasttv-paris-major-2023-europe-rmr-b-cloud9-vs-g2-m2-inferno" & pause



**************************** Labels ****************************
label var pause "Technical timeout"
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



* Matching players to teams

	gen win_tto = 0
	label var win_tto "Winner Technical timeout"
	gen loss_tto = 0 
	label var loss_tto "Loser Technical timeout"
	
	* If the player who called the timeout is in the team that won the previous round, replace win_tto = 1
	replace win_tto = 1 if pause ///
	& ( ( inlist(player, ct_p1, ct_p2, ct_p3, ct_p4, ct_p5) & lag_ct_win ) ///
	| ( inlist(player, t_p1, t_p2, t_p3, t_p4, t_p5) & lag_t_win ) )
	
	* If the player who called the timeout is in the team that lost the previous round, replace win_tto = 1
	replace loss_tto = 1 if pause ///
	& ( ( inlist(player, ct_p1, ct_p2, ct_p3, ct_p4, ct_p5) & lag_t_win ) ///
	| ( inlist(player, t_p1, t_p2, t_p3, t_p4, t_p5) & lag_ct_win ) )
	
	tab player if win_tto ==0 & loss_tto ==0
	
	* NATUS VINCERE
	replace win_tto = 1 if inlist(player, "electronic", "Zeus", "s1mple") ///
	& win_Team == "Natus Vincere" /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "electronic", "Zeus", "s1mple") ///
	& loss_Team == "Natus Vincere" /// 
	& win_tto == 0 & loss_tto == 0
	
	* G2
	replace win_tto = 1 if inlist(player, "AmaNEk", "NiKo") ///
	&  win_Team == "G2 Esports" ///
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "AmaNEk", "NiKo") ///
	& loss_Team == "G2 Esports" ///
	& win_tto == 0 & loss_tto == 0
	
	* FNATIC
	replace win_tto = 1 if inlist(player, "mezii") ///
	& win_Team == "Fnatic" /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "mezii") ///
	& loss_Team == "Fnatic" /// 
	& win_tto == 0 & loss_tto == 0
	
	* ASTRALIS
	replace win_tto = 1 if inlist(player, "k0nfig", "Xyp9x") ///
	& win_Team == "Astralis" /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "k0nfig", "Xyp9x") ///
	& loss_Team == "Astralis" /// 
	& win_tto == 0 & loss_tto == 0

	
	* SPIRIT
	replace win_tto = 1 if inlist(player, "magixx.Parimatch", "Mir.Parimatch") ///
	& win_Team == "Spirit" /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "magixx.Parimatch", "Mir.Parimatch") ///
	& loss_Team == "Spirit" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* FAZE
	replace win_tto = 1 if inlist(player, "NiKo", "rain ") ///
	& win_Team == "FaZe" /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "NiKo", "rain ") ///
	& loss_Team == "FaZe" /// 
	& win_tto == 0 & loss_tto == 0
	
	* NIP
	replace win_tto = 1 if inlist(player, "REZ") ///
	& win_Team == "NiP" /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "REZ") ///
	& loss_Team == "NiP" /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* BIG
	replace win_tto = 1 if inlist(player, "tabseN") ///
	& win_Team == "BIG" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "tabseN") ///
	& loss_Team == "BIG" /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* Vitality
	replace win_tto = 1 if inlist(player, "apEX", "NBK-") ///
	& win_Team == "Vitality" /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "apEX", "NBK-") ///
	& loss_Team == "Vitality" /// 
	& win_tto == 0 & loss_tto == 0

	
	* EVIL GENIUSES
	replace win_tto = 1 if inlist(player, "Ethan", "Stanislaw") ///
	& win_Team == "EG" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "Ethan", "Stanislaw") ///
	& loss_Team == "EG" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* TEAM LIQUID
	replace win_tto = 1 if inlist(player, "nitr0") ///
	& win_Team == "Team Liquid" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "nitr0") ///
	& loss_Team == "Team Liquid" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* ENCE
	replace win_tto = 1 if inlist(player, "allu", "Aleksib") ///
	& win_Team == "ENCE" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "allu", "Aleksib") ///
	& loss_Team == "ENCE" ///   
	& win_tto == 0 & loss_tto == 0
	
	
	* CLOUD9
	replace win_tto = 1 if inlist(player, "nafany") ///
	& win_Team == "Cloud9" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "nafany") ///
	& loss_Team == "Cloud9" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* NRG
	replace win_tto = 1 if inlist(player, "stanislaw") ///
	& win_Team == "NRG" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "stanislaw") ///
	& loss_Team == "NRG" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* RENEGADES
	replace win_tto = 1 if inlist(player, "Gratisfaction") ///
	& win_Team == "Renegades" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "Gratisfaction") ///
	& loss_Team == "Renegades" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* MIBR
	replace win_tto = 1 if inlist(player, "TACO") ///
	& win_Team == "mibr" ///   
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "TACO") ///
	& loss_Team == "mibr" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* COPENHAGEN FLAMES
	replace win_tto = 1 if inlist(player, "HooXi") ///
	& win_Team == "CPH Flames" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "HooXi") ///
	& loss_Team == "CPH Flames" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* ENTROPIQ
	replace win_tto = 1 if inlist(player, "NickelBack", "hooch") ///
	& win_Team == "Entropiq" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "NickelBack", "hooch") ///
	& loss_Team == "Entropiq" ///  
	& win_tto == 0 & loss_tto == 0
	
	
	* ECSTATIC
	replace win_tto = 1 if inlist(player, "birdfromsky") ///
	& win_Team == "ECSTATIC" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "birdfromsky") ///
	& loss_Team == "ECSTATIC" ///  
	& win_tto == 0 & loss_tto == 0
	
	* Gambit
	replace win_tto = 1 if inlist(player, "interz") ///
	& win_Team == "Gambit" ///  
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "interz") ///
	& loss_Team == "Gambit" ///   
	& win_tto == 0 & loss_tto == 0
	
	* Apeks
	replace win_tto = 1 if inlist(player, "jkaem", "kyxsan") ///
	& win_Team == "Apeks" ///   
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "jkaem", "kyxsan") ///
	& loss_Team == "Apeks" ///   
	& win_tto == 0 & loss_tto == 0
	
	
	tab player if win_tto == 0 & loss_tto == 0
	
	tab win_tto loss_tto
	
	* Admin at half-time
	drop if player == "Admin" 
	
	
	br matchID tto_time* if pause
	
*-------------------------------------------------------------------------------
**# 							Summary tables
*-------------------------------------------------------------------------------	

	**# Table 1: Summary statistic

	tabstat pause tto_time tto_time_actual lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, save statistics(mean sd min max) columns(statistics)
	matrix stats = r(StatTotal)
	matrix stats = stats'
	frmttable using "Table 1 - Summary statistics", varlabels tex statmat(stats) sdec(3,3,3,3) ctitles("Variable name","Mean", "SD", "Minimum","Maximum") replace 

	**# Histograms of timeouts' duration
	hist tto_time_a_min if pause ==1, width(1) percent
	graph export "$main/Histogram duration.png", replace
	
	
	bys lossTeam: gen obs = _N
	bys lossTeam: egen obs_pause = total(loss_tto)
	
	pwcorr obs_p obs, star(0.01)
	
	drop obs*
	
	bys winTeam: gen obs = _N
	bys winTeam: egen obs_pause = total(win_tto)
	
	pwcorr obs_p obs, star(0.01)
	
	drop obs*
	
	
	
*-------------------------------------------------------------------------------
**# 							Main regressions
*-------------------------------------------------------------------------------

	gl controls i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet 
	gl scalars ""ctrls Controls" "mfe Match fixed effects" "rnfe Round fixed effects" "wfe Winner team fixed effects" "matches Number of matches" "mean_outcome Mean outcome""

	
	gen pause30 = (pause == 1 & tto_time_actual >= 20)
	replace pause30 = . if (pause != pause30)
	label var pause30 "Technical Timeout > 30 seconds"
	
	gen under_three = (lag_cum_win < 3 & pause == 1)
	gen over_three =  (lag_cum_win >= 3 & pause == 1)
	label var under_three "Technical Timeout $\times$ 1-2 Wins in a row"
	label var over_three "Technical Timeout  $\times$ 3+ Wins in a row"
	
	gen under_three30 = (lag_cum_win < 3 & pause30 == 1) if (pause == pause30)
	gen over_three30 = (lag_cum_win >= 3 & pause30 == 1) if (pause == pause30)
	label var under_three30 "Technical Timeout (30+) $\times$ 1-2 Wins in a row"
	label var over_three30 "Technical Timeout (30+)  $\times$ 3+ Wins in a row"
	
	gen win_tto30 = win_tto if (pause == pause30)
	lab var win_tto30 "Winner Technical Timeout (30s+)"
	gen loss_tto30 = loss_tto if (pause == pause30)
	lab var loss_tto30 "Loser Technical Timeout (30s+)"
	
	foreach team in win loss{
		gen `team'_under_three = (lag_cum_win < 3 & `team'_tto == 1)
		gen `team'_over_three = (lag_cum_win >= 3 & `team'_tto == 1)
		gen `team'_under_three30 = (lag_cum_win < 3 & `team'_tto30 == 1) if (pause == pause30)
		gen `team'_over_three30 = (lag_cum_win >= 3 & `team'_tto30 == 1) if (pause == pause30)
		
	}
	lab var win_under_three "Winner Technical Timeout $\times$ 1-2 Wins in a row"
	lab var win_over_three "Winner Technical Timeout $\times$ 3+ Wins in a row"
	lab var loss_under_three "Loser Technical Timeout $\times$ 1-2 Wins in a row"
	lab var loss_over_three "Loser Technical Timeout $\times$ 3+ Wins in a row"
	lab var win_under_three30 	"Winner Technical Timeout (30+) $\times$ 1-2 Wins in a row"
	lab var win_over_three30 	"Winner Technical Timeout (30+) $\times$ 3+ Wins in a row"
	lab var loss_under_three30 	"Loser Technical Timeout (30+) $\times$ 1-2 Wins in a row"
	lab var loss_over_three30 	"Loser Technical Timeout (30+) $\times$ 3+ Wins in a row"
	
	
	**# Table 2 - Main results
	eststo clear
	foreach technical in "pause" "under_three over_three" "win_under_three win_over_three loss_under_three loss_over_three" {
		
		eststo: reghdfe y `technical' $controls, abs(ID roundN winTeam) vce(cluster ID)
		summ y if e(sample)
		estadd local ctrls Yes
		estadd local mfe Yes
		estadd local rnfe Yes
		estadd scalar matches = floor(`e(N_clust1)')
		estadd scalar mean_outcome = round(`r(mean)', 0.01)
		estadd local wfe Yes

	}
	
	gen sample = e(sample)
	
	esttab using "${main}\\Table 2 - Main results.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(pause under_three over_three win_under_three win_over_three loss_under_three loss_over_three) order(pause under_three over_three win_under_three win_over_three loss_under_three loss_over_three) sfmt(a2)
	
	hist lag_cum_win if pause, freq discrete addl
	graph export "$main/Histogram accumulated wins for timeouts.png", replace
	
	
*-------------------------------------------------------------------------------
**# 						Further heterogeneity
*-------------------------------------------------------------------------------

	gen tech_1 = (lag_cum_win == 1 & pause == 1)
	label var tech_1 "Technical Timeout * 1 Win in a row"
	
	forval numb = 2/9{
		
		gen tech_`numb' = (lag_cum_win == `numb' & pause == 1)
		label var tech_`numb' "Technical Timeout * `numb' Wins in a row"
	
	}
	
	gen win_tech_1 = (lag_cum_win == 1 & win_tto == 1)
	label var win_tech_1 "Winner Technical Timeout * 1 Win in a row"
	
	forval numb = 2/9{
		
		gen win_tech_`numb' = (lag_cum_win == `numb' & win_tto == 1)
		label var win_tech_`numb' "Winner Technical Timeout * `numb' Wins in a row"
	
	}
	
	gen loss_tech_1 = (lag_cum_win == 1 & loss_tto == 1)
	label var loss_tech_1 "Loser Technical Timeout * 1 Win in a row"
	
	forval numb = 2/9{
		
		gen loss_tech_`numb' = (lag_cum_win == `numb' & loss_tto == 1)
		label var loss_tech_`numb' "Loser Technical Timeout * `numb' Wins in a row"
	
	}
	
	eststo clear
	eststo: reghdfe y tech_* $controls, abs(ID roundN winTeam) vce(cluster ID)
	summ y if e(sample)
	estadd local ctrls Yes
	estadd local mfe Yes
	estadd local rnfe Yes
	estadd scalar matches = floor(`e(N_clust1)')
	estadd scalar mean_outcome = round(`r(mean)', 0.01)
	estadd local wfe Yes
	estimates store winner
	estimates store loser
	
	esttab using "${main}\\Table 3 - Further heterogeneity.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(tech_*) order(tech_*) sfmt(a2)
	

**# Time placebos are unable to replicate the results
*-------------------------------------------------------------------------------

	xtset ID roundN
	gen tech_lead_0 = pause
	
	forval j = 1/3{
		
		local i = `j' - 1
		gen tech_lead_`j' = F.tech_lead_`i'
		label var tech_lead_`j' "`j' round lead technical timeout"
		recode tech_lead_`j' (.=0)
		
	}
	
	gen win_tech_lead_0 = win_tto
	gen loss_tech_lead_0 = loss_tto
	
	forval j = 1/3{
		
		foreach winloss in win loss {
		
			local i = `j' - 1
			gen `winloss'_tech_lead_`j' = F.`winloss'_tech_lead_`i'
			label var `winloss'_tech_lead_`j' "`j' round lead technical timeout"
			recode `winloss'_tech_lead_`j' (.=0)

			
		}
		
	}
	
	
	**# Win / Loss, 1-2 / 3+
	
	preserve
	
		local replace replace
		eststo clear
		
		forval lead = 1/3{
			
			local j = `lead' - 1
			drop if win_tech_lead_`j' ==1 | loss_tech_lead_`j' == 1
			
			drop win_under_three win_over_three loss_under_three loss_over_three
			
			foreach winloss in win loss {
			
				gen `winloss'_under_three = (lag_cum_win < 3 & `winloss'_tech_lead_`lead' == 1)
				gen `winloss'_over_three = (lag_cum_win >= 3 & `winloss'_tech_lead_`lead' == 1)
			
			}
			
			label var win_under_three "Winner Technical Timeout * 1-2 Wins in a row"
			label var win_over_three  "Winner Technical Timeout * 3+ Wins in a row"
			label var loss_under_three "Loser Technical Timeout * 1-2 Wins in a row"
			label var loss_over_three  "Loser Technical Timeout * 3+ Wins in a row"
		
			eststo: reghdfe y win_under_three win_over_three loss_under_three loss_over_three $controls, abs(ID roundN winTeam) vce(cluster ID)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd local wfe Yes
			
			esttab using "${main}\\Table 4 - Time placebos.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(win_under_three win_over_three loss_under_three loss_over_three) order(win_under_three win_over_three loss_under_three loss_over_three) sfmt(0)
		
		
			local replace append
			
			tab win_under_three win_over_three
			tab loss_under_three loss_over_three
			* 6 con 1 round lead, 5 con 2 round lead, 1 con 3 round lead
			
		}
	
	restore
	

**# Robustness: one table

	local replace replace
	
	foreach technical in "win_under_three win_over_three loss_under_three loss_over_three" {
	
		eststo clear
		
		preserve
			
			keep if strpos(msg, "tech") > 0 | pause == 0
					
			eststo: reghdfe y `technical' $controls, abs(ID roundN winTeam) vce(cluster ID)
			summ y if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes
						
		restore
		
		preserve
			
			summ tto_time_actual if pause, d
			drop if tto_time_actual > `r(p95)'
					
			eststo: reghdfe y `technical' $controls, abs(ID roundN winTeam) vce(cluster ID)
			summ y if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes
						
		restore

		preserve
			
			summ tto_time if pause, d
			drop if tto_time > `r(p95)'
					
			eststo: reghdfe y `technical' $controls, abs(ID roundN winTeam) vce(cluster ID)
			summ y if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes

						
		restore
		
		preserve
	
			keep if strpos(msg, "tech") > 0 | pause == 0
			summ tto_time_actual if pause, d
			drop if tto_time_actual > `r(p95)'
	
				
			eststo: reghdfe y `technical' $controls, abs(ID roundN winTeam) vce(cluster ID)
			summ y if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes

		restore
		
		preserve
	
			keep if strpos(msg, "tech") > 0 | pause == 0
			summ tto_time if pause, d
			drop if tto_time > `r(p95)'
	
				
			eststo: reghdfe y `technical' $controls, abs(ID roundN winTeam) vce(cluster ID)
			summ y if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes
			
		restore
		
		esttab using "${main}\\Table 5 - Robustness.tex", fr label nonumber `replace' b(4) se(4) mtitle("Word tech in message" "Excluding duration outliers (manual)" "Excluding duration outliers (recorded time)" "Word tech in message and excluding duration outliers (manual)" "Word tech in message and excluding duration outliers (recorded time)") star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(`technical') order(`technical') sfmt(a2)
		
		local replace append
		
	}
	
	