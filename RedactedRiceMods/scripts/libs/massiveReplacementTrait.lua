-- massiveReplacementTrait
-- Created by adapting pyramidIcon.lua and trait.lua patterns
--
-- Overrides a target trait to allow custom traits to be displayed
-- Cycles through vanilla trait icon and custom trait icons

local VERSION = "0.5.2"

local mod_path = mod_loader.mods[modApi.currentMod]
local path = mod_path.scriptPath

local TARGET_TRAIT_CONFIG = {
	-- The trait ID used in GetStatusTooltip (e.g., "massive", "flying", etc.)
	id = "massive",
	-- The pawn method to check if trait is active (e.g., "IsMassive", "IsFlying")
	checkMethod = "IsMassive",
	-- Icon filename (without path, e.g., "icon_massive.png")
	iconFilename = "icon_massive.png",
	-- Localization keys for vanilla trait
	descTitle = "Status_massive_Title",
	descText = "Status_massive_Text",
}

local iconPlaceholderFolder = path .. "libs/"
local function makePlaceholder(new_name)
	local origPlaceholder = iconPlaceholderFolder .. "icon_placeholder.png"
    local newPlaceholder = iconPlaceholderFolder .. new_name
	
    -- read original file in binary mode
    local f_in = assert(io.open(origPlaceholder, "rb"))

    -- build destination path

    -- read all bytes
    local data = f_in:read("*a")
    f_in:close()

    -- write to new file
    local f_out = assert(io.open(newPlaceholder, "wb"))
    f_out:write(data)
    f_out:close()
end

-- Derived paths and surfaces based on config
local placeholderName = "icon_" .. TARGET_TRAIT_CONFIG.id .. "_placeholder.png"
local placeholderPath = iconPlaceholderFolder .. placeholderName
makePlaceholder(placeholderName)

local targetIcon = sdlext.getSurface({ path = placeholderPath })
local targetIconPath = "img/combat/icons/" .. TARGET_TRAIT_CONFIG.iconFilename
local targetIconNewPath = "img/combat/icons/icon_" .. TARGET_TRAIT_CONFIG.id .. "_vanilla.png"
local targetOrigIcon = sdlext.getSurface({ path = targetIconPath })


-- Time in seconds between icon changes when cycling traits
local TRAIT_CYCLE_INTERVAL = 1.25

-- Widget size constants
local SMALL_ICON_W, SMALL_ICON_H = 25, 21
local LARGE_ICON_W, LARGE_ICON_H = 50, 42

-- UI widget references
local missionSmallWidget
local missionSmallWidgetIcon
local missionLargeWidget
local missionLargeWidgetIcon

-- Module-level cycling state
local cycleTimer = 0
local cycleIndex = 0

-- Vanilla trait definition based on config
local vanillaTraitDef = {
	id = TARGET_TRAIT_CONFIG.id .. "_vanilla",
	desc_title = TARGET_TRAIT_CONFIG.descTitle,
	desc_text = TARGET_TRAIT_CONFIG.descText,
}

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

-- Get all active traits for a pawn - target trait and custom traits
local function getActiveTraits(pawn, massiveReplacementTraitObj)
	if not pawn then return {} end

	local activeTraits = {}

	-- Always include vanilla trait first
	table.insert(activeTraits, vanillaTraitDef)

	-- Check func traits
	for _, trait in ipairs(massiveReplacementTraitObj.funcs) do
		if trait.func and trait:func(pawn) then
			table.insert(activeTraits, trait)
		end
	end

	-- Check pilotSkill
	for pilotSkill, trait in pairs(massiveReplacementTraitObj.pilotSkills) do
		if pawn:IsAbility(pilotSkill) then
			table.insert(activeTraits, trait)
		end
	end

	-- Check pawnType
	local pawnType = pawn:GetType()
	local pawnTrait = massiveReplacementTraitObj.pawnTypes[pawnType]
	if pawnTrait then
		table.insert(activeTraits, pawnTrait)
	end

	return activeTraits
end

