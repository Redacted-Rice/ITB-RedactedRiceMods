---------------------------------------------------------------------
-- Tutorial Tips v1.5 - code library
--
-- Originally by Lemonymous
--
-- Modified by Das Keifer to allow a custom root identifier via Init instead of
-- always using the current mod's ID (for shared libs like WeaponPreview).
---------------------------------------------------------------------
-- small helper lib to manage tutorial tips that will only display once per profile.
-- can be reset, and would likely be done via a mod option.
--
-- Note: Each mod using this library must each have their unique instance of it.

local mod = mod_loader.mods[modApi.currentMod]
local tips = {}
local cachedTips
local rootId = mod.id

local function cacheCurrentProfileData()
	if not modApi:isProfilePath() then
		return
	end

	sdlext.config(
		modApi:getCurrentProfilePath().."modcontent.lua",
		function(obj)
			obj.tutorialTips = obj.tutorialTips or {}
			obj.tutorialTips[rootId] = obj.tutorialTips[rootId] or {}
			cachedTips = obj.tutorialTips[rootId]
		end
	)
end

-- Initialize the library with a root ID.
-- If not provided, defaults to the current mod's ID.
function tips:init(customRootId)
	if customRootId then
		Assert.Equals('string', type(customRootId), "Argument #1")
		rootId = customRootId
	else
		local currentMod = mod_loader.mods[modApi.currentMod]
		rootId = currentMod and currentMod.id or nil
		assert(rootId, "Could not determine mod ID and no customRootId provided")
	end

	cachedTips = nil
	cacheCurrentProfileData()

	return self
end

-- writes tutorial tips data.
local function writeData(id, obj)
	sdlext.config(
		modApi:getCurrentProfilePath().."modcontent.lua",
		function(readObj)
			readObj.tutorialTips[rootId][id] = obj
			cachedTips = readObj.tutorialTips[rootId]
		end
	)
end

-- reads tutorial tips data.
local function readData(id)
	local result = nil

	if cachedTips then
		result = cachedTips[id]
	else
		sdlext.config(
			modApi:getCurrentProfilePath().."modcontent.lua",
			function(readObj)
				cachedTips = readObj.tutorialTips[rootId]
				result = cachedTips[id]
			end
		)
	end

	return result
end

function tips:resetAll()
	sdlext.config(
		modApi:getCurrentProfilePath().."modcontent.lua",
		function(obj)
			obj.tutorialTips = obj.tutorialTips or {}
			obj.tutorialTips[rootId] = {}
			cachedTips = obj.tutorialTips[rootId]
		end
	)
end

function tips:reset(id)
	Assert.Equals('string', type(id), "Argument #1")
	writeData(id, nil)
end

function tips:add(tip)
	Assert.Equals('table', type(tip), "Argument #1")
	Assert.Equals('string', type(tip.id))
	Assert.Equals('string', type(tip.title))
	Assert.Equals('string', type(tip.text))

	Global_Texts[rootId .. tip.id .."_Title"] = tip.title
	Global_Texts[rootId .. tip.id .."_Text"] = tip.text
end

function tips:trigger(id, loc)
	Assert.Equals('string', type(id), "Argument #1")
	Assert.TypePoint(loc, "Argument #2")

	if sdlext.isMapEditor() then
		return
	end

	if not readData(id) then
		Game:AddTip(rootId .. id, loc)
		writeData(id, true)
	end
end

function tips:getCachedProfileData()
	return cachedTips
end

-- backwards compatibility
tips.Init = tips.init
tips.ResetAll = tips.resetAll
tips.Reset = tips.reset
tips.Add = tips.add
tips.Trigger = tips.trigger

cacheCurrentProfileData()
modApi.events.onProfileChanged:subscribe(cacheCurrentProfileData)

return tips
