local mod = {
	id = "redactedrice_treeherders",
	name = "Treeherders",
	icon = "img/mod_icon.png",
	version = "2.0",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        modApiExt = "1.21",
        memedit = "1.2.0",
    },
	libs = {},
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

	require(self.scriptPath.. "forestUtils")

	-- Pawns
	require(self.scriptPath .. "mechs/th_entborg")
	require(self.scriptPath .. "mechs/th_forestfirer")
	require(self.scriptPath .. "mechs/th_arbiformer")

	-- Weapons
	require(self.scriptPath .. "weapons/th_forestfire")
	modApi:addWeaponDrop("Treeherders_ForestFire")

	require(self.scriptPath .. "weapons/th_treevenge")
	modApi:addWeaponDrop("Treeherders_Treevenge")

	require(self.scriptPath .. "weapons/th_violentgrowth")
	modApi:addWeaponDrop("Treeherders_ViolentGrowth")

	require(self.scriptPath .. "weapons/th_waketheforest")
	modApi:addWeaponDrop("Treeherders_Passive_WakeTheForest")
	
	require(self.scriptPath .. "weapons/th_overgrowth")
	modApi:addWeaponDrop("Treeherders_Overgrowth")
end

function mod:load(options, version)
	modApi:addSquad(
		{
			id = "treeherders",
			"Treeherders",
			"Treeherders_EntborgMech",
			"Treeherders_ForestFirerMech",
			"Treeherders_ArbiformerMech",
		},
		"Treeherders",
		"One with the forests, these mechs harness natures power to defend earth from the vek onslaught",
		self.resourcePath .. "img/squad_icon.png"
	)

	TreeherdersAchievements:addHooks()
	-- Libs initialized once in the lib init script
	--self.libs.passiveEffect:load()
	--self.libs.predictableRandom:load()
end

function mod:metadata()
	modApi:addGenerationOption(
		"th_EntborgCyborg", "Entborg Class",
		"Changes the class of the enborg mech, and their weapons to Cyborg.\nREQUIRES RESTART TO TAKE EFFECT!",
		{
			strings = { "Brute", "Cyborg"},
			values = { 0, 1},
			value = 1
		}
	)
end

return mod