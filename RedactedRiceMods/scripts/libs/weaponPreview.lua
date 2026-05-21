
local VERSION = "4.0.3"
----------------------------------------------------------------------
-- Weapon Preview - code library
-- https://github.com/Lemonymous/ITB-LemonymousMods/wiki/weaponPreview
--
-- by Lemonymous
-- Enhanced by Das Keifer to allow usage in skill build events and
-- for two click weapon support
----------------------------------------------------------------------
--  A library for
--   - enhancing preview of weapons/move/repair skills with
--      - damage marks
--      - colored tiles
--      - tile descriptions
--      - tile images
--      - animations
--      - emitters
--
--  The following methods are meant to be used in either GetTargetArea
--  or GetSkillEffect, whichever makes the most sense.
--  GetTargetArea can display marks as soon as a weapon is selected.
--  GetSkillEffect can display marks only after a tile is highlighted,
--  and should be used if mark is dependent of target location.
--
--  methods:
--      :AddAnimation(point, animation, delay)
--      :AddColor(point, gl_color, duration)
--      :AddDamage(spaceDamage, duration)
--      :AddDelay(duration)
--      :AddDesc(point, desc, flag, duration)
--      :AddEmitter(point, emitter, duration)
--      :AddFlashing(point, flag, duration)
--      :AddImage(point, path, gl_color, duration)
--      :AddSimpleColor(point, gl_color, duration)
--      :ClearMarks()
--      :SetLooping(flag)
--
--  The following methods can be used at any time to gain information
--  about what is being currently previewed.
--
--      :GetQueuedSkillEffectMarker()
--      :GetSkillEffectMarker()
--      :GetTargetAreaMarker()
--      :IsQueuedSkillEffectMarker()
--      :IsSkillEffectMarker()
--      :IsTargetAreaMarker()
--
--  The following methods will reset the animation timer for the various
--  markers.
--
--      :ResetQueuedSkillEffectTimer()
--      :ResetSkillEffectTimer()
--      :ResetTargetAreaTimer()
--
--  The following events can be subscribed to in order to be informed
--  when the preview state changes. Note that these events will be
--  dispatched for all weapons, even if they have no custom preview
--  marks added with this library.
--
--      :events.onTargetAreaShown()
--      :events.onTargetAreaHidden()
--      :events.onSecondTargetAreaShown()
--      :events.onSecondTargetAreaHidden()
--      :events.onSkillEffectShown()
--      :events.onSkillEffectHidden()
--      :events.onFinalEffectShown()
--      :events.onFinalEffectHidden()
--      :events.onQueuedSkillEffectShown()
--      :events.onQueuedSkillEffectHidden()
--
----------------------------------------------------------------------


if Assert.TypeGLColor == nil then
	local function traceback()
		return Assert.Traceback and debug.traceback("\n", 3) or ""
	end

	function Assert.TypeGLColor(arg, msg)
		msg = (msg and msg .. ": ") or ""
		msg = msg .. string.format("Expected GL_Color, but was %s%s", tostring(type(arg)), traceback())
		assert(
			type(arg) == "userdata" and
			type(arg.r) == "number" and
			type(arg.g) == "number" and
			type(arg.b) == "number" and
			type(arg.a) == "number", msg
		)
	end
end

local OUT_OF_BOUNDS = Point(-1, -1)
local PREFIX = "_weapon_preview_%s_"
local PREFIX_ANIM = string.format(PREFIX, "1")
local PREFIX_EMITTER = string.format(PREFIX, "emitter")

local STATE_NONE = 0
local STATE_SKILL_EFFECT = 1
local STATE_TARGET_AREA = 2
local STATE_QUEUED_SKILL = 3
local STATE_SECOND_TARGET_AREA = 4
local STATE_FINAL_EFFECT = 5
local STATE_QUEUED_FINAL_EFFECT = 6

local NULL_PAWNID = -1
local NULL_WEAPON = ""
local NULL_WEAPID = -1
local INT_MAX = 2147483647

-- Tooltip key configuration
local TOOLTIP_KEY = SDLKeycodes.h
local TOOLTIP_KEY_TEXT = "H"

-- Group consolidation support
local DEFAULT_MULTI_ICON = nil  -- Will be initialized during finalizeInit
local DEFAULT_MULTI_ICON_MARK_DATA = nil  -- Will be initialized after createAnim is available
local groupRegistry = {}  -- Maps groupId -> {offset = Point, multiIcon = string, multiIconMarkData = {duration, delay, loop}, groupMultiIconKey = string}
local pendingGroupAnimations = {}  -- Tracks animations by group: [state][groupId][loc_hash] = {loc, anims = {{anim, duration, delay, loop}, ...}}
local animationDescriptions = {}  -- Maps anim name -> description string

-- Track state for tooltip key display
local isTooltipKeyHeld = false
local lastTooltipKeyState = false
local lastHighlightedTile = nil

-- TutorialTips library
local tutorialTips

local Marker = Class.new()
local selfMetatable = setmetatable({}, Marker)
selfMetatable.__index = Marker
selfMetatable.__call = function()
	error("attempted to call an instance\n", 2)
end
selfMetatable.__eq = function(a, b)
	return
		a.pawnId == b.pawnId and
		a.weapon == b.weapon and
		a.weapId == b.weapId
end

local Marker_mt = getmetatable(Marker)
function Marker_mt:__call(...)
	local newInstance = setmetatable({}, selfMetatable)
	newInstance:new(...)
	return newInstance
end

function Marker:new()
	self:clear()
end

function Marker:unpack()
	return self.pawnId, self.weapon, self.weapId
end

function Marker:clear()
	self.pawnId = NULL_PAWNID
	self.weapon = NULL_WEAPON
	self.weapId = NULL_WEAPID
	self.ticker = 0
end

function Marker:copy(other)
	if other then
		self.pawnId = other.pawnId
		self.weapon = other.weapon
		self.weapId = other.weapId
	else
		self:clear()
	end
end

function Marker:setArmed(pawn)
	if pawn then
		self.pawnId = pawn:GetId()
		self.weapon = pawn:GetArmedWeapon()
		self.weapId = pawn:GetArmedWeaponId()
	else
		self:clear()
	end
end

function Marker:setQueued(pawn)
	if pawn then
		self.pawnId = pawn:GetId()
		self.weapon = pawn:GetQueuedWeapon()
		self.weapId = pawn:GetQueuedWeaponId()
	else
		self:clear()
	end
end

function Marker:isActive()
	return self.weapId > NULL_WEAPID
end

function Marker:isInActive()
	return not self:isActive()
end

