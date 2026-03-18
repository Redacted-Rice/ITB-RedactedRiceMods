
local mod =  {
	id = "redactedrice_libs",
	name = "Redacted Rice Mods",
	version = "1.3.0",
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
	"boardUtils",
	"pawnTypeUtils",
	"passiveEffect",
	"predictableRandom",
	"trait",
}

function mod:init(options)
	local path = self.scriptPath

	self.libs = {}
	for _, libId in ipairs(libs) do
		self.libs[libId] = require(path.."libs/"..libId)
		if self.libs[libId].init then
			self.libs[libId]:init()
		end
	end

    -- add modApiExt as well
	self.libs.modApiExt = modapiext
end

function mod:load(options, version)
	for _, libId in ipairs(libs) do
		if self.libs[libId].load then
			self.libs[libId]:load()
		end
	end
end

return mod