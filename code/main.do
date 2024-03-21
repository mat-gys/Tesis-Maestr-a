
**# Setup
********************************************************************************
		
	clear all
	cls
	
	global main "C:/Users/Matias/Documents/UDESA/Tesis_maestria/Replication files/output"
	
	cd "$main"
	
	import delimited "parsed.csv", varnames(1) clear encoding("utf-8")
	
	compress
	
	split matchid, parse("-") gen(splitID)
	
	assert lower(iswarmup) == "false"

	replace splitID3 = splitID3 + "-" + splitID4 if inlist(splitID6, "m1", "m2", "m3", "m4", "m5")
	replace splitID4 = splitID5 if inlist(splitID6, "m1", "m2", "m3", "m4", "m5")
	replace splitID5 = splitID6 if inlist(splitID6, "m1", "m2", "m3", "m4", "m5")
	replace splitID6 = cond(inlist(splitID7, "p1", "p2", "p3") ///
							, splitID7 ///
							, cond(inlist(splitID6, "m1", "m2", "m3", "m4", "m5") ///
								   , "" ///
								   , splitID6))
	
	encode splitID3, gen(tournament)
	
	
	foreach str in "th" "rd" "st" "nd" {
	
		di "`str'"
	
		replace splitID4 = subinstr(splitID4, "`str'", "", .)
	
	}
	
	gen date = date(splitID4, "MDY")
	format date %td
	
	gen year = year(date)
	gen month = month(date)
	gen day = day(date)
	
	
	
	gen matchNumber = real(substr(splitID5, -1, .))
	gen mapPart = real(substr(splitID6, -1, .))
	
	drop splitID4 splitID7

	
	**# Checking data
	****************************************************************************
	
	* Fixing issue with split demos
	
	// If missing first part, drop
	
	bys tournament date splitID1 splitID2 (mapPart): gen missingPartOne = (mapPart[1] != 1) if !missing(mapPart)
	
	drop if missingPartOne == 1
	
	
	forval part = 1(1)3 {
	
		replace matchid = subinstr(matchid, "-p`part'", "", .) if !missing(mapPart)
	
	}
	
	bys matchid (mapPart roundnum): replace roundnum = _n if !missing(mapPart)
	
	forval i = 1/5 {
	
		bys matchid (roundnum): replace ct_p`i' = ct_p`i'[_n - 1] if !missing(ct_p`i'[_n - 1]) & inrange(roundnum, 2, 15)
		
		bys matchid (roundnum): replace t_p`i' = t_p`i'[_n - 1] if !missing(t_p`i'[_n - 1]) & inrange(roundnum, 2, 15)
		
		bys matchid (roundnum): replace ct_p`i' = t_p`i'[_n - 1] if !missing(ct_p`i'[_n - 1]) & roundnum == 16
		
		bys matchid (roundnum): replace t_p`i' = ct_p`i'[_n - 1] if !missing(t_p`i'[_n - 1]) & roundnum == 16
	
		bys matchid (roundnum): replace ct_p`i' = ct_p`i'[_n - 1] if !missing(ct_p`i'[_n - 1]) & roundnum >= 17
		
		bys matchid (roundnum): replace t_p`i' = t_p`i'[_n - 1] if !missing(t_p`i'[_n - 1]) & roundnum >= 17
	
	}
	
	encode matchid, gen(ID)
	
	ren (roundnum ctscore tscore endctscore endtscore ctteam tteam winningside freezetimetotal ctalive cthp ctarmor cthelmet cteq ctutility cteqvalstart ctcash talive thp tarmor thelmet teq tutility teqvalstart tcash mapname splitID1 splitID2) (roundNumber ctScore tScore endCTScore endTScore ctTeam tTeam winningSide freezeTimeTotal ctAlive ctHp ctArmor ctHelmet ctEq ctUtility ctEqValStart ctCash tAlive tHp tArmor tHelmet tEq tUtility tEqValStart tCash mapName team1 team2)
	
	xtset ID roundNumber
	
	gen totalScore = endCTScore + endTScore
	gen scoreMismatch = totalScore != roundNumber
	bys ID: egen maxScoreMismatch = max(scoreMismatch)
	
	/*
	br ID roundNumber ctScore tScore end* scoreMismatch if maxScoreMismatch == 1
	*/
	
	drop if maxScoreMismatch == 1
	
	drop totalScore scoreMismatch maxScoreMismatch
	
	**# For graphs
	****************************************************************************
	
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
	
