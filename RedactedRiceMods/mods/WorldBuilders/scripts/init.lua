local mod = {
	id = "redactedrice_worldbuilders",
	name = "World Builders",
	icon = "img/mod_icon.png",
	version = "1.1.1",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        modApiExt = "1.21",
        memedit = "1.2.1",
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
	mod.libs.weaponPreview = require(self.scriptPath.."libs/weaponPreview")
	mod.libs.trait = require(self.scriptPath.."libs/trait")

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

	require(self.scriptPath .. "weapons/wb_move")
	modApi:addWeaponDrop("WorldBuilders_Passive_Move")
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
		"Once used to build the very islands, these mechs re-emerged to make the world inhospitable for the vek",
		self.resourcePath .. "img/squad_icon.png"
	)

	WorldBuildersAchievements:addHooks()
	-- Libs initialized once in the lib init script
	--self.libs.passiveEffect:load()
end

return mod