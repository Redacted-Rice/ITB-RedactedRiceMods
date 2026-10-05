-- Dialog for Darth Vader

return {
	-- Game States
	Gamestart = {"The Empire will crush all resistance.", "I sense great fear among our enemies.", "You underestimate the power of the Dark Side."},
	FTL_Found = {"A disruption... Investigate it.", "Something stirs in the force. I will tolerate no surprises."},
	FTL_Start = {"The Empire does not retreat."},
	Gamestart_PostVictory = {"Victory is assured.", "Another timeline brought to heel."},
	Death_Revived = {"Death is a weakness I have overcome before.", "You cannot destroy me so easily."},
	Death_Main = {"The circle is now complete.", "You have failed me for the last time.", "Impressive... most impressive."},
	Death_Response = {"A costly loss.", "The Dark Side demands sacrifice."},
	Death_Response_AI = {"Dispose of the wreckage. Continue the mission."},
	TimeTravel_Win = {"Time bends to those strong in the Force.", "Even time cannot save them from the Empire."},
	Gameover_Start = {"This failure will not be forgotten.", "The Emperor will hear of this."},
	Gameover_Response = {"There is no excuse for defeat."},

	-- UI Barks
	Upgrade_PowerWeapon = {"A weapon worthy of the Empire.", "Let them fear our firepower.", "Crush them with it."},
	Upgrade_NoWeapon = {"The Force is enough for a true master.", "Weapons are tools. Fear is the true weapon."},
	Upgrade_PowerGeneric = {"Acceptable.", "Make use of it."},

	-- Mid-Battle
	MissionStart = {"Perhaps you think you are immune to the Dark Side.", "I will not tolerate failure.", "The Vek scum will pay for their defiance.", "There will be no mercy."},
	Mission_ResetTurn = {"Do not dissapoint me again.", "I am more forgiving than the Emperor. Do not fail me again."},
	MissionEnd_Dead = {"As I foresaw.", "The weakness has been removed.", "The mission is complete. For now."},
	MissionEnd_Retreat = {"Let them run. Fear will finish what we started.", "You cannot escape me."},

	MissionFinal_Start = {"This ends now.", "The time has come to extinguish all hope.", "I have you now."},
	MissionFinal_StartResponse = {"Stay in formation."},
	MissionFinal_FallStart = {"What is happening?!"},
	MissionFinal_FallResponse = {"Hold your position!"},
	MissionFinal_Pylons = {"The grid remains stable."},
	MissionFinal_Bomb = {"Destroy the target.", "Leave no survivors."},
	MissionFinal_BombResponse = {"Focus fire on the objective."},
	MissionFinal_CaveStart = {"Proceed. I sense no threat worth my concern."},
	MissionFinal_BombDestroyed = {"The weapon is gone. Recover it or replace it."},
	MissionFinal_BombArmed = {"Move if you value your lives."},

	PodIncoming = {"A pod. Capture it."},
	PodResponse = {"Recover whatever is inside."},
	PodCollected_Self = {"You are under Imperial protection now.", "Do not waste my time."},
	PodDestroyed_Obs = {"Unfortunate."},
	Secret_DeviceSeen_Mountain = {"What is that device?"},
	Secret_DeviceSeen_Ice = {"Something is buried there."},
	Secret_DeviceUsed = {"Activate it."},
	Secret_Arriving = {"Another pod incoming. Make it ours."},
	Emerge_Detected = {"Soon they will understand the power of the Dark Side.", "They are no match for me.", "So be it."},
	Emerge_Success = {"Destroy them."},
	Emerge_FailedMech = {"Pathetic."},
	Emerge_FailedVek = {"Finish them."},

	-- Mech State
	Mech_LowHealth = {"I cannot be defeated.", "The Force will sustain me.", "Hnnnng... Hnnng..."},
	Mech_Webbed = {"Release me.", "This changes nothing."},
	Mech_Shielded = {"Shields online."},
	Mech_Repaired = {"Fully operational.", "Back online."},
	Pilot_Level_Self = {"The Dark Side grows stronger.", "My power is unmatched."},
	Pilot_Level_Obs = {"Acceptable progress, #main_first.", "Do not disappoint me again."},
	Mech_ShieldDown = {"Shields down."},

	-- Damage Done
	Vek_Drown = {"Into the depths."},
	Vek_Fall = {"A sorry lack of foresight."},
	Vek_Smoke = {"Incapacited. Such weakness"},
	Vek_Frozen = {"Frozen in fear."},
	VekKilled_Self = {"Destroyed.", "Another vek crushed.", "Pathetic."},
	VekKilled_Obs = {"Acceptable.", "Continue."},
	VekKilled_Vek = {"They turn on each other. Good.", "The Force clouds thier vision."},

	DoubleVekKill_Self = {"So fragile...", "The Force is strong with us."},
	DoubleVekKill_Obs = {"Impressive, #main_second.", "Adequate."},
	DoubleVekKill_Vek = {"Another tool of the empire."},

	MntDestroyed_Self = {"Nothing will stand in my way."},
	MntDestroyed_Obs = {"We will persue no matter the cost."},
	MntDestroyed_Vek = {"Fear the power of the Empire."},

	PowerCritical = {"Protect the power core.", "Failure is unacceptable."},
	Bldg_Destroyed_Self = {"An acceptable cost.", "Most regrettable."},
	Bldg_Destroyed_Obs = {"A small cost for victory.", "Let them fear us."},
	Bldg_Destroyed_Vek = {"They destroy what they fail to conquer."},
	Bldg_Resisted = {"..."},

	-- Shared Missions
	Mission_Train_TrainStopped = {"Failure is not tolerated."},
	Mission_Train_TrainDestroyed = {"... Most distressing."},
	Mission_Block_Reminder = {"Let the force guide you to their location"},

	-- Archive
	Mission_Airstrike_Incoming = {"Air support inbound. Make way."},
	Mission_Tanks_Activated = {"Tanks under Empire control"},
	Mission_Tanks_PartialActivated = {"The strong will survive"},
	Mission_Dam_Reminder = {"Destroy the dam."},
	Mission_Dam_Destroyed = {"Mission completed."},
	Mission_Satellite_Destroyed = {"Regrettable."},
	Mission_Satellite_Imminent = {"Steady. Almost there."},
	Mission_Satellite_Launch = {"The Empire is stronger.", "Another tool of Imperial control."},
	Mission_Mines_Vek = {"As I foresaw."},

	-- RST
	Mission_Terraform_Destroyed = {"..."},
	Mission_Terraform_Attacks = {"Guard it or you will die."},
	Mission_Cataclysm_Falling = {"Let the force guide you."},
	Mission_Lightning_Strike_Vek = {"Foolish Vek."},
	Mission_Solar_Destroyed = {"They shall pay for their rebellion."},
	Mission_Force_Reminder = {"Level their home."},

	-- Pinnacle
	Mission_Freeze_Mines_Vek = {"Frozen. Helpless."},
	Mission_Factory_Destroyed = {"Target eliminated."},
	Mission_Factory_Spawning = {"Get it under control."},
	Mission_Reactivation_Thawed = {"A foolish escape."},
	Mission_SnowStorm_FrozenVek = {"Leave them as a reminder."},
	Mission_SnowStorm_FrozenMech = {"This is unacceptable."},
	BotKilled_Self = {"Droid destroyed."},
	BotKilled_Obs = {"Droid eliminated."},

	-- Detritus
	Mission_Disposal_Destroyed = {"A small blow to the Empire."},
	Mission_Disposal_Activated = {"Let them fear us."},
	Mission_Barrels_Destroyed = {"Make them suffer."},
	Mission_Power_Destroyed = {"... Pray the Emperor does not hear of your failure."},
	Mission_Teleporter_Mech = {"Relocated."},
	Mission_Belt_Mech = {"You cannot escape me."},

	-- Additional valid mission triggers
	Mission_Airstrike_Arrival = {"Strike inbound."},
	Mission_Snowstorm_FrozenVek = {"Let them freeze."},
	Mission_Shields_Down = {"Exploit their fear."},

	-- Vader's custom pilot ability dialog
	Vader_ForceChoke = {
		"I find your lack of faith disturbing.",
		"You are as clumsy as you are stupid.",
		"Do not resist.",
	},
}