**# Variable generation
********************************************************************************

	* Charity matches
	drop if strpos(matchid, "Gamers Without Borders") > 1 | strpos(matchid, "Showmatch CS") > 1 | strpos(matchid, "Battle of Betway 2021")

	bys tournament: egen medianFreezeTime = median(freezeTimeTotal)
	
	assert !missing(winningSide)
	
	**# Win, loss and difference in scores
	****************************************************************************
	gen ctWin = (winningSide == "CT")
	label var ctWin "Team A won this round"
	
	gen tWin = (ctWin ~= 1)
	label var tWin "Team B won this round"
	
	* Last round's winner, loser and differential score
	bys ID (roundNum): gen winScore = (endCTScore[_n-1] * ctWin[_n-1]) + (endTScore[_n-1] * tWin[_n-1])
	
	bys ID (roundNum): gen lossScore = (endCTScore[_n-1] * tWin[_n-1]) + (endTScore[_n-1] * ctWin[_n-1])
	
	bys ID (roundNum): gen differenceScore = winScore - lossScore
	
	label var winScore "Score for previous round winner"
	label var lossScore "Score for previous round loser"
	label var differenceScore "Score differential (winner - loser)"
	
	**# Accumulated wins
	****************************************************************************
	
	bys ID: egen maxRoundNumber = max(roundNumber)
	bys ID: egen minRoundNumber = min(roundNumber)
	
	tab maxRoundNumber minRoundNumber // There are some incomplete demos
	
	/*
	If a game is less than 16 rounds, then the demo is incomplete
	
	br ID roundNum maxRoundNumber pause if maxRoundNumber <= 15
	
	As long as the data is not missing, and no rounds are skipped, no reason to drop these
	*/
	order ID roundNumber 
	bys ID (roundNumber): gen roundSkipped = ((roundNumber - 1) != roundNumber[_n-1]) if roundNumber != 1 // First round has no comparison
	
	assert roundSkipped == 0 if roundNumber != 1 // No rounds are skipped
	
	gen accumulatedWins = 1
	bysort ID (roundNumber): replace accumulatedWins = accumulatedWins + accumulatedWins[_n - 1] if ctWin == ctWin[_n - 1] & roundNum <= 15
	
	bysort ID (roundNumber): replace accumulatedWins = accumulatedWins + accumulatedWins[_n - 1] if ctWin != ctWin[_n - 1] & roundN == 16
	
	bysort ID (roundNumber): replace accumulatedWins = accumulatedWins + accumulatedWins[_n - 1] if ctWin == ctWin[_n - 1] & inrange(roundN, 17, 33)
	
	forval round = 34(6)60 { // Teams switch every 6 rounds starting on round 34
	
		bysort ID (roundNumber): replace accumulatedWins = accumulatedWins + accumulatedWins[_n - 1] if ctWin != ctWin[_n - 1] & roundN == `round'
		bysort ID (roundNumber): replace accumulatedWins = accumulatedWins + accumulatedWins[_n - 1] if ctWin == ctWin[_n - 1] & inrange(roundN, `round' + 1, `round' + 5)
	
	}
	
	/*
	Checking it works
	br ID roundNumber *Team *Win end*Score accumulatedWins if maxRoundNumber > 31
	*/
	
	sort ID roundNum
	
	bysort ID (roundNumber): gen lagAccumulatedWins = L.accumulatedWins
	label var lagAccumulatedWins "Wins in a row"
	
	tab lagAccumulatedWins, gen(lagAccumulatedWins_)
	
	**# Distribution of accumulated wins
	****************************************************************************
	
	hist lagAccumulatedWins, discrete percent xtitle("Distribution of accumulated wins")
	graph export "$main/R&R - Accumulated wins all.png", replace
	
	
	**# Generating controls
	****************************************************************************
	
	xtset ID roundN
	bysort ID (roundNumber): gen lagCtWin = L.ctWin
	bysort ID (roundNumber): gen lagTWin = L.tWin
	
	local variables Alive Armor Helmet Eq Utility EqValStart Cash
	
	foreach var of local variables {
	
		* Variable state at last recorded frame of previous round
		bysort ID (roundNumber): gen lagCt`var' = L.ct`var'
		bysort ID (roundNumber): gen lagT`var' = L.t`var'
		
		* Winner and loser
		bysort ID (roundNumber): gen win`var' = (lagCt`var' * lagCtWin) + (lagT`var' * lagTWin)
		bysort ID (roundNumber): gen loss`var' = (lagCt`var' * lagTWin) + (lagT`var' * lagCtWin)
		
	}
	
	// After round 15, teams switch sides, and everything resets
		
	bysort ID (roundNumber): replace winCash = 800 * 5 if roundN == 16
	bysort ID (roundNumber): replace lossCash = 800 * 5 if roundN == 16
								
	
	foreach var in Armor Helmet Eq Utility EqValStart {
	
		bysort ID (roundNumber): replace win`var' = 0 if roundN == 16
		bysort ID (roundNumber): replace loss`var' = 0 if roundN == 16
	
	}
	
	// In overtime, at each team switch, players are given 16000 cash (each) and they don't get to keep any equipment from the previous round
	
	forval round = 34(6)60 {
	
		bysort ID (roundNumber): replace winCash = 16000 * 5 if roundNumber == `round'
		bysort ID (roundNumber): replace lossCash = 16000 * 5 if roundNumber == `round'
		
		foreach var in Armor Helmet Eq Utility EqValStart {
		
			bysort ID (roundNumber): replace win`var' = 0 if roundNumber == `round'
			bysort ID (roundNumber): replace loss`var' = 0 if roundNumber == `round'
		
		}
	
	}
	
		
	// Non-linear cash control
	label define wincashCategory 0 "Win team - Full economy" 1 "Win team - Economy" 2 "Win team - Half buy" 3 "Win team - Full buy"
	label define losscashCategory 0 "Loss team - Full economy" 1 "Loss team - Economy" 2 "Loss team - Half buy" 3 "Loss team - Full buy"
	
	foreach v in win loss {
	
		gen `v'CashCategory = cond(`v'Cash < 2000 ///
								   , 0 ///
								   , cond(`v'Cash < 8000 ///
										  , 1 ///
										  , cond(`v'Cash < 22000 ///
												 , 2 ///
												 , 3))) if !missing(`v'Cash)
		
		label values `v'CashCategory `v'cashCategory
		
	}
	
	
	/*
	Checking it works
	br ID roundNumber ctTeam tTeam winCash lossCash winEq lossEq if maxRoundNumber > 31
	*/
	
	// Have to do defusers separately because only CTs have them
	bysort ID (roundNumber): gen lagDefusers = L.defusers
	bysort ID (roundNumber): gen winDefusers = (lagDefusers * lagCtWin)
	bysort ID (roundNumber): gen lossDefusers = (lagDefusers * lagTWin)
	
	replace winDefusers = 0 if roundN == 16
	replace lossDefusers = 0 if roundN == 16
	
	forval round = 34(6)60 {
	
		replace winDefusers = 0 if roundNumber == `round'
	
	}
	
	// Win and loss team
	bys ID (roundN): gen lagCtTeam = ctTeam[_n - 1]
	bys ID (roundN): gen lagTTeam = tTeam[_n - 1]
	bys ID (roundN): gen winTeam = (lagCtTeam * lagCtWin) + (lagTTeam * lagTWin)
	bys ID (roundN): gen lossTeam = (lagCtTeam * lagTWin) + (lagTTeam * lagCtWin)
	
	// Cleaning names
	foreach team in win loss {
	
		replace `team'Team = subinstr(`team'Team, "." , "", .)
		
		replace `team'Team = "BIG" if strpos(lower(`team'Team), "big") > 0
		replace `team'Team = "CPH Flames" if strpos(lower(`team'Team), "flames") > 0
		replace `team'Team = "ENCE" if strpos(lower(`team'Team), "ence") > 0
		replace `team'Team = "forZe" if strpos(lower(`team'Team), "forze") > 0
		replace `team'Team = "FURIA" if strpos(lower(`team'Team), "furia") > 0
		replace `team'Team = "FaZe" if strpos(lower(`team'Team), "faze") > 0
		replace `team'Team = "Fnatic" if strpos(lower(`team'Team), "fnatic") > 0
		replace `team'Team = "G2" if strpos(lower(`team'Team), "g2") > 0
		replace `team'Team = "Gambit" if strpos(lower(`team'Team), "gambit") > 0 | strpos(lower(`team'Team), "gmb")
		replace `team'Team = "Heroic" if strpos(lower(`team'Team), "heroic") > 0
		replace `team'Team = "HAVU" if strpos(lower(`team'Team), "havu") > 0
		replace `team'Team = "Imperial" if strpos(lower(`team'Team), "imperial") > 0
		replace `team'Team = "Movistar Riders" if strpos(lower(`team'Team), "movistar") > 0
		replace `team'Team = "Natus Vincere" if strpos(lower(`team'Team), "navi") > 0 | strpos(lower(`team'Team), "na'vi") > 0
		replace `team'Team = "NiP" if (lower(`team'Team) == "nip") | strpos(lower(`team'Team), "ninjas") > 0
		replace `team'Team = "OG" if (lower(`team'Team) == "og") | strpos(lower(`team'Team), "ogesports") > 0 | strpos(lower(`team'Team), "og esports") > 0 | strpos(lower(`team'Team), "team og") > 0
		replace `team'Team = "Sprout" if strpos(lower(`team'Team), "sprout") > 0
		replace `team'Team = "Spirit" if strpos(lower(`team'Team), "spirit") > 0
		replace `team'Team = "Virtus Pro" if strpos(lower(`team'Team), "virtus") > 0 | strpos(lower(`team'Team), "vp") > 0
		replace `team'Team = "MOUZ" if strpos(lower(`team'Team), "mouz") > 0 | strpos(lower(`team'Team), "mouse") > 0
		replace `team'Team = "paiN" if strpos(lower(`team'Team), "pain") > 0
		replace `team'Team = "Complexity" if strpos(lower(`team'Team), "complexity") > 0
		replace `team'Team = "Eternal Fire" if strpos(lower(`team'Team), "eternal fire") > 0
		replace `team'Team = "FunPlus Pheonix" if strpos(lower(`team'Team), "funplus phoenix") > 0 | lower(`team'Team) == "fpx"
		replace `team'Team = "Vitality" if strpos(lower(`team'Team), "vitality") | strpos(lower(`team'Team), "vita") 
		replace `team'Team = "sAw" if (lower(`team'Team) == "saw")
		replace `team'Team = "100 Thieves" if strpos(lower(`team'Team), "100t") 
		replace `team'Team = "Avangar" if strpos(lower(`team'Team), "avangar") 
		replace `team'Team = "Astralis" if strpos(lower(`team'Team), "astralis") 
		replace `team'Team = "Evil Geniuses" if strpos(lower(`team'Team), "evil geniuses") | lower(`team'Team) == "EG"
		replace `team'Team = "GenG" if strpos(lower(`team'Team), "geng") 
		replace `team'Team = "Team Liquid" if strpos(lower(`team'Team), "liquid") 
		replace `team'Team = "mibr" if strpos(lower(`team'Team), "mibr") 
		replace `team'Team = "Windigo" if strpos(lower(`team'Team), "windigo") 
		replace `team'Team = "Valiance" if strpos(lower(`team'Team), "valiance") 
		replace `team'Team = "Tricked" if strpos(lower(`team'Team), "tricked")  
		replace `team'Team = "North" if strpos(lower(`team'Team), "north")  
		replace `team'Team = "NRG" if strpos(lower(`team'Team), "nrg")   
		replace `team'Team = "Mad Lions" if strpos(lower(`team'Team), "mad lions") | strpos(lower(`team'Team), "madlions")
		replace `team'Team = "HellRaisers" if strpos(lower(`team'Team), "hellraisers") | strpos(lower(`team'Team), "hr 1xbet")   
		replace `team'Team = "Ghost" if strpos(lower(`team'Team), "ghost")
		replace `team'Team = "Renegades" if strpos(lower(`team'Team), "renegades")
		replace `team'Team = "OpTic" if strpos(lower(`team'Team), "optic")
		replace `team'Team = "Cloud9" if strpos(lower(`team'Team), "cloud9")
		replace `team'Team = "Vega squadron" if strpos(lower(`team'Team), "vega squadron")
		replace `team'Team = "Tyloo" if strpos(lower(`team'Team), "tyloo")
		replace `team'Team = "Team Envy" if strpos(lower(`team'Team), "teamenvy") | strpos(lower(`team'Team), "team envy")
		replace `team'Team = "SK Gaming" if strpos(lower(`team'Team), "sk gaming")
		replace `team'Team = "AGO" if strpos(lower(`team'Team), "ago esports") | strpos(lower(`team'Team), "agomrcat") | strpos(lower(`team'Team), "ago-")
		replace `team'Team = "GODSENT" if strpos(lower(`team'Team), "godsent")
	
	}
	
	encode winTeam, gen(eWinTeam)
	encode lossTeam, gen(eLossTeam)
	
	// What side the previous round winner is currently playing on
	bys ID (roundNumber): gen ewinCurrentSide = cond(lagCtWin == 1, "CT", "T") if !missing(lagCtWin)
	replace ewinCurrentSide = "T" if roundNumber == 16 & lagCtWin
	replace ewinCurrentSide = "CT" if roundNumber == 16 & lagTWin
	
	forval round = 34(6)60 {
		
		replace ewinCurrentSide = "T" if roundNumber == `round' & lagCtWin
		replace ewinCurrentSide = "CT" if roundNumber == `round' & lagTWin
	
	}
	
	/*
	Checking it works
	br ID roundNumber ctTeam tTeam ctWin ewinCurrentSide if maxRoundNumber > 33
	*/
	
	encode ewinCurrentSide, gen(winCurrentSide)
	
	* You might prefer one side on a specific map
	encode mapName, gen(eMap)
	
	
	// Cleaning messages
	local j 78
	forval i = 284(3)862 {
	
		rename v`i' player`j'
		
		local j = `j' + 1
	
	}
	
	local j 78
	forval i = 285(3)862 {
	
		rename v`i' msg`j'
		
		local j = `j' + 1
	
	}
	
	local j 78
	forval i = 286(3)862 {
	
		rename v`i' msgtick`j'
		
		local j = `j' + 1
	
	}
	
	
	renvars msgtick*, presub(msgtick messageTick)
	
	gen reverseWinner = (accumulatedWins == 1 )
	label var reverseWinner "Reversing of the previous round's winner"
	
	
**# Technical and tactical timeouts
********************************************************************************
	
	**# Technical timeouts
	****************************************************************************
	
	gen technical = 0 // default is NOT technical
	
	gen obsNumber = _n
	
	gen teamTechnicalMessage = ""
	gen playerTechnicalMessage = ""
	gen teamCalledTechnical = ""
	gen playerCalledTechnical = ""
	
	gen issue = 0
	gen playerIssue = ""
	gen playerIssueMessage = ""
	
	drop pause
	gen pause = 0
	gen playerCalledPause = ""
	gen playerPauseMessage = ""
		
	levelsof obsNumber if !missing(msg1), local(observationsToIterate) // Only look at rounds with chat messages
	
	sort obsNumber
	foreach i of local observationsToIterate {
		
		foreach message of varlist msg* {
	
			local msgNumber = substr("`message'", 4, .)
			
			if missing(messageTick`msgNumber'[`i']) {
			
				continue, break
			
			}
		
			local pos = strpos(`message'[`i'], " has called a technical pause")
			
			if `pos' > 0 {
			
				replace teamCalledTechnical = subinstr(substr(`message'[`i'], 1, `pos' - 1), "Console: ", "", .) in `i' if missing(teamCalledTechnical[`i'])
				
				replace teamTechnicalMessage = `message'[`i'] in `i'
				replace technical = 1 in `i'
				
			}
			
			if inlist(lower(`message'[`i']), ".tech", "!tech", "tec", ".tec", "tech", "!admin", ".admin") {
			
				replace playerCalledTechnical = player`msgNumber'[`i'] in `i' if missing(playerCalledTechnical[`i'])
				
				replace playerTechnicalMessage = `message'[`i'] in `i'
				replace technical = 1 in `i'
			
			}
			
			local pos = strpos(`message'[`i'], " wants to stop")
			
			if `pos' > 0 {
				
				replace teamCalledTechnical = subinstr(substr(`message'[`i'], 1, `pos' - 1), "Console: ", "", .) in `i' if missing(teamCalledTechnical[`i'])
				
				replace teamTechnicalMessage = `message'[`i'] in `i' if missing(teamCalledTechnical[`i'])
				replace technical = 1 in `i'
			
			}
			
			local pause = strpos(`message'[`i'], " left for pauses.")
			local pos = strpos(`message'[`i'], " has")
			
			if `pause' > 0 & `pos' > 0 {
				
				replace teamCalledTechnical = substr(`message'[`i'], 17, `=`=strlen("`string'")' - (`=strlen("`string'")' - `pos') - 17') in `i' if missing(teamCalledTechnical[`i'])
				
				replace teamTechnicalMessage = `message'[`i'] in `i'
				replace technical = 1 in `i'
			
			}
			
			if strpos(lower(`message'[`i']), "issue") > 0| strpos(lower(`message'[`i']), "crash") > 0 | strpos(lower(`message'[`i']), "work") > 0 | strpos(lower(`message'[`i']), "blue screen") > 0 | inlist(lower(`message'[`i']), ".stop", "!stop", "abort", "!abort", ".abort") | ( (strpos(`message'[`i'], "waiting for both teams and admin to ready") > 0 | strpos(`message'[`i'], "player disconnected auto pausing") > 0 ) & !inlist(roundNumber[`i'], 1, 16) ) {
			
				replace playerIssue = player`msgNumber'[`i'] in `i' if missing(playerIssue[`i'])
				
				replace playerIssueMessage = `message'[`i'] in `i'
				replace issue = 1 in `i'
			
			}
			
			if inlist(lower(`message'[`i']), ".pause", "!pause", ".unpause", "!unpause") {
			
				replace playerCalledPause = player`msgNumber'[`i'] in `i' if missing(playerCalledTechnical[`i'])
				
				replace playerPauseMessage = `message'[`i'] in `i'
				replace pause = 1 in `i'
			
			}
			
		}
	
	}
	
	* Contiguous tech pauses
	gen techInRow= 0
	bysort ID (roundNum): replace techInRow = 1 if technical[_n]==1 & technical[_n+1]==1
	
	compress
	
	**# Technical timeout duration
	****************************************************************************
	
	gen technicalTime = technical * (freezeTimeTotal - medianFreezeTime)/128
	label var technicalTime "Duration (s) of technical timeout (recorded in demo)"
	
	**# Tactical timeouts
	****************************************************************************
	
	gen byte tactical = 0
	label var tactical "Tactical timeout"
	
	gen teamCalledTactical = ""
	gen playerCalledTactical = ""
	gen teamTacticalMessage = ""
	gen playerTacticalMessage = ""
	
	levelsof obsNumber if !missing(msg1), local(observationsToIterate) // Only look at rounds with chat messages
	
	sort obsNumber
	foreach i of local observationsToIterate {
		
		foreach message of varlist msg* {
	
			local msgNumber = substr("`message'", 4, .)
			
			if missing(messageTick`msgNumber'[`i']) {
			
				continue, break
			
			}
		
			local pos = strpos(`message'[`i'], "will take a timeout next round for 30 sec")
			
			if `pos' > 0 {
			
				local pos2 = strpos(`message'[`i'], " will take a timeout next round for 30 sec")
			
				replace teamCalledTactical = subinstr(subinstr(substr(`message'[`i'], 9, `=`pos2' - 9'), " (CT)", "", .), "(T)", "", .) in `i' if missing(teamCalledTechnical[`i'])
				
				replace teamTacticalMessage = `message'[`i'] in `i'
				replace tactical = 1 in `i'
				
			}
			
			if inlist(lower(`message'[`i']), ".tac", "!tac", ".timeout", "!timeout", "tac") {
			
				replace playerCalledTactical = player`msgNumber'[`i'] in `i' if missing(playerCalledTechnical[`i'])
				
				replace playerTacticalMessage = `message'[`i'] in `i'
				replace tactical = 1 in `i' if (freezeTimeTotal - medianFreezeTime > 1)
			
			}
			
		}
	
	}
	
	gen tacticalTime = tactical * (freezeTimeTotal - medianFreezeTime)/128
	label var technicalTime "Duration (s) of technical timeout (recorded in demo)"

**# Labels
************************************************************************

	label var technical "Technical timeout"
	label var tactical "Tactical timeout"
	label var winEq "Winner's equipment value"
	label var lossEq "Loser's equipment value"
	label var winCash "Winner's cash"
	label var lossCash "Loser's cash"
	label var winCashCategory "Winner's cash category"
	label var lossCashCategory "Loser's cash category"
	label var winArmor "Winner's armor"
	label var lossArmor "Loser's armor"
	label var winDefusers "Winner's defusers"
	label var lossDefusers "Loser's defusers"
	label var winHelmet "Winner's helmet"
	label var lossHelmet "Loser's helmet"
	
**# Round dropping
********************************************************************************
	
	* Creating non-defined timeout rounds to drop
	gen nonDefinedTimeOut = ((freezeTimeTotal > medianFreezeTime + 1) & roundNum != 1 & technical == 0 & tactical == 0)
	
	egen afterNonDefinedTimeOut = min(cond(nonDefinedTimeOut == 1, roundNum, .)), by(ID)  
	bys ID (roundN): keep if roundNum < afterNonDefinedTimeOut
	
	* Deleting rounds after a technical timeout
	egen afterTactical = min(cond(tactical == 1 & roundNumber != 1, roundNum, .)), by(ID) 
	bysort ID (roundN): keep if roundNum <= afterTactical

	* Deleting rounds after contiguous technical issues
	egen afterTechInRow = min(cond(techInRow == 1, roundNum, .)), by(ID)  
	bysort ID (roundN): keep if roundNum < afterTechInRow
	drop techInRow afterTechInRow

	* Dropping rounds after usual pauses
	gen usualPause = inlist(roundNumber, 16, 31) & ( msg1 == "Console: Waiting for both teams and admin to ready to continue.  Say .ready to continue." | (technical == 0 & (freezeTimeTotal > medianFreezeTime + 1))) 
	
	egen afterUsualPause = min(cond(usualPause == 1, roundNum, .)), by(ID) 
	bysort ID (roundN): keep if roundNum < afterUsualPause

	* Deleting rounds after a technical timeout
	egen afterTechnical = min(cond(technical == 1, roundNum, .)), by(ID) 
	bysort ID (roundN): keep if roundNum <= afterTechnical

	
	**# Check issues with no technical
	****************************************************************************
	
	sort date
	br ID roundNumber mapName medianFreezeTime technicalTime ctTeam tTeam player1-msg270 if technical == 0 & issue == 1 & roundNumber != 1
	
	replace technical = 1 if matchid == "MAD Lions-MIBR-Flashpoint 1-April 15th 2020-m3" & roundNumber == 4
	replace teamCalledTechnical = "mibr-" if technical == 1 & matchid == "MAD Lions-MIBR-Flashpoint 1-April 15th 2020-m3"

	
**# Hand-measured time between rounds
************************************************************************

	gen technicalTimeActual = technicalTime
	label var technicalTimeActual "Duration (s) of technical timeout"
	
	replace technicalTimeActual = 124 - (medianFreezeTime / 128) if technical & matchid == "ENCE-Vitality-Gamers8 2023-August 20th 2023-m2"
	
	replace technicalTimeActual = 158 - (medianFreezeTime / 128) if technical & matchid == "Cloud9-ENCE-Gamers8 2023-August 18th 2023-m1"
	
	replace technicalTimeActual = 215 - (medianFreezeTime / 128) if technical & matchid == "FaZe-Virtus.pro-Gamers8 2023-August 17th 2023-m1"
	
	replace technicalTimeActual = 130 - (medianFreezeTime / 128) if technical & matchid == "9INE-Liquid-BLAST.tv Paris Major 2023-May 13th 2023-m1"

	replace technicalTimeActual = 90 - (medianFreezeTime / 128) if technical & matchid == "OG-ENCE-BLAST.tv Paris Major 2023 Challengers Stage-May 8th 2023-m1"
	
	replace technicalTimeActual = 155 - (medianFreezeTime / 128) if technical & matchid == "Astralis-Spirit-BLAST.tv Paris Major 2023 Europe RMR B-April 12th 2023-m3"
	
	replace technicalTimeActual = 95 - (medianFreezeTime / 128) if technical & matchid == "Astralis-Spirit-BLAST.tv Paris Major 2023 Europe RMR B-April 12th 2023-m1"
	
	replace technicalTimeActual = 115 - (medianFreezeTime / 128) if technical & matchid == "Natus Vincere-Liquid-IEM Katowice 2023-February 5th 2023-m1"
	
	replace technicalTimeActual = 106 - (medianFreezeTime / 128) if technical & matchid == "Liquid-FaZe-BLAST Premier World Final 2022-December 15th 2022-m1"
	
	replace technicalTimeActual = 117 - (medianFreezeTime / 128) if technical & matchid == "Outsiders-Liquid-BLAST Premier World Final 2022-December 14th 2022-m1"
	
	replace technicalTimeActual = 1466 - (medianFreezeTime / 128) if technical & matchid == "Heroic-Ninjas in Pyjamas-BLAST Premier Fall Final 2022-November 23rd 2022-m1"
	
	replace technicalTimeActual = 818 - (medianFreezeTime / 128) if technical & matchid == "FaZe-OG-BLAST Premier Fall Final 2022-November 23rd 2022-m1"
	
	replace technicalTimeActual = 141 - (medianFreezeTime / 128) if technical & matchid == "fnatic-Astralis-Elisa Masters Espoo 2022-November 19th 2022-m1"
	
	replace technicalTimeActual = 134 - (medianFreezeTime / 128) if technical & matchid == "Outsiders-fnatic-IEM Rio Major 2022 Challengers Stage-November 2nd 2022-m1"
	
	replace technicalTimeActual = 1291 - (medianFreezeTime / 128) if technical & matchid == "G2-Natus Vincere-ESL Pro League Season 16-September 30th 2022-m3"
	
	replace technicalTimeActual = 125 - (medianFreezeTime / 128) if technical & matchid == "Vitality-Spirit-ESL Pro League Season 16-September 4th 2022-m1"
	
	replace technicalTimeActual = 146 - (medianFreezeTime / 128) if technical & matchid == "FaZe-Astralis-BLAST Premier Fall Groups 2022-August 28th 2022-m3"
	
	replace technicalTimeActual = 294 - (medianFreezeTime / 128) if technical & matchid == "G2-BIG-BLAST Premier Fall Groups 2022-August 25th 2022-m1"
	
	replace technicalTimeActual = 139 - (medianFreezeTime / 128) if technical & matchid == "MOUZ-Astralis-IEM Cologne 2022-July 15th 2022-m2"
	
	replace technicalTimeActual = 126 - (medianFreezeTime / 128) if technical & matchid == "Heroic-MOUZ-IEM Cologne 2022-July 8th 2022-m2"
	
	replace technicalTimeActual = 59 - (medianFreezeTime / 128) if technical & matchid == "Movistar Riders-Vitality-IEM Cologne 2022 Play-in-July 5th 2022-m1" 
	
	replace technicalTimeActual = 485 - (medianFreezeTime / 128) if technical & matchid == "ENCE-Cloud9-IEM Dallas 2022-June 5th 2022-m1"
	
	replace technicalTimeActual = 77 - (medianFreezeTime / 128) if technical & matchid == "FaZe-Cloud9-IEM Dallas 2022-June 4th 2022-m1"
	
	replace technicalTimeActual = 129 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-Cloud9-IEM Dallas 2022-June 1st 2022-m1"
	
	replace technicalTimeActual = 103 - (medianFreezeTime / 128) if technical & matchid == "G2-Movistar Riders-IEM Dallas 2022-May 30th 2022-m1"
	
	replace technicalTimeActual = 214 - (medianFreezeTime / 128) if technical & matchid == "Entropiq-Astralis-ESL Pro League Season 15-April 6th 2022-m1"
	
	replace technicalTimeActual = 45 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-MOUZ-ESL Pro League Season 15-March 11th 2022-m1"
	
	replace technicalTimeActual = 103 - (medianFreezeTime / 128) if technical & matchid == "Entropiq-ECSTATIC-Funspark ULTI 2021 Finals-January 18th 2022-m2"
	
	replace technicalTimeActual = 137 - (medianFreezeTime / 128) if technical & matchid == "fnatic-ENCE-IEM Winter 2021-December 3rd 2021-m1"
	
	replace technicalTimeActual = 112 - (medianFreezeTime / 128) if technical & matchid == "G2-Liquid-IEM Winter 2021-December 2nd 2021-m1"
	
	replace technicalTimeActual = 483 - (medianFreezeTime / 128) if technical & matchid == "MOUZ-Vitality-IEM Winter 2021-December 2nd 2021-m1"
	
	replace technicalTimeActual = 254 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-Astralis-IEM Winter 2021-December 2nd 2021-m1"
	
	replace technicalTimeActual = 116 - (medianFreezeTime / 128) if technical & matchid == "Vitality-Astralis-IEM Fall 2021 Europe-October 10th 2021-m2"
	
	replace technicalTimeActual = 902 - (medianFreezeTime / 128) if technical & matchid == "BIG-FaZe-IEM Fall 2021 Europe-October 6th 2021-m1"
	
	replace technicalTimeActual = 536 - (medianFreezeTime / 128) if technical & matchid == "BIG-FaZe-IEM Fall 2021 Europe-October 6th 2021-m2"
	
	replace technicalTimeActual = 226 - (medianFreezeTime / 128) if technical & matchid == "Gambit-Entropiq-IEM Fall 2021 CIS-October 2nd 2021-m2"
	
	replace technicalTimeActual = 134 - (medianFreezeTime / 128) if technical & matchid == "Complexity-FORZE-ESL Pro League Season 14-August 21st 2021-m3"
	
	replace technicalTimeActual = 152 - (medianFreezeTime / 128) if technical & matchid == "Natus Vincere-FaZe-IEM Cologne 2021-July 17th 2021-m1"
	
	replace technicalTimeActual = 340 - (medianFreezeTime / 128) if technical & matchid == "Astralis-Heroic-IEM Cologne 2021-July 10th 2021-m1"
	
	replace technicalTimeActual = 240 - (medianFreezeTime / 128) if technical & matchid == "Liquid-MOUZ-IEM Cologne 2021-July 9th 2021-m3"
	
	replace technicalTimeActual = 170 - (medianFreezeTime / 128) if technical & matchid == "Liquid-Ninjas in Pyjamas-IEM Cologne 2021-July 8th 2021-m1"
	
	replace technicalTimeActual = 863 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-MOUZ-IEM Cologne 2021 Play-in-July 6th 2021-m2"
	
	replace technicalTimeActual = 421 - (medianFreezeTime / 128) if technical & matchid == "Vitality-Gambit-IEM Summer 2021-June 3rd 2021-m2"
	
	replace technicalTimeActual = 237 - (medianFreezeTime / 128) if technical & matchid == "Extra Salt-Vitality-DreamHack Masters Spring 2021-April 30th 2021-m3"
	
	replace technicalTimeActual = 303 - (medianFreezeTime / 128) if technical & matchid == "Natus Vincere-Virtus.pro-DreamHack Masters Spring 2021-April 29th 2021-m1"
	
	replace technicalTimeActual = 209 - (medianFreezeTime / 128) if technical & matchid == "FunPlus Phoenix-G2-IEM Summer 2021 Closed Qualifier-April 27th 2021-m2"
	
	replace technicalTimeActual = 418 - (medianFreezeTime / 128) if technical & matchid == "Gambit-Spirit-Pinnacle Cup 2021-April 3rd 2021-m2"
	
	replace technicalTimeActual = 185 - (medianFreezeTime / 128) if technical & matchid == "Gambit-Spirit-Pinnacle Cup 2021-April 3rd 2021-m3"
	
	replace technicalTimeActual = 191 - (medianFreezeTime / 128) if technical & matchid == "fnatic-Virtus.pro-ESL Pro League Season 13-March 28th 2021-m1"
	
	replace technicalTimeActual = 425 - (medianFreezeTime / 128) if technical & matchid == "G2-MOUZ-ESL Pro League Season 13-March 18th 2021-m2"
	
	replace technicalTimeActual = 390 - (medianFreezeTime / 128) if technical & matchid == "BIG-FunPlus Phoenix-ESL Pro League Season 13-March 11th 2021-m1"
	
	replace technicalTimeActual = 25 - (medianFreezeTime / 128) if technical & matchid == "Evil Geniuses-Liquid-BLAST Premier Global Final 2020-January 22nd 2021-m1"
	
	replace technicalTimeActual = 186 - (medianFreezeTime / 128) if technical & matchid == "Astralis-Evil Geniuses-BLAST Premier Global Final 2020-January 19th 2021-m1"
	
	replace technicalTimeActual = 207 - (medianFreezeTime / 128) if technical & matchid == "MOUZ-Astralis-BLAST Premier Fall 2020 Finals-December 9th 2020-m1"
	
	replace technicalTimeActual = 106 - (medianFreezeTime / 128) if technical & matchid == "FURIA-Liquid-IEM New York 2020 North America-October 16th 2020-m3"
	
	replace technicalTimeActual = 423 - (medianFreezeTime / 128) if technical & matchid == "Liquid-Chaos-IEM New York 2020 North America-October 10th 2020-m1"
	
	replace technicalTimeActual = 138 - (medianFreezeTime / 128) if technical & matchid == "Natus Vincere-Heroic-ESL Pro League Season 12 Europe-October 2nd 2020-m2"
	
	replace technicalTimeActual = 772 - (medianFreezeTime / 128) if technical & matchid == "Vitality-Astralis-ESL Pro League Season 12 Europe-September 10th 2020-m3"
	
	replace technicalTimeActual = 294 - (medianFreezeTime / 128) if technical & matchid == "FURIA-Cloud9-cs_summit 6 North America-July 3rd 2020-m1"
	
	replace technicalTimeActual = 294 - (medianFreezeTime / 128) if technical & matchid == "FURIA-Liquid-BLAST Premier Spring 2020 Americas Finals-June 19th 2020-m3"
	
	replace technicalTimeActual = 128 - (medianFreezeTime / 128) if technical & matchid == "FURIA-MIBR-BLAST Premier Spring 2020 Americas Finals-June 17th 2020-m1"
	
	replace technicalTimeActual = 52 - (medianFreezeTime / 128) if technical & matchid == "Astralis-Ninjas in Pyjamas-DreamHack Masters Spring 2020 - Europe-June 9th 2020-m2"
	
	replace technicalTimeActual = 156 - (medianFreezeTime / 128) if technical & matchid == "Evil Geniuses-100 Thieves-DreamHack Masters Spring 2020 - North America-May 30th 2020-m1"
	
	replace technicalTimeActual = 324 - (medianFreezeTime / 128) if technical & matchid == "FaZe-Spirit-DreamHack Masters Spring 2020 - Europe-May 26th 2020-m2"
	
	replace technicalTimeActual = 86 - (medianFreezeTime / 128) if technical & matchid == "Astralis-FaZe-ESL One Road to Rio - Europe-May 15th 2020-m1"
	
	replace technicalTimeActual = 230 - (medianFreezeTime / 128) if technical & matchid == "Evil Geniuses-100 Thieves-ESL One Road to Rio - North America-April 25th 2020-m3"
	
	replace technicalTimeActual = 24 - (medianFreezeTime / 128) if technical & matchid == "MAD Lions-MIBR-Flashpoint 1-April 15th 2020-m3"
	
	replace technicalTimeActual = 251 - (medianFreezeTime / 128) if technical & matchid == "fnatic-Ninjas in Pyjamas-ESL Pro League Season 11 Europe-April 4th 2020-m1"
	
	replace technicalTimeActual = 312 - (medianFreezeTime / 128) if technical & matchid == "MOUZ-Virtus.pro-ESL Pro League Season 11 Europe-March 31st 2020-m2"
	
	replace technicalTimeActual = 85 - (medianFreezeTime / 128) if technical & matchid == "FaZe-Vitality-ESL Pro League Season 10 Europe-November 16th 2019-m1"
	
	replace technicalTimeActual = 184 - (medianFreezeTime / 128) if technical & matchid == "Renegades-MIBR-StarSeries i-League Season 8-October 21st 2019-m1"
	
	replace technicalTimeActual = 74 - (medianFreezeTime / 128) if technical & matchid == "FaZe-Evil Geniuses-ESL One New York 2019-September 26th 2019-m1"
	
	replace technicalTimeActual = 1924 - (medianFreezeTime / 128) if technical & matchid == "FURIA-Vitality-ECS Season 7 Finals-June 9th 2019-m1"
	
	replace technicalTimeActual = 270 - (medianFreezeTime / 128) if technical & matchid == "Liquid-ENCE-DreamHack Masters Dallas 2019-June 2nd 2019-m1"
	
	replace technicalTimeActual = 2526 - (medianFreezeTime / 128) if technical & matchid == "Vitality-Ninjas in Pyjamas-DreamHack Masters Dallas 2019-May 30th 2019-m2"
	
	replace technicalTimeActual = 304 - (medianFreezeTime / 128) if technical & matchid == "Valiance-Vitality-ECS Season 7 Europe Week 3-April 27th 2019-m2"
	
	replace technicalTimeActual = 234 - (medianFreezeTime / 128) if technical & matchid == "Liquid-FaZe-BLAST Pro Series Miami 2019-April 14th 2019-m1"
	
	replace technicalTimeActual = 120 - (medianFreezeTime / 128) if technical & matchid == "Astralis-Liquid-BLAST Pro Series Miami 2019-April 13th 2019-m1"
	
	replace technicalTimeActual = 209 - (medianFreezeTime / 128) if technical & matchid == "Liquid-FaZe-BLAST Pro Series Miami 2019-April 12th 2019-m1"
	
	replace technicalTimeActual = 122 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-FaZe-ECS Season 7 Europe Week 1-March 13th 2019-m1"
	
	replace technicalTimeActual = 648 - (medianFreezeTime / 128) if technical & matchid == "fnatic-Cloud9-iBUYPOWER Masters 2019-January 20th 2019-m1"
	
	replace technicalTimeActual = 22 - (medianFreezeTime / 128) if technical & matchid == "MIBR-NRG-ESL Pro League Season 8 Finals-December 5th 2018-m1"
	
	replace technicalTimeActual = 82 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-North-ECS Season 6 Finals-November 23rd 2018-m1"
	
	replace technicalTimeActual = 155 - (medianFreezeTime / 128) if technical & matchid == "FaZe-Astralis-BLAST Pro Series Copenhagen 2018-November 3rd 2018-m1"
	
	replace technicalTimeActual = 116 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-FaZe-EPICENTER 2018-October 27th 2018-m1"
	
	replace technicalTimeActual = 116 - (medianFreezeTime / 128) if technical & matchid == "fnatic-MOUZ-ESL One New York 2018-September 26th 2018-m1"
	
	replace technicalTimeActual = 622 - (medianFreezeTime / 128) if technical & matchid == "Astralis-Cloud9-ESL One Cologne 2018-July 3rd 2018-m1"
	
	replace technicalTimeActual = 187 - (medianFreezeTime / 128) if technical & matchid == "fnatic-North-ESL One Cologne 2018-July 3rd 2018-m1"
	
	replace technicalTimeActual = 147 - (medianFreezeTime / 128) if technical & matchid == "Gambit-Virtus.pro-ECS Season 5 Europe-April 8th 2018-m1"
	
	replace technicalTimeActual = 1625 - (medianFreezeTime / 128) if technical & matchid == "FaZe-HellRaisers-V4 Future Sports Festival 2018-March 24th 2018-m1"
	
	replace technicalTimeActual = 83 - (medianFreezeTime / 128) if technical & matchid == "FaZe-SK-ESL Pro League Season 7 Finals-May 19th 2018-m2"
	
	replace technicalTimeActual = 111 - (medianFreezeTime / 128) if technical & matchid == "Astralis-FaZe-ECS Season 5 Europe-March 15th 2018-m1"
	
	replace technicalTimeActual = 451 - (medianFreezeTime / 128) if technical & matchid == "Ninjas in Pyjamas-Virtus.pro-ECS Season 5 Europe-March 14th 2018-m1"
	
	replace technicalTimeActual = 178 - (medianFreezeTime / 128) if technical & matchid == "FaZe-fnatic-IEM Katowice 2018-March 5th 2018-m2"
	
	replace technicalTimeActual = 410 - (medianFreezeTime / 128) if technical & matchid == "fnatic-Gambit-StarSeries i-League Season 4-February 17th 2018-m1"
	
	drop if technicalTimeActual == 0 & technical == 1
	
	gen technicalTimeActualMin = technicalTimeActual / 60
	lab var technicalTimeActualMin "Duration (min) of technical timeout"

**# Rounds with a technical and a tactical pause
********************************************************************************

	gen technicalAndTactical = 0
	
#delimit ;
	
	local matches "
	"Natus Vincere-BIG-BLAST Premier Fall Final 2021-November 24th 2021-m2"
	"G2-BIG-BLAST Premier Spring Final 2021-June 16th 2021-m3"
	"Natus Vincere-G2-BLAST Premier World Final 2021-December 17th 2021-m1"
	"G2-Ninjas in Pyjamas-ESL Pro League Season 13-March 13th 2021-m1"
	"G2-FORZE-ESL Pro League Season 14-August 26th 2021-m1"
	"G2-Heroic-IEM Dallas 2023-May 31st 2023-m1"
	"Virtus.pro-MOUZ-BLAST.tv Paris Major 2023 Europe RMR A-April 8th 2023-m1"
	"Astralis-Spirit-BLAST.tv Paris Major 2023 Europe RMR B-April 12th 2023-m2"
	"Cloud9-ENCE-BLAST.tv Paris Major 2023 Europe RMR B-April 14th 2023-m2"
	"Gambit-Copenhagen Flames-Elisa Invitational Fall 2021-October 15th 2021-m2"
	"ENCE-fnatic-FantasyExpo EU Champions Spring 2022 - BLAST Premier Qualifier-March 26th 2022-m1"
	"Complexity-MOUZ-Flashpoint 3 Closed Qualifier-May 1st 2021-m1"
	"Ninjas in Pyjamas-Gambit-IEM Cologne 2021-July 9th 2021-m1"
	"Virtus.pro-Astralis-IEM Cologne 2021-July 16th 2021-m1"
	"G2-BIG-IEM Katowice 2021-February 19th 2021-m2"
	"Astralis-BIG-IEM Katowice 2022 Play-in-February 15th 2022-m1"
	"FURIA-Natus Vincere-IEM Rio Major 2022-November 12th 2022-m3"
	"Liquid-Spirit-IEM Rio Major 2022-November 9th 2022-m1" 
	"Cloud9-Ninjas in Pyjamas-IEM Road to Rio 2022 Europe RMR A-October 6th 2022-m3" 
	"fnatic-Eternal Fire-IEM Road to Rio 2022 Europe RMR A-October 7th 2022-m1"
	"FaZe-Gambit-IEM Winter 2021-December 4th 2021-m1" 
	"Entropiq-Fiend-REPUBLEAGUE TIPOS Season 2-November 16th 2021-m1" 
	"FaZe-OG-SteelSeries Nova Invitational 2022-August 13th 2022-m2" 
	"Gambit-Entropiq-V4 Future Sports Festival 2021-November 21st 2021-m5"
	"Gambit-Heroic-BLAST Premier World Final 2021-December 14th 2021-m1"
	"FURIA-Cloud9-IEM Rio 2023-April 20th 2023-m1"
	"FURIA-BIG-IEM Katowice 2023 Play-in-February 1st 2023-m3"
	"Eternal Fire-fnatic-ESL Pro League Season 17-February 27th 2023-m1"
	"Outsiders-fnatic-ESL Pro League Season 17-February 23rd 2023-m1"
	"Outsiders-Natus Vincere-ESL Pro League Season 17-March 22nd 2023-m1"
	"ENCE-BIG-BLAST Premier Spring Final 2022-June 15th 2022-m2"
	"Virtus.pro-G2-ESL Pro League Season 18-September 21st 2023-m1"
	"Vitality-Cloud9-IEM Cologne 2023-August 4th 2023-m1"
	"Vitality-G2-IEM Cologne 2023-August 1st 2023-m1"
	"FURIA-BIG-ESL Pro League Season 17-March 4th 2023-m2"
	"Liquid-FURIA-ESL Pro League Season 16-September 23rd 2022-m3"
	"FaZe-G2-BLAST Premier Spring Final 2022-June 16th 2022-m2"
	"Movistar Riders-Fiend-V4 Future Sports Festival 2021-November 19th 2021-m1"
	"Astralis-Spirit-ESL Pro League Season 14-August 16th 2021-m3"
	"Ninjas in Pyjamas-G2-BLAST Premier Spring Final 2021-June 19th 2021-m2"
	"Liquid-OG-IEM Katowice 2021 Play-in-February 16th 2021-m2"
	"Evil Geniuses-FunPlus Phoenix-DreamHack Open January 2021 Europe-January 29th 2021-m1"
	"Natus Vincere-FURIA-IEM Global Challenge 2020-December 15th 2020-m1"
	"FURIA-Complexity-DreamHack Masters Winter 2020 Europe-December 4th 2020-m1"
	"100 Thieves-Liquid-IEM New York 2020 North America-October 12th 2020-m2"
	"fnatic-Astralis-ESL Pro League Season 12 Europe-September 19th 2020-m2"
	"Vitality-FaZe-ESL Pro League Season 12 Europe-September 12th 2020-m1"
	"Liquid-100 Thieves-ESL Pro League Season 12 North America-September 7th 2020-m2"
	"Liquid-Evil Geniuses-ESL One Cologne 2020 North America-August 30th 2020-m1"
	"Astralis-G2-DreamHack Masters Spring 2020 - Europe-May 21st 2020-m1"
	"FaZe-Natus Vincere-ESL Pro League Season 11 Europe-April 8th 2020-m2"
	"G2-FaZe-ESL Pro League Season 11 Europe-March 29th 2020-m2"
	"Vitality-Ninjas in Pyjamas-ESL Pro League Season 11 Europe-March 23rd 2020-m1"
	"Liquid-Virtus.pro-IEM Katowice 2020-February 25th 2020-m1"
	"MAD Lions-Evil Geniuses-IEM Katowice 2020-February 25th 2020-m1"
	"G2-ENCE-Champions Cup Finals-December 21st 2019-m1"
	"MOUZ-G2-cs_summit 5-December 14th 2019-m1"
	"Liquid-Astralis-BLAST Pro Series Global Final 2019-December 12th 2019-m1"
	"Natus Vincere-TYLOO-ESL Pro League Season 10 Finals-December 3rd 2019-m1"
	"Astralis-Evil Geniuses-ECS Season 8 Finals-November 30th 2019-m2"
	"Vitality-North-StarSeries i-League Season 8-October 21st 2019-m1"
	"G2-MIBR-IEM Chicago 2019-July 20th 2019-m2"
	"Heroic-ENCE-IEM Chicago 2019-July 19th 2019-m2"
	"Astralis-fnatic-ESL One Cologne 2019-July 3rd 2019-m1"
	"Grayhound-fnatic-ESL Pro League Season 9 Finals-June 18th 2019-m2"
	"Vitality-North-ECS Season 7 Finals-June 6th 2019-m1"
	"FURIA-fnatic-DreamHack Masters Dallas 2019-May 30th 2019-m1"
	"NRG-G2-DreamHack Masters Dallas 2019-May 30th 2019-m3"
	"Liquid-FaZe-BLAST Pro Series Miami 2019-April 14th 2019-m2"
	"FaZe-MIBR-BLAST Pro Series Miami 2019-April 13th 2019-m1"
	"NRG-MIBR-StarSeries i-League Season 7-April 1st 2019-m2"
	"Liquid-BIG-SuperNova CSGO Malta-December 1st 2018-m1"
	"North-NRG-ECS Season 6 Finals-November 24th 2018-m1"
	"Liquid-North-ECS Season 6 Finals-November 22nd 2018-m1"
	"NRG-HellRaisers-IEM Shanghai 2018-August 1st 2018-m2"
	"GODSENT-HellRaisers-DreamHack Open Tours 2018-May 21st 2018-m1"
	"Cloud9-G2-DreamHack Masters Marseille 2018-April 18th 2018-m1"
	"Ninjas in Pyjamas-G2-IEM Katowice 2018-March 1st 2018-m3"
	"Tricked-North-ECS Season 8 Europe Week 5-October 29th 2019-m1"
	"fnatic-AVANGAR-ECS Season 7 Europe Week 5-May 22nd 2019-m3"
	"AVANGAR-MOUZ-ECS Season 7 Europe Week 5-May 21st 2019-m2"
	"fnatic-Gambit-ECS Season 5 Europe-April 3rd 2018-m1"
	";
	
#delimit cr
	
	foreach match of local matches{
	
		replace tactical = 1 if matchid == "`match'" & technical == 1
	
	}
	
#delimit
	
	local noVideo "
	"Into the Breach-Apeks-Elisa Invitational Spring 2023-June 8th 2023-m1"
	"Bad News Eagles-ENCE-IEM Rio 2023 Europe Closed Qualifier-February 9th 2023-m2"
	"Bad News Eagles-Astralis-Elisa Masters Espoo 2022-November 17th 2022-m1"
	"ENCE-Entropiq-Malta Vibes Knockout Series 1-August 26th 2021-m1"
	"Entropiq-BIG-Spring Sweet Spring 2-June 2nd 2021-m1"
	"OG-BIG-Spring Sweet Spring 2-June 2nd 2021-m1"
	"MOUZ-fnatic-Snow Sweet Snow 3-April 7th 2021-m1"
	"FaZe-G2-ECS Season 7 Europe Week 5-May 21st 2019-m2"
	"Renegades-Liquid-StarSeries i-League Season 4 North America Qualifier-February 4th 2018-m1"
	"HAVU-MOUZ-Flashpoint 3 Closed Qualifier-April 28th 2021-m2"
	";

#delimit cr

	foreach match of local noVideo {
	
		drop if technical == 1 & matchid == "`match'"
	
	}

#delimit
	
	local durationZero "
	"MAD Lions-MIBR-Flashpoint 1-April 15th 2020-m3"
	";

#delimit cr

	foreach match of local durationZero {
	
		drop if technical ==1 & matchid == "`match'"
	
	}
	
	// Wrong round number:
	drop if technical & matchid == "MOUZ-Complexity-Flashpoint 3 Closed Qualifier-April 29th 2021-m3" // It's the next round
	
**# Matching players and teams
********************************************************************************
	
	gen byte winTechnical = 0
	label var winTechnical "Winner Technical timeout"
	gen byte lossTechnical = 0 
	label var lossTechnical "Loser Technical timeout"
	
	* Players
	bys ID (roundNumber): replace winTechnical = 1 if technical ///
	& ( ( inlist(playerCalledTechnical, ct_p1[_n-1], ct_p2[_n-1], ct_p3[_n-1], ct_p4[_n-1], ct_p5[_n-1]) & lagCtWin == 1 ) ///
	| ( inlist(playerCalledTechnical, t_p1[_n-1], t_p2[_n-1], t_p3[_n-1], t_p4[_n-1], t_p5[_n-1]) & lagTWin == 1 ) ) & !missing(playerCalledTechnical)
	
	bys ID (roundNumber): replace lossTechnical = 1 if technical ///
	& ( ( inlist(playerCalledTechnical, ct_p1[_n-1], ct_p2[_n-1], ct_p3[_n-1], ct_p4[_n-1], ct_p5[_n-1]) & lagTWin == 1 ) ///
	| ( inlist(playerCalledTechnical, t_p1[_n-1], t_p2[_n-1], t_p3[_n-1], t_p4[_n-1], t_p5[_n-1]) & lagCtWin == 1 ) ) & !missing(playerCalledTechnical)
	
	* Team
	bys ID (roundNumber): replace winTechnical = 1 if technical & !missing(teamCalledTechnical) & ((strpos(teamCalledTechnical, ctTeam[_n - 1]) & lagCtWin) | (strpos(teamCalledTechnical, tTeam[_n - 1]) & lagTWin))
	
	bys ID (roundNumber): replace lossTechnical = 1 if technical & !missing(teamCalledTechnical) & ( (strpos(teamCalledTechnical, ctTeam[_n - 1]) & lagTWin) | (strpos(teamCalledTechnical, tTeam[_n - 1]) & lagCtWin) )
	
	gen byte winTactical = 0
	label var winTactical "Winner Tactical timeout"
	gen byte lossTactical = 0 
	label var lossTactical "Loser Tactical timeout"
	
	* Players
	bys ID (roundNumber): replace winTactical = 1 if tactical ///
	& ( ( inlist(playerCalledTactical, ct_p1[_n-1], ct_p2[_n-1], ct_p3[_n-1], ct_p4[_n-1], ct_p5[_n-1]) & lagCtWin == 1 ) ///
	| ( inlist(playerCalledTactical, t_p1[_n-1], t_p2[_n-1], t_p3[_n-1], t_p4[_n-1], t_p5[_n-1]) & lagTWin == 1 ) ) & !missing(playerCalledTactical)
	
	bys ID (roundNumber): replace lossTactical = 1 if tactical ///
	& ( ( inlist(playerCalledTactical, ct_p1[_n-1], ct_p2[_n-1], ct_p3[_n-1], ct_p4[_n-1], ct_p5[_n-1]) & lagTWin == 1 ) ///
	| ( inlist(playerCalledTactical, t_p1[_n-1], t_p2[_n-1], t_p3[_n-1], t_p4[_n-1], t_p5[_n-1]) & lagCtWin == 1 ) ) & !missing(playerCalledTactical)
	
	* Team
	bys ID (roundNumber): replace winTactical = 1 if tactical & !missing(teamCalledTactical) & ((strpos(teamCalledTactical, ctTeam[_n - 1]) & lagCtWin) | (strpos(teamCalledTactical, tTeam[_n - 1]) & lagTWin))
	
	bys ID (roundNumber): replace lossTactical = 1 if tactical & !missing(teamCalledTactical) & ( (strpos(teamCalledTactical, ctTeam[_n - 1]) & lagTWin) | (strpos(teamCalledTactical, tTeam[_n - 1]) & lagCtWin) )
	
	
	drop if roundNum == 1 // Dropping it here because I need the tTeam and ctTeam in the previous round for cases where a technical happened in round number 2
	
	**# Check cases where no team got matched
	****************************************************************************
	
	unab want: player1-msg270
	unab omit: messageTick*
	global messageVars: list want - omit
	
	di "${messageVars}"
	
	br matchid roundNumber ctTeam tTeam lagCtWin playerCalledTechnical teamCalledTechnical *t_p* ${messageVars} if technical == 1 & winTechnical == 0 & lossTechnical == 0
	
	replace lossTechnical = 1 if technical == 1& matchid == "Astralis-Cloud9-ELEAGUE CSGO Premier 2018-July 21st 2018-m2"
	
	// Blaze is not a player or coach in either team
	drop if technical == 1 & winTechnical == 0 & lossTechnical == 0
	
	// Tacticals
	br matchid roundNumber ctTeam tTeam lagCtWin playerCalledTactical teamCalledTactical *t_p* ${messageVars} if tactical == 1 & winTactical == 0 & lossTactical == 0
	
	drop if tactical == 1 & winTactical == 0 & lossTactical == 0
	
	
	**# Need to check cases where both teams are classified as calling the timeouts
	****************************************************************************
	
	br ID roundNumber ctTeam tTeam lagCtWin teamCalledTechnical playerCalledTechnical ${messageVars} if winTechnical == 1 & lossTechnical == 1
	
	replace lossTechnical = 0 if technical == 1 & matchid == "Astralis-OG-BLAST Premier Spring Showdown 2021-April 13th 2021-m1"
	
	replace winTechnical = 0 if technical == 1 & matchid == "FaZe-Ninjas in Pyjamas-BLAST Pro Series SÃ£o Paulo 2019-March 22nd 2019-m1"
	
	replace winTechnical = 0 if technical == 1 & matchid == "Natus Vincere-Astralis-BLAST Pro Series Copenhagen 2018-November 3rd 2018-m1"
	
	replace winTechnical = 0 if technical == 1 & matchid == "SK-Astralis-IEM Katowice 2018-February 27th 2018-m1"
	
	replace lossTechnical = 0 if technical == 1 & matchid == "Vitality-Natus Vincere-BLAST Premier World Final 2021-December 19th 2021-m1"
	
	
	// Fixing one round where the measured cash was after buying
	replace winCash = 19600 if matchid == "fnatic-AVANGAR-ECS Season 7 Europe Week 5-May 22nd 2019-m1"  & roundNumber == 13
	replace winCashCategory = 1 if matchid == "fnatic-AVANGAR-ECS Season 7 Europe Week 5-May 22nd 2019-m1"  & roundNumber == 13
	replace winCash = 12350 if matchid == "fnatic-AVANGAR-ECS Season 7 Europe Week 5-May 22nd 2019-m1"  & roundNumber == 13
	replace winCashCategory = 1 if matchid == "fnatic-AVANGAR-ECS Season 7 Europe Week 5-May 22nd 2019-m1"  & roundNumber == 13
	
	
**# Table - Technicals and tacticals
********************************************************************************

	global controls i.lagAccumulatedWins differenceScore winEq lossEq i.winCashCat#i.lossCashCat winDefusers lossDefusers winArmor lossArmor winHelmet lossHelmet
	global scalars ""ctrls Controls" "mfe Match fixed effects" "rnfe Round fixed effects" "wfe Winner team-Year fixed effects" "sidemapfe Side-Map fixed effects" "trnfe Tournament fixed effects" "matches Number of matches" "mean_outcome Mean outcome""
	
	foreach type in technical tactical {
	
		local proper = proper("`type'")
	
		gen `type'UnderThree = (lagAccumulatedWins < 3 & `type' == 1)
		gen `type'OverThree =  (lagAccumulatedWins >= 3 & `type' == 1)
		label var `type'UnderThree "`proper' Timeout $\times$ 1-2 Wins in a row"
		label var `type'OverThree "`proper' Timeout  $\times$ 3+ Wins in a row"
		
		foreach team in win loss{
		
			gen `team'`proper'UnderThree = (lagAccumulatedWins < 3 & `team'`proper' == 1)
			gen `team'`proper'OverThree = (lagAccumulatedWins >= 3 & `team'`proper' == 1)
			
		}
		
		lab var win`proper'UnderThree "Winner `proper' Timeout $\times$ 1-2 Wins in a row"
		lab var win`proper'OverThree  "Winner `proper' Timeout $\times$ 3+ Wins in a row"
		lab var loss`proper'UnderThree "Loser `proper' Timeout $\times$ 1-2 Wins in a row"
		lab var loss`proper'OverThree  "Loser `proper' Timeout $\times$ 3+ Wins in a row"
	
	}
	
	eststo clear
	
	foreach technical in "i.technical i.tactical" "i.(technicalUnderThree technicalOverThree) i.(tacticalUnderThree tacticalOverThree)" "i.(winTechnicalUnderThree winTechnicalOverThree lossTechnicalUnderThree lossTechnicalOverThree) i.(winTacticalUnderThree winTacticalOverThree lossTacticalUnderThree lossTacticalOverThree)" {
		
		eststo: reghdfe reverseWinner `technical' $controls, abs(ID roundN i.winCurrentSide#i.eMap eWinTeam#year tournament) vce(cluster ID)
		summ reverseWinner if e(sample)
		estadd local ctrls Yes
		estadd local mfe Yes
		estadd local rnfe Yes
		estadd local sidemapfe Yes
		estadd local trnfe Yes
		estadd scalar matches = floor(`e(N_clust1)')
		estadd scalar mean_outcome = round(`r(mean)', 0.01)
		estadd local wfe Yes

	}
	
	esttab using "${main}/Table C1 - Technicals and tacticals.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(1.technical 1.tactical 1.technicalUnderThree 1.technicalOverThree 1.tacticalUnderThree 1.tacticalOverThree 1.winTechnicalUnderThree 1.winTechnicalOverThree 1.lossTechnicalUnderThree 1.lossTechnicalOverThree 1.winTacticalUnderThree 1.winTacticalOverThree 1.lossTacticalUnderThree 1.lossTacticalOverThree) order(1.technical 1.underThree 1.overThree 1.winUnderThree 1.winOverThree 1.lossUnderThree 1.lossOverThree) sfmt(a2)
	
	drop if tactical == 1

**# Summary tables
************************************************************************

	**# Table 1: Summary statistic

	tabstat technical technicalTime technicalTimeActual lagAccumulatedWins differenceScore winEq lossEq winCashCategory lossCashCategory winDefusers lossDefusers winArmor lossArmor winHelmet lossHelmet, save statistics(mean sd min max) columns(statistics)
	matrix stats = r(StatTotal)
	matrix stats = stats'
	frmttable using "Table 1 - Summary statistics", varlabels tex statmat(stats) sdec(3,3,3,3) ctitles("Variable name","Mean", "SD", "Minimum","Maximum") replace 

	**# Histograms of timeouts' duration
	hist technicalTimeActualMin if pause ==1, width(1) percent
	graph export "$main/Figure 1 - Duration.png", replace
	
	bys eLossTeam: gen obs = _N
	bys eLossTeam: egen obs_pause = total(lossTechnical)
	
	pwcorr obs_p obs, star(0.01)
	
	drop obs*
	
	bys eWinTeam: gen obs = _N
	bys eWinTeam: egen obs_pause = total(winTechnical)
	
	pwcorr obs_p obs, star(0.01)
	
	drop obs*
	
	quietly foreach winloss in win loss {
	
		unique `winloss'Team
	
		mat J`winloss' = J(`r(unique)', 2, .)
		
		levelsof `winloss'Team, local(`winloss'Teams)
		
		local i 1
		foreach `winloss'Team of local `winloss'Teams {
		
			local rowName = strtoname("`winTeam'")
		
			local rowNames "`rowNames' `rowName'"
			
			summ ID if `winloss'Team == "``winloss'Team'", meanonly
			
			local denominator = `r(N)'
			
			summ ID if `winloss'Team == "``winloss'Team'" & `winloss'Technical == 1, meanonly
			
			local numerator = `r(N)'
			
			di "`=`numerator'/`denominator''"
			
			mat J`winloss'[`i', 1] = `=round(`numerator'/`denominator', 0.01)'
			
			mat J`winloss'[`i', 2] = `denominator'
			
			local i = `i' + 1
		
		}	
		
		mat rownames J`winloss' =  `rowNames'
		
		noisily mat li J`winloss'
		
	}
	
// 	bys winTeam: egen countWinTeam = count(winTeam)
//	
// 	graph hbar winTechnical, over(winTeam, sort(winTechnical)) name(meanTechnicalwin, replace)
// 	graph hbar countWinTeam, over(winTeam, sort(winTechnical)) name(countwin, replace)
//	
// 	bys lossTeam: egen countLossTeam = count(lossTeam)
//	
// 	graph hbar lossTechnical, over(lossTeam, sort(lossTechnical)) name(meanTechnicalloss, replace)
// 	graph hbar countLossTeam, over(lossTeam, sort(lossTechnical)) name(countloss, replace)
	
	// All cases where the percentage of observations in which a team called a technical timeout after winning/losing is more than 2% is with less than 100 observations
	
	
**# Main regression
************************************************************************

	global controls i.lagAccumulatedWins differenceScore winEq lossEq i.winCashCat#i.lossCashCat winDefusers lossDefusers winArmor lossArmor winHelmet lossHelmet
	global scalars ""ctrls Controls" "mfe Match fixed effects" "rnfe Round fixed effects" "wfe Winner team-Year fixed effects" "sidemapfe Side-Map fixed effects" "trnfe Tournament fixed effects" "matches Number of matches" "mean_outcome Mean outcome""
	
	gen underThree = (lagAccumulatedWins < 3 & technical == 1)
	gen overThree =  (lagAccumulatedWins >= 3 & technical == 1)
	label var underThree "Technical Timeout $\times$ 1-2 Wins in a row"
	label var overThree "Technical Timeout  $\times$ 3+ Wins in a row"
	
	foreach team in win loss{
	
		gen `team'UnderThree = (lagAccumulatedWins < 3 & `team'Technical == 1)
		gen `team'OverThree = (lagAccumulatedWins >= 3 & `team'Technical == 1)
		
	}
	
	lab var winUnderThree "Winner Technical Timeout $\times$ 1-2 Wins in a row"
	lab var winOverThree "Winner Technical Timeout $\times$ 3+ Wins in a row"
	lab var lossUnderThree "Loser Technical Timeout $\times$ 1-2 Wins in a row"
	lab var lossOverThree "Loser Technical Timeout $\times$ 3+ Wins in a row"
	
	
	**# Table 2 - Main results
	eststo clear
	
	foreach technical in "i.technical" "i.(underThree overThree)" "i.(winUnderThree winOverThree lossUnderThree lossOverThree)" {
		
		eststo: reghdfe reverseWinner `technical' $controls, abs(ID roundN i.winCurrentSide#i.eMap eWinTeam#year tournament) vce(cluster ID)
		summ reverseWinner if e(sample)
		estadd local ctrls Yes
		estadd local mfe Yes
		estadd local rnfe Yes
		estadd local sidemapfe Yes
		estadd local trnfe Yes
		estadd scalar matches = floor(`e(N_clust1)')
		estadd scalar mean_outcome = round(`r(mean)', 0.01)
		estadd local wfe Yes

	}
	
	lincom 1.winOverThree - 1.lossOverThree
	test _b[1.winOverThree] = _b[1.lossOverThree]
	
	cap gen sample = e(sample)
	
	esttab using "${main}/Table 2 - Main results.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(1.technical 1.underThree 1.overThree 1.winUnderThree 1.winOverThree 1.lossUnderThree 1.lossOverThree) order(1.technical 1.underThree 1.overThree 1.winUnderThree 1.winOverThree 1.lossUnderThree 1.lossOverThree) sfmt(a2)
	
	hist lagAccumulatedWins if technical, freq discrete addl
	graph export "$main/Figure 2 - Accumulated wins.png", replace
	
**# Further heterogeneity
************************************************************************

	gen tech_1 = (lagAccumulatedWins == 1 & technical == 1)
	label var tech_1 "Technical Timeout * 1 Win in a row"
	
	summ lagAccumulatedWins if technical == 1
	local max = r(max)
	
	forval numb = 2/`max'{
		
		gen tech_`numb' = (lagAccumulatedWins == `numb' & technical == 1)
		label var tech_`numb' "Technical Timeout * `numb' Wins in a row"
	
	}
	
	eststo clear
	eststo: reghdfe reverseWinner tech_* $controls, abs(ID roundN i.winCurrentSide#i.eMap eWinTeam#year tournament) vce(cluster ID)
	summ reverseWinner if e(sample)
	estadd local ctrls Yes
	estadd local mfe Yes
	estadd local rnfe Yes
	estadd local sidemapfe Yes
	estadd local trnfe Yes
	estadd scalar matches = floor(`e(N_clust1)')
	estadd scalar mean_outcome = round(`r(mean)', 0.01)
	estadd local wfe Yes
	estimates store winner
	estimates store loser
	
	levelsof lagAccumulatedWins if technical, local(wins)
	
	foreach win of local wins {
	
		local keep "`keep' tech_`win'"
	
	}
	di "`keep'"
	
	esttab using "${main}\\Table 3 - Further heterogeneity.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(`keep') order(`keep') sfmt(a2)
	

**# Time placebos are unable to replicate the results
************************************************************************

	xtset ID roundN
	gen technicalLead_0 = technical
	
	forval j = 1/3{
		
		local i = `j' - 1
		bys ID (roundNumber): gen technicalLead_`j' = F.technicalLead_`i'
		label var technicalLead_`j' "`j' round lead technical timeout"
		recode technicalLead_`j' (.=0)
		
	}
	
	gen winTechnicalLead_0 = winTechnical
	gen lossTechnicalLead_0 = lossTechnical
	
	forval j = 1/3{
		
		foreach winloss in win loss {
		
			local i = `j' - 1
			bys ID (roundNumber): gen `winloss'TechnicalLead_`j' = F.`winloss'TechnicalLead_`i'
			label var `winloss'TechnicalLead_`j' "`j' round lead technical timeout"
			recode `winloss'TechnicalLead_`j' (.=0)

			
		}
		
	}
	
	
	**# Win / Loss, 1-2 / 3+
	
	preserve
	
		local replace replace
		eststo clear
		
		forval lead = 1/3{
			
			local j = `lead' - 1
			drop if winTechnicalLead_`j' ==1 | lossTechnicalLead_`j' == 1
			
			drop winUnderThree winOverThree lossUnderThree lossOverThree
			
			foreach winloss in win loss {
			
				gen `winloss'UnderThree = (lagAccumulatedWins < 3 & `winloss'TechnicalLead_`lead' == 1)
				gen `winloss'OverThree = (lagAccumulatedWins >= 3 & `winloss'TechnicalLead_`lead' == 1)
			
			}
			
			label var winUnderThree "Winner Technical Timeout * 1-2 Wins in a row"
			label var winOverThree  "Winner Technical Timeout * 3+ Wins in a row"
			label var lossUnderThree "Loser Technical Timeout * 1-2 Wins in a row"
			label var lossOverThree  "Loser Technical Timeout * 3+ Wins in a row"
		
			eststo: reghdfe reverseWinner winUnderThree winOverThree lossUnderThree lossOverThree $controls, abs(ID roundN i.winCurrentSide#i.eMap eWinTeam#year tournament) vce(cluster ID)
			summ reverseWinner if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd local sidemapfe Yes
			estadd local trnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes
			
			esttab using "${main}/Table 4 - Time placebos.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(winUnderThree winOverThree lossUnderThree lossOverThree) order(winUnderThree winOverThree lossUnderThree lossOverThree) sfmt(0)
		
		
			local replace append
			
			tab winUnderThree winOverThree
			tab lossUnderThree lossOverThree
			
		}
	
	restore
	

**# Robustness
************************************************************************

	local replace replace
	
	foreach technical in "winUnderThree winOverThree lossUnderThree lossOverThree" {
	
		eststo clear
		
		preserve
			
			summ technicalTimeActual if pause, d
			drop if technicalTimeActual > `r(p95)'
					
			eststo: reghdfe reverseWinner `technical' $controls, abs(ID roundN i.winCurrentSide#i.eMap eWinTeam#year tournament) vce(cluster ID)
			summ reverseWinner if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd local sidemapfe Yes
			estadd local trnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes
						
		restore

		preserve
			
			summ technicalTime if pause, d
			drop if technicalTime > `r(p95)'
					
			eststo: reghdfe reverseWinner `technical' $controls, abs(ID roundN i.winCurrentSide#i.eMap eWinTeam#year tournament) vce(cluster ID)
			summ reverseWinner if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd local sidemapfe Yes
			estadd local trnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes

						
		restore
		
		preserve
			
			drop if roundNumber >= 16
					
			eststo: reghdfe reverseWinner `technical' $controls, abs(ID roundN i.winCurrentSide#i.eMap eWinTeam#year tournament) vce(cluster ID)
			summ reverseWinner if e(sample)
			estadd local ctrls Yes
			estadd local mfe Yes
			estadd local rnfe Yes
			estadd local sidemapfe Yes
			estadd local trnfe Yes
			estadd scalar matches = floor(`e(N_clust1)')
			estadd scalar mean_outcome = round(`r(mean)', 0.01)
			estadd local wfe Yes

						
		restore
		
		esttab using "${main}/Table 5 - Robustness.tex", fr label nonumber `replace' b(4) se(4) mtitle("Excluding duration outliers (manual)" "Excluding duration outliers (recorded time)" "Excluding all rounds after round 15") star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars($scalars) nobaselevels nogap keep(`technical') order(`technical') sfmt(a2)
		
		local replace append
		
	}
	
	
**# Timeout's exogeneity
********************************************************************************

	eststo clear
	
	eststo: reghdfe technical $controls, abs(ID roundN i.eWinTeam#i.year i.winCurrentSide#i.eMap tournament) vce(cluster ID) nocons
	
	summ reverseWinner if e(sample)
	
	estadd local mfe Yes
	estadd local rnfe Yes
	estadd local trnfe Yes
	estadd scalar matches = floor(`e(N_clust1)')
	estadd scalar mean_outcome = round(`r(mean)', 0.01)
	estadd local wfe Yes
	
	esttab using "${main}/Table 6 - Exogeneity.tex", fr label nonumber replace b(4) se(4)  star(* 0.1 ** 0.05 *** 0.01) nocons noomitted scalars("mfe Match fixed effects" "rnfe Round fixed effects" "trnfe Tournament fixed effects" "wfe Winner team fixed effects" "matches Number of matches" "mean_outcome Mean outcome") nogap sfmt(a2) order(*.lagAccumulatedWins)

