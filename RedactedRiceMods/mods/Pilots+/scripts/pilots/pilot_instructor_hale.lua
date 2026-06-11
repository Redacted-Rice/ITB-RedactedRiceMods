local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath
local scriptPath = mod.scriptPath

local DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("Pilots+", "InstructorHale", DEBUG)

local pilotSkill_tooltip = require(scriptPath .. "libs/pilotSkill_tooltip")

local MISSIONS_TO_TEACH = 3
local MAX_SKILLS_PER_TRAINEE = 2
local VIRTUAL_SKILL_SOURCE = "instructor_hale"

local pilot = {
	Id = "Pilot_Instructor_Hale",
	Personality = "Instructor_Hale_Personality",
	Name = "Instructor Hale",
	Sex = SEX_FEMALE,
	Skill = "Knowledge Share",
	Voice = "/voice/bethany",
}

local dialog = require(path .. "scripts/pilots/dialog_instructor_hale")

function this:GetPilot()
	return pilot
end

function this:initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.pilots_plus == nil then
		GAME.pilots_plus = {}
	end

	if GAME.pilots_plus.instructor_hale == nil then
		GAME.pilots_plus.instructor_hale = {}
	end

	-- Ordered queue: { traineeId, skillId, missionCount }
	-- Array order is priority. First in-squad entry is the active trainee.
	if GAME.pilots_plus.instructor_hale.trainings == nil then
		GAME.pilots_plus.instructor_hale.trainings = {}
	end

	-- Finished pass-downs: trained_skills[traineeId] = { skillId, ... } (max 2 per pilot)
	if GAME.pilots_plus.instructor_hale.trained_skills == nil then
		GAME.pilots_plus.instructor_hale.trained_skills = {}
	end
end

function this:getSaveData()
	self:initGameSaveData()
	return GAME.pilots_plus.instructor_hale
end

function this:getTrainedSkillCount(traineeId)
	local trainedSkills = self:getSaveData().trained_skills[traineeId]
	return trainedSkills and #trainedSkills or 0
end

function this:findPilotInSquad(pilotId)
	if not Game or not pilotId then
		return nil
	end

	for _, pilotStruct in ipairs(Game:GetSquadPilots()) do
		if pilotStruct:getIdStr() == pilotId then
			return pilotStruct
		end
	end
	return nil
end

-- Skills this trainee can still receive from Hale
-- i.e. earned by Hale and not already learned
function this:getRemainingSkills(mentorStruct, traineeStruct)
	local remaining = {}
	local traineeId = traineeStruct:getIdStr()

	-- See if we can learn more skills
	local trainedCount = self:getTrainedSkillCount(traineeId)
	if trainedCount >= MAX_SKILLS_PER_TRAINEE then
		return remaining
	end

	-- See what skills this trainee can learn from Hale still
	for _, skillId in ipairs(cplus_plus_ex:getPilotEarnedSkillIds(mentorStruct)) do
		if not cplus_plus_ex:isSkillOnPilot(skillId, traineeStruct, true) then
			table.insert(remaining, skillId)
		end
	end
	return remaining
end

function this:getSkillDisplayName(skillId)
	local skillInfo = cplus_plus_ex:getRegisteredSkillInfo(skillId)
	if skillInfo and skillInfo.fullName then
		return GetText(skillInfo.fullName) or skillId
	end
	return skillId
end

-- Squad pilots (excluding Hale) who still have at least one skill they can learn from her.
function this:getEligibleTrainees(mentorStruct)
	local eligible = {}
	for _, traineeStruct in ipairs(Game:GetSquadPilots()) do
		if traineeStruct:getSkill():get() ~= pilot.Skill then
			if #self:getRemainingSkills(mentorStruct, traineeStruct) > 0 then
				table.insert(eligible, traineeStruct)
			end
		end
	end
	return eligible
end

-- Active trainee is the first trainings entry whose pilot is currently in a mech.
-- If the first pilot is not in the squad, move to the next until we find one
function this:getActiveTraining(saveData)
	saveData = saveData or self:getSaveData()

	for _, training in ipairs(saveData.trainings) do
		if self:findPilotInSquad(training.traineeId) then
			return training
		end
	end
	return nil
end

-- Pick a random eligible squad pilot and random remaining skill and append to the trainings queue.
function this:startNewTraining(mentorStruct)
	local eligibleTrainees = self:getEligibleTrainees(mentorStruct)
	if #eligibleTrainees == 0 then
		return nil
	end

	local traineeStruct = random_element(eligibleTrainees)
	local remaining = self:getRemainingSkills(mentorStruct, traineeStruct)
	local training = {
		traineeId = traineeStruct:getIdStr(),
		skillId = random_element(remaining),
		missionCount = 0,
	}

	table.insert(self:getSaveData().trainings, training)
	logger.logInfo(SUBMODULE, "Started training %s on %s from Instructor Hale",
			training.skillId, training.traineeId)
	return training
