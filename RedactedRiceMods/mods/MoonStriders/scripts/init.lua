local mod = {
	id = "redactedrice_moonstriders",
	name = "Moon Striders",
	icon = "img/mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
}

function mod:init()
	-- Assets
	require(self.scriptPath .. "images")
	require(self.scriptPath .. "palettes")

	-- Achievements
	require(self.scriptPath .. "achievements")
	MoonStridersAchievements:subscribe()

	-- Pawns
	require(self.scriptPath .. "mechs/ms_fighter")
	require(self.scriptPath .. "mechs/ms_falconet")
	require(self.scriptPath .. "mechs/ms_mortar")

	-- Weapons
	require(self.scriptPath .. "weapons/ms_apollo_mortar")
	modApi:addWeaponDrop("MoonStriders_ApolloMortar")

	require(self.scriptPath .. "weapons/ms_colossus_hook")
	modApi:addWeaponDrop("MoonStriders_ColossusHook")

	require(self.scriptPath .. "weapons/ms_scorpio_falconet")
	modApi:addWeaponDrop("MoonStriders_ScorpioFalconet")
end

function mod:load(options, version)
	modApi:addSquad(
		{
			id = "moonstriders",
			"Moon Striders",
			"MoonStriders_MortarMech",
			"MoonStriders_FalconetMech",
			"MoonStriders_FighterMech",
		},
		"Moon Striders",
		"They seem so familiar... but backwards",
		self.resourcePath .. "img/squad_icon.png"
	)

	MoonStridersAchievements:addHooks()
end

return mod