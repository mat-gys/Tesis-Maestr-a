	
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
	
	egen after_tec_in_row = min(cond(tec_in_row == 1, roundNum, .)), by(matchID)  
	bysort matchID: keep if roundNum < after_tec_in_row
	drop tec_in_row after_tec_in_row
	
	xtset ID roundN
	gen lag_cum_win = L.cum_win
	label var lag_cum_win "Wins in a row"
	gen lag_lag_cum_win = L.lag_cum_win
	

* Deleting rounds after a technical timeout
	bysort matchID: tab pause
	egen after_tto = min(cond(pause == 1 & roundN !=1, roundNum, .)), by(matchID)  
	bysort matchID: keep if roundNum <= after_tto

* Creating non-defined timeout rounds to drop
	gen nonDefinedTimeOut = ((freezeTimeTotal > median_freeze_time) & roundNum != 1 & pause == 0)
	
	egen after_nond_to = min(cond(nonD ==1, roundNum, .)), by(matchID)  
	bysort matchID: keep if roundNum < after_nond_to
	
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
	
	gen tto_time = pause * (freezeTimeTotal - median_freeze_time)/128
	label var tto_time "Duration (s) of technical timeout (recorded in demo)"
	
	replace tto_time = 0 if tto_time < 0
	
	************************* Creating outcome vars ************************
	gen y = (cum_win == 1 )
	label var y "0 if team that won last round also wins current round"
	
	
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
	* These rounds were probably reset, check manually if possible
	
	
	* Dropping matches with win_score >15
	br if (ctScore > 15 | tScore > 15) & !missing(ctS, tS)
	drop if (ctScore >= 16 | tScore >= 16) & !missing(ctS, tS)

	
	**************** Hand-measured time between rounds ****************
	
	gen tto_time_actual = tto_time
	label var tto_time_a "Duration (s) of technical timeout"
	
	
	*replace tto_time_a = 157 - (2560 / 128)  if pause & matchID == "xIEM-Global-Challenge-2020-natus-vincere-vs-astralis-m2-nuke" & roundNum == 5
	*replace tto_time_a = (14115/128) - (6400 / 128)  if pause & matchID == "xIEM-Katowice-2021-g2-vs-big-m2-mirage" & roundNum == 7
	*replace tto_time_a = 418 - (2560 / 128)  if pause & matchID == "xPinnacle-Cup-2021-gambit-vs-spirit-m2-mirage" & roundNum == 8
	*replace tto_time_a = 181 - (2560 / 128)  if pause & matchID == "xPinnacle-Cup-2021-gambit-vs-spirit-m3-train" & roundNum == 3
	*replace tto_time_a = 117 - (2560 / 128)  if pause & matchID == "xcs-summit-6-Europe-25jun-faze-vs-big-m1-mirage" & roundNum == 8
	*replace tto_time_a = 85 - (2560 / 128)  if pause & matchID == "xESL-One-Road-to-Rio-Europe-astralis-vs-faze-m1-dust2" & roundNum == 5
	*replace tto_time_a = 230 - (2560 / 128)  if pause & matchID == "xESL-One-Road-to-Rio-NorthAmerica-evil-geniuses-vs-100-thieves-m3-nuke" & roundNum == 4
	*replace tto_time_a = 260 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Spring-2020-Americas-Finals-furia-vs-liquid-m3-mirage" & roundNum == 9
	*replace tto_time_a = 139 - (2560 / 128)  if pause & matchID == "xESL-Pro-League-Season12-Europe-2oct-natus-vincere-vs-heroic-m2-mirage" & roundNum == 2
	*replace tto_time_a = 106 - (2560 / 128)  if pause & matchID == "xIEM-New-York-2020-NorthAmerica-furia-vs-liquid-m3-vertigo" & roundNum == 9
	*replace tto_time_a = 207 - (2560 / 128)  if pause & matchID == "xxBLAST-Premier-Fall-2020-Finals-mousesports-vs-astralis-m1-nuke" & roundNum == 4
	*replace tto_time_a = 88 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Spring-Showdown-2021-gambit-vs-furia-m1-mirage" & roundNum == 3
	*replace tto_time_a = 190 - (2560 / 128)  if pause & matchID == "xBLAST-Premier-Spring-Groups-2021-og-vs-big-m1-inferno" & roundNum == 6
	*replace tto_time_a = 85 - (2560 / 128)  if pause & matchID == "xESL-One-Cologne-2020-NorthAmerica-evil-geniuses-vs-liquid-m1-mirage" & roundNum == 11
	
	
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