local actingMarker
local targetMarker
local secondTargetMarker
local effectMarker
local finalEffectMarker
local queuedMarker
local queuedFinalEffectMarker
local time_prev = 0

local getTargetAreaCallers = {}
local getSecondTargetAreaCallers = {}
local getSkillEffectCallers = {}
local getFinalEffectCallers = {}
local oldGetTargetAreas = {}
local oldGetSecondTargetAreas = {}
local oldGetSkillEffects = {}
local oldGetFinalEffects = {}
local oldGetTargetScores = {}
local armedTargetAreaTimer = 0
local armedSkillEffectTimer = 0
local queuedSkillEffectTimer = 0
local previewTargetArea = PointList()
local previewSecondTargetArea = PointList()
local previewState = STATE_NONE
local previewMarks = {}
local queuedPreviewMarks = {}
local events = {}
local isScoring = false

local function spaceEmitter(loc, emitter)
	local fx = SkillEffect()
	fx:AddEmitter(loc, emitter)
	return fx.effect:index(1)
end

local function createAnim(anim)
	local base = ANIMS[anim]

	-- chop up animation to single frame units.
	if not ANIMS[PREFIX_ANIM..anim] then
		local frames = base.Frames
		local lengths = base.Lengths

		if not frames then
			frames = {}
			for i = 1, base.NumFrames do
				frames[i] = i - 1
			end
		end

		if not lengths then
			lengths = {}
			for i = 1, #frames do
				lengths[i] = base.Time
			end
		end

		for i, frame in ipairs(frames) do
			local prefix = string.format(PREFIX, i)
			ANIMS[prefix..anim] = base:new{
				__NumFrames = #frames,
				__Lengths = lengths,
				Frames = { frame },
				Lengths = nil,
				Loop = false,
				Time = 0,
			}
		end
	end
end

local function sum(t)
	local result = 0
	for i = 1, #t do
		result = result + t[i]
	end
	return result
end

local function list_contains(list, value)
	for _, v in ipairs(list) do
		if v == value then
			return true
		end
	end
	return false
end

local function pointListContains(pointList, obj)
	if not pointList then return false end
	for i = 1, pointList:size() do
		if obj == pointList:index(i) then
			return true
		end
	end

	return false
end

local function isPreviewerUnavailable()
	return previewState == STATE_NONE or Board:IsTipImage() or isScoring
end

-- Get group data
local function getGroupData(groupId)
	return groupRegistry[groupId]
end

-- Get multi-icon for a group
local function getGroupMultiIcon(groupId)
	local groupData = groupRegistry[groupId]
	if groupData and groupData.multiIcon then
		return groupData.multiIcon
	end
	return DEFAULT_MULTI_ICON
end

local function addAnimation(self, p, anim, delay, groupId, description)
	if isPreviewerUnavailable() then return end

	Assert.TypePoint(p, "Argument #1")
	Assert.Equals('string', type(anim), "Argument #2")
	Assert.NotEquals('nil', type(ANIMS[anim]), "Argument #2")
	Assert.Equals({'nil', 'string'}, type(groupId), "Argument #4 (groupId)")
	Assert.Equals({'nil', 'string'}, type(description), "Argument #5 (description)")

	-- Store the original animation name before any group modifications
	local originalAnimName = anim

	-- Store description if provided
	if description then
		animationDescriptions[originalAnimName] = description
	end

	-- If groupId provided, apply group offset to the animation
	if groupId then
		local groupData = getGroupData(groupId)
		Assert.NotEquals('nil', type(groupData), "Group ID '"..tostring(groupId).."' not registered. Call RegisterGroup first.")
		if groupData.offset then
			-- base anims already asserted above
			local baseAnim = ANIMS[anim]
			-- Create a group specific variant with offset applied
			local groupAnimKey = anim .. "_group_" .. groupId
			if not ANIMS[groupAnimKey] then
				ANIMS[groupAnimKey] = baseAnim:new{
					PosX = groupData.offset.x,
					PosY = groupData.offset.y
				}
			end
			anim = groupAnimKey
		end
	end

	createAnim(anim)

	local base = ANIMS[anim]
	local duration = sum(ANIMS[PREFIX_ANIM..anim].__Lengths)

	if delay == ANIM_DELAY then
		delay = duration
	else
		delay = nil
	end

	-- Track grouped animations for consolidation
	if groupId then
		if not pendingGroupAnimations[previewState] then
			pendingGroupAnimations[previewState] = {}
		end
		if not pendingGroupAnimations[previewState][groupId] then
			pendingGroupAnimations[previewState][groupId] = {}
		end

		local locHash = p.x * 10 + p.y
		if not pendingGroupAnimations[previewState][groupId][locHash] then
			pendingGroupAnimations[previewState][groupId][locHash] = {
				loc = Point(p),
				anims = {}
			}
		end

		-- Add animation to array with its mark data, storing the original animation name
		table.insert(pendingGroupAnimations[previewState][groupId][locHash].anims, {
			anim = anim,  -- Store the adjusted animation name with group offset
			duration = duration,
			delay = delay,
			loop = base.Loop,
			originalAnim = originalAnimName  -- Store original anim name for description lookup
		})

		-- Don't add grouped animations to marks yet - consolidation will handle it
		return
	end

	-- Normal (non-grouped) animations are added directly to marks
	table.insert(previewMarks[previewState], {
		fn = 'AddAnimation',
		anim = anim,
		data = {Point(p), anim, ANIM_NO_DELAY},
		duration = duration,
		delay = delay,
		loop = base.Loop,
		originalAnim = originalAnimName  -- Store original anim name for description lookup
	})
end

local function addColor(self, p, gl_color, duration)
	if isPreviewerUnavailable() then return end

	Assert.TypePoint(p, "Argument #1")
	Assert.TypeGLColor(gl_color, "Argument #2")
	Assert.Equals({'nil', 'number'}, type(duration), "Argument #3")

	table.insert(previewMarks[previewState], {
		fn = 'MarkSpaceColor',
		data = {Point(p), gl_color},
		duration = duration
	})
end

local function addDamage(self, d, duration)
	if isPreviewerUnavailable() then return end

	Assert.Equals({'userdata', 'table'}, type(d), "Argument #1")
	Assert.Equals({'nil', 'number'}, type(duration), "Argument #2")
	Assert.TypePoint(d.loc, "Argument #1 - Field 'loc'")

	table.insert(previewMarks[previewState], {
		fn = 'MarkSpaceDamage',
		data = {shallow_copy(d)},
		duration = duration
	})
end

