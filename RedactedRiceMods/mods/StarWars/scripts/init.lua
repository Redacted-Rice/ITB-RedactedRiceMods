local mod = {
	id = "redactedrice_starwars",
	name = "Star Wars",
	icon = "img/mod_icon.png",
	version = "1.0.3",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	dependencies = {
        modApiExt = "1.24",
    },
	libs = {}
}

function mod:init()
	-- Common Redacted Rice Libs
	for libId, lib in pairs(mod_loader.mods.redactedrice_libs.libs) do
		self.libs[libId] = lib
	end

	-- Load replace repair
	require(self.scriptPath .. "replaceRepair/api")

	self.libs.pilotSkill_tooltip = require(self.scriptPath .. "libs/pilotSkill_tooltip")
	self.libs.personality = require(self.scriptPath .. "libs/personality")

	-- Assets
	require(self.scriptPath .. "images")
	require(self.scriptPath .. "palettes")

	-- Achievements
	require(self.scriptPath .. "achievements")

	-- Rebel Pawns
	require(self.scriptPath .. "mechs/sw_mel_falcon")
	require(self.scriptPath .. "mechs/sw_snow_speeder")
	require(self.scriptPath .. "mechs/sw_x_wing")

	-- Empire Pawns
	require(self.scriptPath .. "mechs/sw_death_star")
	require(self.scriptPath .. "mechs/sw_atat")
	require(self.scriptPath .. "mechs/sw_tie_fighter")

	-- Rebel Weapons
	require(self.scriptPath .. "weapons/sw_cannon_turrets")
	modApi:addWeaponDrop("StarWars_CannonTurrets")

	require(self.scriptPath .. "weapons/sw_paired_cannons")
	modApi:addWeaponDrop("StarWars_PairedTurrets")

	require(self.scriptPath .. "weapons/sw_proton_torpedo")
	modApi:addWeaponDrop("StarWars_ProtonTorpedo")

	require(self.scriptPath .. "weapons/sw_rebel_hope")
	modApi:addWeaponDrop("StarWars_RebelHope")

	require(self.scriptPath .. "weapons/sw_cannon_array")
	modApi:addWeaponDrop("StarWars_CannonArray")

	require(self.scriptPath .. "weapons/sw_tow_cable")
	modApi:addWeaponDrop("StarWars_TowCable")

	-- Empire Weapons
	require(self.scriptPath .. "weapons/sw_empire_of_terror")
	modApi:addWeaponDrop("StarWars_EmpireOfTerror")

	require(self.scriptPath .. "weapons/sw_auxiliary_laser")
	modApi:addWeaponDrop("StarWars_AuxiliaryLaser")

	require(self.scriptPath .. "weapons/sw_heavy_turbocannons")
	modApi:addWeaponDrop("StarWars_HeavyTurbocannons")

	require(self.scriptPath .. "weapons/sw_stomp")
	modApi:addWeaponDrop("StarWars_Stomp")

	require(self.scriptPath .. "weapons/sw_tie_cannon_array")
	modApi:addWeaponDrop("StarWars_TIECannonArray")

	require(self.scriptPath .. "weapons/sw_tie_engine_overdrive")
	modApi:addWeaponDrop("StarWars_TIEEngineOverdrive")

	-- Pilots
	local pilots = require(self.scriptPath .. "pilots/init")
	pilots:init()
	self.pilots = pilots
end

function mod:load(options, version)
	-- Load as needed
	self.pilots:load(options, version)
	StarWars_TowCable:load(options, version)
	
	-- Load passive effects
	self.libs.passiveEffect:load()

	modApi:addSquad(
		{
			id = "starwars_rebels",
			"Star Wars Rebels",
			"StarWars_MelFalconMech",
			"StarWars_XWingMech",
			"StarWars_SnowSpeederMech",
		},
		"Star Wars Rebels",
		"Brought from a long, long time ago in a galaxy far, far away, these Rebel starships are fighting back against the evil vek empire wherever it may be",
		self.resourcePath .. "img/squad_icon.png"
	)

	-- Register squad skill exclusions if CPLUS+ is available
	-- This is 1.2 which won't be released yet
	if cplus_plus_ex then
		-- Prevent Jump Jets and Pontoons for the Rebels squad
		-- These flying mechs already have built-in movement advantages
		cplus_plus_ex:registerSquadSkillExclusions("starwars_rebels", {
			"RrJumpJets",
			"RrPontoons"
		})
	end

	modApi:addSquad(
		{
			id = "starwars_empire",
			"Star Wars Empire",
			"StarWars_DeathStarMech",
			"StarWars_TIEFighterMech",
			"StarWars_ATATMech",
		},
		"Star Wars Empire",
		"Rule the galaxy with fear and overwhelming power. The Empire's advanced war machines crush all resistance under their iron grip.",
		self.resourcePath .. "img/squad_icon.png"
	)

	-- Register squad skill exclusions if CPLUS+ is available
	if cplus_plus_ex then
		-- Prevent Jump Jets for the Empire squad (2 out of 3 are flying)
		cplus_plus_ex:registerSquadSkillExclusions("starwars_empire", {
			"RrJumpJets",
			"RrPontoons"
		})
	end

	StarWarsAchievements:addHooks()
end

return mod