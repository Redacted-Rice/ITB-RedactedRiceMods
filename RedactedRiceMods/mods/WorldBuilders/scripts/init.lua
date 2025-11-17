local mod = {
	id = "redactedrice_worldbuilders",
	name = "World Builders",
	icon = "img/mod_icon.png",
	version = "0.8.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        modApiExt = "1.21",
        memedit = "1.2.0",
    },
	libs = {}
}

function mod:init()
	-- Common Redacted Rice Libs
	for libId, lib in pairs(mod_loader.mods.redactedrice_libs.libs) do
		self.libs[libId] = lib
	end

	-- Assets
	require(self.scriptPath .. "images")
	require(self.scriptPath .. "palettes")

	-- Achievements
	require(self.scriptPath .. "achievements")

	-- Libs
	mod.libs.weaponPreview = require(self.scriptPath.."libs/".."weaponPreview")

	-- Pawns
	require(self.scriptPath .. "mechs/wb_maker")
	require(self.scriptPath .. "mechs/wb_eater")
	require(self.scriptPath .. "mechs/wb_shaper")

	-- Weapons
	require(self.scriptPath .. "weapons/wb_mold")
	modApi:addWeaponDrop("WorldBuilders_Mold")

	require(self.scriptPath .. "weapons/wb_consume")
	modApi:addWeaponDrop("WorldBuilders_Consume")

	require(self.scriptPath .. "weapons/wb_shift")
	modApi:addWeaponDrop("WorldBuilders_Shift")

	LOG("MOVE")
	require(self.scriptPath .. "weapons/wb_move")
	modApi:addWeaponDrop("WorldBuilders_Passive_Move")
	LOG("MOVE2")

	-- Shop... TBD
	-- modApi:addWeaponDrop("...")
end

function mod:load(options, version)
	modApi:addSquad(
		{
			id = "worldbuilders",
			"World Builders",
			"WorldBuilders_MakerMech",
			"WorldBuilders_EaterMech",
			"WorldBuilders_ShaperMech",
		},
		"World Builders",
		"... Something cool here...",
		self.resourcePath .. "img/squad_icon.png"
	)

	WorldBuildersAchievements:addHooks()
	self.libs.passiveEffect:load()
end

return mod