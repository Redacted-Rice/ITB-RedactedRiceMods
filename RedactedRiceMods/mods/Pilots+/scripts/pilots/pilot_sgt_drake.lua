local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath
local scriptPath = mod.scriptPath

-- Register with logging system
local DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("Pilots+", "SgtDrake", DEBUG)

local pilot = {
	Id = "Pilot_Sgt_Drake",
	Personality = "Sgt_Drake_Personality",
	Name = "Sgt. Drake",
	Sex = SEX_MALE,
	Skill = "Combat Mentor",
	Voice = "/voice/ralph",
}

local dialog = require(path .. "scripts/pilots/dialog_sgt_drake")

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

	if GAME.pilots_plus.veteran_skills == nil then
		GAME.pilots_plus.veteran_skills = {}
	end
end

-- Give a random virtual skill to each other pilot after mission completion
function this:onMissionEnd(mission)
	if not Game then return end

	self:initGameSaveData()

	local pilots = Game:GetAvailablePilots()
	local veteranPresent = false
	local veteranPilotId = nil

	-- Check if Sgt. Drake is in the squad
	for _, pilotStruct in ipairs(pilots) do
		local pilotSkill = pilotStruct:getSkill():get()
		if pilotSkill == pilot.Skill then
			veteranPresent = true
			veteranPilotId = pilotStruct:getIdStr()
			break
		end
	end

	if not veteranPresent then
		logger.logDebug(SUBMODULE, "Sgt. Drake not present, skipping veteran training")
		return
	end

	-- Give each other pilot a virtual skill (teaching them combat tricks)
	for _, pilotStruct in ipairs(pilots) do
		local pilotId = pilotStruct:getIdStr()
		local pilotSkill = pilotStruct:getSkill():get()

		-- Skip the veteran themselves
		if pilotSkill ~= pilot.Skill then
			logger.logInfo(SUBMODULE, "Teaching combat tricks to pilot %s", pilotId)

			-- Track that this pilot received veteran training
			if not GAME.pilots_plus.veteran_skills[pilotId] then
				GAME.pilots_plus.veteran_skills[pilotId] = {}
			end

			-- Get current virtual skills to see what was added
			local beforeSkills = cplus_plus_ex:getVirtualSkills(pilotId)

			-- Add one random virtual skill
			cplus_plus_ex:addRandomVirtualSkillsToPilot(pilotStruct, 1)

			-- Get new virtual skills to see what was added
			local afterSkills = cplus_plus_ex:getVirtualSkills(pilotId)

			-- Find the newly added skill
			for _, skillId in ipairs(afterSkills) do
				local isNew = true
				for _, oldSkillId in ipairs(beforeSkills) do
					if skillId == oldSkillId then
						isNew = false
						break
					end
				end
				if isNew then
					table.insert(GAME.pilots_plus.veteran_skills[pilotId], skillId)
					logger.logInfo(SUBMODULE, "Pilot %s learned combat trick %s from Sgt. Drake", pilotId, skillId)
				end
			end
		end
	end
end

-- Clear all veteran-granted virtual skills at the end of a run
function this:clearVeteranSkills()
	if not Game then return end

	self:initGameSaveData()

	local pilots = Game:GetAvailablePilots()

	-- Clear virtual skills from all pilots who received veteran training
	for pilotId, veteranSkills in pairs(GAME.pilots_plus.veteran_skills) do
		-- Find the pilot struct
		local pilotStruct = nil
		for _, p in ipairs(pilots) do
			if p:getIdStr() == pilotId then
				pilotStruct = p
				break
			end
		end

		if pilotStruct then
			logger.logInfo(SUBMODULE, "Clearing %d veteran skills from pilot %s", #veteranSkills, pilotId)

			-- Remove each veteran-granted skill
			for _, skillId in ipairs(veteranSkills) do
				cplus_plus_ex:removeVirtualSkillFromPilot(pilotStruct, skillId)
				logger.logDebug(SUBMODULE, "Removed veteran skill %s from pilot %s", skillId, pilotId)
			end
		end
	end

	-- Clear the tracking data
	GAME.pilots_plus.veteran_skills = {}
	logger.logDebug(SUBMODULE, "Veteran combat tricks cleared at end of run")
end

-- Build skill description showing current state
function this:buildSkillDescription()
	local description = "After each mission, teaches the squad combat tricks learned from years of experience, granting them one random level up skill. These lessons fade at the end of the run."

	-- Try to get virtual skills info from current game
	if Game then
		local pilots = Game:GetAvailablePilots()
		local hasVeteranSkills = false
		local squadInfo = {}

		self:initGameSaveData()

		-- Check if any pilots have veteran training
		for _, pilotStruct in ipairs(pilots) do
			local pilotId = pilotStruct:getIdStr()
			local pilotSkill = pilotStruct:getSkill():get()

			-- Skip Sgt. Drake themselves
			if pilotSkill ~= pilot.Skill then
				local veteranSkills = GAME.pilots_plus.veteran_skills[pilotId]

				if veteranSkills and #veteranSkills > 0 then
					hasVeteranSkills = true
					local pilotName = pilotStruct:getName():get()
					local skillNames = {}

					for _, skillId in ipairs(veteranSkills) do
						local skillData = cplus_plus_ex:getRegisteredSkillInfo(skillId)
						if skillData then
							local name = GetText(skillData.fullName)
							table.insert(skillNames, name)
						end
					end

					if #skillNames > 0 then
						table.insert(squadInfo, pilotName .. ": " .. table.concat(skillNames, ", "))
					end
				end
			end
		end

		if hasVeteranSkills then
			description = description .. "\n\nLessons taught:\n" .. table.concat(squadInfo, "\n")
		end
	end

	return description
end

function this:init(mod)
	logger.logDebug(SUBMODULE, "Initializing Sgt. Drake pilot")

	-- Create the pilot
	CreatePilot(pilot)

	-- Override GetSkillInfo to dynamically show veteran training
	local originalGetSkillInfo = GetSkillInfo
	function GetSkillInfo(skill)
		if skill == pilot.Skill then
			return PilotSkill(pilot.Skill, self:buildSkillDescription())
		end
		return originalGetSkillInfo(skill)
	end

	logger.logDebug(SUBMODULE, "Sgt. Drake pilot initialized")
end

function this:load(options, version)
	logger.logDebug(SUBMODULE, "Loading Sgt. Drake pilot module")

	-- Subscribe to mission end to grant skills
	modApi.events.onMissionEnd:subscribe(function(mission)
		self:onMissionEnd(mission)
	end)

	-- Subscribe to game exit to clear veteran skills
	modApi.events.onGameExited:subscribe(function()
		logger.logDebug(SUBMODULE, "Game exited, clearing veteran combat tricks")
		self:clearVeteranSkills()
	end)

	-- Subscribe to game victory to clear veteran skills
	modApi.events.onGameVictory:subscribe(function()
		logger.logDebug(SUBMODULE, "Game victory, clearing veteran combat tricks")
		self:clearVeteranSkills()
	end)

	-- Initialize at mission start (in case of save/load issues)
	modApi:addMissionStartHook(function(mission)
		self:initGameSaveData()
		-- Don't clear here, just initialize
	end)
end

-- Register personality with dialog
CreatePilotPersonality(pilot.Personality, dialog)

Pilot_Sgt_Drake_Ref = this
return Pilot_Sgt_Drake_Ref
