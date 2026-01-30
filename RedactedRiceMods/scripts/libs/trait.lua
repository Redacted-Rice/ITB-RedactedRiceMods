
local VERSION = "2.2.1"
---------------------------------------------------------------------
-- Trait v2.2.1 - code library
--
-- by Lemonymous
---------------------------------------------------------------------
-- Provides functionality to add traits to pawns.
-- Traits are purely visual - displaying an icon and a description.
-- Only one trait can be visible on a unit at the same time.
--
--    Requires libraries:
-- memedit
-- modApiExt
--
--    Fetch library:
-- local trait = require(self.scriptPath..'trait')
--
--    Methods:
-- :add(trait) - adds a trait that will update when pawns change positions.
--    trait.pilotSkill - trait applies to pawns with this pilotSkill
--    trait.pawnType - trait applies to pawns with this pawnType
--    trait.func - trait applies to pawns which this function returns true for
--    trait.icon - path to icon used in the pilot tooltip; either relative to mod, or path to asset in resource.dat
--    trait.icon_glow - path to icon used on the Board; either relative to mod, or path to asset in resource.dat
--    trait.icon_offset
--    trait.desc_title
--    trait.desc_text
-- :update(loc) - manually updates the trait on a location.
--                Useful for traits that can change without
--                pawns changing location
--
--    Priority order when multiple traits appliest to a pawn:
-- func > pilotSkill > pawnType
-- first created > last created
-- 

local mod = modApi:getCurrentMod()
local modApiExt = modapiext or require(mod.scriptPath.."modApiExt/modApiExt")
local isMemeditAvailable = memedit ~= nil

local function isManagedTrait(id)
	local prefix = id:sub(1,5)
	local number = id:sub(6,-1)

	number = tonumber(number)

	return true
		and prefix == "trait"
		and number ~= nil
		and number <= #Traits
end

local function onModsInitialized()
	if VERSION < Traits.version then
		return
	end

	if Traits.initialized then
		return
	end

	Traits:finalizeInit()
	Traits.initialized = true
end

local function getTraitIcon(loc)
	local pawn = Board:GetPawn(loc)

	if pawn == nil then
		return ""
	end

	for _, customTrait in ipairs(Traits.funcs) do
		if customTrait:func(pawn) then
			return customTrait.id
		end
	end

	for pilotSkill, pilotTrait in pairs(Traits.pilotSkills) do
		if pawn:IsAbility(pilotSkill) then
			return pilotTrait.id
		end
	end

	local pawnType = pawn:GetType()
	local pawnTrait = Traits.pawnTypes[pawnType]
	if pawnTrait then
		return pawnTrait.id
	end

	return ""
end

local function updateLoc(loc)
	if not isMemeditAvailable then
		Board:SetTerrainIcon(loc, getTraitIcon(loc))

		return
	end

	local traitIcon_new = getTraitIcon(loc)
	local traitIcon_old = Board:GetTerrainIcon(loc)

	local updateIcon = true
		and traitIcon_old ~= traitIcon_new
		and isManagedTrait(traitIcon_old)
		or isManagedTrait(traitIcon_new)

	if updateIcon then
		Board:SetTerrainIcon(loc, traitIcon_new)
	end
end

local function updateAll()
	if not Board then return end
	local pawns = Board:GetPawns(TEAM_ANY)
	for i = 1, pawns:size() do
		local pawnId = pawns:index(i)
		local pawn = Board:GetPawn(pawnId)
		local loc = pawn:GetSpace()
		updateLoc(loc)
	end
end

local function updatePawn(mission, pawn)
	local loc = pawn:GetSpace()
	updateLoc(loc)
end

local function pawnMoved(mission, pawn, loc_old)
	local loc = pawn:GetSpace()
	updateLoc(loc_old)
	updateLoc(loc)
end

local function onModsLoaded()
	modApiExt:addPawnTrackedHook(updatePawn)
	modApiExt:addPawnUntrackedHook(updatePawn)
	modApiExt:addPawnPositionChangedHook(pawnMoved)
end

local function overrideGetStatusTooltip()
	local oldGetStatusTooltip = GetStatusTooltip
	function GetStatusTooltip(id)
		for _, trait in ipairs(Traits) do
			if id == trait.id then
				return {
					trait.desc_title,
					trait.desc_text
				}
			end
		end

		return oldGetStatusTooltip(id)
	end