/*
replace tto_time_a = 237 - (2560 / 128)  if pause & matchID == "xESL-Pro-League-Season11-NorthAmerica-10apr-liquid-vs-evil-geniuses-m1-nuke" & roundNum == 13

There was an error with this match's freezetime, etc variables
*/



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
	& ((inlist(ctTeam, "NAVI", "NAVI 1XBET", "NAVI GG.BET", "NAVI GGBET", "Natus Vincere") & lag_ct_win) | (inlist(tTeam, "NAVI", "NAVI 1XBET", "NAVI GG.BET", "NAVI GGBET", "Natus Vincere") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "electronic", "Zeus", "s1mple") ///
	& ((inlist(ctTeam, "NAVI", "NAVI 1XBET", "NAVI GG.BET", "NAVI GGBET", "Natus Vincere") & lag_t_win) | (inlist(tTeam, "NAVI", "NAVI 1XBET", "NAVI GG.BET", "NAVI GGBET", "Natus Vincere") & lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	* G2
	replace win_tto = 1 if inlist(player, "AmaNEk", "NiKo") ///
	& ((inlist(ctTeam, "G2 Esports") & lag_ct_win) | (inlist(tTeam, "G2 Esports") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "AmaNEk", "NiKo") ///
	& ((inlist(ctTeam, "G2 Esports") & lag_t_win) | (inlist(tTeam, "G2 Esports") & lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	* FNATIC
	replace win_tto = 1 if inlist(player, "mezii") ///
	& ((inlist(ctTeam, "Fnatic", "Fnatic Rivalry", "fnatic") & lag_ct_win) | (inlist(tTeam, "Fnatic", "Fnatic Rivalry", "fnatic") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "mezii") ///
	& ((inlist(ctTeam, "Fnatic", "Fnatic Rivalry", "fnatic") & lag_t_win) | (inlist(tTeam, "Fnatic", "Fnatic Rivalry", "fnatic") & lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	* ASTRALIS
	replace win_tto = 1 if inlist(player, "k0nfig", "Xyp9x") ///
	& ((inlist(ctTeam, "Astralis", "Astralis UNIBET") & lag_ct_win) | (inlist(tTeam, "Astralis", "Astralis UNIBET") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "k0nfig", "Xyp9x") ///
	& ((inlist(ctTeam, "Astralis", "Astralis UNIBET") & lag_t_win) | (inlist(tTeam, "Astralis", "Astralis UNIBET") & lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0

	
	* SPIRIT
	replace win_tto = 1 if inlist(player, "magixx.Parimatch", "Mir.Parimatch") ///
	& ((inlist(ctTeam, "Spirit") & lag_ct_win) | (inlist(tTeam, "Spirit") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "magixx.Parimatch", "Mir.Parimatch") ///
	& ((inlist(ctTeam, "Spirit") & lag_t_win) | (inlist(tTeam, "Spirit") & lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* FAZE
	replace win_tto = 1 if inlist(player, "NiKo", "rain ") ///
	& ((inlist(ctTeam, "FaZe", "FaZe Clan") &  lag_ct_win) | (inlist(tTeam, "FaZe", "FaZe Clan") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "NiKo", "rain ") ///
	& ((inlist(ctTeam, "FaZe", "FaZe Clan") & lag_t_win) | (inlist(tTeam, "FaZe", "FaZe Clan") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	* NIP
	replace win_tto = 1 if inlist(player, "REZ") ///
	& ((inlist(ctTeam, "Ninjas in Pyjamas") &  lag_ct_win) | (inlist(tTeam, "Ninjas in Pyjamas", "Ninjas In Pyjamas") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "REZ") ///
	& ((inlist(ctTeam, "Ninjas in Pyjamas") & lag_t_win) | (inlist(tTeam, "Ninjas in Pyjamas", "Ninjas In Pyjamas") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* BIG
	replace win_tto = 1 if inlist(player, "tabseN") ///
	& ((inlist(ctTeam, "BIG", "BIG Clan") &  lag_ct_win) | (inlist(tTeam, "BIG", "BIG Clan") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "tabseN") ///
	& ((inlist(ctTeam, "BIG", "BIG Clan") & lag_t_win) | (inlist(tTeam, "BIG", "BIG Clan") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* Vitality
	replace win_tto = 1 if inlist(player, "apEX", "NBK-") ///
	& ((inlist(ctTeam, "Team Vitality", "TeamVitality", "Vitality") &  lag_ct_win) | (inlist(tTeam, "Team Vitality", "TeamVitality", "Vitality") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "apEX", "NBK-") ///
	& ((inlist(ctTeam, "Team Vitality", "TeamVitality", "Vitality") & lag_t_win) | (inlist(tTeam, "Team Vitality", "TeamVitality", "Vitality") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0

	
	* EVIL GENIUSES
	replace win_tto = 1 if inlist(player, "Ethan", "Stanislaw") ///
	& ((inlist(ctTeam, "Evil Geniuses") &  lag_ct_win) | (inlist(tTeam, "Evil Geniuses", "EVIL GENIUSES", "EG") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "Ethan", "Stanislaw") ///
	& ((inlist(ctTeam, "Evil Geniuses") & lag_t_win) | (inlist(tTeam, "Evil Geniuses", "EVIL GENIUSES", "EG") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* TEAM LIQUID
	replace win_tto = 1 if inlist(player, "nitr0") ///
	& ((inlist(ctTeam, "Team Liquid", "Liquid") &  lag_ct_win) | (inlist(tTeam, "Team Liquid", "Liquid") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "nitr0") ///
	& ((inlist(ctTeam, "Team Liquid", "Liquid") & lag_t_win) | (inlist(tTeam, "Team Liquid", "Liquid") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* ENCE
	replace win_tto = 1 if inlist(player, "allu", "Aleksib") ///
	& ((inlist(ctTeam, "ENCE") &  lag_ct_win) | (inlist(tTeam, "ENCE") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "allu", "Aleksib") ///
	& ((inlist(ctTeam, "ENCE") & lag_t_win) | (inlist(tTeam, "ENCE") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* CLOUD9
	replace win_tto = 1 if inlist(player, "nafany") ///
	& ((inlist(ctTeam, "Cloud9") &  lag_ct_win) | (inlist(tTeam, "Cloud9") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "nafany") ///
	& ((inlist(ctTeam, "Cloud9") & lag_t_win) | (inlist(tTeam, "Cloud9") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* NRG
	replace win_tto = 1 if inlist(player, "stanislaw") ///
	& ((inlist(ctTeam, "NRG", "NRG Esports") &  lag_ct_win) | (inlist(tTeam, "NRG", "NRG Esports") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "stanislaw") ///
	& ((inlist(ctTeam, "NRG", "NRG Esports") & lag_t_win) | (inlist(tTeam, "NRG", "NRG Esports") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* RENEGADES
	replace win_tto = 1 if inlist(player, "Gratisfaction") ///
	& ((inlist(ctTeam, "Renegades") &  lag_ct_win) | (inlist(tTeam, "Renegades") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "Gratisfaction") ///
	& ((inlist(ctTeam, "Renegades") & lag_t_win) | (inlist(tTeam, "Renegades") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* MIBR
	replace win_tto = 1 if inlist(player, "TACO") ///
	& ((inlist(ctTeam, "MIBR") &  lag_ct_win) | (inlist(tTeam, "MIBR") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "TACO") ///
	& ((inlist(ctTeam, "MIBR") & lag_t_win) | (inlist(tTeam, "MIBR") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* COPENHAGEN FLAMES
	replace win_tto = 1 if inlist(player, "HooXi") ///
	& ((inlist(ctTeam, "CPH Flames", "Copenhagen Flames") &  lag_ct_win) | (inlist(tTeam, "CPH Flames", "Copenhagen Flames") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "HooXi") ///
	& ((inlist(ctTeam, "CPH Flames", "Copenhagen Flames") & lag_t_win) | (inlist(tTeam, "CPH Flames", "Copenhagen Flames") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* ENTROPIQ
	replace win_tto = 1 if inlist(player, "NickelBack", "hooch") ///
	& ((inlist(ctTeam, "Entropiq") &  lag_ct_win) | (inlist(tTeam, "Entropiq") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "NickelBack", "hooch") ///
	& ((inlist(ctTeam, "Entropiq") & lag_t_win) | (inlist(tTeam, "Entropiq") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	* ECSTATIC
	replace win_tto = 1 if inlist(player, "birdfromsky") ///
	& ((inlist(ctTeam, "ECSTATIC") &  lag_ct_win) | (inlist(tTeam, "ECSTATIC") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "birdfromsky") ///
	& ((inlist(ctTeam, "ECSTATIC") & lag_t_win) | (inlist(tTeam, "ECSTATIC") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	* Gambit
	replace win_tto = 1 if inlist(player, "interz") ///
	& ((inlist(ctTeam, "Gambit") &  lag_ct_win) | (inlist(tTeam, "Gambit") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "interz") ///
	& ((inlist(ctTeam, "Gambit") & lag_t_win) | (inlist(tTeam, "Gambit") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	* Apeks
	replace win_tto = 1 if inlist(player, "jkaem", "kyxsan") ///
	& ((inlist(ctTeam, "Apeks") &  lag_ct_win) | (inlist(tTeam, "Apeks") & lag_t_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	replace loss_tto = 1 if inlist(player, "jkaem", "kyxsan") ///
	& ((inlist(ctTeam, "Apeks") & lag_t_win) | (inlist(tTeam, "Apeks") &  lag_ct_win)) /// 
	& win_tto == 0 & loss_tto == 0
	
	
	tab player if win_tto == 0 & loss_tto == 0
	
	tab win_tto loss_tto
	
	* Admin at half-time
	drop if player == "Admin" 
	* & roundN == 16
	
	
	br matchID tto_time* if pause
	
	
	*hist tto_time_actual if pause, width(50) percent
	*summ tto_time_a if pause, d
	*drop if tto_time_a > `r(p90)'
	
*-------------------------------------------------------------------------------
**# 							Summary tables
*-------------------------------------------------------------------------------	

	**# Table 1: Summary statistic

	tabstat pause tto_time tto_time_a lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet, save statistics(mean sd min max) columns(statistics)
	matrix stats = r(StatTotal)
	matrix stats = stats'
	frmttable using "Table 1 - Summary statistics", varlabels tex statmat(stats) sdec(3,3,3,3) ctitles("Variable name","Mean", "SD", "Minimum","Maximum") replace 

	**# Histograms of timeouts' duration
	hist tto_time_actual if pause ==1, width(30) percent
	graph export "$main/Histogram duration.png", replace
	
*-------------------------------------------------------------------------------
**# 							Main regressions
*-------------------------------------------------------------------------------

	gl controls i.lag_cum_win win_score win_Eq loss_Eq win_Cash loss_Cash win_defusers loss_defusers win_Armor loss_Armor win_Helmet loss_Helmet
	gl scalars ""ctrls Controls" "mfe Match FE" "rnfe Round FE" "matches Number of matches""

	
	gen pause30 = (pause == 1 & tto_time_a >= 20)
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
		
		eststo: reghdfe y `technical' $controls, abs(ID roundN) vce(cluster ID)
		estadd local ctrls Yes
		estadd local mfe Yes
		estadd local rnfe Yes
		estadd scalar matches = floor(`e(N_clust1)')

	}
	
	esttab using "${main}\\Table 2 - Main results.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(pause under_three over_three win_under_three win_over_three loss_under_three loss_over_three) order(pause under_three over_three win_under_three win_over_three loss_under_three loss_over_three) sfmt(0)
	
	
	esttab using "${main}\\Appendix table 1 - Full regression.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap order(pause under_three over_three win_under_three win_over_three loss_under_three loss_over_three *) sfmt(0)
	
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
	eststo: reghdfe y tech_* $controls, abs(ID roundN) vce(cluster ID)
	estadd local ctrls Yes
	estadd local mfe Yes
	estadd local rnfe Yes
	estadd scalar matches = floor(`e(N_clust1)')
	estimates store winner
	estimates store loser
	
	esttab using "${main}\\Table 3 - Further heterogeneity.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(tech_*) order(tech_*) sfmt(0) unst
	
	*coefplot 	(winner, keep(win_tech_*) label(Winner)) ///
	*			(loser, keep(loss_tech_*) label(Loser)), drop(_cons) xline(0)  level(95)
	*///
	*ylabel(, val) keep(win_tech_* loss_tech_*) order(win_tech_* loss_tech_*) level(95) title(,position(12))
	


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
		
			eststo: reghdfe y win_under_three win_over_three loss_under_three loss_over_three $controls, abs(ID roundN) vce(cluster ID)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			
			esttab using "${main}\\Table 4 - Time placebos.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(win_under_three win_over_three loss_under_three loss_over_three) order(win_under_three win_over_three loss_under_three loss_over_three) sfmt(0)
		
		
			local replace append
			
			tab win_under_three win_over_three
			tab loss_under_three loss_over_three
			* 6 con 1 round lead, 5 con 2 round lead, 1 con 3 round lead
			
		}
	
	restore
	

**# Robustness: one table

	local replace replace
	
	foreach technical in "win_under_three win_over_three loss_under_three loss_over_three" "under_three over_three"{
	
		eststo clear
		
		preserve
			
			keep if strpos(msg, "tech") > 0 | pause == 0
					
			eststo: reghdfe y `technical' $controls, abs(ID roundN) vce(cluster ID)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
						
		restore
		
		preserve
			
			summ tto_time_a if pause, d
			drop if tto_time_a > `r(p95)'
					
			eststo: reghdfe y `technical' $controls, abs(ID roundN) vce(cluster ID)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
						
		restore

		preserve
			
			summ tto_time if pause, d
			drop if tto_time > `r(p95)'
					
				eststo: reghdfe y `technical' $controls, abs(ID roundN) vce(cluster ID)
				estadd local ctrls Yes
				estadd local mfe Yes
				estadd local rnfe Yes
				estadd scalar matches = floor(`e(N_clust1)')

						
		restore
		
		preserve
	
			keep if strpos(msg, "tech") > 0 | pause == 0
			summ tto_time_a if pause, d
			drop if tto_time_a > `r(p95)'
	
				
			eststo: reghdfe y `technical' $controls, abs(ID roundN) vce(cluster ID)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')

		restore
		
		preserve
	
			keep if strpos(msg, "tech") > 0 | pause == 0
			summ tto_time if pause, d
			drop if tto_time > `r(p95)'
	
				
			eststo: reghdfe y `technical' $controls, abs(ID roundN) vce(cluster ID)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')

		restore
		
		esttab using "${main}\\Table 5 - Robustness.tex", fr label nonumber `replace' b(4) se(4) mtitle("Word tech in message" "Excluding duration outliers (manual)" "Excluding duration outliers (recorded time)" "Word tech in message and excluding duration outliers (manual)" "Word tech in message and excluding duration outliers (recorded time)") star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(`technical') order(`technical') sfmt(0)
		
		local replace append
		
	}
	
	