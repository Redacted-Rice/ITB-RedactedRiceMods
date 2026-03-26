--[[
TraitReplace - Allows adding custom UI traits that cycle with vanilla traits

Author: Das Keifer of Redacted Rice
Version: 0.8.0
Discord Server: https://discord.gg/CNjTVrpN4v

Overrides target traits to allow custom traits to be displayed
Cycles through vanilla trait icon and custom trait icons
Supports multiple traits simultaneously (e.g., massive and flying)

Special thanks to Generic and Lemonymous who paved the way with drawing
icons on top of flying and Lemonymous for the trait library which was
the inspiration/starting point for this
]]

local VERSION = "0.8.0"

local mod_path = mod_loader.mods[modApi.currentMod]
local path = mod_path.scriptPath


local function parseVersion(versionStr)
	if not versionStr then return 0, 0, 0 end
	local major, minor, patch = versionStr:match("(%d+)%.(%d+)%.(%d+)")
	return tonumber(major) or 0, tonumber(minor) or 0, tonumber(patch) or 0
end

local function isNewerVersion(v1, v2)
	local v1maj, v1min, v1patch = parseVersion(v1)
	local v2maj, v2min, v2patch = parseVersion(v2)

	if v1maj ~= v2maj then return v1maj > v2maj end
	if v1min ~= v2min then return v1min > v2min end
	return v1patch > v2patch
end

-- Create the global singleton
if not TraitReplace then
	TraitReplace = {
		version = nil,
		initialized = false,
		queuedRegistrations = {},
		queuedTraits = {},
		traitRegistry = {},
		globalCycleTimer = 0,
		globalCycleIndex = 0,
		nextPlaceholderIndex = 0,
		MAX_PLACEHOLDERS = 10,
	}
end

-- Local alias for the global version
local traitRegistry = TraitReplace.traitRegistry
local iconPlaceholderFolder = path .. "libs/traitReplacePlaceholders/"

-- Get next available placeholder filename
local function getNextPlaceholder()
	if TraitReplace.nextPlaceholderIndex >= TraitReplace.MAX_PLACEHOLDERS then
		LOG("ERROR: Maximum replacement traits exceeded (10)")
		LOG("  Consider increasing MAX_PLACEHOLDERS or removing unused traits")
		return nil
	end
	
	local index = TraitReplace.nextPlaceholderIndex
	TraitReplace.nextPlaceholderIndex = index + 1
	
	return string.format("icon_trait_replace_placeholder_%d.png", index)
end

-- Register a new target trait for replacement
-- config = {
--   id = "massive",
--   checkMethod = "IsMassive",
--   iconFilename = "icon_massive.png",
--   descTitle = "Status_massive_Title",
--   descText = "Status_massive_Text",
-- }
local function registerTargetTrait(config)
	if traitRegistry[config.id] then
		LOG("Target trait '" .. config.id .. "' already registered, skipping.")
		return false
	end

	LOG("Registering target trait: " .. config.id)

	-- Get next sequential placeholder
	local placeholderName = getNextPlaceholder()

	-- Derived paths and surfaces
	local placeholderPath = iconPlaceholderFolder .. placeholderName
	local targetIconPath = "img/combat/icons/" .. config.iconFilename

	-- Load surfaces
	local targetOrigIcon = sdlext.surface(targetIconPath)
	modApi:appendAsset(targetIconPath, placeholderPath)
	local targetIcon = sdlext.surface(placeholderPath)

	-- Create trait data structure
	traitRegistry[config.id] = {
		config = config,
		targetIcon = targetIcon,
		targetOrigIcon = targetOrigIcon,
		targetIconPath = targetIconPath,
		placeholderPath = placeholderPath,

		-- Trait storage
		surfaces = {},
		allTraits = {},
		queuedTraits = {},
		funcs = {},
		pilotSkills = {},
		pawnTypes = {},

		-- UI widgets that are created later
		smallWidget = nil,
		smallWidgetIcon = nil,
		largeWidget = nil,
		largeWidgetIcon = nil,

		-- Vanilla trait definition
		vanillaTraitDef = {
			id = config.id .. "_vanilla",
			desc_title = config.descTitle,
			desc_text = config.descText,
		},
	}

	return true
end

-- Time in seconds between icon changes when cycling traits
local TRAIT_CYCLE_INTERVAL = 1.25

