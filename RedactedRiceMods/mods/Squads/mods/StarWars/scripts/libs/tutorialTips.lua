
---------------------------------------------------------------------
-- Tutorial Tips v1.1 - code library
---------------------------------------------------------------------
-- small helper lib to manage tutorial tips that will only display once per profile.
-- can be reset, and would likely be done via a mod option.

local mod = mod_loader.mods[modApi.currentMod]
local this = {}
local cachedTips

sdlext.config(
	"modcontent.lua",
	function(obj)
		obj.tutorialTips = obj.tutorialTips or {}
		obj.tutorialTips[mod.id] = obj.tutorialTips[mod.id] or {}
		cachedTips = obj.tutorialTips
	end
)

-- writes tutorial tips data.
local function writeData(id, obj)
	sdlext.config(
		"modcontent.lua",
		function(readObj)
			readObj.tutorialTips[mod.id][id] = obj
			cachedTips = readObj.tutorialTips
		end
	)
end

-- reads tutorial tips data.
local function readData(id)
	local result = nil
	
	if cachedTips then
		result = cachedTips[mod.id][id]
	else
		sdlext.config(
			"modcontent.lua",
			function(readObj)
				cachedTips = readObj.tutorialTips
				result = cachedTips[mod.id][id]
			end
		)
	end
	
	return result
end

function this:ResetAll()
	sdlext.config(
		"modcontent.lua",
		function(obj)
			obj.tutorialTips = obj.tutorialTips or {}
			obj.tutorialTips[mod.id] = {}
			cachedTips = obj.tutorialTips
		end
	)
end

function this:Reset(id)
	assert(type(id) == 'string')
	writeData(id, nil)
end

function this:Add(tip)
	assert(type(tip) == 'table')
	assert(type(tip.id) == 'string')
	assert(type(tip.title) == 'string')
	assert(type(tip.text) == 'string')
	
	Global_Texts[mod.id .. tip.id .."_Title"] = tip.title
	Global_Texts[mod.id .. tip.id .."_Text"] = tip.text
end

function this:Trigger(id, loc)
	assert(type(id) == 'string')
	assert(type(loc) == 'userdata')
	assert(type(loc.x) == 'number')
	assert(type(loc.y) == 'number')
	
	if not readData(id) then
		Game:AddTip(mod.id .. id, loc)
		writeData(id, true)
	end
end

return this