local mod = {
	id = "redactedrice_Legendary+",
	name = "Legendary Lvl Up Skills",
	icon = "mod_icon.png",
	version = "1.0.0",
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	dependencies = {
		redactedrice_memhack = "1.4.0",
		redactedrice_cplus_plus = "1.4.0",
	}
}

function mod:metadata()
	modApi:addGenerationOption(
		"alwaysShowQueuedPreviewIcons",
		"Always Show Queued Preview Icons",
		"When enabled, Legendary+ effect icons for queued enemy attacks stay visible without hovering the attacker or target.",
		{ enabled = false }
	)
end

function mod:init()
	self.legendary_plus = require(self.scriptPath .. "legendary_plus")

	for libId, lib in pairs(mod_loader.mods.redactedrice_libs.libs) do
		self.legendary_plus.libs[libId] = lib
	end

	self.legendary_plus:init()
end

function mod:load(options, version)
	self.legendary_plus:load()
end

return mod