-- Widget size constants
local SMALL_ICON_W, SMALL_ICON_H = 25, 21
local LARGE_ICON_W, LARGE_ICON_H = 50, 42

-- Inline clip functionality
local clipRect = {
	l = sdl.rect(0,0,0,0),
	t = sdl.rect(0,0,0,0),
	r = sdl.rect(0,0,0,0),
	b = sdl.rect(0,0,0,0)
}

local function clip(base, widget, screen)
	local menu = sdlext.CurrentWindowRect
	clipRect.l.w = math.max(0, menu.x)
	clipRect.l.h = screen:h()
	clipRect.t.w = screen:w()
	clipRect.t.h = math.max(0, menu.y)
	clipRect.r.x = math.min(menu.x + menu.w, screen:w())
	clipRect.r.w = screen:w() - clipRect.r.x
	clipRect.r.h = screen:h()
	clipRect.b.y = math.min(menu.y + menu.h, screen:h())
	clipRect.b.w = screen:w()
	clipRect.b.h = screen:h() - clipRect.r.y

	local tmp = modApi.msDeltaTime
	local updated

	for _, r in pairs(clipRect) do
		screen:clip(r)
		if updated then
			modApi.msDeltaTime = 0
		end
		updated = true
		base.draw(widget, screen)
		screen:unclip()
	end

	modApi.msDeltaTime = tmp
end

-- Get all active traits for a pawn for a specific target trait
local function getActiveTraits(pawn, replaceTraitId)
	if not pawn then return {} end

	local traitData = traitRegistry[replaceTraitId]
	if not traitData then return {} end

	local activeTraits = {}

	-- Always include vanilla trait first
	table.insert(activeTraits, traitData.vanillaTraitDef)

	-- Check func traits
	for _, trait in ipairs(traitData.funcs) do
		if trait.func and trait:func(pawn) then
			table.insert(activeTraits, trait)
		end
	end

	-- Check pilotSkill
	for pilotSkill, trait in pairs(traitData.pilotSkills) do
		if pawn:IsAbility(pilotSkill) then
			table.insert(activeTraits, trait)
		end
	end

	-- Check pawnType
	local pawnType = pawn:GetType()
	local pawnTrait = traitData.pawnTypes[pawnType]
	if pawnTrait then
		table.insert(activeTraits, pawnTrait)
	end

	return activeTraits
end

-- Get the current icon to display based on global cycling timer
local function getCurrentIcon(pawn, replaceTraitId)
	if not pawn then return nil end

	local traitData = traitRegistry[replaceTraitId]
	if not traitData then return nil end

	-- Get all active traits
	local activeTraits = getActiveTraits(pawn, replaceTraitId)

	if #activeTraits == 0 then
		return nil  -- No icon to display
	elseif #activeTraits == 1 then
		-- Just the vanilla trait
		return activeTraits[1].id
	else
		-- Multiple traits - cycle through them using global timer
		local traitIndex = TraitReplace.globalCycleIndex % #activeTraits + 1
		return activeTraits[traitIndex].id
	end
end

-- Get pawn highlighted in UI
local function getUIEnabledPawn()
	local pawn = Board:GetSelectedPawn()

	if not pawn then
		local highlighted = Board:GetHighlighted()

		if highlighted and Board then
			pawn = Board:GetPawn(highlighted)
		end
	end

	return pawn
end

-- Check if we should be showing the icon for a specific trait
local function shouldShowIcon(pawn, replaceTraitId)
	if not pawn then return false end

	local traitData = traitRegistry[replaceTraitId]
	if not traitData then return false end

	-- Call the configured pawn method
	return pawn[traitData.config.checkMethod](pawn)
end

-- Get the current icon surface for the pawn
local function getIconSurface(iconId, replaceTraitId)
	if not iconId or not replaceTraitId then 
		LOG("getIconSurface: nil params - iconId="..iconId..", replaceTraitId="..replaceTraitId)
		return nil 
	end

	local traitData = traitRegistry[replaceTraitId]
	if not traitData then 
		LOG("getIconSurface: traitData not found for replaceTraitId="..replaceTraitId)
		return nil 
	end

	-- Return the appropriate surface based on the icon ID
	local surface = traitData.surfaces[iconId]
	if not surface then
		local availableKeys = {}
		for k, v in pairs(traitData.surfaces) do
			table.insert(availableKeys, k)
		end
		LOG("getIconSurface: Surface not found for replaceTraitId="..replaceTraitId..", iconId="..iconId)
		LOG("  Available surfaces: "..table.concat(availableKeys, ", "))
	end
	return surface
