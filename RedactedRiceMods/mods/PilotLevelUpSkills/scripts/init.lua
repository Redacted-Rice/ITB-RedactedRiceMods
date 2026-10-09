
local mod = {
	id = "redactedrice_pilot_level_up_skills",
	name = "Pilot Level Up Skills",
	description = "Custom pilot level up skills by Redacted Rice.",
	icon = "scripts/icon.png",
	submodFolders = {"mods/"},
	version = "5.0.0",
	modApiVersion = "2.9.6",
	gameVersion = "1.2.93",
	dependencies = {
		modApiExt = "1.25",
		redactedrice_memhack = "1.4.1",
		redactedrice_cplus_plus = "2.0.0",
	}
}

function mod:init(options)
end

function mod:load(options, version)
end

return mod