end

function this:removeTraining(training)
	local saveData = self:getSaveData()
	for index, entry in ipairs(saveData.trainings) do
		if entry == training then
			table.remove(saveData.trainings, index)
			return
		end
	end
end

-- True when the trainee is in squad and already has the assigned skill somehow
function this:traineeHasAssignedSkill(training)
	local traineeStruct = self:findPilotInSquad(training.traineeId)
	if not traineeStruct then
		return false
	end
	return cplus_plus_ex:isSkillOnPilot(training.skillId, traineeStruct, true)
end

-- Drop stale queue entries where the trainee already has the skill, then return the active
-- training or start a new one if there is no active training
function this:resolveActiveTraining(mentorStruct, saveData)
	local activeTraining = self:getActiveTraining(saveData)
	while activeTraining and self:traineeHasAssignedSkill(activeTraining) do
		logger.logInfo(SUBMODULE, "Trainee %s already has %s; clearing stale training",
				activeTraining.traineeId, activeTraining.skillId)
		self:removeTraining(activeTraining)
		activeTraining = self:getActiveTraining(saveData)
	end

	if not activeTraining then
		activeTraining = self:startNewTraining(mentorStruct)
	end
	return activeTraining
end

-- Grant the assigned skill as a virtual skill and record in trained_skills on success.
function this:grantTraining(training)
	local traineeStruct = self:findPilotInSquad(training.traineeId)
	if not traineeStruct then
		logger.logWarn(SUBMODULE, "Trainee %s not available to receive %s", training.traineeId, training.skillId)
		return false
	end

	local success = cplus_plus_ex:addVirtualSkillToPilot(traineeStruct, training.skillId, VIRTUAL_SKILL_SOURCE)
	if success then
		local saveData = self:getSaveData()
		if not saveData.trained_skills[training.traineeId] then
			saveData.trained_skills[training.traineeId] = {}
		end
		table.insert(saveData.trained_skills[training.traineeId], training.skillId)
		logger.logInfo(SUBMODULE, "Pilot %s learned %s from Instructor Hale",
				training.traineeId, training.skillId)
	end
	return success
end

-- Runs after each mission. Hale must be in a mech and have at least one earned skill.
function this:onMissionEnd(mission)
	if not Game then
		return
	end

	-- Find Hale in the current squad
	local mentorStruct = nil
	for _, pilotStruct in ipairs(Game:GetSquadPilots()) do
		if pilotStruct:getSkill():get() == pilot.Skill then
			mentorStruct = pilotStruct
			break
		end
	end
	if not mentorStruct then
		logger.logDebug(SUBMODULE, "Instructor Hale not present, skipping pass-down")
		return
	end

	-- Hale needs at least one earned level up skill before she can teach anything
	if #cplus_plus_ex:getPilotEarnedSkillIndexes(mentorStruct) == 0 then
		logger.logDebug(SUBMODULE, "Instructor Hale has no earned skills yet")
		return
	end

	local saveData = self:getSaveData()

	-- Clear stale entries, pick active trainee, or start a new training when the queue is empty
	local activeTraining = self:resolveActiveTraining(mentorStruct, saveData)
	if not activeTraining then
		return
	end

	-- Increment progress
	if activeTraining.missionCount < MISSIONS_TO_TEACH then
		activeTraining.missionCount = activeTraining.missionCount + 1
		logger.logInfo(SUBMODULE, "Training progress for %s (%s): %d/%d missions",
				activeTraining.traineeId, activeTraining.skillId, activeTraining.missionCount, MISSIONS_TO_TEACH)
	end

	-- When the trainee has completed the training, grant the skill, record in trained_skills,
	-- and remove from trainings queue.
	-- Next eligible pilot is picked on a future mission end when the queue is empty again.
	if activeTraining.missionCount >= MISSIONS_TO_TEACH then
		if self:grantTraining(activeTraining) then
			self:removeTraining(activeTraining)
		end
	end
end

-- Hale's info will show all in progress queue entries
function this:buildMentorDescription(saveData)
	local activeTraining = self:getActiveTraining(saveData)
	local lines = {}

	for _, training in ipairs(saveData.trainings) do
		local traineeName = cplus_plus_ex:getPilotDisplayName(training.traineeId)
		local skillName = self:getSkillDisplayName(training.skillId)
		local status = training == activeTraining and " - Active" or " - In Progress"

		table.insert(lines,
			string.format("%s: %s (%d/%d missions)%s",
					traineeName, skillName, training.missionCount, MISSIONS_TO_TEACH, status)
		)
	end

	if #lines == 0 then
		return "No active training."
	end
	return table.concat(lines, "\n")
end

