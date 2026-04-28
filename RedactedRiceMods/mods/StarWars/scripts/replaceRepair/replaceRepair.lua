
local VERSION = "3.0.0"
local PRIORITY_CUSTOM = 0
local PRIORITY_PILOT = 1
local PRIORITY_MECH = 2

local path = GetParentPath(...)
local selected = require(path.."lib/selected")
local getSelectedPawn = selected.getSelectedPawn

local function onModsInitialized()
	if VERSION < ReplaceRepair.version then
		return
	end

	if ReplaceRepair.initialized then
		return
	end

	ReplaceRepair:finalizeInit()
	ReplaceRepair.initialized = true
end

local function isPilotSkill(self, pawn)
	return pawn:IsAbility(self.pilotSkill)
end

local function isMechType(self, pawn)
	return pawn:GetType() == self.mechType
end

local function addSkill(self, repairSkill)
	-- backwards compatibility
	-- IsActive didn't use to have a 'self' parameter.
	if repairSkill.IsActive then
		repairSkill.isActive = function(self, pawn) return repairSkill.IsActive(pawn) end
	end

	repairSkill.name = repairSkill.name or repairSkill.Name
	repairSkill.description = repairSkill.description or repairSkill.Description
	repairSkill.weapon = repairSkill.weapon or repairSkill.Weapon
	repairSkill.icon = repairSkill.icon or repairSkill.Icon
	repairSkill.pilotSkill = repairSkill.pilotSkill or repairSkill.PilotSkill
	repairSkill.mechType = repairSkill.mechType or repairSkill.MechType

	local name = repairSkill.name
	local description = repairSkill.description
	local weapon = repairSkill.weapon
	local icon = repairSkill.icon
	local iconFrozen = repairSkill.iconFrozen
	local pilotSkill = repairSkill.pilotSkill
	local mechType = repairSkill.mechType
	local isActive = repairSkill.isActive

	Assert.Equals('string', type(weapon), "Field 'weapon'")
	Assert.Equals({'nil', 'string'}, type(icon), "Field 'icon'")
	Assert.Equals({'nil', 'string'}, type(iconFrozen), "Field 'iconFrozen'")
	Assert.Equals({'nil', 'function'}, type(isActive), "Field 'isActive'")

	-- backwards compatibility
	repairSkill.Name = name
	repairSkill.Description = description
	repairSkill.Weapon = weapon
	repairSkill.Icon = icon
	repairSkill.PilotSkill = pilotSkill
	repairSkill.MechType = mechType

	if isActive then
		repairSkill.priority = PRIORITY_CUSTOM
	else
		if pilotSkill then
			repairSkill.isActive = isPilotSkill
			repairSkill.priority = PRIORITY_PILOT
		elseif mechType then
			repairSkill.isActive = isMechType
			repairSkill.priority = PRIORITY_MECH
		else
			Assert.Error(string.format(
				"Repair skill condition not defined for"..
				"repair skill added by mod with id [%s]",
				repairSkill.modId
			))
		end
	end

	local mod = mod_loader.mods[repairSkill.modId]

	if icon then
		icon = icon:match(".-.png$") or icon..".png"
		iconFrozen = iconFrozen or icon:sub(1,-5).."_frozen.png"
		iconFrozen = iconFrozen:match(".-.png$") or iconFrozen..".png"

		if modApi:fileExists(mod.resourcePath..icon) then
			repairSkill.surface = sdlext.getSurface{ path = mod.resourcePath..icon }
		elseif modApi:assetExists(icon) then
			repairSkill.surface = sdlext.getSurface{ path = icon }
		end

		if modApi:fileExists(mod.resourcePath..iconFrozen) then
			repairSkill.surface_frozen = sdlext.getSurface{ path = mod.resourcePath..iconFrozen }
		elseif modApi:assetExists(iconFrozen) then
			repairSkill.surface_frozen = sdlext.getSurface{ path = iconFrozen }
		end
	end

	table.insert(self.repairSkills, repairSkill)
end

local function getCurrentSkill(self)
	if not Board then
		return nil
	end

	local highlighted = Board:GetHighlighted() or Point(-1, -1)
	local pawn = getSelectedPawn() or Board:GetPawn(highlighted)

	if pawn == nil then
		return
	end

	for _, repairSkill in ipairs(self.repairSkills) do
		if repairSkill:isActive(pawn) then
			return repairSkill
		end
	end
end

modApi:addModsInitializedHook(onModsInitialized)

if ReplaceRepair == nil or not modApi:isVersion(VERSION, ReplaceRepair.version) then
	ReplaceRepair = ReplaceRepair or {}
	ReplaceRepair.version = VERSION
	ReplaceRepair.queued = ReplaceRepair.queued or {}

	function ReplaceRepair:getVersion()
		return self.version
	end

	function ReplaceRepair:addSkill(repairSkill)
		Assert.ModInitializingOrLoading()
		Assert.Equals('table', type(repairSkill), "Argument #1")

		repairSkill.modId = modApi.currentMod
		repairSkill.Priority = PRIORITY_CUSTOM -- comp
		table.insert(self.queued, repairSkill)
	end

	function ReplaceRepair:finalizeInit()
		self.addSkill = addSkill
		self.getCurrentSkill = getCurrentSkill

		require(path.."defaults")
		require(path.."ui")
		require(path.."alter")

		self.repairSkills = {}

		for _, repairSkill in ipairs(self.queued) do
			self:addSkill(repairSkill)
		end

		self.queued = nil
		self.addSkill = nil

		table.sort(self.repairSkills, function(a,b)
			-- sort table, such that: custom skill > pilot skills > mech skills
			return a.priority > b.priority
		end)
	end

	require(path.."compatibility")
end

return ReplaceRepair
