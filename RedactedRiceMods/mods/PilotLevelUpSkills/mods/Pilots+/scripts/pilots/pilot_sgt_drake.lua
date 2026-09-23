local this = {}

local mod = mod_loader.mods[modApi.currentMod]
local path = mod.resourcePath
local scriptPath = mod.scriptPath

-- Register with logging system
local DEBUG = false
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

	local pilots = Game:GetSquadPilots()
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
		local pilotUid = pilotStruct:getUidStr()
		local pilotSkill = pilotStruct:getSkill():get()

		-- Skip Sgt. Drake themselves
		if pilotSkill ~= pilot.Skill then
			-- Initialize tracking structures
			if not GAME.pilots_plus.sgt_drake.trained_skills[pilotUid] then
				GAME.pilots_plus.sgt_drake.trained_skills[pilotUid] = {}
			end
			if not GAME.pilots_plus.sgt_drake.mission_count[pilotUid] then
				GAME.pilots_plus.sgt_drake.mission_count[pilotUid] = 0
			end

			-- Check if pilot already has a skill from Sgt. Drake
			local alreadyHasSkill = #GAME.pilots_plus.sgt_drake.trained_skills[pilotUid] > 0

			if not alreadyHasSkill then
				-- Increment mission count
				GAME.pilots_plus.sgt_drake.mission_count[pilotUid] = GAME.pilots_plus.sgt_drake.mission_count[pilotUid] + 1
				local missionCount = GAME.pilots_plus.sgt_drake.mission_count[pilotUid]

				logger.logInfo(SUBMODULE, "Pilot %s trained with Sgt. Drake (%d/3 missions)", pilotUid, missionCount)

				-- Grant skill after 3 missions
				if missionCount >= 3 then
					logger.logInfo(SUBMODULE, "Pilot %s completed training, teaching combat trick", pilotUid)

					-- Add one random virtual skill with sgt_drake source and get the selected skills
					local successCount, selectedSkills = cplus_plus_ex:addRandomVirtualSkillsToPilot(pilotStruct, 1, "sgt_drake")

					-- Track the granted skills
					if successCount > 0 and #selectedSkills > 0 then
						for _, skillId in ipairs(selectedSkills) do
							table.insert(GAME.pilots_plus.sgt_drake.trained_skills[pilotUid], skillId)
							logger.logInfo(SUBMODULE, "Pilot %s learned combat trick %s from Sgt. Drake", pilotUid, skillId)
						end
					end
				end
			else
				logger.logInfo(SUBMODULE, "Pilot %s already has a skill from Sgt. Drake, skipping", pilotUid)
			end
		end
	end
end

function this:init(mod)
	logger.logDebug(SUBMODULE, "Initializing Sgt. Drake pilot")

	-- Create the pilot
	CreatePilot(pilot)
	pilotSkill_tooltip.Add(pilot.Skill, PilotSkill(pilot.Skill,
			"A pilot completing 3 missions with Sgt. Drake gains a level up skill"))

	-- Register Sgt Drake as a virtual skill source. Not strictly needed since we re-roll anyways
	cplus_plus_ex:registerVirtualSkillSource("sgt_drake")

	logger.logDebug(SUBMODULE, "Sgt. Drake pilot initialized")
end

-- Handler for extra info UI hook
function this:onExtraInfoSelectedChanged(uiObj, pawn, pilotStruct)
	-- Add nil checks for all parameters
	if not uiObj or not pawn or not pilotStruct then
		logger.logDebug(SUBMODULE, "onExtraInfoSelectedChanged called with nil parameter (uiObj=%s, pawn=%s, pilot=%s)",
			tostring(uiObj ~= nil), tostring(pawn ~= nil), tostring(pilotStruct ~= nil))
		return
	end

	if not GAME or not GAME.pilots_plus then
		return
	end

	local pilotUid = pilotStruct:getUidStr()
	local pilotSkill = pilotStruct:getSkill():get()

	-- Don't show for Sgt. Drake himself
	if pilotSkill == pilot.Skill then
		return
	end

	self:initGameSaveData()

	local missionCount = GAME.pilots_plus.sgt_drake.mission_count[pilotUid] or 0
	local hasSkill = GAME.pilots_plus.sgt_drake.trained_skills[pilotUid]
		and #GAME.pilots_plus.sgt_drake.trained_skills[pilotUid] > 0

	-- Check if Sgt. Drake is in the squad
	local drakePresent = false
	if Game then
		local pilots = Game:GetSquadPilots()
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
	local title = "Sgt. Drake Training"
	local description = ""
	if hasSkill then
		description = "Training Complete"
	elseif drakePresent then
		description = string.format("Progress: %d/3 missions", missionCount)
	end

	-- Add icon to UI
	local iconPath = mod.resourcePath .. "img/combat/icons/icon_sgt_drake_training.png"
	uiObj:addIcon(iconPath, title, description)
	logger.logDebug(SUBMODULE, "Added training status icon for pilot %s: %s", pilotUid, description)
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

	-- Register Sgt Drake's training data to persist across time travel
	cplus_plus_ex:registerTimeTravelerData(
		"pilots_plus",
		"sgt_drake_training",
		function(pilotStruct)
			local pilotUid = pilotStruct:getUidStr()
			if GAME and GAME.pilots_plus and GAME.pilots_plus.sgt_drake
					and GAME.pilots_plus.sgt_drake.mission_count[pilotUid] then
				local trainingData = {
					trained_skills = GAME.pilots_plus.sgt_drake.trained_skills[pilotUid],
					mission_count = GAME.pilots_plus.sgt_drake.mission_count[pilotUid],
				}
				logger.logDebug(SUBMODULE, "Saving Sgt Drake training data for pilot %s", pilotUid)
				return trainingData
			end
			return nil
		end,
		function(pilotStruct, value)
			if value ~= nil and type(value) == "table" then
				self:initGameSaveData()
				local pilotUid = pilotStruct:getUidStr()
				GAME.pilots_plus.sgt_drake.trained_skills[pilotUid] = value.trained_skills or {}
				GAME.pilots_plus.sgt_drake.mission_count[pilotUid] = value.mission_count or 0
				logger.logInfo(SUBMODULE, "Restored Sgt Drake training data for pilot %s: %d missions, %d skills",
						pilotUid, value.mission_count or 0, (value.trained_skills and #value.trained_skills) or 0)
			end
		end
	)
end

-- Register personality with dialog
local personality = CreatePilotPersonality(pilot.Personality, pilot.Name)
personality:AddDialogTable(dialog)
Personality[pilot.Personality] = personality

Pilot_Sgt_Drake_Ref = this
return Pilot_Sgt_Drake_Ref
