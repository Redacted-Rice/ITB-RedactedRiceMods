
local mod =  {
	id = "redactedrice_libs",
	name = "Redacted Rice Mods",
	version = "1.0.0",
	icon = "scripts/icon.png",
	description = "A Collection of mods made by Redacted Rice",
	submodFolders = {"mods/"},
	modApiVersion = "2.9.4",
	gameVersion = "1.2.93",
	dependencies = {
        modApiExt = "1.21",
        memedit = "1.2.0",
    }
}

local libs = {
	"passiveEffect",
	"predictableRandom",
}

function mod:init(options)
	local path = self.scriptPath

	self.libs = {}
	for _, libId in ipairs(libs) do
		self.libs[libId] = require(path.."libs/"..libId)
	end

    -- add modApiExt as well
	self.libs.modApiExt = modapiext
end

function mod:load(options, version)
	-- Should only be called once per instance
	self.libs.passiveEffect:load()
	self.libs.predictableRandom:load()
end

return mod