local function addDelay(self, duration)
	if isPreviewerUnavailable() then return end

	Assert.Equals('number', type(duration), "Argument #1")

	table.insert(previewMarks[previewState], {
		delay = duration
	})
end

local function addDesc(self, p, desc, flag, duration)
	if isPreviewerUnavailable() then return end

	Assert.TypePoint(p, "Argument #1")
	Assert.Equals('string', type(desc), "Argument #2")
	Assert.Equals({'nil', 'boolean'}, type(flag), "Argument #3")
	Assert.Equals({'nil', 'number'}, type(duration), "Argument #4")

	flag = flag ~= false

	table.insert(previewMarks[previewState], {
		fn = 'MarkSpaceDesc',
		data = {Point(p), desc, flag},
		duration = duration
	})
end

local function addEmitter(self, p, emitter, duration)
	if isPreviewerUnavailable() then return end

	Assert.TypePoint(p, "Argument #1")
	Assert.Equals('string', type(emitter), "Argument #2")
	Assert.NotEquals('nil', type(_G[emitter]), "Argument #2")
	Assert.Equals({'nil', 'number'}, type(duration), "Argument #3")

	local base = _G[emitter]

	if not _G[PREFIX_EMITTER..emitter] then
		_G[PREFIX_EMITTER..emitter] = base:new{
			birth_rate = base.birth_rate / 4,
			burst_count = base.burst_count / 4
		}
	end

	table.insert(previewMarks[previewState], {
		fn = 'DamageSpace',
		loc = Point(p),
		emitter = emitter,
		data = {},
		duration = duration
	})
end

local function addFlashing(self, p, flag, duration)
	if isPreviewerUnavailable() then return end

	Assert.TypePoint(p, "Argument #1")
	Assert.Equals({'nil', 'boolean'}, type(flag), "Argument #2")
	Assert.Equals({'nil', 'number'}, type(duration), "Argument #3")

	flag = flag ~= false

	table.insert(previewMarks[previewState], {
		fn = 'MarkFlashing',
		data = {Point(p), flag},
		duration = duration
	})
end

local function addImage(self, p, path, gl_color, duration)
	if isPreviewerUnavailable() then return end

	Assert.TypePoint(p, "Argument #1")
	Assert.Equals('string', type(path), "Argument #2")
	Assert.TypeGLColor(gl_color, "Argument #3")
	Assert.Equals({'nil', 'number'}, type(duration), "Argument #4")

	table.insert(previewMarks[previewState], {
		fn = 'MarkSpaceImage',
		data = {Point(p), path, gl_color},
		duration = duration
	})
end

local function addSimpleColor(self, p, gl_color, duration)
	if isPreviewerUnavailable() then return end

	Assert.TypePoint(p, "Argument #1")
	Assert.TypeGLColor(gl_color, "Argument #2")
	Assert.Equals({'nil', 'number'}, type(duration), "Argument #3")

	table.insert(previewMarks[previewState], {
		fn = 'MarkSpaceSimpleColor',
		data = {Point(p), gl_color},
		duration = duration
	})
end

local function addFunction(self, fn, duration, ...)
	if isPreviewerUnavailable() then return end

	Assert.Equals('function', type(fn), "Argument #1")

	table.insert(previewMarks[previewState], {
		script = true,
		fn = fn,
		data = {...},
		duration = duration
	})
end

local function clearMarks(state)
	if state then
		previewMarks[state] = {}
		pendingGroupAnimations[state] = {}
	else
		for _, s in ipairs({STATE_TARGET_AREA, STATE_SECOND_TARGET_AREA, STATE_SKILL_EFFECT,
				STATE_FINAL_EFFECT, STATE_QUEUED_SKILL, STATE_QUEUED_FINAL_EFFECT}) do
			previewMarks[s] = {}
			pendingGroupAnimations[s] = {}
		end
	end
end

-- Register a group with icon offset, optional multi-icon, and optional multi-icon mark data
-- groupId: unique identifier for the group
-- offset: Point - offset for all icons in this group
-- multiIcon: optional string - animation key for multi-icon (uses default if not provided)
-- multiIconMarkData: optional table - {duration, delay, loop} for the multi-icon (uses defaults if not provided)
local function registerGroup(self, groupId, offset, multiIcon, multiIconMarkData)
	Assert.Equals('string', type(groupId), "Argument #1 (groupId)")
	Assert.TypePoint(offset, "Argument #2 (offset)")
	Assert.Equals({'nil', 'string'}, type(multiIcon), "Argument #3 (multiIcon)")
	Assert.Equals({'nil', 'table'}, type(multiIconMarkData), "Argument #4 (multiIconMarkData)")

	if multiIcon then
		Assert.NotEquals('nil', type(ANIMS[multiIcon]), "Animation '"..multiIcon.."' does not exist")
	end

	-- Only register if not already registered
	if not groupRegistry[groupId] then
		local finalMultiIcon = multiIcon or DEFAULT_MULTI_ICON

		-- Create group specific multi-icon with offset applied
		local groupMultiIconKey = finalMultiIcon .. "_group_" .. groupId
		if ANIMS[finalMultiIcon] and not ANIMS[groupMultiIconKey] then
			ANIMS[groupMultiIconKey] = ANIMS[finalMultiIcon]:new{
				PosX = offset.x,
				PosY = offset.y
			}
			createAnim(groupMultiIconKey)
		end

		groupRegistry[groupId] = {
			offset = Point(offset.x, offset.y),
			multiIcon = multiIcon,
			multiIconMarkData = multiIconMarkData,
			groupMultiIconKey = groupMultiIconKey
		}
	end
end

-- Consolidate grouped animations - add individual or multi-icon marks as appropriate
-- This function ONLY processes animations that were added with a groupId parameter.
-- Normal animations (without groupId) are added directly to marks and bypass this entirely.
local function consolidateGroupedAnimations(marks, state)
	if not pendingGroupAnimations[state] then
		return
	end

	-- Process each group
	for groupId, locations in pairs(pendingGroupAnimations[state]) do
		for locHash, data in pairs(locations) do
			-- Consolidate if there are multiple icons
			if #data.anims > 1 then
				local groupData = getGroupData(groupId)
				local groupMultiIconKey = groupData.groupMultiIconKey

				if groupMultiIconKey and ANIMS[groupMultiIconKey] then
					-- Use mark data from group registration or fall back to defaults
					local markData = groupData.multiIconMarkData or DEFAULT_MULTI_ICON_MARK_DATA

					-- Collect original animation names for tooltip support
					local combinedAnims = {}
					for _, animData in ipairs(data.anims) do
						table.insert(combinedAnims, animData.originalAnim)
					end

					table.insert(marks, {
						fn = 'AddAnimation',
						anim = groupMultiIconKey,
						data = {Point(data.loc), groupMultiIconKey, ANIM_NO_DELAY},
						duration = markData.duration,
						delay = markData.delay,
						loop = markData.loop,
						isMultiIcon = true,
						combinedAnims = combinedAnims  -- Store list of original animations for tooltips
					})
				end
			elseif #data.anims == 1 then
				-- Single animation - add it normally
				local animData = data.anims[1]
				table.insert(marks, {
					fn = 'AddAnimation',
					anim = animData.anim,
					data = {Point(data.loc), animData.anim, ANIM_NO_DELAY},
					duration = animData.duration,
					delay = animData.delay,
					loop = animData.loop,
					originalAnim = animData.originalAnim
				})
			end
		end
	end

	-- Clear pending animations for this state after consolidation
	pendingGroupAnimations[state] = nil
