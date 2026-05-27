local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath
local scriptPath = mod.scriptPath

-- Register with logging system
local DEBUG = true
local logger = memhack.logger
local SUBMODULE = logger.register("Pilots+", "SgtDrake", DEBUG)

-- Require the pilotSkill_tooltip library
local pilotSkill_tooltip = require(scriptPath .. "libs/pilotSkill_tooltip")

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

	if GAME.pilots_plus.sgt_drake == nil then
		GAME.pilots_plus.sgt_drake = {}
	end

	if GAME.pilots_plus.sgt_drake.trained_skills == nil then
		GAME.pilots_plus.sgt_drake.trained_skills = {}
	end

	if GAME.pilots_plus.sgt_drake.mission_count == nil then
		GAME.pilots_plus.sgt_drake.mission_count = {}
	end
end

-- Give a random virtual skill to each other pilot after 3 missions with Sgt. Drake. Limited to 1 per pilot
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

	-- Track missions and grant skills for each other pilot
	for _, pilotStruct in ipairs(pilots) do
		local pilotId = pilotStruct:getIdStr()
		local pilotSkill = pilotStruct:getSkill():get()

		-- Skip Sgt. Drake themselves
		if pilotSkill ~= pilot.Skill then
			-- Initialize tracking structures
			if not GAME.pilots_plus.sgt_drake.trained_skills[pilotId] then
				GAME.pilots_plus.sgt_drake.trained_skills[pilotId] = {}
			end
			if not GAME.pilots_plus.sgt_drake.mission_count[pilotId] then
				GAME.pilots_plus.sgt_drake.mission_count[pilotId] = 0
			end

			-- Check if pilot already has a skill from Sgt. Drake
			local alreadyHasSkill = #GAME.pilots_plus.sgt_drake.trained_skills[pilotId] > 0

			if not alreadyHasSkill then
				-- Increment mission count
				GAME.pilots_plus.sgt_drake.mission_count[pilotId] = GAME.pilots_plus.sgt_drake.mission_count[pilotId] + 1
				local missionCount = GAME.pilots_plus.sgt_drake.mission_count[pilotId]

				logger.logInfo(SUBMODULE, "Pilot %s trained with Sgt. Drake (%d/3 missions)", pilotId, missionCount)

				-- Grant skill after 3 missions
				if missionCount >= 3 then
					logger.logInfo(SUBMODULE, "Pilot %s completed training, teaching combat trick", pilotId)

					-- Add one random virtual skill and get the selected skills
					local successCount, selectedSkills = cplus_plus_ex:addRandomVirtualSkillsToPilot(pilotStruct, 1)

					-- Track the granted skills
					if successCount > 0 and #selectedSkills > 0 then
						for _, skillId in ipairs(selectedSkills) do
							table.insert(GAME.pilots_plus.sgt_drake.trained_skills[pilotId], skillId)
							logger.logInfo(SUBMODULE, "Pilot %s learned combat trick %s from Sgt. Drake", pilotId, skillId)
						end
					end
				end
			else
				logger.logDebug(SUBMODULE, "Pilot %s already has a skill from Sgt. Drake, skipping", pilotId)
			end
		end
	end
end

-- Build static skill description
function this:getSkillDescription()
	return "After completing 3 missions with a pilot, the pilot will gain one random level up skill. Training progress and completion is shown in the Extra Info panel."
end

function this:init(mod)
	logger.logDebug(SUBMODULE, "Initializing Sgt. Drake pilot")

	-- Create the pilot
	CreatePilot(pilot)

	-- Register skill tooltip using the pilotSkill_tooltip library
	pilotSkill_tooltip.Add(pilot.Skill, PilotSkill(pilot.Skill, self:getSkillDescription()))

	logger.logDebug(SUBMODULE, "Sgt. Drake pilot initialized")
end

-- Handler for extra info UI hook
function this:onExtraInfoSelectedChanged(ui, pawn, pilotStruct)
	if not pilotStruct or not GAME or not GAME.pilots_plus then
		return
	end

	local pilotId = pilotStruct:getIdStr()
	local pilotSkill = pilotStruct:getSkill():get()

	-- Don't show for Sgt. Drake himself
	if pilotSkill == pilot.Skill then
		return
	end

	self:initGameSaveData()

	local missionCount = GAME.pilots_plus.sgt_drake.mission_count[pilotId] or 0
	local hasSkill = GAME.pilots_plus.sgt_drake.trained_skills[pilotId] and #GAME.pilots_plus.sgt_drake.trained_skills[pilotId] > 0

	-- Check if Sgt. Drake is in the squad
	local drakePresent = false
	if Game then
		local pilots = Game:GetAvailablePilots()
		for _, p in ipairs(pilots) do
			local skill = p:getSkill():get()
			if skill == pilot.Skill then
				drakePresent = true
				break
			end
		end
	end

	-- Only show if Drake is present OR pilot has completed training
	if not drakePresent and not hasSkill then
		return
	end

	-- Build status text
	local statusText = ""
	if hasSkill then
		statusText = "Training Complete"
	elseif drakePresent then
		statusText = string.format("Progress: %d/3 missions", missionCount)
		if missionCount < 3 then
			statusText = statusText .. string.format(" (%d more needed)", 3 - missionCount)
		end
	end

	-- Add section to UI
	ui:addAdditionalSection("Sgt. Drake Training", statusText)
end

function this:load(options, version)
	logger.logDebug(SUBMODULE, "Loading Sgt. Drake pilot module")

	-- Subscribe to mission end to grant skills
	modApi:addMissionEndHook(function(mission)
		self:onMissionEnd(mission)
	end)

	-- Subscribe to extraInfoSelectedChanged hook to show training status
	cplus_plus_ex:addExtraInfoSelectedChangedHook(function(ui, pawn, pilotStruct)
		self:onExtraInfoSelectedChanged(ui, pawn, pilotStruct)
	end)

	logger.logDebug(SUBMODULE, "Sgt. Drake training status hooked to Extra Info UI")
end

-- Register personality with dialog
CreatePilotPersonality(pilot.Personality, dialog)

Pilot_Sgt_Drake_Ref = this
return Pilot_Sgt_Drake_Ref