-- Trainee info will show in progress from trainings and completed from trained skills.
function this:buildTraineeDescription(traineeId, saveData, mentorStruct, traineeStruct)
	local lines = {}
	local activeTraining = self:getActiveTraining(saveData)

	-- Current in progress skill(s) from the trainings queue
	if saveData.trainings then
		for _, training in ipairs(saveData.trainings) do
			if training.traineeId == traineeId and training.missionCount >= 1 then
				local skillName = self:getSkillDisplayName(training.skillId)
				local line = string.format("%s (%d/%d missions)", skillName, training.missionCount, MISSIONS_TO_TEACH)
				if training ~= activeTraining then
					line = line .. " - In Progress"
				end
				table.insert(lines, line)
			end
		end
	end

	-- Completed skills
	local trainedSkills = saveData.trained_skills and saveData.trained_skills[traineeId] or nil
	if trainedSkills then
		for _, skillId in ipairs(trainedSkills) do
			table.insert(lines, self:getSkillDisplayName(skillId) .. " - Complete")
		end
	end

	-- Show whether they can still learn more from Hale
	local remainingCount = mentorStruct and #self:getRemainingSkills(mentorStruct, traineeStruct) or 0
	if remainingCount > 0 then
		table.insert(lines, string.format("Can learn %d more from Hale.", remainingCount))
	elseif mentorStruct then
		table.insert(lines, "No more skills to learn from Hale.")
	end

	return #lines > 0 and table.concat(lines, "\n") or nil
end

function this:onExtraInfoSelectedChanged(uiObj, pawn, pilotStruct)
	if not uiObj or not pilotStruct then
		return
	end
	if not GAME or not GAME.pilots_plus then
		return
	end

	-- Try to find Hale anywhere in the run
	local mentorStruct = nil
	if Game then
		for _, p in ipairs(Game:GetAvailablePilots()) do
			if p:getIdStr() == pilot.Id then
				mentorStruct = p
				break
			end
		end
	end

	local pilotId = pilotStruct:getIdStr()
	local pilotSkill = pilotStruct:getSkill():get()
	local saveData = self:getSaveData()
	local iconPath = mod.resourcePath .. "img/combat/icons/icon_instructor_hale_training.png"

	-- If it's Hale, show her training queue
	if pilotSkill == pilot.Skill then
		uiObj:addIcon(iconPath, "Knowledge Sharing", self:buildMentorDescription(saveData))
		return
	end

	-- If it's not Hale but has some of her training, display the icon
	local description = self:buildTraineeDescription(pilotId, saveData, mentorStruct, pilotStruct)
	if not description then
		return
	end
	uiObj:addIcon(iconPath, "Training under Hale", description)
end

function this:init(mod)
	logger.logDebug(SUBMODULE, "Initializing Instructor Hale pilot")

	CreatePilot(pilot)
	pilotSkill_tooltip.Add(pilot.Skill, PilotSkill(pilot.Skill,
		"Every 3 missions, passes one of your earned level up skills to another pilot in the squad."))

	-- Don't re-roll invalidated skills - just remove them
	cplus_plus_ex:registerVirtualSkillSource(VIRTUAL_SKILL_SOURCE, function()
		return nil
	end)

	logger.logDebug(SUBMODULE, "Instructor Hale pilot initialized")
end

function this:load(options, version)
	logger.logDebug(SUBMODULE, "Loading Instructor Hale pilot module")

	modApi:addMissionEndHook(function(mission)
		self:onMissionEnd(mission)
	end)

	cplus_plus_ex:addExtraInfoSelectedChangedHook(function(ui, pawn, pilotStruct)
		self:onExtraInfoSelectedChanged(ui, pawn, pilotStruct)
	end)

	-- Carry over training queue on Hale and completed skills per trainee (max 2 each)
	cplus_plus_ex:registerTimeTravelerData(
		"pilots_plus",
		"instructor_hale_training",
		function(pilotId)
			-- Nothing needs to be saved for Hale
			if pilotId == pilot.Id then
				return
			end

			local saveData = self:getSaveData()
			local trainedSkills = saveData.trained_skills[pilotId]
			if trainedSkills and #trainedSkills > 0 then
				return trainedSkills
			end
			return nil
		end,
		function(pilotId, value)
			if value == nil or type(value) ~= "table" then
				return
			end
			-- Nothing needs to be saved for Hale
			if pilotId == pilot.Id then
				return
			end

			local saveData = self:getSaveData()
			saveData.trained_skills[pilotId] = value
			logger.logInfo(SUBMODULE, "Restored Hale pass-down history for pilot %s (%d skills)",
					pilotId, #value)
		end
	)
end

local personality = CreatePilotPersonality(pilot.Personality, pilot.Name)
personality:AddDialogTable(dialog)
Personality[pilot.Personality] = personality

Pilot_Instructor_Hale_Ref = this
return Pilot_Instructor_Hale_Ref
