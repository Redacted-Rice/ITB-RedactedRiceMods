
local VERSION = "2.3.0"
---------------------------------------------------------------------
-- Trait v2.3.0 - code library
--
-- by Lemonymous
-- Enhanced by Das Keifer to support multiple trait cycling
---------------------------------------------------------------------
-- Provides functionality to add traits to pawns.
-- Traits are purely visual - displaying an icon and a description.
-- Multiple traits can be active on a unit - they will cycle through icons.
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
--    Order of cycling/descriptions when multiple traits apply to a pawn:
-- func > pilotSkill > pawnType
-- first created > last created
--

-- Time in seconds between icon changes
local TRAIT_CYCLE_INTERVAL = 1.25

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

-- Global timer (seconds) for synchronized cycling
local traitCycleTimer = 0
local traitCycleIndex = 0

local function getAllActiveTraits(pawn)
	local activeTraits = {}

	-- Check func traits (highest priority)
	for _, customTrait in ipairs(Traits.funcs) do
		if customTrait:func(pawn) then
			table.insert(activeTraits, customTrait)
		end
	end

	-- Check pilotSkill traits
	for pilotSkill, pilotTrait in pairs(Traits.pilotSkills) do
		if pawn:IsAbility(pilotSkill) then
			table.insert(activeTraits, pilotTrait)
		end
	end

	-- Check pawnType traits
	local pawnType = pawn:GetType()
	local pawnTrait = Traits.pawnTypes[pawnType]
	if pawnTrait then
		table.insert(activeTraits, pawnTrait)
	end

	return activeTraits
end

-- Get the current icon to display based on cycling timer
local function getCurrentIconFromTraits(traits)
	if #traits == 0 then
		return ""
	end

	if #traits == 1 then
		return traits[1].id
	end

	-- Calculate which icon to show based on the timer
	local traitIndex = traitCycleIndex % #traits + 1
	return traits[traitIndex].id
end

local function getTraitIcon(loc)
	local pawn = Board:GetPawn(loc)	
	-- We use this to update the old loc as well so make sure to 
	-- handle nil pawn case
	if pawn == nil then
		return ""
	end
	local activeTraits = getAllActiveTraits(pawn)
	local icon = getCurrentIconFromTraits(activeTraits)
	return icon
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

local function maybeCycleTraits()
	if not Board then return end
	traitCycleTimer = os.clock()

	-- Calculate current cycle index
	local currentCycleIndex = math.ceil(traitCycleTimer / TRAIT_CYCLE_INTERVAL)

	-- Only update icons when we've crossed to a new cycle
	if currentCycleIndex ~= traitCycleIndex then
		traitCycleIndex = currentCycleIndex
		updateAll()
	end
end

local function onModsLoaded()
	modApiExt:addPawnTrackedHook(updatePawn)
	modApiExt:addPawnUntrackedHook(updatePawn)
	modApiExt:addPawnPositionChangedHook(pawnMoved)
	modApi:addMissionUpdateHook(maybeCycleTraits)
end

local function tryGetTraitsFromSelectedPawn(targetId)
	if not Board then return nil end
	local selectedPawn = Board:GetSelectedPawn()
	if selectedPawn then
		local activeTraits = getAllActiveTraits(selectedPawn)

		-- Check if the requested trait ID is in this pawn's active traits
		for _, trait in ipairs(activeTraits) do
			if trait.id == targetId then
				return activeTraits
			end
		end

		LOG("Warning: Trait tooltip requested for trait "..targetId.." but selected pawn does not have this trait active")
	else
		LOG("Warning: Trait tooltip requested for trait "..targetId.." but no pawn is selected")
	end
	return nil
end

local function combineTraitsDescriptions(traits)
	local combinedText = ""

	for i, trait in ipairs(traits) do
		if i > 1 then
			combinedText = combinedText .. "\n\n"
		end
		combinedText = combinedText .. trait.desc_title .. "\n" .. trait.desc_text
	end

	return {
		"Modded Traits",
		combinedText
	}
end

local function overrideGetStatusTooltip()
	local oldGetStatusTooltip = GetStatusTooltip
	function GetStatusTooltip(id)
		-- Check if this is a managed trait
		local managedTrait = nil
		for _, trait in ipairs(Traits) do
			if id == trait.id then
				managedTrait = trait
				break
			end
		end

		if not managedTrait then
			return oldGetStatusTooltip(id)
		end

		local activeTraits = tryGetTraitsFromSelectedPawn(id)
		if activeTraits and #activeTraits > 1 then
			return combineTraitsDescriptions(activeTraits)
		end

		return {
			managedTrait.desc_title,
			managedTrait.desc_text
		}
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
		local icon = icon:match(".-.png$") or icon..".png"
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
				-- Reset timer and state on mission start
				traitCycleTimer = os.clock()
				traitCycleIndex = 0
				updateAll()
			end
		end)
	end
end

return Traits
