local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath
local scriptPath = mod.scriptPath

-- Register with logging system
local DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("Pilots+", "Warbot", DEBUG)

-- Require the pilotSkill_tooltip library
local pilotSkill_tooltip = require(scriptPath .. "libs/pilotSkill_tooltip")

local pilot = {
	Id = "Pilot_Warbot",
	Personality = "Warbot_Personality",
	Name = "Warbot",
	Sex = SEX_MALE,
	Skill = "Combat Protocols",
	Voice = "/voice/ralph",
}

local dialog = require(path .. "scripts/pilots/dialog_warbot")

function this:GetPilot()
	return pilot
end

-- Initialize GAME save data structure
function this:initGameSaveData()
	if GAME == nil then
		GAME = {}
	end

	if GAME.pilots_plus == nil then
		GAME.pilots_plus = {}
	end

	if GAME.pilots_plus.warbot == nil then
		GAME.pilots_plus.warbot = {}
	end

	if GAME.pilots_plus.warbot.added_count == nil then
		GAME.pilots_plus.warbot.added_count = 0
	end
end

function this:addVirtualSkills(pilotStruct)
	-- Warbot gains skills equal to their level
	-- At level 1: 1 skill, level 2: 3 skills (2 more)
	local pilotLevel = pilotStruct:getLevel()
	if pilotLevel < 1 then
		return
	end

	self:initGameSaveData()

	local pilotId = pilotStruct:getIdStr()
	local targetSkillCount = pilotLevel == 1 and 1 or 3
	local currentSkillCount = GAME.pilots_plus.warbot.added_count

	-- Check if we already have the right number of skills
	if currentSkillCount < targetSkillCount then
		-- Add the missing skills
		local skillsToAdd = targetSkillCount - currentSkillCount
		logger.logDebug(SUBMODULE, "Warbot %s needs %d more virtual skills (current: %d, target: %d)",
				pilotId, skillsToAdd, currentSkillCount, targetSkillCount)
		local addedCount, _ = cplus_plus_ex:addRandomVirtualSkillsToPilot(pilotStruct, skillsToAdd, "warbot")
		GAME.pilots_plus.warbot.added_count = GAME.pilots_plus.warbot.added_count + addedCount
	else
		logger.logDebug(SUBMODULE, "Warbot %s already has %d/%d virtual skills",
				pilotId, currentSkillCount, targetSkillCount)
	end
	for i, skillId in ipairs(cplus_plus_ex:getVirtualSkills(pilotId)) do
		logger.logDebug(SUBMODULE, "  Virtual Skill %d: %s", i, skillId)
	end
end

function this:init(mod)
	logger.logDebug(SUBMODULE, "Initializing Warbot pilot")

	-- Create the pilot
	CreatePilot(pilot)

	-- Use pilotSkill_tooltip for the base registration, then override for dynamic behavior
	pilotSkill_tooltip.Add(pilot.Skill, PilotSkill(pilot.Skill,
			"Gets two level up skills at level 1 and five at level 2."))

	-- Register as a virtual skill source. Not strictly needed since we re-roll anyways
	cplus_plus_ex:registerVirtualSkillSource("warbot")

	logger.logDebug(SUBMODULE, "Warbot pilot initialized")
end

-- Handle pilot level changes to add virtual skills
-- Uses skill ID check to work with any pilot that has Combat Protocols
function this:onPilotLevelChanged(pilotStruct, changes)
	if not changes.level then
		return
	end
	-- Check by skill ID to be more generic
	local pilotSkill = pilotStruct:getSkill():get()
	if pilotSkill == pilot.Skill then
		logger.logDebug(SUBMODULE, "Warbot level changed to %d, checking virtual skills", pilotStruct:getLevel())
		self:addVirtualSkills(pilotStruct)
	end
end

-- Handle skill assignment completion to ensure virtual skills are correct
-- Uses skill ID check to work with any pilot that has Combat Protocols
function this:onSkillsAssigned()
	if not Game then return end

	local pilots = Game:GetAvailablePilots()
	for _, pilotStruct in ipairs(pilots) do
		-- Check by skill ID to be more generic
		local pilotSkill = pilotStruct:getSkill():get()
		if pilotSkill == pilot.Skill then
			logger.logDebug(SUBMODULE, "Skills assigned event, checking Warbot virtual skills")
			self:addVirtualSkills(pilotStruct)
		end
	end
end

function this:load(options, version)
	logger.logDebug(SUBMODULE, "Loading Warbot pilot module")

	-- Use memhack's onPilotChanged event which fires when pilot properties change
	memhack:addPilotChangedHook(function(pilotStruct, changes)
		self:onPilotLevelChanged(pilotStruct, changes)
	end)

	-- After skills are assigned, ensure warbot has the correct number of virtual skills
	cplus_plus_ex:addPostAssigningLvlUpSkillsHook(function()
		self:onSkillsAssigned()
	end)

	-- Register warbot's added_count data to persist across time travel
	cplus_plus_ex:registerTimeTravelerData(
		"pilots_plus",
		"warbot_added_count",
		function(pilotId)
			-- Only save for Warbot pilot
			if pilotId == pilot.Id then
				-- We only need to store the count as virtual skills are handled by basic virtual logic
				local count = (GAME and GAME.pilots_plus and GAME.pilots_plus.warbot and GAME.pilots_plus.warbot.added_count) or 0
				logger.logDebug(SUBMODULE, "Saving warbot added_count for time traveler: %d", count)
				return count
			end
			return nil
		end,
		function(pilotId, value)
			-- Only restore for Warbot pilot
			if pilotId == pilot.Id and value ~= nil then
				self:initGameSaveData()
				GAME.pilots_plus.warbot.added_count = value
				logger.logInfo(SUBMODULE, "Restored warbot added_count from time travel: %d", value)
			end
		end
	)
end

-- Register personality with dialog
CreatePilotPersonality(pilot.Personality, dialog)

Pilot_Warbot_Ref = this
return Pilot_Warbot_Ref
