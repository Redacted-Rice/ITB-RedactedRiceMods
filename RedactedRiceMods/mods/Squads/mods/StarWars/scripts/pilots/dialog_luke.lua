-- Dialog for Luke Skywalker

return {
	-- Game States
	Gamestart = {"The Force will be with us.", "Time to make a difference.", "I may be a farm boy, but I'm ready for this fight."},
	FTL_Found = {"What is that? I sense something... strange.", "There's something familiar about this technology."},
	FTL_Start = {"This feels just like jumping to hyperspace!"},
	Gamestart_PostVictory = {"We can do this again. I believe in us.", "Every victory brings hope to those who need it most."},
	Death_Revived = {"I'm not afraid. Not anymore.", "The Force is still with me."},
	Death_Main = {"Tell my sister... I...", "Remember... the Force will be with you... always.", "I've failed them..."},
	Death_Response = {"No! #main_first!"},
	Death_Response_AI = {"It fought bravely. We honor its sacrifice."},
	TimeTravel_Win = {"This reminds me of what Yoda said about the future..."},
	Gameover_Start = {"I won't give up. Not on them. Not ever.", "There's still hope... there has to be..."},
	Gameover_Response = {"I'm sorry. I tried."},

	-- UI Barks
	Upgrade_PowerWeapon = {"Now THIS is an upgrade!", "The Force is strong with this one.", "An elegant weapon for a more civilized age. Well, close enough."},
	Upgrade_NoWeapon = {"I can work with this.", "A Jedi's strength flows from the Force, not just weapons."},
	Upgrade_PowerGeneric = {"This will make a difference.", "Just what we needed!"},

	-- Mid-Battle
	MissionStart = {"Red Five, standing by.", "Stay focused. Trust your instincts.", "Like shooting womp rats back home!", "Trust your feelings. The Force will guide us."},
	Mission_ResetTurn = {"I have a bad feeling about this... let's try again.", "Your eyes can deceive you, don't trust them. Let's try a different approach."},
	MissionEnd_Dead = {"That's it! Great shot!", "The Force was with us.", "We saved everyone. That's what matters."},
	MissionEnd_Retreat = {"They're retreating! We did it!"},

	MissionFinal_Start = {"This is it. Stay on target.", "I'm going in.", "The fate of everyone rests on this mission.", "No. I am a Jedi, like my father before me. And we will win this."},
	MissionFinal_StartResponse = {"I'm right behind you!"},
	MissionFinal_FallStart = {"What's happening?!"},
	MissionFinal_FallResponse = {"Hold on! We can get through this!"},
	MissionFinal_Pylons = {"The power grid is stable!"},
	MissionFinal_Bomb = {"One shot. Just like Beggar's Canyon.", "Stay on target... stay on target..."},
	MissionFinal_BombResponse = {"I've got a good feeling about this!"},
	MissionFinal_CaveStart = {"Remember, the Force will be with you. Always."},
	MissionFinal_BombDestroyed = {"No! We need that bomb!"},
	MissionFinal_BombArmed = {"The bomb is armed! Get clear!"},

	PodIncoming = {"A distress signal! Someone needs our help!"},
	PodResponse = {"We have to save them!"},
	PodCollected_Self = {"I've got you. You're safe now.", "You're among friends now."},
	PodDestroyed_Obs = {"No... we were too late."},
	Secret_DeviceSeen_Mountain = {"What is that device?"},
	Secret_DeviceSeen_Ice = {"There's something buried in the ice."},
	Secret_DeviceUsed = {"Let's see what this does..."},
	Secret_Arriving = {"Another Time Pod! Incoming!"},
	Emerge_Detected = {"Hostiles emerging! Stay alert!", "Here they come!", "I've got a bad feeling about this..."},
	Emerge_Success = {"They're here. Let's show them what we can do."},
	Emerge_FailedMech = {"That was too close!"},
	Emerge_FailedVek = {"Hah! Blocked!"},

	-- Mech State
	Mech_LowHealth = {"I can't shake him!", "Shields are failing!"},
	Mech_Webbed = {"I'm caught! I can't move!", "Not good!"},
	Mech_Shielded = {"Shield holding!"},
	Mech_Repaired = {"Systems restored. Ready to continue.", "Back in action!"},
	Pilot_Level_Self = {"Like my training with Master Yoda.", "I feel the Force growing stronger within me.", "Master Yoda would be proud."},
	Pilot_Level_Obs = {"Well done, #main_first! Your skills are improving.", "Great work out there!"},
	Mech_ShieldDown = {"Lost shields!"},

	-- Damage Done
	Vek_Drown = {"Into the water!"},
	Vek_Fall = {"Down you go!"},
	Vek_Smoke = {"Can't see through that smoke, can you?"},
	Vek_Frozen = {"Frozen solid!"},
	VekKilled_Self = {"Hostile down!", "That's one!", "Got it!", "For the Rebellion!"},
	VekKilled_Obs = {"Nice shot!", "Excellent work!"},
	VekKilled_Vek = {"They're turning on each other!"},

	DoubleVekKill_Self = {"Two with one shot!", "Just like bulls-eyeing womp rats!"},
	DoubleVekKill_Obs = {"Two kills! Impressive!", "That was incredible, #main_second!"},
	DoubleVekKill_Vek = {"Unexpected, but useful."},

	MntDestroyed_Self = {"I... destroyed the mountain?!", "That was more powerful than I thought!"},
	MntDestroyed_Obs = {"The whole mountain just collapsed!"},
	MntDestroyed_Vek = {"Incredible power..."},

	PowerCritical = {"The power grid! We need to protect it!", "We can't give up now! These people are counting on us!"},
	Bldg_Destroyed_Self = {"No... I destroyed it...", "This is my fault...", "I'm so sorry..."},
	Bldg_Destroyed_Obs = {"We lost a building. We need to do better!"},
	Bldg_Destroyed_Vek = {"They destroyed a building! We can't let this continue!"},
	Bldg_Resisted = {"The building held! That was close.", "Never give up. Never surrender."},

	-- Shared Missions
	Mission_Train_TrainStopped = {"The train stopped. Not good."},
	Mission_Train_TrainDestroyed = {"The train! No!"},
	Mission_Block_Reminder = {"We need to block their emergence points!"},

	-- Archive
	Mission_Airstrike_Incoming = {"Air support inbound! Get clear!"},
	Mission_Tanks_Activated = {"Tanks are rolling! Give them support!"},
	Mission_Tanks_PartialActivated = {"Some tanks are operational. Make them count!"},
	Mission_Dam_Reminder = {"The dam! We can't let them breach it!"},
	Mission_Dam_Destroyed = {"The dam is gone. This is bad."},
	Mission_Satellite_Destroyed = {"We lost the satellite."},
	Mission_Satellite_Imminent = {"The satellite is launching!"},
	Mission_Satellite_Launch = {"It's away! The satellite launched successfully!", "A new hope for communication!"},
	Mission_Mines_Vek = {"The mines worked!"},

	-- RST
	Mission_Terraform_Destroyed = {"The terraformer is down!"},
	Mission_Terraform_Attacks = {"Watch out for the terraformer!"},
	Mission_Cataclysm_Falling = {"The ground is collapsing!"},
	Mission_Lightning_Strike_Vek = {"Lightning strike! Direct hit!"},
	Mission_Solar_Destroyed = {"The solar collector is destroyed."},
	Mission_Force_Reminder = {"We need to clear those mountains!"},

	-- Pinnacle
	Mission_Freeze_Mines_Vek = {"Frozen in place!"},
	Mission_Factory_Destroyed = {"The factory's gone."},
	Mission_Factory_Spawning = {"The factory is producing more enemies!"},
	Mission_Reactivation_Thawed = {"They broke free!"},
	Mission_SnowStorm_FrozenVek = {"The storm froze them!"},
	Mission_SnowStorm_FrozenMech = {"No... Not again!"},
	BotKilled_Self = {"Droid down."},
	BotKilled_Obs = {"Target eliminated!"},

	-- Detritus
	Mission_Disposal_Destroyed = {"The disposal unit is destroyed!"},
	Mission_Disposal_Activated = {"Disposal activated!"},
	Mission_Barrels_Destroyed = {"A.C.I.D. barrels breached! Watch out!"},
	Mission_Power_Destroyed = {"Power plant destroyed. The grid is weakening."},
	Mission_Teleporter_Mech = {"Whoa... teleportation. That was... strange.", "I'm still here. All in one piece."},
	Mission_Belt_Mech = {"Moving on the conveyor!", "This reminds me of the Death Star's tractor beam!"},

	-- Additional valid mission triggers
	Mission_Airstrike_Arrival = {"Cover me, Red Two!", "Almost there... almost..."},
	Mission_Snowstorm_FrozenVek = {"The cold has stopped them cold!"},
	Mission_Shields_Down = {"Enemy shields are down!"},

	-- Luke's custom pilot ability dialog
	Luke_ForceFocused = {"I can feel it... the Force is with me", "Trust in the Force", "Use the Force."},
	Luke_ForceFocus_Used = {"The Force guides my movements.", "I can see what needs to be done.", "This ends now!"},
}