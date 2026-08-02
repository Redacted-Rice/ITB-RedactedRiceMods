local mod = {
	id = "redactedrice_Legendary+",
	name = "Legendary Lvl Up Skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	dependencies = {
		redactedrice_memhack = "1.3.0",
		redactedrice_cplus_plus = "1.3.1",
	}
}

function mod:init()
	local legendary_plus = require(self.scriptPath .. "legendary_plus")

	for libId, lib in pairs(mod_loader.mods.redactedrice_libs.libs) do
		legendary_plus.libs[libId] = lib
	end

	legendary_plus:init()
end

function mod:load(options, version)
	legendary_plus:load()
end

return mod
