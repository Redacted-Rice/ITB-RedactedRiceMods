-- Level-up skill choice UI
-- Shows a non-dismissible dialog when a pilot levels up so the player can pick a skill.

local skill_choice_ui = {}

local SUBMODULE = "SkillChoices"

local mod = modApi:getCurrentMod()

local pendingQueue = {}
local dialogOpen = false

local ROW_HEIGHT = 45
local BUTTON_MIN_WIDTH = 220
local GRID_GAP = 8
local GRID_PADDING = 4

-- TODO: Just remove now that I have a scroll panel its not needed
local LIST_MAX_ITEMS = 100

-- TODO: Consider what I want these to actually be
local DIALOG_MIN_WIDTH = 540
local DIALOG_MAX_WIDTH = 960
local DIALOG_WIDTH_PCT = 0.70
local DIALOG_HEIGHT_PCT = 0.80

local SKILL_LIST_VGAP = 10
local PROMPT_BOTTOM_GAP = 10
local HEADER_INNER_GAP = 10
local PORTRAIT_SIZE = 130
local PORTRAIT_COLUMN_WIDTH = PORTRAIT_SIZE + 32
local PROMPT_CHAR_WRAP = 100

local SKILL_ICON_SCALE = 2
local SKILL_ICON_OUTLINE = 1
local SKILL_ICON_SPACING = 3

local ADVANCED_PILOTS = {
	"Pilot_Arrogant",
	"Pilot_Caretaker",
	"Pilot_Chemical",
	"Pilot_Delusional",
}

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

local function addChoiceAndRemoveFromPool(choices, value, pool)
	table.insert(choices, value)
	for i, id in ipairs(pool) do
		if id == value then
			table.remove(pool, i)
			return
		end
	end
end