end

local function setLooping(self, flag)
	if isPreviewerUnavailable() then return end

	if flag == nil then
		flag = true
	end

	previewMarks[previewState].loop = flag
end

local function resetTargetTimer()
	targetMarker.ticker = 0
end

local function resetSecondTargetTimer()
	secondTargetMarker.ticker = 0
end

local function resetEffectTimer()
	effectMarker.ticker = 0
end

local function resetFinalEffectTimer()
	finalEffectMarker.ticker = 0
end

local function resetQueuedTimer()
	queuedMarker.ticker = 0
end

local function resetQueuedFinalEffectTimer()
	queuedFinalEffectMarker.ticker = 0
end

local function isTargetMarker()
	return targetMarker:isActive()
end

local function isSecondTargetMarker()
	return secondTargetMarker:isActive()
end

local function isEffectMarker()
	return effectMarker:isActive()
end

local function isFinalEffectMarker()
	return finalEffectMarker:isActive()
end

local function isQueuedMarker()
	return queuedMarker:isActive()
end

local function isQueuedFinalEffectMarker()
	return queuedFinalEffectMarker:isActive()
end

local function getTargetMarker()
	return targetMarker:unpack()
end

local function getSecondTargetMarker()
	return secondTargetMarker:unpack()
end

local function getEffectMarker()
	return effectMarker:unpack()
end

local function getFinalEffectMarker()
	return finalEffectMarker:unpack()
end

local function getQueuedMarker()
	return queuedMarker:unpack()
end

local function getQueuedFinalEffectMarker()
	return queuedFinalEffectMarker:unpack()
end

local function executeWithState(newPreviewState, fn, queuedPawnId)
	Assert.Equals('number', type(newPreviewState), "Argument #1")
	Assert.Equals('function', type(fn), "Argument #2")
	Assert.Equals({'nil', 'number'}, type(queuedPawnId), "Argument #3")

	-- Bail out early if we're in AI scoring mode
	if isScoring then
		return
	end

	-- If its a queued state, we need the queued pawn id arg and we need to make sure the
	-- queued preview marks are set up for the pawn
	if newPreviewState == STATE_QUEUED_SKILL or newPreviewState == STATE_QUEUED_FINAL_EFFECT then
		Assert.NotEquals('nil', type(queuedPawnId), "Argument #3 can't be nil if preview state is for queued skill")
		-- Initialize queued marks structure if needed
		if not queuedPreviewMarks[newPreviewState] then
			queuedPreviewMarks[newPreviewState] = {}
		end
		if not queuedPreviewMarks[newPreviewState][queuedPawnId] then
			queuedPreviewMarks[newPreviewState][queuedPawnId] = {}
		end
	end

	-- Set the state and call the fn
	local prevState = previewState
	previewState = newPreviewState
	fn()

	-- If it was a queued skill, we need to reset the queued preview marks to match
	if newPreviewState == STATE_QUEUED_SKILL or newPreviewState == STATE_QUEUED_FINAL_EFFECT then
		queuedPreviewMarks[previewState][queuedPawnId] = previewMarks[previewState]
	end
	-- Set the state back
	previewState = prevState
end

