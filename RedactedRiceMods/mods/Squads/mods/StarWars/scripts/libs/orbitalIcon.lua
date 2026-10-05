-- orbitalIcon
-- Adapted from pyramidIcon by Lemonymous/tosx for Thoths Sentinels
-- Modified for orbital pawns
--
-- This lib replaces the flying icon with an orbital icon
-- Shows in both mission AND hangar (like pyramidIcon)
-- To use: add OrbitalIcon = true to your pawn table

local VERSION = "0.0.3"

local icon = sdlext.surface("img/combat/icons/icon_flying.png")
local mod = modApi:getCurrentMod()
local path = mod.scriptPath
local menu = require(path .."libs/menu")
local UiCover = require(path .."ui/cover")
local clip = require(path .."libs/clip")
local tips = require(path.."libs/tutorialTips")

local newicon
local pawnTypeShown = false
local delayOnce = 0

-- Helper functions
local function IsOrbital(pawn)
	local pawnType
	local flyingPilot
	
	if pawn then
		pawnType = pawn:GetType()
		flyingPilot = pawn:IsAbility("Flying")
	elseif pawnTypeShown then
		pawnType = pawnTypeShown
		flyingPilot = false
	else
		return false
	end
	
	local pawnData = _G[pawnType]
	
	return pawnData and pawnData.OrbitalIcon and pawnData.Flying and not flyingPilot
end

local function IsOrbitalType(pawnType)
	local pawnData = _G[pawnType]
	return pawnData and pawnData.OrbitalIcon and pawnData.Flying
end

function GetUIEnabledPawn()
	local pawn = Board:GetSelectedPawn()
	
	if not pawn then
		local highlighted = Board:GetHighlighted()
		
		if highlighted and Board then
			pawn = Board:GetPawn(highlighted)
		end
	end
	
	return pawn
end

-- Hangar tracking variables
local orbitalHangar = {
	count = 0,
	icon = nil,
	pawnTypes = {},
	oldGetNames = nil,
	title = "Orbital",
	desc = "Orbital units stay outside of the map area.",
}