-- Get the current icon to display based on cycling timer
local function getCurrentIcon(pawn, massiveReplacementTraitObj)
	if not pawn then return nil end

	-- Get all active traits
	local activeTraits = getActiveTraits(pawn, massiveReplacementTraitObj)

	if #activeTraits == 0 then
		return nil  -- No icon to display
	elseif #activeTraits == 1 then
		-- Just the vanilla trait
		return activeTraits[1].id
	else
		-- Multiple traits - cycle through them
		local traitIndex = cycleIndex % #activeTraits + 1
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

-- Check if we should be showing the icon
local function shouldShowIcon(pawn)
	if not pawn then return false end
	-- Call the configured pawn method
	return pawn[TARGET_TRAIT_CONFIG.checkMethod](pawn)
end

-- Get the current icon surface for the pawn
local function getIconSurface(iconId, massiveReplacementTraitObj)
	if not iconId then return nil end

	-- Return the appropriate surface based on the icon ID
	local surface = massiveReplacementTraitObj.surfaces[iconId]
	if not surface then
		-- Log available surfaces for debugging
		local availableSurfaces = {}
		for k, v in pairs(massiveReplacementTraitObj.surfaces) do
			table.insert(availableSurfaces, k)
		end
		LOGF("MassiveReplacementTrait: Surface not found for iconId="..iconId)
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
local function recreateSmallIcon(surface)
	if missionSmallWidgetIcon then
		missionSmallWidgetIcon:detach()
	end

	missionSmallWidgetIcon = Ui()
		:widthpx(SMALL_ICON_W):heightpx(SMALL_ICON_H)
		:decorate({ DecoSurfaceOutlined(surface, 1, deco.colors.buttonborder, deco.colors.focus, 1) })
		:addTo(missionSmallWidget)
	missionSmallWidgetIcon.translucent = true

	-- Override decoration draw to show highlighted surface when tooltip is open
	local decoration = missionSmallWidgetIcon.decorations[1]
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
local function recreateLargeIcon(surface)
	if missionLargeWidgetIcon then
		missionLargeWidgetIcon:detach()
	end

	missionLargeWidgetIcon = Ui()
		:widthpx(LARGE_ICON_W):heightpx(LARGE_ICON_H)
		:decorate({ DecoSurfaceOutlined(surface, 1, deco.colors.buttonborder, deco.colors.buttonborder, 2) })
		:addTo(missionLargeWidget)
	missionLargeWidgetIcon.translucent = true
end

