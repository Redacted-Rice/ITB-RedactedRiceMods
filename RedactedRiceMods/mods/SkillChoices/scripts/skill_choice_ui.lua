-- Level-up skill choice UI
-- Shows a non-dismissible dialog when a pilot levels up so the player can pick a skill.

local skill_choice_ui = {}

skill_choice_ui.DEBUG = false

local logger = memhack.logger
local LOG_ID = logger.register("SkillChoices", "UI", skill_choice_ui.DEBUG)
skill_choice_ui.LOG_ID = LOG_ID

local PENDING_SELECTION_SKILL_ID = "SkillChoices_PendingSelection"

local PAUSE_ANIM_ID = "sc_skillchoices_pause"
local PAUSE_ANIM_IMAGE = "effects/sc_skillchoices_pause.png"
local PAUSE_ANIM_DURATION = 0.05
local OPEN_CLOSE_DELAY_MS = 500

local pendingQueue = {}
local dialogOpen = false
local activeDialogEntry = nil
local pausingForSelection = false
local pauseAnimRegistered = false
local deferredSkillIds = {}

local ROW_HEIGHT = 45
local GRID_GAP = 8
local GRID_PADDING = 4

-- TODO: Consider what I want these to actually be
local DIALOG_MIN_WIDTH = 900
local DIALOG_MAX_WIDTH = 1080
local DIALOG_WIDTH_PCT = 0.70
local DIALOG_MIN_HEIGHT = 600
local DIALOG_MAX_HEIGHT = 1200
local DIALOG_HEIGHT_PCT = 0.80

local SKILL_LIST_VGAP = 10
local PROMPT_BOTTOM_GAP = 10
local HEADER_INNER_GAP = 10
local TEXT_HEIGHT = 20
local PORTRAIT_SIZE = 130
local PORTRAIT_COLUMN_WIDTH = PORTRAIT_SIZE
local PROMPT_CHAR_WRAP = 100

local SKILL_ICON_SCALE = 2
local SKILL_ICON_OUTLINE = 1
local SKILL_ICON_SPACING = 3

local surfaceCache = {}

function skill_choice_ui:ensureGameStorage()
	if not GAME then
		return nil
	end
	GAME.redactedrice_SkillChoices = GAME.redactedrice_SkillChoices or {}
	GAME.redactedrice_SkillChoices.deferredSkills = GAME.redactedrice_SkillChoices.deferredSkills or {}
	return GAME.redactedrice_SkillChoices.deferredSkills
end

function skill_choice_ui:storeDeferredSkill(pilotId, slotIndex, skillId)
	if not deferredSkillIds[pilotId] then
		deferredSkillIds[pilotId] = {}
	end
	deferredSkillIds[pilotId][slotIndex] = skillId

	local gameDeferred = self:ensureGameStorage()
	if gameDeferred then
		if not gameDeferred[pilotId] then
			gameDeferred[pilotId] = {}
		end
		gameDeferred[pilotId][slotIndex] = skillId
	end
end

function skill_choice_ui:getStoredSkillId(pilot, slotIndex)
	local pilotId = pilot:getIdStr()
	local pilotDeferred = deferredSkillIds[pilotId]
	if pilotDeferred and pilotDeferred[slotIndex] then
		return pilotDeferred[slotIndex]
	end

	local gameDeferred = self:ensureGameStorage()
	if gameDeferred and gameDeferred[pilotId] and gameDeferred[pilotId][slotIndex] then
		return gameDeferred[pilotId][slotIndex]
	end

	return nil
end

function skill_choice_ui:isValidChoiceSkillId(skillId)
	if not skillId or skillId == "" then
		return false
	end
	if cplus_plus_ex:isInternalSkill(skillId) then
		return false
	end
	if not cplus_plus_ex:getRegisteredSkillInfo(skillId) then
		return false
	end
	if not cplus_plus_ex:isSkillEnabled(skillId) then
		return false
	end
	return true
end

function skill_choice_ui:clearInvalidStoredSkill(pilot, slotIndex)
	local stored = self:getStoredSkillId(pilot, slotIndex)
	if stored and not self:isValidChoiceSkillId(stored) then
		logger.logWarn(LOG_ID, "clearInvalidStoredSkill pilot=%s slot=%d skill=%s",
			pilot:getIdStr(), slotIndex, tostring(stored))
		self:clearStoredSkill(pilot, slotIndex)
		return true
	end
	return false