local function getTargetArea(self, p1, ...)
	local skillId = getTargetAreaCallers[#getTargetAreaCallers]
	local pawn = p1 and Board:GetPawn(p1) or Pawn
	local result = nil

	if pawn and previewState == STATE_NONE and not Board:IsTipImage() and not isScoring then

		actingMarker:setArmed(pawn)

		if skillId == actingMarker.weapon and actingMarker ~= targetMarker then
			if targetMarker:isActive() then
				events.onTargetAreaHidden:dispatch(targetMarker:unpack())
				targetMarker:clear()
			end

			previewState = STATE_TARGET_AREA
			previewMarks[previewState] = {}

			targetMarker:copy(actingMarker)
			events.onTargetAreaShown:dispatch(targetMarker:unpack())

			result = oldGetTargetAreas[skillId](self, p1, ...)
			previewTargetArea = result
			previewState = STATE_NONE
		end
	end

	if not result then
		result = oldGetTargetAreas[skillId](self, p1, ...)
		previewTargetArea = result
	end

	return result
end

local function getSecondTargetArea(self, p1, p2, ...)
	local skillId = getSecondTargetAreaCallers[#getSecondTargetAreaCallers]
	local pawn = p1 and Board:GetPawn(p1) or Pawn
	local result = nil

	if pawn and previewState == STATE_NONE and not Board:IsTipImage() and not isScoring then

		actingMarker:setArmed(pawn)

		if skillId == actingMarker.weapon and actingMarker ~= secondTargetMarker then
			if secondTargetMarker:isActive() then
				events.onSecondTargetAreaHidden:dispatch(secondTargetMarker:unpack())
				secondTargetMarker:clear()
			end

			previewState = STATE_SECOND_TARGET_AREA
			previewMarks[previewState] = {}

			secondTargetMarker:copy(actingMarker)
			events.onSecondTargetAreaShown:dispatch(secondTargetMarker:unpack())

			result = oldGetSecondTargetAreas[skillId](self, p1, p2, ...)
			previewSecondTargetArea = result
			previewState = STATE_NONE
		end
	end

	if not result then
		result = oldGetSecondTargetAreas[skillId](self, p1, p2, ...)
		previewSecondTargetArea = result
	end

	return result
end

local function getSkillEffect(self, p1, p2, ...)
	local skillId = getSkillEffectCallers[#getSkillEffectCallers]
	local pawn = p1 and Board:GetPawn(p1) or Pawn
	local result = nil

	if pawn and previewState == STATE_NONE and not Board:IsTipImage() and not isScoring then

		actingMarker:setArmed(pawn)

		if skillId == actingMarker.weapon then
			if effectMarker ~= actingMarker and effectMarker:isActive() then
				events.onSkillEffectHidden:dispatch(effectMarker:unpack())
				effectMarker:clear()
			end

			previewState = STATE_SKILL_EFFECT
			previewMarks[previewState] = {}

			if effectMarker:isInActive() then
				effectMarker:copy(actingMarker)
				events.onSkillEffectShown:dispatch(effectMarker:unpack())
			end

			result = oldGetSkillEffects[skillId](self, p1, p2, ...)
			previewState = STATE_NONE

		elseif pawn and skillId == pawn:GetQueuedWeapon() then
			previewState = STATE_QUEUED_SKILL
			local pawnId = pawn:GetId()

			-- Initialize queued marks structure if needed
			if not queuedPreviewMarks[previewState] then
				queuedPreviewMarks[previewState] = {}
			end
			-- Always regenerate marks for this pawn
			queuedPreviewMarks[previewState][pawnId] = {}
			previewMarks[previewState] = queuedPreviewMarks[previewState][pawnId]

			result = oldGetSkillEffects[skillId](self, p1, p2, ...)
			queuedPreviewMarks[previewState][pawnId] = previewMarks[previewState]
			previewState = STATE_NONE
		end
	end

	return result or oldGetSkillEffects[skillId](self, p1, p2, ...)
end

local function getFinalEffect(self, p1, p2, p3, ...)
	local skillId = getFinalEffectCallers[#getFinalEffectCallers]
	local pawn = p1 and Board:GetPawn(p1) or Pawn
	local result = nil

	if pawn and previewState == STATE_NONE and not Board:IsTipImage() and not isScoring then

		actingMarker:setArmed(pawn)

		if skillId == actingMarker.weapon then
			if finalEffectMarker ~= actingMarker and finalEffectMarker:isActive() then
				events.onFinalEffectHidden:dispatch(finalEffectMarker:unpack())
				finalEffectMarker:clear()
			end

			previewState = STATE_FINAL_EFFECT
			previewMarks[previewState] = {}

			if finalEffectMarker:isInActive() then
				finalEffectMarker:copy(actingMarker)
				events.onFinalEffectShown:dispatch(finalEffectMarker:unpack())
			end

			result = oldGetFinalEffects[skillId](self, p1, p2, p3, ...)
			previewState = STATE_NONE

		elseif pawn and skillId == pawn:GetQueuedWeapon() then
			previewState = STATE_QUEUED_FINAL_EFFECT
			local pawnId = pawn:GetId()

			-- Initialize queued marks structure if needed
			if not queuedPreviewMarks[previewState] then
				queuedPreviewMarks[previewState] = {}
			end
			-- Always regenerate marks for this pawn
			queuedPreviewMarks[previewState][pawnId] = {}
			previewMarks[previewState] = queuedPreviewMarks[previewState][pawnId]

			result = oldGetFinalEffects[skillId](self, p1, p2, p3, ...)
			queuedPreviewMarks[previewState][pawnId] = previewMarks[previewState]
			previewState = STATE_NONE
		end
	end

	return result or oldGetFinalEffects[skillId](self, p1, p2, p3, ...)
end

local function getPreviewLength(marks)
	local delay = 0
	local length = 0

	for _, mark in ipairs(marks) do
		if mark.duration then
			length = math.max(length, delay + mark.duration)
		end

		if mark.delay then
			delay = delay + mark.delay
			length = math.max(length, delay)
		end
	end

	return length
end

local function getAnimFrame(mark, time_start, time_curr)
	local base = ANIMS[PREFIX_ANIM..mark.anim]
	local lengths = base.__Lengths
	local duration = mark.duration

	if mark.loop then
		time_curr = time_start + (time_curr - time_start) % duration
	end

	local frame = time_start
	for i = 1, base.__NumFrames do
		frame = frame + lengths[i]
		if frame > time_curr or i == base.__NumFrames then
			local prefix = string.format(PREFIX, i)
			return prefix..mark.anim
		end
	end
end

local function markSpaces(marks, time_curr)
	local time_start = 0
	local looping = marks.loop

	if looping ~= false then
		local length = getPreviewLength(marks)
		if length > 0 then
			time_curr = time_curr % length
		else
			time_curr = 0
		end
	end

	for _, mark in ipairs(marks) do
		if mark.fn then
			local duration = mark.duration or INT_MAX
			if mark.fn == "AddAnimation" then
				mark.data[2] = getAnimFrame(mark, time_start, time_curr)

			elseif mark.fn == "DamageSpace" then
				mark.data[1] = spaceEmitter(mark.loc, PREFIX_EMITTER..mark.emitter)
			end

			if mark.loop or time_start <= time_curr and time_curr <= time_start + duration then
				if mark.script then
					mark.fn(unpack(mark.data))
				else
					Board[mark.fn](Board, unpack(mark.data))
				end
			end
		end

		time_start = time_start + (mark.delay or 0)
	end
end

local function onMissionChanged(mission, missionOld)
	time_prev = os.clock()
end

-- Collect and show tooltip with descriptions when tooltip key is pressed for highlighted tile
-- Also clear tooltips when key is released or tile changes
local function checkAndShowTooltipKey(highlighted)
	if not highlighted or highlighted == OUT_OF_BOUNDS then return end

	-- Check if the key state or highlighted tile changed
	local currentTooltipKeyState = isTooltipKeyHeld
	local tileChanged = lastHighlightedTile ~= highlighted
	local tooltipKeyPressed = currentTooltipKeyState and not lastTooltipKeyState
	local tooltipKeyReleased = not currentTooltipKeyState and lastTooltipKeyState

	-- Update tracking
	lastTooltipKeyState = currentTooltipKeyState
	lastHighlightedTile = highlighted

	-- Clear tips if key was released or if tile changed while the key is not held
	if tooltipKeyReleased or (tileChanged and not currentTooltipKeyState) then
		Game:ClearTips()
		return
	end

	-- Only show tooltip if key was just pressed or if tile changed while the key is held
	if not (tooltipKeyPressed or (tileChanged and currentTooltipKeyState)) then
		return
	end

	-- Don't show if the key is not currently down
	if not currentTooltipKeyState then return end

	-- If tile changed while the key is held, clear the old tooltip first to avoid stacking
	if tileChanged and currentTooltipKeyState then
		Game:ClearTips()
	end

	local descriptions = {}

	-- Helper function to collect descriptions from marks at location
	local function collectDescriptions(marks)
		if not marks then return end

		for _, mark in ipairs(marks) do
			if mark.fn == 'AddAnimation' and mark.data and mark.data[1] == highlighted then
				-- Check if this is a multi icon mark
				if mark.isMultiIcon and mark.combinedAnims then
					-- Collect descriptions from all combined animations
					for _, originalAnim in ipairs(mark.combinedAnims) do
						local desc = animationDescriptions[originalAnim]
						if desc and not list_contains(descriptions, desc) then
							table.insert(descriptions, desc)
						end
					end
				else
					-- Add just its description for a single icon
					local originalAnim = mark.originalAnim or mark.anim
					local desc = animationDescriptions[originalAnim]
					if desc and not list_contains(descriptions, desc) then
						table.insert(descriptions, desc)
					end
				end
			end
		end
	end

	-- Collect from all active preview states
	if targetMarker:isActive() then
		collectDescriptions(previewMarks[STATE_TARGET_AREA])
	end
	if secondTargetMarker:isActive() then
		collectDescriptions(previewMarks[STATE_SECOND_TARGET_AREA])
	end
	if effectMarker:isActive() then
		collectDescriptions(previewMarks[STATE_SKILL_EFFECT])
	end
	if finalEffectMarker:isActive() then
		collectDescriptions(previewMarks[STATE_FINAL_EFFECT])
	end

	-- Collect from queued marks
	if queuedPreviewMarks[STATE_QUEUED_SKILL] then
		for pawnId, marks in pairs(queuedPreviewMarks[STATE_QUEUED_SKILL]) do
			collectDescriptions(marks)
		end
	end
	if queuedPreviewMarks[STATE_QUEUED_FINAL_EFFECT] then
		for pawnId, marks in pairs(queuedPreviewMarks[STATE_QUEUED_FINAL_EFFECT]) do
			collectDescriptions(marks)
		end
	end

	-- Show tooltip if we have any descriptions
	if #descriptions > 0 then
		local desc = ""
		for i, text in ipairs(descriptions) do
			if i > 1 then
				desc = desc .. "\n"
			end
			desc = desc .. text
		end

		Global_Texts["WeaponPreview_TempExplanation_Title"] = "Space Effects Details"
		Global_Texts["WeaponPreview_TempExplanation_Text"] = desc
		Game:AddTip("WeaponPreview_TempExplanation", highlighted)
		Global_Texts["WeaponPreview_TempExplanation_Title"] = nil
		Global_Texts["WeaponPreview_TempExplanation_Text"] = nil
	end
end

-- Check for features in marks and show first time notifications using tutorialTips
local function checkAndShowFirstTimeNotifications(marks, loc)
	if not marks or not loc or not tutorialTips then return end

	-- Check if we need to show any first-time notifications
	local hasDescriptions = false
	local hasMultiIcon = false

	for _, mark in ipairs(marks) do
		if mark.fn == 'AddAnimation' and mark.data and mark.data[1] == loc then
			-- Check if this is a multiicon
			if mark.isMultiIcon then
				hasMultiIcon = true
				-- Multi icons with descriptions
				if mark.combinedAnims then
					for _, originalAnim in ipairs(mark.combinedAnims) do
						if animationDescriptions[originalAnim] then
							hasDescriptions = true
						end
					end
				end
			else
				-- Regular animation with description
				local originalAnim = mark.originalAnim or mark.anim
				if animationDescriptions[originalAnim] then
					hasDescriptions = true
				end
			end
		end
	end

	-- Show multi-icon notification first if needed
	if hasMultiIcon then
		tutorialTips:Trigger("WeaponPreview_MultiIconNotification", loc)
	end

	-- Then show first-time notification for descriptions if needed
	if hasDescriptions then
		tutorialTips:Trigger("WeaponPreview_DescriptionNotification", loc)
	end
end

local function onMissionUpdate()

	local time_now = os.clock()
	local time_delta = time_now - time_prev
	time_prev = time_now

	-- Clean up queued preview marks for removed pawns or pawns without queued weapons
	for state, pawnMarks in pairs(queuedPreviewMarks) do
		for pawnId, _ in pairs(pawnMarks) do
			local pawn = Board:GetPawn(pawnId)
			-- Clear marks if pawn doesn't exist, has no queued weapon, or queued weapon ID is invalid
			if not pawn or not pawn:GetQueuedWeapon() or pawn:GetQueuedWeaponId() < 0 then
				pawnMarks[pawnId] = nil
			end
		end
	end

	local selected = Board:GetSelectedPawn()
	local highlighted = Board:GetHighlighted() or OUT_OF_BOUNDS
	local highlightedPawn = Board:GetPawn(highlighted)
	local boardIsBusy = Board:IsBusy()

	actingMarker:setArmed(selected)

	if targetMarker:isActive() and actingMarker:isInActive() then
		events.onTargetAreaHidden:dispatch(targetMarker:unpack())
		targetMarker:clear()
	end

	if secondTargetMarker:isActive() and actingMarker:isInActive() then
		events.onSecondTargetAreaHidden:dispatch(secondTargetMarker:unpack())
		secondTargetMarker:clear()
	end

	if effectMarker:isActive() and actingMarker:isInActive() then
		events.onSkillEffectHidden:dispatch(effectMarker:unpack())
		effectMarker:clear()
	end

	if finalEffectMarker:isActive() and actingMarker:isInActive() then
		events.onFinalEffectHidden:dispatch(finalEffectMarker:unpack())
		finalEffectMarker:clear()
	end

	if targetMarker:isActive() then
		consolidateGroupedAnimations(previewMarks[STATE_TARGET_AREA], STATE_TARGET_AREA)
		markSpaces(previewMarks[STATE_TARGET_AREA], targetMarker.ticker)
		-- Check for first time notifications when displaying marks
		checkAndShowFirstTimeNotifications(previewMarks[STATE_TARGET_AREA], highlighted)
		targetMarker.ticker = targetMarker.ticker + time_delta
	end

	if secondTargetMarker:isActive() then
		consolidateGroupedAnimations(previewMarks[STATE_SECOND_TARGET_AREA], STATE_SECOND_TARGET_AREA)
		markSpaces(previewMarks[STATE_SECOND_TARGET_AREA], secondTargetMarker.ticker)
		-- Check for first time notifications when displaying marks
		checkAndShowFirstTimeNotifications(previewMarks[STATE_SECOND_TARGET_AREA], highlighted)
		secondTargetMarker.ticker = secondTargetMarker.ticker + time_delta
	end

	if effectMarker:isActive() then
		if not boardIsBusy and pointListContains(previewTargetArea, highlighted) then
			consolidateGroupedAnimations(previewMarks[STATE_SKILL_EFFECT], STATE_SKILL_EFFECT)
			markSpaces(previewMarks[STATE_SKILL_EFFECT], effectMarker.ticker)
			-- Check for first time notifications when displaying marks
			checkAndShowFirstTimeNotifications(previewMarks[STATE_SKILL_EFFECT], highlighted)
			effectMarker.ticker = effectMarker.ticker + time_delta
		else
			events.onSkillEffectHidden:dispatch(effectMarker:unpack())
			effectMarker:clear()
		end
	end

	if finalEffectMarker:isActive() then
		if not boardIsBusy and pointListContains(previewSecondTargetArea, highlighted) then
			consolidateGroupedAnimations(previewMarks[STATE_FINAL_EFFECT], STATE_FINAL_EFFECT)
			markSpaces(previewMarks[STATE_FINAL_EFFECT], finalEffectMarker.ticker)
			-- Check for first time notifications when displaying marks
			checkAndShowFirstTimeNotifications(previewMarks[STATE_FINAL_EFFECT], highlighted)
			finalEffectMarker.ticker = finalEffectMarker.ticker + time_delta
		else
			events.onFinalEffectHidden:dispatch(finalEffectMarker:unpack())
			finalEffectMarker:clear()
		end
	end

	if actingMarker.weapId <= 0 then
		actingMarker:setQueued(highlightedPawn)
	else
		actingMarker:clear()
	end

	-- Display all queued marks
	if queuedPreviewMarks[STATE_QUEUED_SKILL] then
		for pawnId, marks in pairs(queuedPreviewMarks[STATE_QUEUED_SKILL]) do
			consolidateGroupedAnimations(marks, STATE_QUEUED_SKILL)
			markSpaces(marks, queuedMarker.ticker)
			-- Check for first time notifications when displaying marks
			checkAndShowFirstTimeNotifications(marks, highlighted)
		end
		queuedMarker.ticker = queuedMarker.ticker + time_delta
	end

	if queuedPreviewMarks[STATE_QUEUED_FINAL_EFFECT] then
		for pawnId, marks in pairs(queuedPreviewMarks[STATE_QUEUED_FINAL_EFFECT]) do
			consolidateGroupedAnimations(marks, STATE_QUEUED_FINAL_EFFECT)
			markSpaces(marks, queuedFinalEffectMarker.ticker)
			-- Check for first time notifications when displaying marks
			checkAndShowFirstTimeNotifications(marks, highlighted)
		end
		queuedFinalEffectMarker.ticker = queuedFinalEffectMarker.ticker + time_delta
	end
	-- Check every frame if the key is pressed and show tooltip for highlighted tile
	checkAndShowTooltipKey(highlighted)
end

local function onQueuedSkillEnd(pawn, state)
	if pawn then
		local pawnId = pawn:GetId()
		if queuedPreviewMarks[state] and queuedPreviewMarks[state][pawnId] then
			queuedPreviewMarks[state][pawnId] = nil
		end
	end
end

local function overrideAllSkillMethods()
	local skills = {}
	for skillId, skill in pairs(_G) do
		if type(skill) == 'table' then
			skills[skillId] = skill
		end
	end

	for skillId, skill in pairs(skills) do
		if type(skill.GetTargetArea) == 'function' then
			oldGetTargetAreas[skillId] = skill.GetTargetArea
			skill.__Id = skillId
		end
		if type(skill.GetSecondTargetArea) == 'function' then
			oldGetSecondTargetAreas[skillId] = skill.GetSecondTargetArea
			skill.__Id = skillId
		end
		if type(skill.GetSkillEffect) == 'function' then
			oldGetSkillEffects[skillId] = skill.GetSkillEffect
			skill.__Id = skillId
		end
		if type(skill.GetFinalEffect) == 'function' then
			oldGetFinalEffects[skillId] = skill.GetFinalEffect
			skill.__Id = skillId
		end
		if type(skill.GetTargetScore) == 'function' then
			oldGetTargetScores[skillId] = skill.GetTargetScore
			skill.__Id = skillId
		end
	end

	for skillId, _ in pairs(oldGetTargetAreas) do
		local skill = _G[skillId]

		function skill.GetTargetArea(...)
			getTargetAreaCallers[#getTargetAreaCallers + 1] = skillId

			local result = getTargetArea(...)

			getTargetAreaCallers[#getTargetAreaCallers] = nil

			return result
		end
	end

	for skillId, _ in pairs(oldGetSecondTargetAreas) do
		local skill = _G[skillId]

		function skill.GetSecondTargetArea(...)
			getSecondTargetAreaCallers[#getSecondTargetAreaCallers + 1] = skillId

			local result = getSecondTargetArea(...)

			getSecondTargetAreaCallers[#getSecondTargetAreaCallers] = nil

			return result
		end
	end

	for skillId, _ in pairs(oldGetSkillEffects) do
		local skill = _G[skillId]

		function skill.GetSkillEffect(...)
			getSkillEffectCallers[#getSkillEffectCallers + 1] = skillId

			local result = getSkillEffect(...)

			getSkillEffectCallers[#getSkillEffectCallers] = nil

			return result
		end
	end

	for skillId, _ in pairs(oldGetFinalEffects) do
		local skill = _G[skillId]

		function skill.GetFinalEffect(...)
			getFinalEffectCallers[#getFinalEffectCallers + 1] = skillId

			local result = getFinalEffect(...)

			getFinalEffectCallers[#getFinalEffectCallers] = nil

			return result
		end
	end

	for skillId, _ in pairs(oldGetTargetScores) do
		local skill = _G[skillId]
		local oldGetTargetScore = oldGetTargetScores[skillId]

		function skill.GetTargetScore(...)
			isScoring = true
			local result = oldGetTargetScore(...)
			isScoring = false
			return result
		end
	end
end

local path = GetParentPath(...)

local function initTutorialTips()
	tutorialTips = require(path .. "tutorialTips")

	-- Add tutorial tips
	tutorialTips:Add{
		id = "WeaponPreview_MultiIconNotification",
		title = "Multi-Icon Indicator",
		text = "This icon indicates multiple effects are active on this tile.",
	}

	tutorialTips:Add{
		id = "WeaponPreview_DescriptionNotification",
		title = "Extra Effects Preview Tips",
		text = "Hold " .. TOOLTIP_KEY_TEXT .. " while hovering to see detailed information (if available) about the effects.",
	}
end

local function initMultiIcon()
	DEFAULT_MULTI_ICON = "weaponPreview_icon_multihit"
	local DEFAULT_MULTI_ICON_IMG = DEFAULT_MULTI_ICON .. "_glow.png"
	modApi:appendAsset("img/combat/icons/" .. DEFAULT_MULTI_ICON_IMG, path.."/"..DEFAULT_MULTI_ICON_IMG)
	ANIMS[DEFAULT_MULTI_ICON] = ANIMS.Animation:new{
		Image = "combat/icons/".. DEFAULT_MULTI_ICON .. "_glow.png",
		NumFrames = 1,
		Time = 1,
		Loop = true,
	}
	createAnim(DEFAULT_MULTI_ICON)
	DEFAULT_MULTI_ICON_MARK_DATA = {
		duration = sum(ANIMS[PREFIX_ANIM..DEFAULT_MULTI_ICON].__Lengths),
		delay = nil,
		loop = true
	}
end

local function initGlobals()
	clearMarks()
	queuedPreviewMarks = {}

	actingMarker = Marker()
	targetMarker = Marker()
	secondTargetMarker = Marker()
	effectMarker = Marker()
	finalEffectMarker = Marker()
	queuedMarker = Marker()
	queuedFinalEffectMarker = Marker()

	events.onTargetAreaShown = Event()
	events.onTargetAreaHidden = Event()
	events.onSecondTargetAreaShown = Event()
	events.onSecondTargetAreaHidden = Event()
	events.onSkillEffectShown = Event()
	events.onSkillEffectHidden = Event()
	events.onFinalEffectShown = Event()
	events.onFinalEffectHidden = Event()
	events.onQueuedSkillEffectShown = Event()
	events.onQueuedSkillEffectHidden = Event()
	events.onQueuedFinalEffectShown = Event()
	events.onQueuedFinalEffectHidden = Event()

	initMultiIcon()
end

local function onModsInitialized()
	if VERSION < WeaponPreview.version then
		return
	end

	if WeaponPreview.initialized then
		return
	end

	WeaponPreview:finalizeInit()
	WeaponPreview.initialized = true
end

modApi.events.onModsInitialized:subscribe(onModsInitialized)


local isNewestVersion = false
	or WeaponPreview == nil
	or modApi:isVersion(VERSION, WeaponPreview.version) == false

if isNewestVersion then
	WeaponPreview = WeaponPreview or {}
	WeaponPreview.version = VERSION

	function WeaponPreview:finalizeInit()
		overrideAllSkillMethods()
		initGlobals()
		initTutorialTips()

		WeaponPreview.AddAnimation = addAnimation
		WeaponPreview.AddColor = addColor
		WeaponPreview.AddDamage = addDamage
		WeaponPreview.AddDelay = addDelay
		WeaponPreview.AddDesc = addDesc
		WeaponPreview.AddEmitter = addEmitter
		WeaponPreview.AddFlashing = addFlashing
		WeaponPreview.AddImage = addImage
		WeaponPreview.AddSimpleColor = addSimpleColor
		WeaponPreview.AddFunction = addFunction
		WeaponPreview.ClearMarks = clearMarks
		WeaponPreview.RegisterGroup = registerGroup
		WeaponPreview.GetGroupData = getGroupData
		WeaponPreview.GetQueuedSkillEffectMarker = getQueuedMarker
		WeaponPreview.GetQueuedFinalEffectMarker = getQueuedFinalEffectMarker
		WeaponPreview.GetSkillEffectMarker = getEffectMarker
		WeaponPreview.GetFinalEffectMarker = getFinalEffectMarker
		WeaponPreview.GetTargetAreaMarker = getTargetMarker
		WeaponPreview.GetSecondTargetAreaMarker = getSecondTargetMarker
		WeaponPreview.IsQueuedSkillEffectMarker = isQueuedMarker
		WeaponPreview.IsQueuedFinalEffectMarker = isQueuedFinalEffectMarker
		WeaponPreview.IsSkillEffectMarker = isEffectMarker
		WeaponPreview.IsFinalEffectMarker = isFinalEffectMarker
		WeaponPreview.IsTargetAreaMarker = isTargetMarker
		WeaponPreview.IsSecondTargetAreaMarker = isSecondTargetMarker
		WeaponPreview.ResetQueuedSkillEffectTimer = resetQueuedTimer
		WeaponPreview.ResetQueuedFinalEffectTimer = resetQueuedFinalEffectTimer
		WeaponPreview.ResetSkillEffectTimer = resetEffectTimer
		WeaponPreview.ResetFinalEffectTimer = resetFinalEffectTimer
		WeaponPreview.ResetTargetAreaTimer = resetTargetTimer
		WeaponPreview.ResetSecondTargetAreaTimer = resetSecondTargetTimer
		WeaponPreview.SetLooping = setLooping
		WeaponPreview.ExecuteWithState = executeWithState
		WeaponPreview.STATE_NONE = STATE_NONE
		WeaponPreview.STATE_SKILL_EFFECT = STATE_SKILL_EFFECT
		WeaponPreview.STATE_TARGET_AREA = STATE_TARGET_AREA
		WeaponPreview.STATE_QUEUED_SKILL = STATE_QUEUED_SKILL
		WeaponPreview.STATE_SECOND_TARGET_AREA = STATE_SECOND_TARGET_AREA
		WeaponPreview.STATE_FINAL_EFFECT = STATE_FINAL_EFFECT
		WeaponPreview.STATE_QUEUED_FINAL_EFFECT = STATE_QUEUED_FINAL_EFFECT
		WeaponPreview.DEFAULT_MULTI_ICON = DEFAULT_MULTI_ICON

		WeaponPreview.events = events

		modApi.events.onMissionChanged:subscribe(onMissionChanged)
		modApi.events.onMissionUpdate:subscribe(onMissionUpdate)

		-- Clear queued marks when queued actions execute
		modapiext.events.onQueuedSkillEnd:subscribe(function(mission, pawn, weaponId) onQueuedSkillEnd(pawn, STATE_QUEUED_SKILL) end)
		modapiext.events.onQueuedFinalEffectEnd:subscribe(function(mission, pawn, weaponId) onQueuedSkillEnd(pawn, STATE_QUEUED_FINAL_EFFECT) end)

		-- Track the key state for tooltip display
		modApi.events.onKeyPressed:subscribe(function(keycode)
			if keycode == TOOLTIP_KEY then
				isTooltipKeyHeld = true
			end
		end)

		modApi.events.onKeyReleased:subscribe(function(keycode)
			if keycode == TOOLTIP_KEY then
				isTooltipKeyHeld = false
			end
		end)
	end
end

return WeaponPreview