function orbitalHangar:OverrideGetName(pawnType, pawn)
	assert(pawn.GetName)
	assert(_G[pawnType] == pawn)

	if self.oldGetNames[pawnType] then
		error(pawnType .." is already overridden!")
	end
	
	self.oldGetNames[pawnType] = pawn.GetName
	
	pawn.GetName = function(pawnSelf, pawnArg, parent)
		if not parent then
			orbitalHangar.count = orbitalHangar.count + 1
			if IsOrbitalType(pawnType) or _G[pawnType].Flying then
				orbitalHangar.pawnTypes[orbitalHangar.count] = {
					pawnType = pawnType,
					skills = math.max(1, #_G[pawnType].SkillList),
				}
			end
		end
		return orbitalHangar.oldGetNames[pawnType](pawnSelf, pawnArg, true)
	end
end

function orbitalHangar:OverrideAllGetName()
	if not self.oldGetNames then
		self.oldGetNames = {}
		
		for k, v in pairs(_G) do
			if	type(v) == "table" and
				v.GetName and
				v.Image then
				
				self:OverrideGetName(k, v)
			end
		end
	end
end

-- Create UI elements
local missionSmallWidget
local missionSmallWidgetIcon
local missionLargeWidget
local hangarIconHolder = {}

local function UiRootCreatedHook(screen, uiRoot)
	local decoDrawFn = function(self, screen, widget)
		local oldX = widget.rect.x
		local oldY = widget.rect.y
		
		widget.rect.x = widget.rect.x - 2
		widget.rect.y = widget.rect.y + 2
		
		DecoSurfaceOutlined.draw(self, screen, widget)
		
		widget.rect.x = oldX
		widget.rect.y = oldY
	end
	
	-- Mission widgets
	missionSmallWidget = Ui()
		:widthpx(25):heightpx(21)
		:addTo(uiRoot)
	missionSmallWidgetIcon = Ui()
		:widthpx(25):heightpx(21)
		:decorate({ DecoSurfaceOutlined(newicon, 1, deco.colors.buttonborder, deco.colors.focus, 1) })
		:addTo(missionSmallWidget)
	missionSmallWidget.translucent = true
	missionSmallWidget.visible = false
	missionSmallWidgetIcon.translucent = true
	missionSmallWidgetIcon.decorations.draw = function(self, screen, widget)
		self.surface = self.surface or self.surfacenormal
		DecoSurface.draw(self, screen, widget)
	end
	
	missionLargeWidget = Ui()
		:widthpx(50):heightpx(42)
		:addTo(uiRoot)
	local child = Ui()
		:widthpx(50):heightpx(42)
		:decorate({ DecoSurfaceOutlined(newicon, 1, deco.colors.buttonborder, deco.colors.buttonborder, 2) })
		:addTo(missionLargeWidget)
	child.translucent = true
	missionLargeWidget.translucent = true
	missionLargeWidget.visible = false

	-- Create hangar icon holders
	hangarIconHolder = {}
	for i = 1, 4 do
		hangarIconHolder[i] = Ui()
			:widthpx(25):heightpx(21)
			:decorate({ DecoSolid(deco.colors.button) })
			:addTo(uiRoot)
		hangarIconHolder[i+4] = Ui()
			:widthpx(25):heightpx(21)
			:decorate({ DecoSurfaceOutlined(newicon, 1, deco.colors.buttonborder, deco.colors.focus, 1) })
			:addTo(hangarIconHolder[i])
		
		-- Set mouse events on BOTH the holder and the icon child
		local holder = hangarIconHolder[i]
		local iconChild = hangarIconHolder[i+4]
		holder.onMouseEnter = function(self)
			if orbitalHangar.pawnTypes[i] and IsOrbitalType(orbitalHangar.pawnTypes[i].pawnType) then
				self.tooltip = orbitalHangar.title .. "\n" .. orbitalHangar.desc
			else
				self.tooltip = "Flying\nFlying units can move over any terrain tile."
			end
		end

		holder.onMouseExit = function(self)
			self.tooltip = nil
		end

		iconChild.onMouseEnter = function(self)
			if orbitalHangar.pawnTypes[i] and IsOrbitalType(orbitalHangar.pawnTypes[i].pawnType) then
				self.tooltip = orbitalHangar.title .. "\n" .. orbitalHangar.desc
			else
				self.tooltip = "Flying\nFlying units can move over any terrain tile."
			end
		end

		iconChild.onMouseExit = function(self)
			self.tooltip = nil
		end
		
		holder.translucent = true
		holder.visible = false
		holder.clipRect = sdl.rect(0, 0, 25, 21)
	end

	-- Mission widget draw function
	missionSmallWidget.draw = function(self, screen)
		self.visible = false
		if icon:wasDrawn() and GetCurrentMission() and not missionSmallWidget.isMasked then
			local pawn = GetUIEnabledPawn()
			if IsOrbital(pawn) then
				if not sdlext:isStatusTooltipWindowVisible() then
					self.x = icon.x
					self.y = icon.y
					missionSmallWidgetIcon.decorations.surface = missionSmallWidgetIcon.decorations.surfacenormal
				elseif sdlext:isStatusTooltipWindowVisible() then
					if Board:IsValid(Board:GetHighlighted()) then
						-- Status window due to mousing over a board unit with CTRL; don't highlight small icon
					else
						missionSmallWidgetIcon.decorations.surface = missionSmallWidgetIcon.decorations.surfacehl
					end
				end
				self.visible = true
			end
		end
		clip(Ui, self, screen)
	end
	
	missionLargeWidget.draw = function(self, screen)
		self.visible = false
		if icon:wasDrawn() and GetCurrentMission() then
			local pawn = GetUIEnabledPawn()
			if IsOrbital(pawn) then
				if sdlext:isStatusTooltipWindowVisible() and not sdlext:isEscapeMenuWindowVisible() then
					self.x = icon.x
					self.y = icon.y
					self.visible = true
				end
			end
		end
		Ui.draw(self, screen)
	end
	
	-- Hangar icon draw functions
	for i = 1, 4 do
		local holder = hangarIconHolder[i]
		holder.draw = function(self, screen)
			self.visible = false
			if icon:wasDrawn() and sdlext.isHangar() then
				if	IsHangarWindowlessState()
				or	((orbitalHangar.count == 1 or orbitalHangar.count == 4) and
					i == orbitalHangar.count) then
					
					if orbitalHangar.pawnTypes[i] then
						if IsOrbitalType(orbitalHangar.pawnTypes[i].pawnType) then
							self.x = icon.x
							self.y = icon.y
							
							if IsHangarWindowlessState() then
								if icon.y == 540 or icon.y == 613 then
									if orbitalHangar.pawnTypes[1] then
										self.x = self.x - 67 * (orbitalHangar.pawnTypes[1].skills - orbitalHangar.pawnTypes[i].skills)
									end
									self.y = self.y - 105 * (3 - i)
									
								elseif icon.y == 435 or icon.y == 508 then
									if orbitalHangar.pawnTypes[1] then
										self.x = self.x - 67 * (orbitalHangar.pawnTypes[1].skills - orbitalHangar.pawnTypes[i].skills)
									end
									self.y = self.y - 105 * (2 - i)
								end
							end
							
							self.clipRect.x = self.x
							self.clipRect.y = self.y
							
							if IsHangarWindowlessState() then
								if	(sdlext.CurrentWindowRect.w ~= 420
								or	(sdlext.CurrentWindowRect.h ~= 480			and
									sdlext.CurrentWindowRect.h ~= 493))			and
									rect_intersects(self.clipRect,
													sdlext.CurrentWindowRect)	then
									
									self.clipRect.w = math.max(0, math.min(25, sdlext.CurrentWindowRect.x - self.x))
								else
									self.clipRect.w = 25
								end
							end
							
							self.visible = true
						end
					end
				end
			end
			screen:clip(self.clipRect)
			Ui.draw(self, screen)
			screen:unclip()
		end
	end
end

local function onModsLoaded()
	require(path .."libs/menu"):load()
	
	modApi.events.onFrameDrawStart:subscribe(function()
		if delayOnce > 0 then
			delayOnce = delayOnce - 1
		else
			pawnTypeShown = false
		end
	end)
end

local function finalizeInit(self)	
	-- Load the icon first
	newicon = sdlext.surface(mod.resourcePath .."img/combat/icons/icon_orbital.png")
	orbitalHangar.icon = newicon
	
	-- Initialize hangar tracking
	orbitalHangar:OverrideAllGetName()
	
	-- Add the hook after the icon is loaded
	sdlext.addUiRootCreatedHook(UiRootCreatedHook)
	
	local original_GetStatusTooltip = GetStatusTooltip
	function GetStatusTooltip(id)
		if id == "flying" then
			local pawn = GetUIEnabledPawn()
			if IsOrbital(pawn) then
				return {orbitalHangar.title, orbitalHangar.desc}
			end
		end
		return original_GetStatusTooltip(id)
	end
	
	local oldGetText = GetText
	function GetText(id, ...)
		if Pawn_Texts[id] then
			pawnTypeShown = id
			delayOnce = 2
		end
		return oldGetText(id, ...)
	end
	
	-- Add tutorial tip
	tips:Add{
		id = "OrbitalPawn",
		title = "Orbital Unit",
		text = "Orbital units stay outside of the map area. Use the unit list on the left of the screen to select them."
	}
	
	-- Trigger tutorial tip on deployment
	modApi.events.onDeploymentPhaseEnd:subscribe(function()
		if Board then
			local orbitalPawn = nil
			local pawnList = extract_table(Board:GetPawns(TEAM_PLAYER))
			
			for _, p in ipairs(pawnList) do
				local pawn = Board:GetPawn(p)
				if pawn and IsOrbital(pawn) then
					orbitalPawn = pawn
					break
				end
			end
			
			if orbitalPawn then
				local loc = orbitalPawn:GetSpace()
				tips:Trigger("OrbitalPawn", loc)
			end
		end
	end)
	
	modApi.events.onModsLoaded:subscribe(onModsLoaded)
end

local function onModsInitialized()
	local isHighestVersion = true
		and OrbitalIcon.initialized ~= true
		and OrbitalIcon.version == VERSION

	if isHighestVersion then
		OrbitalIcon:finalizeInit()
		OrbitalIcon.initialized = true
	end
end

local isNewerVersion = false
	or OrbitalIcon == nil
	or VERSION > OrbitalIcon.version

if isNewerVersion then
	OrbitalIcon = OrbitalIcon or {}
	OrbitalIcon.version = VERSION
	OrbitalIcon.finalizeInit = finalizeInit

	modApi.events.onModsInitialized:subscribe(onModsInitialized)
end

return OrbitalIcon
