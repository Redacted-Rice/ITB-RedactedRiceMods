-- Level-up skill choice UI
-- Shows a non-dismissible dialog when a pilot levels up so the player can pick a skill.

local skill_choice_ui = {}

local SUBMODULE = "SkillChoices"

local pendingQueue = {}
local dialogOpen = false

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

function skill_choice_ui:buildAvailableSkills()
	local availableSkills = {}
	local enabledSet = cplus_plus_ex:getEnabledSkillsSet()
	for skillId in pairs(enabledSet) do
		table.insert(availableSkills, skillId)
	end
	table.sort(availableSkills)
	return availableSkills
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
		selectedSkills[1] = pilot:getLvlUpSkill(1):getIdStr()
	elseif slotIndex == 1 then
		selectedSkills[2] = pilot:getLvlUpSkill(2):getIdStr()
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

	for _, skillId in ipairs(self:buildAvailableSkills()) do
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
	if count == "all" then
		return self:buildAllValidChoices(pilot, slotIndex)
	end

	local selectedSkills = self:buildConstraintContext(pilot, slotIndex)
	local pool = self:buildAvailableSkills()
	local choices = {}

	local preAssigned = pilot:getLvlUpSkill(slotIndex):getIdStr()
	table.insert(choices, preAssigned)
	removeFromPool(pool, preAssigned)

	while #choices < count do
		local skillId = cplus_plus_ex:selectRandomSkill(pool, pilot, nil, selectedSkills)
		if not skillId then
			break
		end
		table.insert(choices, skillId)
		removeFromPool(pool, skillId)
	end

	return choices
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
	local earnedSkillIds = cplus_plus_ex:getPilotEarnedSkillIds(session.pilot, {session.slotIndex})
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
	local skill1 = pilot:getLvlUpSkill(1):getIdStr()
	local skill2 = pilot:getLvlUpSkill(2):getIdStr()

	if slotIndex == 1 then
		skill1 = skillId
	else
		skill2 = skillId
	end

	cplus_plus_ex:applySkillIdsToPilot(pilot, { skill1, skill2 }, true)
end

function skill_choice_ui:applySkillButtonStyle(btn, selected)
	local style = selected and "selected" or "default"
	btn:decorate(self:buildSkillRowDecorations(style, btn._skillInfo, btn._decoText))
end

function skill_choice_ui:onSkillOptionClicked(session, btn, skillId)
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
		return
	end

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
	dialogOpen = false
	if session.onComplete then
		session.onComplete()
	end
end

function skill_choice_ui:showDialog(entry, onComplete)
	local session = self:createDialogSession(entry, onComplete)

	if #session.choices == 0 then
		LOG(SUBMODULE .. ": No valid skill choices for pilot " .. session.pilot:getIdStr() ..
			" at slot " .. session.slotIndex)
		if onComplete then
			onComplete()
		end
		return
	end

	dialogOpen = true

	sdlext.showDialog(function(ui, quit)
		session.quit = quit
		self:onDialogOpened(ui, session)
	end)
end

function skill_choice_ui:processQueue()
	if dialogOpen or #pendingQueue == 0 then
		return
	end

	local entry = table.remove(pendingQueue, 1)
	self:showDialog(entry, function()
		self:processQueue()
	end)
end

function skill_choice_ui:enqueue(pilot, slotIndex)
	table.insert(pendingQueue, {
		pilot = pilot,
		slotIndex = slotIndex,
	})
	self:processQueue()
end

function skill_choice_ui:onPilotLevelChanged(pilot, changes)
	if not changes or not changes.level then
		return
	end

	local newLevel = changes.level.new
	if newLevel <= changes.level.old or newLevel < 1 or newLevel > cplus_plus_ex.MAX_SKILL_SLOTS then
		return
	end
	self:enqueue(pilot, newLevel)
end

function skill_choice_ui:clearPendingDialogs()
	pendingQueue = {}
	dialogOpen = false
end

function skill_choice_ui:load()
	memhack:addPilotChangedHook(function(pilot, changes)
		self:onPilotLevelChanged(pilot, changes)
	end)

	modApi.events.onGameExited:subscribe(function()
		self:clearPendingDialogs()
	end)

	modApi.events.onGameVictory:subscribe(function()
		self:clearPendingDialogs()
	end)
end

return skill_choice_ui