end

function skill_choice_ui:getValidStoredSkillId(pilot, slotIndex)
	self:clearInvalidStoredSkill(pilot, slotIndex)
	return self:getStoredSkillId(pilot, slotIndex)
end

function skill_choice_ui:filterValidChoiceSkillIds(skillIds)
	local filtered = {}
	for _, skillId in ipairs(skillIds) do
		if self:isValidChoiceSkillId(skillId) then
			table.insert(filtered, skillId)
		end
	end
	return filtered
end

function skill_choice_ui:clearStoredSkill(pilot, slotIndex)
	local pilotId = pilot:getIdStr()
	if deferredSkillIds[pilotId] then
		deferredSkillIds[pilotId][slotIndex] = nil
		if next(deferredSkillIds[pilotId]) == nil then
			deferredSkillIds[pilotId] = nil
		end
	end
	local gameDeferred = self:ensureGameStorage()
	if gameDeferred and gameDeferred[pilotId] then
		gameDeferred[pilotId][slotIndex] = nil
		if next(gameDeferred[pilotId]) == nil then
			gameDeferred[pilotId] = nil
		end
	end
end

function skill_choice_ui:clearAllStoredSkills()
	deferredSkillIds = {}
	if GAME and GAME.redactedrice_SkillChoices then
		GAME.redactedrice_SkillChoices.deferredSkills = {}
	end
end

function skill_choice_ui:deferSkillForChoice(pilot, slotIndex, skillId)
	local pilotId = pilot:getIdStr()
	skillId = skillId or self:getResolvedSlotSkillId(pilot, slotIndex)

	if not self:isValidChoiceSkillId(skillId) then
		logger.logWarn(LOG_ID, "deferSkillForChoice skip pilot=%s slot=%d: invalid or internal skill",
			pilotId, slotIndex)
		return false
	end

	if self:getValidStoredSkillId(pilot, slotIndex) then
		return false
	end

	self:storeDeferredSkill(pilotId, slotIndex, skillId)
	local skillIds = self:getPilotSlotSkillIds(pilot)
	skillIds[slotIndex] = PENDING_SELECTION_SKILL_ID
	return cplus_plus_ex:applySkillIdsToPilot(pilot, skillIds, false)
end

function skill_choice_ui:getPilotSlotSkillIds(pilot)
	return {
		pilot:getLvlUpSkill(1):getIdStr(),
		pilot:getLvlUpSkill(2):getIdStr(),
	}
end

function skill_choice_ui:getResolvedSlotSkillId(pilot, slotIndex)
	local memId = pilot:getLvlUpSkill(slotIndex):getIdStr()
	if cplus_plus_ex:isInternalSkill(memId) then
		-- Rolled skill is stashed; slot is awaiting player choice.
		return nil
	end

	local stored = self:getValidStoredSkillId(pilot, slotIndex)
	if stored then
		return stored
	end

	if self:isValidChoiceSkillId(memId) then
		return memId
	end

	return nil
end

function skill_choice_ui:resolveSlotSkillForApply(pilot, slotIndex)
	local resolved = self:getResolvedSlotSkillId(pilot, slotIndex)
	if resolved then
		return resolved
	end

	local memId = pilot:getLvlUpSkill(slotIndex):getIdStr()
	if not memId or memId == "" or cplus_plus_ex:isInternalSkill(memId) then
		return nil
	end

	return memId
end

function skill_choice_ui:getDisplayEarnedSkillIds(pilot, excludeSlotIndexes)
	local skillIds = {}

	for _, skillIndex in ipairs(cplus_plus_ex:getPilotEarnedSkillIndexes(pilot, excludeSlotIndexes)) do
		if skillIndex <= cplus_plus_ex.MAX_SKILL_SLOTS then
			local resolvedId = self:getResolvedSlotSkillId(pilot, skillIndex)
			if resolvedId and not cplus_plus_ex:isInternalSkill(resolvedId) then
				table.insert(skillIds, resolvedId)
			end
		else
			local virtualSkills = cplus_plus_ex:getVirtualSkills(pilot:getIdStr())
			local virtIndex = skillIndex - cplus_plus_ex.MAX_SKILL_SLOTS
			local virtualId = virtualSkills[virtIndex]
			if virtualId and virtualId ~= "" then
				table.insert(skillIds, virtualId)
			end
		end
	end

	return skillIds