end

-- Helper to update widget position and dimensions
local function updateWidgetPosition(widget, x, y, w, h)
	widget.x = x
	widget.y = y
	widget.screenx = x
	widget.screeny = y
	widget.rect.x = x
	widget.rect.y = y
	widget.rect.w = w
	widget.rect.h = h
end

-- Helper to update child icon widget to match parent position
local function updateChildPosition(child, parent, w, h)
	if child and child.root then
		child.x = 0
		child.y = 0
		child.w = w
		child.h = h
		child.screenx = parent.screenx
		child.screeny = parent.screeny
		child.rect.x = parent.screenx
		child.rect.y = parent.screeny
		child.rect.w = w
		child.rect.h = h
		child.visible = true
	end
end

-- Helper to recreate small icon widget with new surface
-- Creating a new surface is the only way I found that works
-- to change the icons
local function recreateSmallIcon(surface, replaceTraitId)
	local traitData = traitRegistry[replaceTraitId]
	if not traitData then return end

	if traitData.smallWidgetIcon then
		traitData.smallWidgetIcon:detach()
	end

	traitData.smallWidgetIcon = Ui()
		:widthpx(SMALL_ICON_W):heightpx(SMALL_ICON_H)
		:decorate({ DecoSurfaceOutlined(surface, 1, deco.colors.buttonborder, deco.colors.focus, 1) })
		:addTo(traitData.smallWidget)
	traitData.smallWidgetIcon.translucent = true

	-- Override decoration draw to show highlighted surface when tooltip is open
	local decoration = traitData.smallWidgetIcon.decorations[1]
	if decoration then
		decoration.draw = function(self, screen, widget)
			-- Check if tooltip is visible
			local tooltipVisible = sdlext:isStatusTooltipWindowVisible()

			-- Use highlighted surface when tooltip is visible, normal otherwise
			local surfaceToUse = tooltipVisible and self.surfacehl or self.surfacenormal
			if surfaceToUse then
				screen:blit(surfaceToUse, nil, widget.rect.x, widget.rect.y)
			end
		end
	end
end

-- Helper to recreate large icon widget with new surface
-- Creating a new surface is the only way I found that works
-- to change the icons
local function recreateLargeIcon(surface, replaceTraitId)
	local traitData = traitRegistry[replaceTraitId]
	if not traitData then return end

	if traitData.largeWidgetIcon then
		traitData.largeWidgetIcon:detach()
	end

	traitData.largeWidgetIcon = Ui()
		:widthpx(LARGE_ICON_W):heightpx(LARGE_ICON_H)
		:decorate({ DecoSurfaceOutlined(surface, 1, deco.colors.buttonborder, deco.colors.buttonborder, 2) })
		:addTo(traitData.largeWidget)
	traitData.largeWidgetIcon.translucent = true
end

