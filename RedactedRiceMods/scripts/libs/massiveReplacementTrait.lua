-- massiveReplacementTrait
-- Created by adapting pyramidIcon.lua and trait.lua patterns
--
-- Overrides the massive trait to allow custom traits to be displayed
-- Cycles through vanilla massive icon and custom trait icons

local VERSION = "0.5.0"

local mod_path = mod_loader.mods[modApi.currentMod]
local path = mod_path.scriptPath

-- We have to use the full path to the image for the surface that we are using
-- so we make a blank placeholder for it
local massivePlaceholderPath = path .."libs/icon_massive_placeholder.png"
local massiveIcon = sdlext.getSurface({ path = massivePlaceholderPath })
local massiveIconPath = "img/combat/icons/icon_massive.png"
local massiveIconNewPath = "img/combat/icons/icon_massive_vanilla.png"
local massiveOrigIcon = sdlext.getSurface({ path = massiveIconPath })

-- Time in seconds between icon changes when cycling traits
local TRAIT_CYCLE_INTERVAL = 1.25

-- UI widget references
local missionSmallWidget
local missionSmallWidgetIcon
local missionLargeWidget
local missionLargeWidgetIcon

-- Module-level cycling state
local cycleTimer = 0
local cycleIndex = 0

local vanillaMassiveTrait = {
	id = "massive_vanilla",
	desc_title = "Status_massive_Title",
	desc_text = "Status_massive_Text",
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

-- Get all active traits for a pawn - massive and custom traits
local function getActiveTraits(pawn, massiveReplacementTraitObj)
	if not pawn then return {} end

	local activeTraits = {}
	
	-- Always include vanilla massive trait first
	table.insert(activeTraits, vanillaMassiveTrait)

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
		-- Just massive
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
	return pawn:IsMassive()
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

-- Helper to recreate small icon widget with new surface
-- Creating a new surface is the only way I found that works
-- to change the icons
local function recreateSmallIcon(surface)
	if missionSmallWidgetIcon then
		missionSmallWidgetIcon:detach()
	end
	
	missionSmallWidgetIcon = Ui()
		:widthpx(25):heightpx(21)
		:decorate({ DecoSurfaceOutlined(surface, 1, deco.colors.buttonborder, deco.colors.focus, 1) })
		:addTo(missionSmallWidget)
	
	missionSmallWidgetIcon.translucent = true
	
	-- Override decoration draw to show highlighted surface when tooltip is open
	local decoration = missionSmallWidgetIcon.decorations[1]
	if decoration then
		decoration.draw = function(self, screen, widget)
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
		:widthpx(50):heightpx(42)
		:decorate({ DecoSurfaceOutlined(surface, 1, deco.colors.buttonborder, deco.colors.buttonborder, 2) })
		:addTo(missionLargeWidget)
	missionLargeWidgetIcon.translucent = true
end

-- Create UI widgets overlay
local function createUIWidgets(uiRoot, massiveReplacementTraitObj)
	-- Use vanilla massive icon as initial surface that will be replaced later
	-- Maybe not needed?
	local initialSurface = massiveReplacementTraitObj.surfaces.massive_vanilla or massiveIcon
	
	-- Large widget for status tooltip display
	missionLargeWidget = Ui()
		:widthpx(50):heightpx(42)
		:addTo(uiRoot)
	missionLargeWidget.translucent = true
	missionLargeWidget.visible = false
	
	missionSmallWidget = Ui()
		:widthpx(25):heightpx(21)
		:addTo(uiRoot)
	missionSmallWidget.translucent = true
	missionSmallWidget.visible = false
	
	-- Create initial icons
	recreateSmallIcon(initialSurface)
	recreateLargeIcon(initialSurface)

	-- Small widget draw function
	local lastSmallIconId = nil
	local cachedSmallX = nil
	local cachedSmallY = nil
	local wasTooltipVisible = false
	
	missionSmallWidget.draw = function(self, screen)
		self.visible = false
		if massiveIcon:wasDrawn() and GetCurrentMission() then
			local pawn = getUIEnabledPawn()

			if shouldShowIcon(pawn) then
				-- Recalculate icon every frame to support cycling
				local iconId = getCurrentIcon(pawn, massiveReplacementTraitObj)
				local surface = getIconSurface(iconId, massiveReplacementTraitObj)

				if surface then
					-- Check if tooltip is visible
					local tooltipVisible = sdlext:isStatusTooltipWindowVisible()
					
					-- Cache position when tooltip first opens, or update from massiveIcon when closed
					if not tooltipVisible then
						-- Tooltip closed: follow massiveIcon
						self.x = massiveIcon.x
						self.y = massiveIcon.y
						self.screenx = massiveIcon.x
						self.screeny = massiveIcon.y
						self.rect.x = massiveIcon.x
						self.rect.y = massiveIcon.y
						
						-- Cache this position for when tooltip opens
						cachedSmallX = massiveIcon.x
						cachedSmallY = massiveIcon.y
						wasTooltipVisible = false
					elseif not wasTooltipVisible and cachedSmallX then
						-- Tooltip just opened: use cached position
						self.x = cachedSmallX
						self.y = cachedSmallY
						self.screenx = cachedSmallX
						self.screeny = cachedSmallY
						self.rect.x = cachedSmallX
						self.rect.y = cachedSmallY
						wasTooltipVisible = true
					end
					
					-- Recreate icon widget when icon changes
					if iconId ~= lastSmallIconId then
						recreateSmallIcon(surface)
						lastSmallIconId = iconId
					end
					
					-- Update child position and rect manually since we're bypassing normal layout
					if missionSmallWidgetIcon and missionSmallWidgetIcon.root then
						missionSmallWidgetIcon.x = 0
						missionSmallWidgetIcon.y = 0
						missionSmallWidgetIcon.w = 25
						missionSmallWidgetIcon.h = 21
						missionSmallWidgetIcon.screenx = self.screenx
						missionSmallWidgetIcon.screeny = self.screeny
						missionSmallWidgetIcon.rect.x = self.screenx
						missionSmallWidgetIcon.rect.y = self.screeny
						missionSmallWidgetIcon.rect.w = 25
						missionSmallWidgetIcon.rect.h = 21
						
						-- Force child to be visible at all times
						missionSmallWidgetIcon.visible = true
					end
					self.visible = true
				end
			end
		end
		-- Use clip to mask outside game window which also draws
		clip(Ui, self, screen)
	end


	-- Large widget draw function
	local lastLargeIconId = nil
	local cachedLargeX = nil
	local cachedLargeY = nil
	local wasLargeTooltipVisible = false
	
	missionLargeWidget.draw = function(self, screen)
		self.visible = false
		if massiveIcon:wasDrawn() and GetCurrentMission() then
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
					-- Don't show large icon if massiveIcon is still at the small icon position
					-- (tooltip just opened but vanilla icon hasn't moved yet - wait for it to move to tooltip position)
					local atSmallIconPosition = (cachedSmallX and cachedSmallY and 
					                             massiveIcon.x == cachedSmallX and massiveIcon.y == cachedSmallY)
					
					if not atSmallIconPosition then
						-- massiveIcon has moved to its tooltip position, safe to show large icon
						
						-- Recreate icon widget when icon changes
						if iconId ~= lastLargeIconId then
							recreateLargeIcon(surface)
							lastLargeIconId = iconId
						end
						
						-- Cache position on first valid frame, then keep it stable
						if not wasLargeTooltipVisible then
							cachedLargeX = massiveIcon.x
							cachedLargeY = massiveIcon.y
							wasLargeTooltipVisible = true
						end
						
						-- Use cached position to prevent jumping as tooltip animates
						local targetX = cachedLargeX
						local targetY = cachedLargeY
						
						self.x = targetX
						self.y = targetY
						self.screenx = targetX
						self.screeny = targetY
						self.rect.x = targetX
						self.rect.y = targetY
						self.rect.w = 50
						self.rect.h = 42
					
					-- Update child position and rect manually
					if missionLargeWidgetIcon and missionLargeWidgetIcon.root then
						missionLargeWidgetIcon.x = 0
						missionLargeWidgetIcon.y = 0
						missionLargeWidgetIcon.w = 50
						missionLargeWidgetIcon.h = 42
						missionLargeWidgetIcon.screenx = self.screenx
						missionLargeWidgetIcon.screeny = self.screeny
						missionLargeWidgetIcon.rect.x = self.screenx
						missionLargeWidgetIcon.rect.y = self.screeny
						missionLargeWidgetIcon.rect.w = 50
						missionLargeWidgetIcon.rect.h = 42
					end
					
						self.visible = true
					end
				else
					-- Tooltip closed: reset cache for next open
					if wasLargeTooltipVisible then
						wasLargeTooltipVisible = false
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
		if id == "massive" then
			local pawn = getUIEnabledPawn()

			if pawn then
				-- Get all active traits (vanilla massive + custom)
				local activeTraits = getActiveTraits(pawn, massiveReplacementTraitObj)
				
				if #activeTraits == 0 then
					-- No traits, no tooltip
					return {"", ""}
				elseif #activeTraits == 1 then
					-- Just massive
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
		error("ERROR: Attempted to add an unlinked massive replacement trait!")
	end

	-- Generate unique ID based on total count
	local totalCount = #massiveReplacementTraitObj.allTraits + 1
	local id = "massive_custom_" .. totalCount
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
		LOG("Warning: Could not load valid icon for massive replacement trait: " .. iconPath)
		return
	end

	massiveReplacementTraitObj.surfaces[id] = surface

	-- Add to appropriate collection
	if func then
		Assert.Equals('function', type(func))
		table.insert(massiveReplacementTraitObj.funcs, trait)
	elseif pilotSkill then
		Assert.Equals('string', type(pilotSkill))
		Assert.Equals('nil', type(massiveReplacementTraitObj.pilotSkills[pilotSkill]), "Duplicate massive replacement trait for pilotSkill")
		massiveReplacementTraitObj.pilotSkills[pilotSkill] = trait
	elseif pawnType then
		Assert.Equals('string', type(pawnType))
		Assert.Equals('nil', type(massiveReplacementTraitObj.pawnTypes[pawnType]), "Duplicate massive replacement trait for pawnType")
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
		-- Copy the vanilla massive icon to a new location and override
		-- the massive trait image with placeholder image
		modApi:copyAsset(massiveIconPath, massiveIconNewPath)
		modApi:appendAsset(massiveIconPath, massivePlaceholderPath)

		-- Load vanilla massive icon surface from the backup
		self.surfaces.massive_vanilla = massiveOrigIcon

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
