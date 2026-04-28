local mod = {
	id = "redactedrice_starwars",
	name = "Star Wars",
	icon = "img/mod_icon.png",
	version = "0.1.0",
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

	require(self.scriptPath .. "libs/weaponArmed")
	require(self.scriptPath .. "libs/artilleryArc")
	self.libs.pilotSkill_tooltip = require(self.scriptPath .. "libs/pilotSkill_tooltip")
	self.libs.personality = require(self.scriptPath .. "libs/personality")

	-- Assets
	require(self.scriptPath .. "images")
	require(self.scriptPath .. "palettes")

	-- Achievements
	--require(self.scriptPath .. "achievements")

	-- Pawns
	require(self.scriptPath .. "mechs/sw_mel_falcon")
	require(self.scriptPath .. "mechs/sw_snow_speeder")
	require(self.scriptPath .. "mechs/sw_x_wing")

	-- Weapons
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

	-- Pilots
	local pilots = require(self.scriptPath .. "pilots/init")
	pilots:init()
	self.pilots = pilots
end

function mod:load(options, version)
	-- Load pilots
	if self.pilots then
		self.pilots:load(options, version)
	end

	modApi:addSquad(
		{
			id = "starwars_rebels",
			"Rebels",
			"StarWars_MelFalconMech",
			"StarWars_XWingMech",
			"StarWars_SnowSpeederMech",
		},
		"Rebels",
		"",
		self.resourcePath .. "img/squad_icon.png"
	)

	-- Register squad skill exclusions if CPLUS+ is available
	if cplus_plus_ex then
		-- Prevent Jump Jets and Pontoons for the Rebels squad
		-- These flying mechs already have built-in movement advantages
		cplus_plus_ex:registerSquadSkillExclusions("starwars_rebels", {
			"RrJumpJets",
			"RrPontoons"
		})
	end

	--WorldBuildersAchievements:addHooks()
end

return mod