
local mod =  {
	id = "redactedrice_libs",
	name = "Redacted Rice Mods",
	version = "2.1.0",
	icon = "icon.png",
	description = "A Collection of mods made by Redacted Rice",
	submodFolders = {"mods/"},
	modApiVersion = "2.9.7",
	gameVersion = "1.2.93",
	-- include all dependencies here to make sure they enable right
	-- when enabling all mods at once with the group checkbox
	dependencies = {
        modApiExt = "1.25",
        memedit = "1.2.1",
        easyEdit = "2.0.8",
        redactedrice_memhack = "1.5.0",
        redactedrice_cplus_plus = "2.1.0",
		redactedrice_mech_forge = "1.0.0",
    }
}

local libs = {
	-- artilleryArc functions a bit differently and is intentionally excluded here
	"weaponArmed",
	"boardUtils",
	"customEmitter",
	"moveThrough",
	"ignoreLiquid",
	"damageModifierLib",
	"inGameToolTip",
	"pawnTypeUtils",
	"passiveEffect",
	"plusHelper",
	"predictableRandom",
	"trait",
	"traitReplace",
	"tutorialTips",
	"weaponPreview",
}

function mod:init(options)
	local path = self.scriptPath

	self.libs = {}
	for _, libId in ipairs(libs) do
		self.libs[libId] = require(path.."libs/"..libId)
	end

	-- artilleryArc functions a bit differently and is intentionally excluded above
	require(path.."libs/artilleryArc")

	-- global ReplaceRepair API (folder lib, same pattern as upstream)
	self.libs.replaceRepair = require(path.."libs/replaceRepair/api")

    -- add modApiExt as well
	self.libs.modApiExt = modapiext
end

function mod:load(options)
end

return mod