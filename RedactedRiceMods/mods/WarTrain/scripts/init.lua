local mod = {
	id = "redactedrice_wartrain",
	name = "Iron Rail",
	icon = "img/mod_icon.png",
	version = "1.1.0",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	dependencies = {
		modApiExt = "1.21",
		redactedrice_libs = "1.6.0",
	},
	libs = {},
}

function mod:init()
	for libId, lib in pairs(mod_loader.mods.redactedrice_libs.libs) do
		self.libs[libId] = lib
	end

	require(self.scriptPath .. "palettes")
	require(self.scriptPath .. "images")

	require(self.scriptPath .. "mechs/war_engine")
	require(self.scriptPath .. "mechs/artillery_car")
	require(self.scriptPath .. "mechs/cannon_car")

	require(self.scriptPath .. "weapons/ramming_speed")
	modApi:addWeaponDrop("WarTrain_RammingSpeed")
end

function mod:load(options, version)
	modApi:addSquad(
		{
			id = "wartrain",
			"War Train",
			"WarTrain_WarEngineMech",
			"WarTrain_ArtilleryCarMech",
			"WarTrain_CannonCarMech",
		},
		"War Train",
		"A three-car train squad. The War Engine pulls the Artillery Car and Cannon Car along its path.",
		self.resourcePath .. "img/squad_icon.png"
	)

end

return mod