end

local function add(self, trait)
	Assert.ResourceDatIsOpen()
	Assert.Equals('table', type(trait), "Argument #1")
	Assert.Equals({'nil', 'string'}, type(trait.icon), "Field 'icon'")
	Assert.Equals({'nil', 'string'}, type(trait.icon_glow), "Field 'icon_glow'")
	Assert.Equals({'nil', 'userdata'}, type(trait.icon_offset), "Field 'icon_offset'")

	trait.icon_offset = trait.icon_offset or Point(0,0)

	if type(trait.desc) == 'table' then
		trait.desc_title = trait.desc.title or trait.desc[1]
		trait.desc_text = trait.desc.text or trait.desc[2]
	end

	Assert.TypePoint(trait.icon_offset, "Field 'icon_offset'")
	Assert.Equals('string', type(trait.desc_title), "Field 'desc_title'")
	Assert.Equals('string', type(trait.desc_text), "Field 'desc_text'")

	local func = trait.func
	local pilotSkill = trait.pilotSkill
	local pawnType = trait.pawnType
	local icon = trait.icon
	local icon_glow = trait.icon_glow
	local icon_offset = trait.icon_offset
	local desc_title = trait.desc_title
	local desc_text = trait.desc_text

	if func then
		Assert.Equals('function', type(func))
		self.funcs[#self.funcs+1] = trait

	elseif pilotSkill then
		Assert.Equals('string', type(pilotSkill))
		Assert.Equals('nil', type(self.pilotSkills[pilotSkill]), "Duplicate trait for pilotSkill")
		self.pilotSkills[pilotSkill] = trait

	elseif pawnType then
		Assert.Equals('string', type(pawnType))
		Assert.Equals('nil', type(self.pawnTypes[pawnType]), "Duplicate trait for pawnType")
		self.pawnTypes[pawnType] = trait
	else
		error("ERROR: Attempted to add an unlinked trait!")
	end

	self[#self+1] = trait

	local id = "trait"..#self
	local path = "combat/icons/icon_"..id..".png"
	local pathGlow = "combat/icons/icon_"..id.."_glow.png"

	trait.id = id

	if icon then
		icon = icon:match(".-.png$") or icon..".png"

		local is_vanilla_asset = icon:find("^img/")
		if is_vanilla_asset then
			if modApi:assetExists(icon) then
				modApi:copyAsset(icon, "img/"..path)
			end
		else
			if modApi:fileExists(icon) then
				modApi:appendAsset("img/"..path, icon)
			end
		end
	else
		modApi:copyAsset("img/empty.png", "img/"..path)
	end

	if icon_glow then
		icon_glow = icon_glow:match(".-.png$") or icon_glow..".png"

		local is_vanilla_asset = icon_glow:find("^img/")
		if is_vanilla_asset then
			if modApi:assetExists(icon_glow) then
				modApi:copyAsset(icon_glow, "img/"..pathGlow)
			end
		else
			if modApi:fileExists(icon_glow) then
				modApi:appendAsset("img/"..pathGlow, icon_glow)
			end
		end

		Location[pathGlow] = icon_offset
	else
		modApi:copyAsset("img/empty.png", "img/"..pathGlow)
	end
end

modApi.events.onModsInitialized:subscribe(onModsInitialized)


local isNewestVersion = false
	or Traits == nil
	or modApi:isVersion(VERSION, Traits.version) == false

if isNewestVersion then
	Traits = Traits or {}
	Traits.version = VERSION
	Traits.queued = Traits.queued or {}

	function Traits:add(trait)
		table.insert(self.queued, trait)
	end

	function Traits:finalizeInit()
		self.add = add
		self.update = function(self, loc) updateLoc(loc) end

		self.pawnTypes = {}
		self.pilotSkills = {}
		self.funcs = {}

		for _, trait in ipairs(self.queued) do
			self:add(trait)
		end

		self.queued = nil

		overrideGetStatusTooltip()

		modApi.events.onModsLoaded:subscribe(onModsLoaded)
		modApi.events.onMissionChanged:subscribe(function(mission, oldMission)
			if mission then
				updateAll()
			end
		end)
	end
end

return Traits
