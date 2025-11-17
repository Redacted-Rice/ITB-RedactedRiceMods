local mod = {
	id = "redactedrice_treeherders",
	name = "Treeherders",
	icon = "img/mod_icon.png",
	version = "0.10.1",
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        modApiExt = "1.21",
        memedit = "1.2.0",
    }
}

function mod:init()	
	-- Assets
	require(self.scriptPath .. "images")
	require(self.scriptPath .. "palettes")

	-- Achievements
	require(self.scriptPath .. "achievements")

	-- Libs
	require(self.scriptPath .. "libs/passiveEffect")
	require(self.scriptPath .. "libs/predictableRandom")
	
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
	
	-- Shop... TBD
	-- modApi:addWeaponDrop("...")
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
	
	--todo remove when pulled into modUtils
	TreeherdersAchievements:addHooks()
	predictableRandom:registerAutoRollHook()
	passiveEffect:addHooks()
	passiveEffect:autoSetWeaponsPassiveFields()
end

return mod