-- Create UI widgets overlay
local function createUIWidgets(uiRoot, massiveReplacementTraitObj)
	-- Use vanilla trait icon as initial surface that will be replaced later
	local initialSurface = massiveReplacementTraitObj.surfaces[TARGET_TRAIT_CONFIG.id .. "_vanilla"] or targetIcon

	-- Large widget for status tooltip display
	missionLargeWidget = Ui()
		:widthpx(LARGE_ICON_W):heightpx(LARGE_ICON_H)
		:addTo(uiRoot)
	missionLargeWidget.translucent = true
	missionLargeWidget.visible = false

	-- Small widget for ui display
	missionSmallWidget = Ui()
		:widthpx(SMALL_ICON_W):heightpx(SMALL_ICON_H)
		:addTo(uiRoot)
	missionSmallWidget.translucent = true
	missionSmallWidget.visible = false

	-- Create initial icons
	recreateSmallIcon(initialSurface)
	recreateLargeIcon(initialSurface)

	-- Small widget draw function
	local lastSmallIconId = nil

	missionSmallWidget.draw = function(self, screen)
		self.visible = false
		if targetIcon:wasDrawn() and GetCurrentMission() then
			local pawn = getUIEnabledPawn()

			if shouldShowIcon(pawn) then
				-- Recalculate icon every frame to support cycling
				local iconId = getCurrentIcon(pawn, massiveReplacementTraitObj)
				local surface = getIconSurface(iconId, massiveReplacementTraitObj)

				if surface then
					local tooltipVisible = sdlext:isStatusTooltipWindowVisible()
					
					-- Only update position when tooltip is closed
					-- When tooltip opens, widget stays at its current position
					if not tooltipVisible then
						updateWidgetPosition(self, targetIcon.x, targetIcon.y, SMALL_ICON_W, SMALL_ICON_H)
					end

					-- Recreate icon widget when icon changes
					if iconId ~= lastSmallIconId then
						recreateSmallIcon(surface)
						lastSmallIconId = iconId
					end

					-- Update child position and rect manually since we're bypassing normal layout
					updateChildPosition(missionSmallWidgetIcon, self, SMALL_ICON_W, SMALL_ICON_H)
					self.visible = true
				end
			end
		end
		-- Use clip to mask outside game window which also draws
		clip(Ui, self, screen)
	end


	-- Large widget draw function
	local lastLargeIconId = nil

	missionLargeWidget.draw = function(self, screen)
		self.visible = false
		if targetIcon:wasDrawn() and GetCurrentMission() then
			local pawn = getUIEnabledPawn()
			if shouldShowIcon(pawn) then
				-- Recalculate icon every frame to support cycling
				local iconId = getCurrentIcon(pawn, massiveReplacementTraitObj)
				local surface = getIconSurface(iconId, massiveReplacementTraitObj)

				-- Show large icon when tooltip window is visible OR when hovering over the small icon area
				local tooltipVisible = sdlext:isStatusTooltipWindowVisible()
				local escapeVisible = sdlext:isEscapeMenuWindowVisible()
				local hoveringSmallIcon = missionSmallWidget.visible and missionSmallWidget.containsMouse

				if surface and (tooltipVisible or hoveringSmallIcon) and not escapeVisible then
					-- Don't show large icon if targetIcon is still at the small icon position
					-- This happens on first frame when tooltip opens - vanilla icon hasn't moved yet
					-- Just compare against small widget's current position directly
					local atSmallIconPosition = (missionSmallWidget.x == targetIcon.x and
					                             missionSmallWidget.y == targetIcon.y)

					if not atSmallIconPosition then
						-- targetIcon has moved to its tooltip position, safe to show large icon

						-- Recreate icon widget when icon changes
						if iconId ~= lastLargeIconId then
							recreateLargeIcon(surface)
							lastLargeIconId = iconId
						end

						-- Use targetIcon's current position (it's at tooltip position now)
						updateWidgetPosition(self, targetIcon.x, targetIcon.y, LARGE_ICON_W, LARGE_ICON_H)
						updateChildPosition(missionLargeWidgetIcon, self, LARGE_ICON_W, LARGE_ICON_H)
						self.visible = true
					end
				end
			end
		end
		Ui.draw(self, screen)
	end
end

-- Override GetStatusTooltip to provide custom descriptions
local function overrideGetStatusTooltip(massiveReplacementTraitObj)
	local oldGetStatusTooltip = GetStatusTooltip

	function GetStatusTooltip(id)
		if id == TARGET_TRAIT_CONFIG.id then
			local pawn = getUIEnabledPawn()

			if pawn then
				-- Get all active traits (vanilla trait + custom)
				local activeTraits = getActiveTraits(pawn, massiveReplacementTraitObj)

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

		return oldGetStatusTooltip(id)
	end
end

-- Cycle traits periodically
local function maybeCycleTraits(mission)
	if not Board then
		return
	end

	local now = os.clock()
	cycleTimer = now

	-- Calculate current cycle index (same as trait.lua)
	local currentCycleIndex = math.ceil(cycleTimer / TRAIT_CYCLE_INTERVAL)

	-- Only update when weve crossed to a new cycle
	if currentCycleIndex ~= cycleIndex then
		cycleIndex = currentCycleIndex
	end
end