end

function skill_choice_ui:sortSkillIdsForDisplay(skillIds)
	table.sort(skillIds, function(a, b)
		local nameA = self:getSkillDisplayInfo(a).shortName:lower()
		local nameB = self:getSkillDisplayInfo(b).shortName:lower()
		if nameA ~= nameB then
			return nameA < nameB
		end
		return a < b
	end)
	return skillIds
end

function skill_choice_ui:buildConstraintContext(pilot, slotIndex)
	local selectedSkills = {}

	if slotIndex == 2 then
		selectedSkills[1] = self:getResolvedSlotSkillId(pilot, 1)
	elseif slotIndex == 1 then
		selectedSkills[2] = self:getResolvedSlotSkillId(pilot, 2)
	end

	for virtIndex, skillId in ipairs(cplus_plus_ex:getVirtualSkills(pilot:getIdStr())) do
		selectedSkills[cplus_plus_ex.MAX_SKILL_SLOTS + virtIndex] = skillId
	end
	return selectedSkills
end

local function removeFromPool(pool, skillId)
	for i, id in ipairs(pool) do
		if id == skillId then
			table.remove(pool, i)
			return
		end
	end
end

-- Returns all enabled skills that pass constraints for this pilot and slot.
function skill_choice_ui:buildAllValidChoices(pilot, slotIndex)
	local selectedSkills = self:buildConstraintContext(pilot, slotIndex)
	local choices = {}

	for _, skillId in ipairs(cplus_plus_ex:getAssignableSkillIds()) do
		if cplus_plus_ex:checkSkillConstraints(pilot, selectedSkills, skillId) then
			table.insert(choices, skillId)
		end
	end

	return choices
end

