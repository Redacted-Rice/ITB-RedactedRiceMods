
---------------------------------------------------------------------
-- Tutorial Tips v1.2 - code library
---------------------------------------------------------------------
-- small helper lib to manage tutorial tips that will only display once per profile.
-- can be reset, and would likely be done via a mod option.

local this = {}
local cachedTips
local rootId = nil

-- Initialize the library with a root ID
-- If not provided, defaults to the current mod's ID
function this:Init(customRootId)
	if customRootId then
		assert(type(customRootId) == 'string', "rootId must be a string")
		rootId = customRootId
	else
		local mod = mod_loader.mods[modApi.currentMod]
		rootId = mod and mod.id or nil
		assert(rootId, "Could not determine mod ID and no customRootId provided")
	end
	
	return self
end

-- writes tutorial tips data.
local function writeData(id, obj)
	sdlext.config(
		"modcontent.lua",
		function(readObj)
			readObj.tutorialTips = readObj.tutorialTips or {}
			readObj.tutorialTips[rootId] = readObj.tutorialTips[rootId] or {}
			readObj.tutorialTips[rootId][id] = obj
			cachedTips = readObj.tutorialTips
		end
	)
end

-- reads tutorial tips data.
local function readData(id)
	local result = nil
	
	if cachedTips then
		result = cachedTips[rootId] and cachedTips[rootId][id]
	else
		sdlext.config(
			"modcontent.lua",
			function(readObj)
				readObj.tutorialTips = readObj.tutorialTips or {}
				cachedTips = readObj.tutorialTips
				result = cachedTips[rootId] and cachedTips[rootId][id]
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
			obj.tutorialTips[rootId] = {}
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
	
	Global_Texts[rootId .. tip.id .."_Title"] = tip.title
	Global_Texts[rootId .. tip.id .."_Text"] = tip.text
end

function this:Trigger(id, loc)
	assert(type(id) == 'string')
	assert(type(loc) == 'userdata')
	assert(type(loc.x) == 'number')
	assert(type(loc.y) == 'number')
	
	if not readData(id) then
		Game:AddTip(rootId .. id, loc)
		writeData(id, true)
	end
end

return this