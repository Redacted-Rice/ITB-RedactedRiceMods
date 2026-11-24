
local mod = {
	id = "redactedrice_squads",
	name = "Squads",
	description = "Custom squads by Redacted Rice.",
	icon = "scripts/icon.png",
	submodFolders = {"mods/"},
	version = "5.0.0",
	modApiVersion = "2.9.7",
	gameVersion = "1.2.93",
	dependencies = {
		modApiExt = "1.24",
		memedit = "1.2.1",
		easyEdit = "2.0.8",
		redactedrice_memhack = "1.5.0",
		redactedrice_mech_forge = "1.0.0",
	},
}

function mod:init(options)
end

function mod:load(options, version)
end

return mod