-- Internal function to actually add a trait
local function addTraitInternal(massiveReplacementTraitObj, trait)
	Assert.Equals('table', type(trait), "Argument #1")

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

	-- Generate unique ID based on total count
	local totalCount = #massiveReplacementTraitObj.allTraits + 1
	local id = TARGET_TRAIT_CONFIG.id .. "_custom_" .. totalCount
	trait.id = id

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
				if surface and surface:w() > 0 then
					LOG(string.format("  Loaded as vanilla: w=%d, h=%d", surface:w(), surface:h()))
				end
			end
		end
	else
		-- Relative mod asset path
		local fullPath = iconPath
		if not iconPath:find("^/") and not iconPath:find("^%a:") then
			fullPath = path .. iconPath
		end
		LOG(string.format("  Loading mod asset: %s", fullPath))

		if modApi:fileExists(fullPath) then
			surface = sdlext.getSurface({ path = fullPath })
			if surface then
				LOG(string.format("  Loaded surface: w=%d, h=%d", surface:w(), surface:h()))
			end
		end
	end

	if not surface or surface:w() == 0 or surface:h() == 0 then
		LOG("Warning: Could not load valid icon for trait replacement (" .. TARGET_TRAIT_CONFIG.id .. "): " .. iconPath)
		return
	end

	massiveReplacementTraitObj.surfaces[id] = surface

	-- Add to appropriate collection
	if func then
		Assert.Equals('function', type(func))
		table.insert(massiveReplacementTraitObj.funcs, trait)
	elseif pilotSkill then
		Assert.Equals('string', type(pilotSkill))
		Assert.Equals('nil', type(massiveReplacementTraitObj.pilotSkills[pilotSkill]), "Duplicate trait replacement for pilotSkill")
		massiveReplacementTraitObj.pilotSkills[pilotSkill] = trait
	elseif pawnType then
		Assert.Equals('string', type(pawnType))
		Assert.Equals('nil', type(massiveReplacementTraitObj.pawnTypes[pawnType]), "Duplicate trait replacement for pawnType")
		massiveReplacementTraitObj.pawnTypes[pawnType] = trait
	end

	-- Keep track of all traits
	table.insert(massiveReplacementTraitObj.allTraits, trait)

end

local function onModsInitialized()
	if VERSION < massiveReplacementTrait.version then
		return
	end

	if massiveReplacementTrait.initialized then
		return
	end

	massiveReplacementTrait:finalizeInit()
	massiveReplacementTrait.initialized = true
end

local isNewestVersion = false
	or massiveReplacementTrait == nil
	or massiveReplacementTrait.version == nil
	or VERSION > massiveReplacementTrait.version

if isNewestVersion then
	massiveReplacementTrait = massiveReplacementTrait or {}
	massiveReplacementTrait.version = VERSION
	massiveReplacementTrait.initialized = false
	massiveReplacementTrait.allTraits = {}
	massiveReplacementTrait.queuedTraits = {}
	massiveReplacementTrait.surfaces = {}
	massiveReplacementTrait.pawnTypes = {}
	massiveReplacementTrait.pilotSkills = {}
	massiveReplacementTrait.funcs = {}

	-- Public add function queues traits before initialization
	function massiveReplacementTrait:add(trait)
		table.insert(self.queuedTraits, trait)
	end

	massiveReplacementTrait.finalizeInit = function(self)
		-- Copy the vanilla target trait icon to a new location and override
		-- the target trait image with placeholder image
		modApi:copyAsset(targetIconPath, targetIconNewPath)
		modApi:appendAsset(targetIconPath, placeholderPath)

		-- Load vanilla target trait icon surface from the backup
		self.surfaces[TARGET_TRAIT_CONFIG.id .. "_vanilla"] = targetOrigIcon

		-- Process queued traits
		for _, trait in ipairs(self.queuedTraits) do
			addTraitInternal(self, trait)
		end
		self.queuedTraits = nil

		-- Update add method to use internal function directly
		self.add = function(massiveReplacementTraitSelf, trait)
			addTraitInternal(massiveReplacementTraitSelf, trait)
		end

		-- Add UI widgets
		sdlext.addUiRootCreatedHook(function(screen, uiRoot)
			createUIWidgets(uiRoot, self)
		end)

		-- Override tooltip
		overrideGetStatusTooltip(self)

		-- Register hooks via onModsLoaded event (same as trait.lua)
		modApi.events.onModsLoaded:subscribe(function()
			LOG("massiveReplacementTrait: onModsLoaded - Adding mission update hook")
			modApi:addMissionUpdateHook(maybeCycleTraits)
		end)

		-- Reset cycle on mission change
		modApi.events.onMissionChanged:subscribe(function(mission, oldMission)
			if mission then
				cycleTimer = os.clock()
				cycleIndex = 0
			end
		end)
	end

	modApi.events.onModsInitialized:subscribe(onModsInitialized)
end

return massiveReplacementTrait
