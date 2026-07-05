
local mod =  {
	id = "redactedrice_libs",
	name = "Redacted Rice Mods",
	version = "1.8.0",
	icon = "icon.png",
	description = "A Collection of mods made by Redacted Rice",
	submodFolders = {"mods/"},
	modApiVersion = "2.9.5",
	gameVersion = "1.2.93",
	-- include all dependencies here to make sure they enable right
	-- when enabling all mods at once with the group checkbox
	dependencies = {
        modApiExt = "1.24",
        memedit = "1.2.1",
        easyEdit = "2.0.8",
        redactedrice_memhack = "1.3.0",
        redactedrice_cplus_plus = "1.3.0",
    }
}

local libs = {
	-- artilleryArc functions a bit differently and is intentionally excluded here
	"weaponArmed",
	"boardUtils",
	"pawnTypeUtils",
	"passiveEffect",
	"predictableRandom",
	"trait",
	"traitReplace",
	-- tutorialTips functions a bit differently and is intentionally excluded here
	"weaponPreview",
}

function mod:init(options)
	local path = self.scriptPath

	self.libs = {}
	for _, libId in ipairs(libs) do
		self.libs[libId] = require(path.."libs/"..libId)
	end

	-- ArtilleryArc and TutorialTip behave a bit differently
	require(path.."libs/artilleryArc")
	self.libs["tutorialTips"] = require(path.."libs/tutorialTips")

    -- add modApiExt as well
	self.libs.modApiExt = modapiext
end

function mod:load(options)
end

return mod