-- Returns up to `count` distinct valid choices, or fewer when not enough skills exist.
-- First choice is always the pre-assigned skill for this slot
function skill_choice_ui:generateChoices(pilot, slotIndex, count)
	local selectedSkills = self:buildConstraintContext(pilot, slotIndex)
	local availableSkills = self:buildAvailableSkills()
	local pool = availableSkills
	local choices = {}
	local chosenSet = {}

	local preAssigned = pilot:getLvlUpSkill(slotIndex):getIdStr()
	addChoiceAndRemoveFromPool(choices, preAssigned, pool)

	local maxChoices = math.min(count, #availableSkills)
	while #choices < maxChoices do
		local skillId = cplus_plus_ex:selectRandomSkill(pool, pilot, nil, selectedSkills)
		if not skillId then
			break
		end
		addChoiceAndRemoveFromPool(choices, skillId, pool)
	end
	return choices
end

function skill_choice_ui:getLayoutColumnCount(itemCount)
	if itemCount <= LIST_MAX_ITEMS then
		return 1
	end
	return 2
end

function skill_choice_ui:getCachedSurface(path)
	if not surfaceCache[path] then
		surfaceCache[path] = sdlext.getSurface({ path = path })
	end
	return surfaceCache[path]
end

function skill_choice_ui:getIconDisplayWidth(iconPath)
	local surface = self:getCachedSurface(iconPath)
	if not surface then
		return 0
	end

	return surface:w() * SKILL_ICON_SCALE + (SKILL_ICON_OUTLINE * 2 * SKILL_ICON_SCALE)
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
	else -- default
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

function skill_choice_ui:calcSkillRowWidth(skillInfo, decoText, buttonWidth, fullWidth)
	if fullWidth then
		return nil
	end

	local textWidth = sdlext.totalWidth(decoText.surface)
	local iconWidth = 0

	if self:hasDisplayableIcon(skillInfo.icon) then
		iconWidth = SKILL_ICON_SPACING * 2 + self:getIconDisplayWidth(skillInfo.icon)
	end

	local contentWidth = textWidth + 40 + iconWidth
	return math.max(buttonWidth, contentWidth)
end

function skill_choice_ui:buildSkillRowText(skillInfo)
	return DecoText(skillInfo.shortName)
end

-- TODO: Consider having CPLUS+ fn for this
function skill_choice_ui:getPilotDisplayName(pilot)
	local nameKey = pilot:getName():get()
	return GetText(nameKey) or nameKey or pilot:getIdStr()
end

-- TODO: Consider having CPLUS+ fn for this
function skill_choice_ui:getPilotPortraitPath(pilotId)
	local pilotDef = _G[pilotId]
	if not pilotDef then
		return nil
	end

	local portrait = pilotDef.Portrait
	if portrait and portrait ~= "" then
		return "img/portraits/" .. portrait .. ".png"
	end

	local advanced = list_contains(ADVANCED_PILOTS, pilotId)
	local prefix = advanced and "img/advanced/portraits/pilots/" or "img/portraits/pilots/"
	return prefix .. pilotId .. ".png"
end

-- TODO: Consider having CPLUS+ fn for this
function skill_choice_ui:getPilotPortraitSurface(pilot)
	local path = self:getPilotPortraitPath(pilot:getIdStr())
	if not path then
		return nil
	end

	return sdlext.getSurface({
		path = path,
		scale = 2,
	})
end

-- TODO: Consider having CPLUS+ fn for this
function skill_choice_ui:getPilotEarnedSkillIds(pilot, excludeSlotIndex)
	local skillIds = {}
	local pilotLevel = pilot:getLevel()

	for skillIndex = 1, pilotLevel do
		if skillIndex ~= excludeSlotIndex then
			local skill = pilot:getLvlUpSkill(skillIndex)
			if skill then
				local skillId = skill:getIdStr()
				if skillId and skillId ~= "" then
					table.insert(skillIds, skillId)
				end
			end
		end
	end

	for _, skillId in ipairs(cplus_plus_ex:getVirtualSkills(pilot:getIdStr())) do
		if skillId and skillId ~= "" then
			table.insert(skillIds, skillId)
		end
	end

	return skillIds
end

function skill_choice_ui:calcHeaderHeight(earnedSkillCount)
	local portraitHeight = PORTRAIT_SIZE + 6 + 24

	if earnedSkillCount == 0 then
		return math.max(portraitHeight, 20 + ROW_HEIGHT)
	end

	local columnCount = self:getLayoutColumnCount(earnedSkillCount)
	local rows = math.ceil(earnedSkillCount / columnCount)
	local skillsHeight = 20 + GRID_PADDING * 2 + rows * ROW_HEIGHT + math.max(0, rows - 1) * GRID_GAP

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

	local columnCount = self:getLayoutColumnCount(#skillIds)
	local container = UiBoxLayout()
		:width(1)
		:vgap(GRID_GAP)
		:padding(GRID_PADDING)
		:addTo(parent)

	if columnCount == 1 then
		for _, skillId in ipairs(skillIds) do
			itemBuilder(container, nil, skillId, true)
		end
		return container
	end

	local col = 0
	local row = nil
	for _, skillId in ipairs(skillIds) do
		if col == 0 then
			row = UiWeightLayout()
				:width(1)
				:hgap(GRID_GAP)
				:addTo(container)
		end
		itemBuilder(container, row, skillId, true)
		col = col + 1
		if col >= columnCount then
			col = 0
		end
	end

	return container
end

function skill_choice_ui:buildSkillUi(parent, rowParent, skillId, fullWidth)
	local skillInfo = self:getSkillDisplayInfo(skillId)
	local decoText = self:buildSkillRowText(skillInfo)
	local target = rowParent or parent

	local skill = Ui()
	if fullWidth then
		skill:width(1)
	else
		skill:widthpx(self:calcSkillRowWidth(skillInfo, decoText, BUTTON_MIN_WIDTH, fullWidth) or BUTTON_MIN_WIDTH)
	end
	skill:heightpx(ROW_HEIGHT)
		:decorate(self:buildSkillRowDecorations("display", skillInfo, decoText))
		:addTo(target)

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

	return self:buildSkillRowsLayout(parent, skillIds, function(container, row, skillId, fullWidth)
		self:buildSkillUi(container, row, skillId, fullWidth)
	end)
end

function skill_choice_ui:buildHeaderSection(parent, session)
	local earnedSkillIds = self:getPilotEarnedSkillIds(session.pilot, session.slotIndex)
	local headerHeight = self:calcHeaderHeight(#earnedSkillIds)

	local headerRow = UiWeightLayout()
		:width(1)
		:heightpx(headerHeight)
		:hgap(HEADER_INNER_GAP)
		:addTo(parent)

	local portraitColumn = UiBoxLayout()
		:widthpx(PORTRAIT_COLUMN_WIDTH)
		:vgap(6)
		:addTo(headerRow)

	local portraitSurface = self:getPilotPortraitSurface(session.pilot)
	local portraitDecorations = { DecoFrame(), DecoAlign(0, 0) }
	if portraitSurface then
		table.insert(portraitDecorations, DecoSurface(portraitSurface))
	end

	Ui()
		:widthpx(PORTRAIT_SIZE)
		:heightpx(PORTRAIT_SIZE)
		:decorate(portraitDecorations)
		:addTo(portraitColumn)

	local pilotName = self:getPilotDisplayName(session.pilot)
	Ui()
		:widthpx(PORTRAIT_COLUMN_WIDTH)
		:heightpx(24)
		:decorate({ DecoCAlignedText(pilotName) })
		:addTo(portraitColumn)

	local skillsColumn = UiBoxLayout()
		:width(1)
		:vgap(6)
		:addTo(headerRow)

	Ui()
		:width(1)
		:heightpx(20)
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

function skill_choice_ui:buildSkillOptionButton(parent, rowParent, skillId, fullWidth, session)
	local skillInfo = self:getSkillDisplayInfo(skillId)
	local decoText = self:buildSkillRowText(skillInfo)
	local target = rowParent or parent

	local btn = Ui()
	if fullWidth then
		btn:width(1)
	else
		btn:widthpx(self:calcSkillRowWidth(skillInfo, decoText, BUTTON_MIN_WIDTH, fullWidth) or BUTTON_MIN_WIDTH)
	end
	btn:heightpx(ROW_HEIGHT)
		:decorate(self:buildSkillRowDecorations("default", skillInfo, decoText))
		:addTo(target)

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
	return self:buildSkillRowsLayout(parent, session.choices, function(container, row, skillId, fullWidth)
		self:buildSkillOptionButton(container, row, skillId, fullWidth, session)
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
		maxH = DIALOG_HEIGHT_PCT * ScreenSizeY(),
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
		"Pilot Levelled Up",
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

function skill_choice_ui:clearStoredChoiceCache()
	self:ensureChoiceSaveData()
	GAME.cplus_plus_ex.pilotSkillChoices = {}
end

function skill_choice_ui:onResetTurn()
	self:clearStoredChoiceCache()
	self:resetCplusRandomSession()
	self:clearPendingDialogs()
end

function skill_choice_ui:load()
	memhack:addPilotChangedHook(function(pilot, changes)
		self:onPilotLevelChanged(pilot, changes)
	end)

	if modapiext and modapiext.addResetTurnHook then
		modapiext:addResetTurnHook(function()
			self:onResetTurn()
		end)
	end

	modApi.events.onGameExited:subscribe(function()
		self:clearPendingDialogs()
	end)

	modApi.events.onGameVictory:subscribe(function()
		self:clearPendingDialogs()
	end)
end

return skill_choice_ui