-- Create UI widgets overlay for a specific trait
local function createUIWidgetsForTrait(uiRoot, replaceTraitId)
	local traitData = traitRegistry[replaceTraitId]
	if not traitData then return end

	local initialSurface = traitData.surfaces[replaceTraitId .. "_vanilla"] or traitData.targetIcon

	-- Large widget for status tooltip display
	traitData.largeWidget = Ui()
		:widthpx(LARGE_ICON_W):heightpx(LARGE_ICON_H)
		:addTo(uiRoot)
	traitData.largeWidget.translucent = true
	traitData.largeWidget.visible = false

	-- Small widget for ui display
	traitData.smallWidget = Ui()
		:widthpx(SMALL_ICON_W):heightpx(SMALL_ICON_H)
		:addTo(uiRoot)
	traitData.smallWidget.translucent = true
	traitData.smallWidget.visible = false

	-- Create initial icons
	recreateSmallIcon(initialSurface, replaceTraitId)
	recreateLargeIcon(initialSurface, replaceTraitId)

	-- Small widget draw function
	local lastSmallIconId = nil

	traitData.smallWidget.draw = function(self, screen)
		self.visible = false
		if traitData.targetIcon:wasDrawn() and GetCurrentMission() then
			local pawn = getUIEnabledPawn()

			if shouldShowIcon(pawn, replaceTraitId) then
				-- Recalculate icon every frame to support cycling
				local iconId = getCurrentIcon(pawn, replaceTraitId)
				local surface = getIconSurface(iconId, replaceTraitId)

				if surface then
					local tooltipVisible = sdlext:isStatusTooltipWindowVisible()

					-- Only update position when tooltip is closed
					-- When tooltip opens, widget stays at its current position
					if not tooltipVisible then
						updateWidgetPosition(self, traitData.targetIcon.x, traitData.targetIcon.y, SMALL_ICON_W, SMALL_ICON_H)
					end

					-- Recreate icon widget when icon changes
					if iconId ~= lastSmallIconId then
						recreateSmallIcon(surface, replaceTraitId)
						lastSmallIconId = iconId
					end

					-- Update child position and rect manually since we're bypassing normal layout
					updateChildPosition(traitData.smallWidgetIcon, self, SMALL_ICON_W, SMALL_ICON_H)
					self.visible = true
				end
			end
		end
		-- Use clip to mask outside game window which also draws
		clip(Ui, self, screen)
	end

	-- Large widget draw function
	local lastLargeIconId = nil

	traitData.largeWidget.draw = function(self, screen)
		self.visible = false
		if traitData.targetIcon:wasDrawn() and GetCurrentMission() then
			local pawn = getUIEnabledPawn()
			if shouldShowIcon(pawn, replaceTraitId) then
				-- Recalculate icon every frame to support cycling
				local iconId = getCurrentIcon(pawn, replaceTraitId)
				local surface = getIconSurface(iconId, replaceTraitId)

				-- Show large icon when tooltip window is visible OR when hovering over the small icon area
				local tooltipVisible = sdlext:isStatusTooltipWindowVisible()
				local escapeVisible = sdlext:isEscapeMenuWindowVisible()
				local hoveringSmallIcon = traitData.smallWidget.visible and traitData.smallWidget.containsMouse

				if surface and (tooltipVisible or hoveringSmallIcon) and not escapeVisible then
					-- Don't show large icon if targetIcon is still at the small icon position
					-- This happens on first frame when tooltip opens - vanilla icon hasn't moved yet
					-- Just compare against small widget's current position directly
					local atSmallIconPosition = (traitData.smallWidget.x == traitData.targetIcon.x and
					                             traitData.smallWidget.y == traitData.targetIcon.y)

					if not atSmallIconPosition then
						-- targetIcon has moved to its tooltip position, safe to show large icon
						-- Recreate icon widget when icon changes
						if iconId ~= lastLargeIconId then
							recreateLargeIcon(surface, replaceTraitId)
							lastLargeIconId = iconId
						end

						-- Use targetIcon's current position
						updateWidgetPosition(self, traitData.targetIcon.x, traitData.targetIcon.y, LARGE_ICON_W, LARGE_ICON_H)
						updateChildPosition(traitData.largeWidgetIcon, self, LARGE_ICON_W, LARGE_ICON_H)
						self.visible = true
					end
				end
			end
		end
		Ui.draw(self, screen)
	end
end

-- Create UI widgets overlay for all registered traits
local function createUIWidgets(uiRoot)
	-- Create widgets for each registered trait
	for replaceTraitId, _ in pairs(traitRegistry) do
		createUIWidgetsForTrait(uiRoot, replaceTraitId)
	end
end

-- Override GetStatusTooltip to provide custom descriptions for all registered traits
local function overrideGetStatusTooltip()
	local oldGetStatusTooltip = GetStatusTooltip

	function GetStatusTooltip(replaceTraitId)
		-- Check if this ID is a registered trait
		local traitData = traitRegistry[replaceTraitId]
		if traitData then
			local pawn = getUIEnabledPawn()

			if pawn then
				-- Get all active traits (vanilla trait + custom)
				local activeTraits = getActiveTraits(pawn, replaceTraitId)

				if #activeTraits == 0 then
					-- No traits, no tooltip
					return {"", ""}
				elseif #activeTraits == 1 then
					-- Just the single vanilla trait
					return {
						GetText(activeTraits[1].desc_title),
						GetText(activeTraits[1].desc_text)
					}
				else
					-- Multiple traits, combine descriptions
					local combinedText = ""
					for i, trait in ipairs(activeTraits) do
						if i > 1 then
							combinedText = combinedText .. "\n\n"
						end
						combinedText = combinedText .. GetText(trait.desc_title) .. "\n" .. GetText(trait.desc_text)
					end
					return {
						"Extra Pawn Traits",
						combinedText
					}
				end
			end
		end

		return oldGetStatusTooltip(replaceTraitId)
	end