-- Returns up to `count` distinct valid choices, or fewer when not enough skills exist.
-- The pre-assigned skill is always included. When count is "all", returns every
-- enabled non-conflicting skill.
function skill_choice_ui:generateChoices(pilot, slotIndex, count)
	logger.logDebug(LOG_ID, "generateChoices pilot=%s slot=%d count=%s stored=%s",
		pilot:getIdStr(),
		slotIndex,
		tostring(count),
		tostring(self:getValidStoredSkillId(pilot, slotIndex)))

	if count == "all" then
		local choices = self:filterValidChoiceSkillIds(self:buildAllValidChoices(pilot, slotIndex))
		logger.logDebug(LOG_ID, "generateChoices all mode: %d choices", #choices)
		return choices
	end

	local selectedSkills = self:buildConstraintContext(pilot, slotIndex)
	local pool = cplus_plus_ex:getAssignableSkillIds()
	local choices = {}

	local preAssigned = self:getValidStoredSkillId(pilot, slotIndex)
		or self:getResolvedSlotSkillId(pilot, slotIndex)
	if preAssigned and cplus_plus_ex:checkSkillConstraints(pilot, selectedSkills, preAssigned) then
		table.insert(choices, preAssigned)
		removeFromPool(pool, preAssigned)
	end

	while #choices < count do
		local skillId = cplus_plus_ex:selectRandomSkill(pool, pilot, nil, selectedSkills)
		if not skillId then
			break
		end
		table.insert(choices, skillId)
		removeFromPool(pool, skillId)
	end

	logger.logDebug(LOG_ID, "generateChoices pilot=%s slot=%d result=[%s]",
		pilot:getIdStr(), slotIndex, table.concat(choices, ", "))
	return self:filterValidChoiceSkillIds(choices)
end

function skill_choice_ui:getCachedSurface(path)
	if not surfaceCache[path] then
		surfaceCache[path] = sdlext.getSurface({ path = path })
	end
	return surfaceCache[path]
end

function skill_choice_ui:hasDisplayableIcon(iconPath)
	return iconPath and iconPath ~= "" and self:getCachedSurface(iconPath) ~= nil
end

function skill_choice_ui:getSkillDisplayInfo(skillId)
	local skill = cplus_plus_ex:getRegisteredSkillInfo(skillId)
	if not skill then
		return {
			shortName = skillId,
			fullName = skillId,
			description = "",
			icon = nil,
		}
	end

	local shortName = GetText(skill.shortName) or skill.shortName or skillId
	local fullName = GetText(skill.fullName) or skill.fullName or shortName
	local description = GetText(skill.description) or skill.description or ""
	return {
		shortName = shortName,
		fullName = fullName,
		description = description,
		icon = skill.icon,
	}
end

function skill_choice_ui:setSkillTooltip(widget, skillInfo)
	if skillInfo.description ~= "" then
		widget:settooltip(skillInfo.description, skillInfo.fullName)
	else
		widget:settooltip("")
	end
end

function skill_choice_ui:enableSkillHover(widget, skillInfo)
	self:setSkillTooltip(widget, skillInfo)
	widget.translucent = false
	widget.onclicked = function(_, button)
		return button == 1
	end
end

function skill_choice_ui:getDisplayIconSurface(iconPath)
	local surface = self:getCachedSurface(iconPath)
	if not surface then
		return nil
	end

	return sdl.scaled(
		SKILL_ICON_SCALE,
		sdl.outlined(surface, SKILL_ICON_OUTLINE, deco.colors.buttonborder)
	)
end

function skill_choice_ui:buildSkillRowDecorations(style, skillInfo, decoText)
	local decorations = {}

	if style == "selected" then
		table.insert(decorations, DecoSolid(deco.colors.buttonhl))
	elseif style == "display" then
		table.insert(decorations, DecoFrame())
	else
		table.insert(decorations, DecoButton())
	end

	table.insert(decorations, DecoAlign(2, 0))

	if self:hasDisplayableIcon(skillInfo.icon) then
		table.insert(decorations, DecoAlign(SKILL_ICON_SPACING, 0))
		if style == "display" then
			local iconSurface = self:getDisplayIconSurface(skillInfo.icon)
			if iconSurface then
				table.insert(decorations, DecoSurface(iconSurface))
			end
		else
			local surface = self:getCachedSurface(skillInfo.icon)
			table.insert(decorations, DecoSurfaceOutlined(surface, SKILL_ICON_OUTLINE, nil, nil, SKILL_ICON_SCALE))
		end
		table.insert(decorations, DecoAlign(SKILL_ICON_SPACING, 0))
	end

	table.insert(decorations, DecoAlign(0, 2))
	table.insert(decorations, decoText)

	return decorations
end

function skill_choice_ui:buildSkillRowText(skillInfo)
	return DecoText(skillInfo.shortName)
end

function skill_choice_ui:calcHeaderHeight(earnedSkillCount)
	local portraitHeight = PORTRAIT_SIZE + 8

	if earnedSkillCount == 0 then
		return math.max(portraitHeight, TEXT_HEIGHT + ROW_HEIGHT)
	end

	local skillsHeight = TEXT_HEIGHT + GRID_PADDING * 2
		+ earnedSkillCount * ROW_HEIGHT
		+ math.max(0, earnedSkillCount - 1) * GRID_GAP

	return math.max(portraitHeight, skillsHeight) + 8
end

function skill_choice_ui:buildWrappedText(parent, text, font, textset)
	local wrapped = UiWrappedText(text, font, textset)
		:width(1)
		:padding(GRID_PADDING)
		:addTo(parent)

	wrapped.limit = PROMPT_CHAR_WRAP
	wrapped:rebuild()
	return wrapped
end

function skill_choice_ui:buildSectionDivider(parent)
	Ui()
		:width(1)
		:heightpx(2)
		:decorate({ DecoSolid(deco.colors.buttonborder) })
		:addTo(parent)
end

function skill_choice_ui:buildSkillRowsLayout(parent, skillIds, itemBuilder)
	if #skillIds == 0 then
		return nil
	end

	local sortedSkillIds = {}
	for _, skillId in ipairs(skillIds) do
		table.insert(sortedSkillIds, skillId)
	end
	self:sortSkillIdsForDisplay(sortedSkillIds)

	local container = UiBoxLayout()
		:width(1)
		:vgap(GRID_GAP)
		:padding(GRID_PADDING)
		:addTo(parent)

	for _, skillId in ipairs(sortedSkillIds) do
		itemBuilder(container, skillId)
	end

	return container
end

function skill_choice_ui:buildSkillUi(parent, skillId)
	local skillInfo = self:getSkillDisplayInfo(skillId)
	local decoText = self:buildSkillRowText(skillInfo)

	local skill = Ui()
		:width(1)
		:heightpx(ROW_HEIGHT)
		:decorate(self:buildSkillRowDecorations("display", skillInfo, decoText))
		:addTo(parent)

	self:enableSkillHover(skill, skillInfo)
	return skill
end

function skill_choice_ui:buildSkillDisplayLayout(parent, skillIds)
	if #skillIds == 0 then
		self:buildWrappedText(
			parent,
			"No earned skills yet.",
			deco.uifont.tooltipText.font,
			deco.uifont.tooltipText.set
		)
		return nil
	end

	return self:buildSkillRowsLayout(parent, skillIds, function(container, skillId)
		self:buildSkillUi(container, skillId)
	end)
end

function skill_choice_ui:buildPilotNameSection(parent, session)
	Ui()
		:width(1)
		:heightpx(TEXT_HEIGHT)
		:decorate({
			DecoText(
				cplus_plus_ex:getPilotDisplayName(session.pilot)
			),
		})
		:addTo(parent)
end

function skill_choice_ui:buildHeaderSection(parent, session)
	local earnedSkillIds = self:getDisplayEarnedSkillIds(session.pilot, {session.slotIndex})
	local headerHeight = self:calcHeaderHeight(#earnedSkillIds)

	local headerRow = UiWeightLayout()
		:width(1)
		:heightpx(headerHeight)
		:hgap(HEADER_INNER_GAP)
		:addTo(parent)

	local portraitColumn = UiBoxLayout()
		:widthpx(PORTRAIT_COLUMN_WIDTH)
		:addTo(headerRow)

	local portraitSurface = cplus_plus_ex:getPilotPortraitSurface(session.pilot)
	local portraitDecorations = { DecoFrame(), DecoAlign(0, 0) }
	if portraitSurface then
		table.insert(portraitDecorations, DecoSurface(portraitSurface))
	end

	Ui()
		:widthpx(PORTRAIT_SIZE)
		:heightpx(PORTRAIT_SIZE)
		:decorate(portraitDecorations)
		:addTo(portraitColumn)

	local skillsColumn = UiBoxLayout()
		:width(1)
		:vgap(6)
		:addTo(headerRow)

	Ui()
		:width(1)
		:heightpx(TEXT_HEIGHT)
		:decorate({ DecoText("Current Skills") })
		:addTo(skillsColumn)

	self:buildSkillDisplayLayout(skillsColumn, earnedSkillIds)
end

function skill_choice_ui:applyChosenSkill(pilot, slotIndex, skillId)
	if not self:isValidChoiceSkillId(skillId) then
		logger.logWarn(LOG_ID, "applyChosenSkill skip pilot=%s slot=%d: invalid skill=%s",
			pilot:getIdStr(), slotIndex, tostring(skillId))
		return false
	end

	local skill1 = slotIndex == 1 and skillId or self:resolveSlotSkillForApply(pilot, 1)
	local skill2 = slotIndex == 2 and skillId or self:resolveSlotSkillForApply(pilot, 2)
	if not skill1 or not skill2 then
		logger.logWarn(LOG_ID, "applyChosenSkill skip pilot=%s slot=%d: unresolved slots [%s, %s]",
			pilot:getIdStr(), slotIndex, tostring(skill1), tostring(skill2))
		return false
	end

	self:clearStoredSkill(pilot, slotIndex)
	cplus_plus_ex:applySkillIdsToPilot(pilot, { skill1, skill2 }, true)
	return true
end

function skill_choice_ui:applySkillButtonStyle(btn, selected)
	local style = selected and "selected" or "default"
	btn:decorate(self:buildSkillRowDecorations(style, btn._skillInfo, btn._decoText))
end

function skill_choice_ui:onSkillOptionClicked(session, btn, skillId)
	logger.logDebug(LOG_ID, "onSkillOptionClicked pilot=%s slot=%d skill=%s",
		session.pilot:getIdStr(), session.slotIndex, skillId)
	session.selectedSkillId = skillId
	for _, skillBtn in ipairs(session.skillButtons) do
		self:applySkillButtonStyle(skillBtn, skillBtn == btn)
	end
	if session.confirmButton then
		session.confirmButton.disabled = false
	end
end

function skill_choice_ui:buildSkillOptionButton(parent, skillId, session)
	local skillInfo = self:getSkillDisplayInfo(skillId)
	local decoText = self:buildSkillRowText(skillInfo)

	local btn = Ui()
		:width(1)
		:heightpx(ROW_HEIGHT)
		:decorate(self:buildSkillRowDecorations("default", skillInfo, decoText))
		:addTo(parent)

	btn._decoText = decoText
	btn._skillInfo = skillInfo
	btn._skillId = skillId
	self:setSkillTooltip(btn, skillInfo)

	sdlext.addButtonSoundHandlers(btn, function()
		self:onSkillOptionClicked(session, btn, skillId)
	end)

	table.insert(session.skillButtons, btn)
	return btn
end

function skill_choice_ui:buildChoicesLayout(parent, session)
	return self:buildSkillRowsLayout(parent, session.choices, function(container, skillId)
		self:buildSkillOptionButton(container, skillId, session)
	end)
end

function skill_choice_ui:buildDialogButtons(buttonLayout, session)
	local confirmBtn = sdlext.buildButton("Confirm", "Choose the selected skill", function()
		self:onConfirmClicked(session)
	end)
	confirmBtn.disabled = true
	confirmBtn:addTo(buttonLayout)
	session.confirmButton = confirmBtn
end

function skill_choice_ui:createDialogSession(entry, onComplete)
	local choiceCount = self.config_options.skill_choice_count
	self:clearInvalidStoredSkill(entry.pilot, entry.slotIndex)

	return {
		pilot = entry.pilot,
		slotIndex = entry.slotIndex,
		choices = self:generateChoices(entry.pilot, entry.slotIndex, choiceCount),
		onComplete = onComplete,
		selectedSkillId = nil,
		skillButtons = {},
		confirmButton = nil,
		quit = nil,
	}
end

function skill_choice_ui:pickFallbackChoice(pilot, slotIndex)
	local selectedSkills = self:buildConstraintContext(pilot, slotIndex)
	return cplus_plus_ex:selectRandomSkill(
		cplus_plus_ex:getAssignableSkillIds(),
		pilot,
		slotIndex,
		selectedSkills
	)
end

function skill_choice_ui:getDialogPrompt(session)
	return string.format(
		"Choose a level %d skill. Select an option, then click Confirm.",
		session.slotIndex
	)
end

function skill_choice_ui:getDialogFrameOptions()
	return {
		minW = DIALOG_MIN_WIDTH,
		maxW = math.min(DIALOG_MAX_WIDTH, DIALOG_WIDTH_PCT * ScreenSizeX()),
		minH = DIALOG_MIN_HEIGHT,
		maxH = math.min(DIALOG_MAX_HEIGHT, DIALOG_HEIGHT_PCT * ScreenSizeY()),
		compactH = false,
	}
end

function skill_choice_ui:buildDialogPrompt(parent, session)
	self:buildWrappedText(
		parent,
		self:getDialogPrompt(session),
		deco.uifont.tooltipTextLarge.font,
		deco.uifont.tooltipTextLarge.set
	)
end

function skill_choice_ui:buildSelectionSection(parent, session)
	local section = UiBoxLayout()
		:width(1)
		:vgap(PROMPT_BOTTOM_GAP)
		:addTo(parent)

	self:buildDialogPrompt(section, session)
	self:buildChoicesLayout(section, session)
end

function skill_choice_ui:buildDialogContent(scroll, session)
	local scrollContent = UiBoxLayout()
		:width(1)
		:vgap(SKILL_LIST_VGAP)
		:addTo(scroll)

	self:buildPilotNameSection(scrollContent, session)
	self:buildHeaderSection(scrollContent, session)
	self:buildSectionDivider(scrollContent)
	self:buildSelectionSection(scrollContent, session)

	return scrollContent
end

function skill_choice_ui:onConfirmClicked(session)
	if not session.selectedSkillId or not session.quit then
		logger.logWarn(LOG_ID, "onConfirmClicked ignored: selected=%s quit=%s",
			tostring(session.selectedSkillId), tostring(session.quit ~= nil))
		return
	end

	logger.logDebug(LOG_ID, "onConfirmClicked pilot=%s slot=%d skill=%s",
		session.pilot:getIdStr(), session.slotIndex, session.selectedSkillId)
	self:applyChosenSkill(session.pilot, session.slotIndex, session.selectedSkillId)
	session.quit()
end

function skill_choice_ui:onDialogOpened(ui, session)
	ui.dismissible = false
	ui.onDialogExit = function()
		self:onDialogClosed(session)
	end

	local frame = sdlext.buildButtonDialog(
		"Pilot Leveled Up",
		function(scroll)
			return self:buildDialogContent(scroll, session)
		end,
		function(buttonLayout)
			self:buildDialogButtons(buttonLayout, session)
		end,
		self:getDialogFrameOptions()
	)

	frame
		:pospx((ui.w - frame.w) / 2, (ui.h - frame.h) / 2)
		:addTo(ui)
end

function skill_choice_ui:onDialogClosed(session)
	logger.logDebug(LOG_ID, "onDialogClosed pilot=%s slot=%d",
		session.pilot:getIdStr(), session.slotIndex)
	dialogOpen = false
	activeDialogEntry = nil
	if session.onComplete then
		session.onComplete()
	end
end

function skill_choice_ui:showDialog(entry, onComplete)
	local session = self:createDialogSession(entry, onComplete)

	logger.logDebug(LOG_ID, "showDialog pilot=%s slot=%d choiceCount=%d choices=[%s]",
		session.pilot:getIdStr(),
		session.slotIndex,
		#session.choices,
		table.concat(session.choices, ", "))

	if #session.choices == 0 then
		local fallback = self:pickFallbackChoice(session.pilot, session.slotIndex)
		logger.logWarn(LOG_ID, "showDialog no valid choices for pilot=%s slot=%d fallback=%s",
			session.pilot:getIdStr(), session.slotIndex, tostring(fallback))
		if fallback then
			self:applyChosenSkill(session.pilot, session.slotIndex, fallback)
		end
		if onComplete then
			onComplete()
		end
		return
	end

	if #session.choices == 1 then
		logger.logDebug(LOG_ID, "showDialog auto-applying only choice pilot=%s slot=%d skill=%s",
			session.pilot:getIdStr(), session.slotIndex, session.choices[1])
		if not self:applyChosenSkill(session.pilot, session.slotIndex, session.choices[1]) then
			local fallback = self:pickFallbackChoice(session.pilot, session.slotIndex)
			if fallback then
				self:applyChosenSkill(session.pilot, session.slotIndex, fallback)
			end
		end
		if onComplete then
			onComplete()
		end
		return
	end

	dialogOpen = true
	activeDialogEntry = {
		pilotId = session.pilot:getIdStr(),
		slotIndex = session.slotIndex,
	}
	logger.logDebug(LOG_ID, "showDialog opening UI pilot=%s slot=%d", session.pilot:getIdStr(), session.slotIndex)

	sdlext.showDialog(function(ui, quit)
		session.quit = quit
		self:onDialogOpened(ui, session)
	end)
end

function skill_choice_ui:processQueue()
	logger.logDebug(LOG_ID, "processQueue dialogOpen=%s pausingForSelection=%s queueLen=%d",
	tostring(dialogOpen), tostring(pausingForSelection), #pendingQueue)
	if dialogOpen then
		return
	end

	if #pendingQueue == 0 then
		modApi:scheduleHook(OPEN_CLOSE_DELAY_MS, function()
        		pausingForSelection = false
		end)
		return
	end

	local entry = table.remove(pendingQueue, 1)
	logger.logDebug(LOG_ID, "processQueue dequeue pilot=%s slot=%d remaining=%d",
		entry.pilot:getIdStr(), entry.slotIndex, #pendingQueue)
	self:showDialog(entry, function()
		self:processQueue()
	end)
end

function skill_choice_ui:isPilotSlotPending(pilot, slotIndex)
	local pilotId = pilot:getIdStr()
	if activeDialogEntry
		and activeDialogEntry.pilotId == pilotId
		and activeDialogEntry.slotIndex == slotIndex then
		return true
	end

	for _, entry in ipairs(pendingQueue) do
		if entry.pilot:getIdStr() == pilotId and entry.slotIndex == slotIndex then
			return true
		end
	end

	return false
end

function skill_choice_ui:enqueue(pilot, slotIndex)
	-- Due to some oddities with how options are stored, if we later enabled ext in a run
	-- that didn't have it, events won't get cleared and we can fire multiple times. To
	-- protect against this or other cases that might cause this, ensure we don't already
	-- have the event in the queue before adding it.
	if self:isPilotSlotPending(pilot, slotIndex) then
		logger.logDebug(LOG_ID, "enqueue skip duplicate pilot=%s slot=%d queueLen=%d",
			pilot:getIdStr(), slotIndex, #pendingQueue)
		return
	end

	logger.logDebug(LOG_ID, "enqueue pilot=%s slot=%d queueLen=%d",
		pilot:getIdStr(), slotIndex, #pendingQueue + 1)
	table.insert(pendingQueue, {
		pilot = pilot,
		slotIndex = slotIndex,
	})
	
	-- Delay it slightly
	pausingForSelection = true
	modApi:scheduleHook(OPEN_CLOSE_DELAY_MS, function()
		self:processQueue()
	end)
end

function skill_choice_ui:onPilotLevelChanged(pilot, changes)
	if not pilot or not changes or not changes.level then
		return
	end

	local newLevel = changes.level.new
	local oldLevel = changes.level.old
	if newLevel <= oldLevel or newLevel < 1 or newLevel > cplus_plus_ex.MAX_SKILL_SLOTS then
		return
	end

	if not self:getValidStoredSkillId(pilot, newLevel)
		and pilot:getLvlUpSkill(newLevel):getIdStr() ~= PENDING_SELECTION_SKILL_ID then
		local rolledSkillId = pilot:getLvlUpSkill(newLevel):getIdStr()
		if not self:deferSkillForChoice(pilot, newLevel, rolledSkillId) then
			logger.logWarn(LOG_ID, "defer failed pilot=%s slot=%d skill=%s",
				pilot:getIdStr(), newLevel, tostring(rolledSkillId))
		end
	end

	self:enqueue(pilot, newLevel)
end

function skill_choice_ui:clearPendingDialogs()
	logger.logDebug(LOG_ID, "clearPendingDialogs")
	pendingQueue = {}
	dialogOpen = false
	activeDialogEntry = nil
	pausingForSelection = false
	self:clearAllStoredSkills()
end

function skill_choice_ui:registerPauseAnimation()
	if pauseAnimRegistered then
		return
	end

	ANIMS[PAUSE_ANIM_ID] = ANIMS.Animation:new{
		Image = PAUSE_ANIM_IMAGE,
		NumFrames = 1,
		Time = PAUSE_ANIM_DURATION,
		Loop = false,
	}

	pauseAnimRegistered = true
end

-- Keeps the board busy by retriggering a hidden one-frame animation with FULL_DELAY.
function skill_choice_ui:retriggerBoardBusyHold()
	if not pausingForSelection or not Board or GetCurrentMission() == nil then
		return
	end
	Board:AddAnimation(Point(0, 0), PAUSE_ANIM_ID, FULL_DELAY)
end

function skill_choice_ui:load()
	self:registerPauseAnimation()

	memhack:addPilotChangedHook(function(pilot, changes)
		self:onPilotLevelChanged(pilot, changes)
	end, -100)

	modApi.events.onFrameDrawn:subscribe(function()
		self:retriggerBoardBusyHold()
	end)

	modApi.events.onGameExited:subscribe(function()
		self:clearPendingDialogs()
	end)

	modApi.events.onGameVictory:subscribe(function()
		self:clearPendingDialogs()
	end)
end

return skill_choice_ui
