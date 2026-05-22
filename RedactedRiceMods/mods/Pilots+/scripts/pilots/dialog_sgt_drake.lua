-- Dialog for Sgt. Drake
-- Grizzled veteran sergeant, protective but gruff, teaches through experience

return {
	-- Game States
	Gamestart = {"Alright squad, stay sharp. I've got your backs.", "Listen up. Do what I say and you'll make it home.", "Been through this before. Stick with me."},
	FTL_Found = {"Time device. Seen a few of these. Still don't trust 'em.", "Another time capsule. Let's grab it and move."},
	FTL_Start = {"Here we go again. Different timeline, same mission."},
	Gamestart_PostVictory = {"Last run went well. Keep it up and we'll make it through this one too.", "Good work last time. Let's do it again."},
	Death_Revived = {"Back in the fight. Thanks for the save.", "Not dead yet. Still got some fight left in me."},
	Death_Main = {"No... Take care of... the squad...", "Go on... Without me... That's an order...", "Protect them... That's an order..."},
	Death_Response = {"#main_first! No! Stay with us!", "Medic! Get to #main_first!"},
	Death_Response_AI = {"Lost the AI. Keep moving."},
	TimeTravel_Win = {"Another timeline saved. Good work, squad."},
	Gameover_Start = {"This is what I trained you for! Don't give up on me now!", "Hold the line! We're not done yet!"},
	Gameover_Response = {"We tried. Sometimes that's all you can do."},

	-- UI Barks
	Upgrade_PowerWeapon = {"Now that's firepower. Let's see what it can do.", "Good upgrade. I'll show you how to use it right.", "Solid choice. This'll give us an edge."},
	Upgrade_NoWeapon = {"Better armor. Smart move, kid.", "Defense wins fights. Good call."},
	Upgrade_PowerGeneric = {"Good upgrade. Every advantage counts.", "That'll help. Keep improving."},

	-- Mid-Battle
	MissionStart = {"Here we go. Watch your sectors and call out targets.", "Watch their attack vectors.", "Listen up - stay together, watch each other's backs.", "Alright squad, remember your training!"},
	Mission_ResetTurn = {"Second chance. Don't waste it. Learn from what just happened.", "Take two. Let me show you how it's done."},
	MissionEnd_Dead = {"Clean sweep! That's how it's done, people!", "Got 'em all. Solid work, squad.", "Good kill. Every Vek down is one less to worry about."},
	MissionEnd_Retreat = {"They're running. Good. Let 'em tell the others what happens.", "Vek are pulling back. We held the line."},

	MissionFinal_Start = {"This is it, the big one. Everything I taught you comes down to this!", "Final fight! Show 'em what you've learned!", "Remember your training. We end this now!"},
	MissionFinal_StartResponse = {"Aye aye Sir. We're ready."},
	MissionFinal_FallStart = {"Ground's giving way! Move it!"},
	MissionFinal_FallResponse = {"Stay calm! Keep fighting!"},
	MissionFinal_Pylons = {"Grid's secure. Good work."},
	MissionFinal_Bomb = {"Bomb's moving. Keep it safe!", "Protect that payload!"},
	MissionFinal_BombResponse = {"On it. Nothing's getting this bomb."},
	MissionFinal_CaveStart = {"Into the nest. Stay sharp, watch for ambush."},
	MissionFinal_BombDestroyed = {"Bomb's down. Adapt!"},
	MissionFinal_BombArmed = {"Bomb's armed! Get out now!"},

	PodIncoming = {"Time pod incoming! Someone get to it!", "Pod detected. Let's save whoever's in there."},
	PodResponse = {"Moving to secure the pod."},
	PodCollected_Self = {"Got the survivor. Welcome back to the fight.", "Pod secured. You're safe now."},
	PodDestroyed_Obs = {"Lost the pod. That was a good man."},
	Secret_DeviceSeen_Mountain = {"Something in that mountain. Investigate."},
	Secret_DeviceSeen_Ice = {"There's something frozen in there."},
	Secret_DeviceUsed = {"Activating it. Hope this helps."},
	Secret_Arriving = {"Another pod. Strange signal though."},
	Emerge_Detected = {"Vek emerging! Mark those positions!", "Ground's shaking - Vek incoming! Get ready!", "Here they come! Watch those emergence points!", "Incoming Vek! Defensive positions!"},
	Emerge_Success = {"Vek on the field. Engage!"},
	Emerge_FailedMech = {"Blocked their emergence! That's the trick - learn it!", "Nice positioning! That's how you stop 'em!"},
	Emerge_FailedVek = {"They blocked themselves. Vek ain't too smart."},

	-- Mech State
	Mech_LowHealth = {"Taking heavy damage! Be careful out there!", "Armor's shot. I need support!"},
	Mech_Webbed = {"Webbed! Can't move! Cover me!", "Stuck in webbing. Save yourselves!"},
	Mech_Shielded = {"Shield's up. Make it count."},
	Mech_Repaired = {"Repairs done. Back in the fight.", "Good as new. Let's go."},
	Pilot_Level_Self = {"Still learning, even at my age. Experience never stops.", "Picked up a few new tricks. Old dog, new tricks.", "Combat never stops teaching you."},
	Pilot_Level_Obs = {"#main_first's improving! That's what I like to see!", "Good progress, #main_first. Keep it up!", "#main_first's getting the hang of it. Proud of you!"},
	Mech_ShieldDown = {"Shield's gone. Stay alert!"},

	-- Damage Done
	Vek_Drown = {"Water kill. Use your environment."},
	Vek_Fall = {"Long way down. Target eliminated."},
	Vek_Smoke = {"Smoke out. Use it."},
	Vek_Frozen = {"Frozen solid. One less hostile for now."},
	VekKilled_Self = {"Target down. Moving on.", "Got it.", "Vek eliminated.", "One less bug.", "Kill confirmed. Next target."},
	VekKilled_Obs = {"Good kill, #main_second! That's the way!", "Nice work, #main_second! Good shot.", "#main_second one more down! Keep it up!"},
	VekKilled_Vek = {"They turned on their own. Works for me."},

	DoubleVekKill_Self = {"Two for one! That's efficiency!", "Double kill! That's how it's done!"},
	DoubleVekKill_Obs = {"That's some quick thinking #main_second!", "#main_second took out two! That's some fine shooting!"},
	DoubleVekKill_Vek = {"Two Vek down. Their mistake."},

	MntDestroyed_Self = {"Mountain's down. Cleared the way."},
	MntDestroyed_Obs = {"Mountain destroyed. Watch the debris."},
	MntDestroyed_Vek = {"That Vek just took out the mountain."},

	PowerCritical = {"Grid's failing! Protect those buildings or we lose everything!", "Power's critical! This is what we're here for!"},
	Bldg_Destroyed_Self = {"No! We let them down. This can't happen again.", "Structure down. I should've been better.", "Building destroyed. More innocent casualties of war."},
	Bldg_Destroyed_Obs = {"Lost a structure. Protect the others!"},
	Bldg_Destroyed_Vek = {"Like moths to the flame."},
	Bldg_Resisted = {"Building held! That's what we're fighting for!"},

	-- Shared Missions
	Mission_Train_TrainStopped = {"Train's stopped. Keep the Vek off it!"},
	Mission_Train_TrainDestroyed = {"No! We needed those supplies!"},
	Mission_Block_Reminder = {"Block those emergence points! Keep their numbers down!"},

	-- Archive
	Mission_Airstrike_Incoming = {"Air strike incoming! Clear the zone!", "Bombs away! Get clear!"},
	Mission_Tanks_Activated = {"Tanks online. Work with 'em!", "Ground support's up. Use 'em!"},
	Mission_Tanks_PartialActivated = {"Some tanks are up. Better than nothing."},
	Mission_Dam_Reminder = {"Lets break that dam! Use the environment to our advantage!"},
	Mission_Dam_Destroyed = {"Dam's breached. Flooding incoming - watch your 9's"},
	Mission_Satellite_Destroyed = {"Lost the satellite. Communications down."},
	Mission_Satellite_Imminent = {"Satellite launching! Move out!"},
	Mission_Satellite_Launch = {"Satellite's away! Good work squad!", "Launch successful! We got eyes in the skies."},
	Mission_Mines_Vek = {"Ha! Oldest trick in the book", "Vek hit a mine! Great deployment!"},

	-- RST
	Mission_Terraform_Destroyed = {"Terraformer's down."},
	Mission_Terraform_Attacks = {"Watch out - that thing is deadly"},
	Mission_Cataclysm_Falling = {"Ground's collapsing! Watch your footing!"},
	Mission_Lightning_Strike_Vek = {"Lightning took one out! I'll take it!", "Nature's on our side! One down!"},
	Mission_Solar_Destroyed = {"Solar array destroyed."},
	Mission_Force_Reminder = {"Clear those mountains! That's an order!"},

	-- Pinnacle
	Mission_Freeze_Mines_Vek = {"Freeze mine worked! Remember that trick!", "Vek's frozen! That's textbook!"},
	Mission_Factory_Destroyed = {"Factory down. Keep your heads up for the next time"},
	Mission_Factory_Spawning = {"Factory's making more bugs. Take it out!"},
	Mission_Reactivation_Thawed = {"Vek's back up. Keep fighting."},
	Mission_SnowStorm_FrozenVek = {"Storm froze 'em! Free kill!", "Vek's frozen solid! Take the shot!"},
	Mission_SnowStorm_FrozenMech = {"Controls are frozen! Carry on without me!", "Mech's feeezing up. Controls unresponsive."},
	BotKilled_Self = {"What a waste of money"},
	BotKilled_Obs = {"What a hunk of garbage"},

	-- Detritus
	Mission_Disposal_Destroyed = {"Disposal system's gone. We're fighting uphill now."},
	Mission_Disposal_Activated = {"Watch out! That stuffs no joke!"},
	Mission_Barrels_Destroyed = {"Acid spill! Watch where you step!"},
	Mission_Power_Destroyed = {"Power station destroyed. We can't afford to lose more"},
	Mission_Teleporter_Mech = {"Teleport complete. Hate that feeling.", "Made it through. Still don't like teleporting."},
	Mission_Belt_Mech = {"Belt's got me. Going with it.", "Conveyor activated. Adapting."},

	-- Additional mission triggers
	Mission_Airstrike_Arrival = {"Air support's here! Make room!"},
	Mission_Snowstorm_FrozenVek = {"Storm's doing our job for us!"},
	Mission_Shields_Down = {"Their shields are down! Hit 'em now!"},
}