end

-- Cycle traits periodically using global timer so they are all
-- in sync when they cycle
local function maybeCycleTraits(mission)
	if not Board then
		return
	end

	local now = os.clock()
	TraitReplace.globalCycleTimer = now

	-- Calculate current cycle index. This will be the same for all traits but
	-- each trait may cycle differently based on the number of replacement traits
	-- it has
	local currentCycleIndex = math.ceil(TraitReplace.globalCycleTimer / TRAIT_CYCLE_INTERVAL)

	-- Only update when weve crossed to a new cycle
	if currentCycleIndex ~= TraitReplace.globalCycleIndex then
		TraitReplace.globalCycleIndex = currentCycleIndex
	end
end

-- Internal function to actually add a trait
local function addTraitInternal(trait)
	Assert.Equals('table', type(trait), "Argument #1")

	-- targetTrait specifies which trait to add to (e.g., "massive", "flying")
	-- Defaults to "massive"
	local targetTrait = trait.targetTrait or "massive"
	Assert.Equals('string', type(targetTrait), "Field 'targetTrait' (defaulting to 'massive' if not specified)")

	local traitData = traitRegistry[targetTrait]
	if not traitData then
		error("ERROR: Target trait '" .. targetTrait .. "' is not registered! Call traitReplace:registerTrait() first.")
	end

	if type(trait.desc) == 'table' then
		trait.desc_title = trait.desc.title or trait.desc[1]
		trait.desc_text = trait.desc.text or trait.desc[2]
	end

	Assert.Equals('string', type(trait.icon), "Field 'icon'")
	Assert.Equals('string', type(trait.desc_title), "Field 'desc_title'")
	Assert.Equals('string', type(trait.desc_text), "Field 'desc_text'")

	local func = trait.func
	local pilotSkill = trait.pilotSkill
	local pawnType = trait.pawnType

	-- Must have one of func, pilotSkill, or pawnType
	if not func and not pilotSkill and not pawnType then
		error("ERROR: Attempted to add an unlinked trait replacement! Trait must have func, pilotSkill, or pawnType.")
	end

	-- Generate unique ID based on total count for this specific trait
	local totalCount = #traitData.allTraits + 1
	local id = targetTrait .. "_custom_" .. totalCount
	trait.id = id

	LOG("Adding custom trait '" .. id .. "' to target trait '" .. targetTrait .. "'")

	-- Load the icon surface
	local iconPath = trait.icon:match(".-.png$") or trait.icon..".png"
	local surface

	if iconPath:find("^img/") then
		-- Asset registered by some mod - search for actual file
		for modId, mod in pairs(mod_loader.mods) do
			if mod.resourcePath then
				local possiblePath = mod.resourcePath .. iconPath
				if modApi:fileExists(possiblePath) then
					surface = sdlext.getSurface({ path = possiblePath })
					if surface and surface:w() > 0 and surface:h() > 0 then
						break
					end
				end
			end
		end

		-- Fallback: try as vanilla asset
		if not surface or surface:w() == 0 then
			if modApi:assetExists(iconPath) then
				surface = sdlext.getSurface({ path = iconPath })
			end
		end
	else
		-- Relative mod asset path
		local fullPath = iconPath
		if not iconPath:find("^/") and not iconPath:find("^%a:") then
			fullPath = path .. iconPath
		end

		if modApi:fileExists(fullPath) then
			surface = sdlext.getSurface({ path = fullPath })
		end
	end

	if not surface or surface:w() == 0 or surface:h() == 0 then
		LOG("Warning: Could not load valid icon for trait replacement (" .. targetTrait .. "): " .. iconPath)
		return
	end

	traitData.surfaces[id] = surface

	-- Add to appropriate collection for this specific trait
	if func then
		Assert.Equals('function', type(func))
		table.insert(traitData.funcs, trait)
	elseif pilotSkill then
		Assert.Equals('string', type(pilotSkill))
		Assert.Equals('nil', type(traitData.pilotSkills[pilotSkill]), "Duplicate trait replacement for pilotSkill in " .. targetTrait)
		traitData.pilotSkills[pilotSkill] = trait
	elseif pawnType then
		Assert.Equals('string', type(pawnType))
		Assert.Equals('nil', type(traitData.pawnTypes[pawnType]), "Duplicate trait replacement for pawnType in " .. targetTrait)
		traitData.pawnTypes[pawnType] = trait
	end

	-- Keep track of all traits for this specific trait
	table.insert(traitData.allTraits, trait)

end

-- Shared initialization callback
-- This is subscribed to onModsInitialized by the first version that loads.
-- It calls TraitReplace:finalizeInit() which will use whatever version is stored
-- on the global object as it gets overwritten by newer versions below.
local function onModsInitialized()
	if TraitReplace.initialized then
		return
	end

	TraitReplace:finalizeInit()
	TraitReplace.initialized = true
end

-- Only update methods if this is the newest version
-- State is already shared via global object initialized at top
local isHighestVersion = isNewerVersion(VERSION, TraitReplace.version)

-- If this is a higher version than the previous, we overwrite the functions
-- with this versions
if isHighestVersion then
	LOG("TraitReplace: Loading version " .. VERSION .. " (previous: " .. tostring(TraitReplace.version or "none") .. ")")
	TraitReplace.version = VERSION

	-- Public function to register a target trait to replace
	function TraitReplace:registerTrait(config)
		-- Reinitialize queue if it was cleared after finalization
		self.queuedRegistrations = self.queuedRegistrations or {}
		table.insert(self.queuedRegistrations, config)
	end

	-- Public add function queues traits before initialization
	function TraitReplace:add(trait)
		-- Reinitialize queue if it was cleared after finalization
		self.queuedTraits = self.queuedTraits or {}
		table.insert(self.queuedTraits, trait)
	end

	TraitReplace.finalizeInit = function(self)
		LOG(string.format("*** TraitReplace.finalizeInit executing (version %s) ***", VERSION))

		-- Register "massive" trait by default for backwards compatibility
		-- This ensures existing code that calls TraitReplace:add() without registering works
		if not traitRegistry["massive"] then
			table.insert(self.queuedRegistrations, {
				id = "massive",
				checkMethod = "IsMassive",
				iconFilename = "icon_massive.png",
				descTitle = "Status_massive_Title",
				descText = "Status_massive_Text",
			})
		end

		-- Register all queued target traits
		for _, config in ipairs(self.queuedRegistrations or {}) do
			if registerTargetTrait(config) then
				local traitData = traitRegistry[config.id]

				-- Load vanilla target trait icon surface from the backup
				traitData.surfaces[config.id .. "_vanilla"] = traitData.targetOrigIcon
				
				-- Log registration summary
				LOG("Registered target trait '" .. config.id .. "' with " .. #traitData.allTraits .. " custom traits")
			end
		end
		self.queuedRegistrations = {}

		-- Process queued traits (safe check for nil)
		for _, trait in ipairs(self.queuedTraits or {}) do
			addTraitInternal(trait)
		end
		self.queuedTraits = {}

		-- Update add method to use internal function directly
		-- No longer queue after initialization
		self.add = function(trait)
			addTraitInternal(trait)
		end

		-- Update registerTrait to call directly after init
		self.registerTrait = function(config)
			if registerTargetTrait(config) then
				local traitData = traitRegistry[config.id]
				traitData.surfaces[config.id .. "_vanilla"] = traitData.targetOrigIcon
			end
		end

		-- Add UI widgets for all registered traits after surfaces are populated
		sdlext.addUiRootCreatedHook(function(screen, uiRoot)
			createUIWidgets(uiRoot)
		end)

		-- Override tooltip for all registered traits
		overrideGetStatusTooltip()

		-- Register hooks via onModsLoaded event
		modApi.events.onModsLoaded:subscribe(function()
			modApi:addMissionUpdateHook(maybeCycleTraits)
		end)

		-- Reset global cycle timer on mission change
		modApi.events.onMissionChanged:subscribe(function(mission, oldMission)
			if mission then
				TraitReplace.globalCycleTimer = os.clock()
				TraitReplace.globalCycleIndex = 0
			end
		end)
	end

	-- Only subscribe to initialization the first time. Newer versions can still
	-- use this same registration
	if not TraitReplace.onModsInitializedSubscribed then
		modApi.events.onModsInitialized:subscribe(onModsInitialized)
		TraitReplace.onModsInitializedSubscribed = true
	end
end

return TraitReplace
